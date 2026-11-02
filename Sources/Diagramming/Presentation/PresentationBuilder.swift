//
//  PresentationBuilder.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 27/05/2026.
//

import PoieticCore

/*
 
  Document Event        | data | geometry | layout
 ────────────────────────+──────+---───────+---------
  Plane change          | yes  | yes      | yes
  Viewport change       | -    | yes(1)   | -
  Interactive preview   | -    | yes      | -
  Style change          | -    | -        | yes
  Notation change       | -    | yes      | -
  Simulation step       | yes  | -        | -
  Selection change      | -    | -        | -
 
 (1): Per-camera/per-presentation.
 
 */

/// Object responsible for creating and synchronising a diagram presentation with model.
///
/// Presentation builder is a stateless bridge between diagram (model) and presentation –
/// a structure with direct renderable representation.
///
/// Main functionality:
///
/// - _Create_ diagram presentation from ``DiagramBlock`` and ``DiagramConnector`` objects.
/// - _Update_ geometry and other data.
/// - _Layout_ labels, indicators and other annotations.
///
/// The typical calls:
///
/// - _Create_: on new design plane, new entities. Creation is free from layout.
/// - _Update_: during interaction or on a simulation step.
/// - _Layout_: during interaction or style change which affects layout metrics,
///             including fonts and their sizes. Typically no need to call during interaction.
///
/// ## Interactivity
///
/// Diagram presentation builder prepares canvas nodes for interactivity by setting
/// ``CollisionShape`` (relative coordinates to parent) or ``ConnectorWire`` (absolute coordinates)
/// on interactive entities together with ``Interactivity/interactive`` component.
///
/// It is up to the application to create and manage ``HitRegion`` components.
///
public class PresentationBuilder {
    public let world: World
    
    public struct Context {
        public let presentation: RuntimeEntity
        public let camera: Camera
        public let toPresentationTransform: AffineTransform

        /// Create a new composer context from a presentation entity.
        ///
        /// Presentation is expected to have a ``Camera`` component on it. If the component is
        /// missing, then default camera (zero offset, zoom 100%) is used.
        ///
        public init(presentation: RuntimeEntity) {
            self.presentation = presentation
            self.camera = presentation.component() ?? Camera()
            self.toPresentationTransform = AffineTransform(translation: -self.camera.offset)
                .scaled(Vector2D(self.camera.zoom, self.camera.zoom))
        }
    }
    
    public init(world: World) {
        self.world = world
    }
    
    /// Creates a diagram entity from all diagram blocks and diagram connectors.
    ///
    /// This is a convenience method. Calling it makes sense only when the diagram entities in the
    /// world are not nested, when all of the entities are top-level.
    ///
    /// - Parameters:
    ///     - world: World in which the diagram is to be created.
    ///     - diagram: Existing diagram entity to which the content is to be attached. If not
    ///       provided, new entity will be created. If provided, existing content will be unrelated.
    ///
    /// - **Input**:
    ///     - Entities with component ``DiagramBlock`` and ``DiagramConnector``.
    /// - **Output**:
    ///     - New diagram entity with input entities related with ``Depicts`` relationship.
    ///
    /// - Returns: Created or recycled diagram entity.
    ///
    public static func createDiagramFromAll(world: World, diagram: RuntimeEntity? = nil) -> RuntimeEntity {
        let result: RuntimeEntity
        if let diagram {
            result = diagram
            result.unrelate(Depicts.self)
        }
        else {
            result = world.spawn(Diagram())
        }
        
        for entity: RuntimeEntity in world.query(DiagramBlock.self) {
            result.relate(Depicts(), to: entity)
        }
        for entity: RuntimeEntity in world.query(DiagramConnector.self) {
            result.relate(Depicts(), to: entity)
        }
        return result
    }
   
    // MARK: - Create
    /// Create a diagram presentation for a given diagram entity.
    ///
    /// Result:
    /// - Presentation root of type ``DiagramPresentation`` which represents the diagram entity through
    ///   ``/PoieticCore/RepresentationOf``.
    /// - Presentation children
    ///     - ``BlockNode`` for each ``DiagramBlock``
    ///     - ``ConnectorNode`` for each ``DiagramConnector``
    ///
    /// Called on:
    /// - New diagram.
    ///
    public func createPresentation(diagram: RuntimeEntity, camera: Camera = Camera()) -> RuntimeEntity {
        let presentation: RuntimeEntity = world.spawn(
            DiagramPresentation(),
            camera
        )
        presentation.relate(RepresentationOf(), to: diagram)
        syncPresentation(presentation)
        return presentation
    }

    // MARK: - Sync
    /// Updates a presentation from the diagram it represents.
    ///
    /// Requirements and Expectations:
    /// - `presentation` requires ``RepresentationOf`` relationship to a ``Diagram`` entity
    /// - (optional) `presentation` is expected to have ``Camera`` component. If not present, then
    ///   default one is created.
    ///
    public func syncPresentation(_ presentation: RuntimeEntity) {
        guard let diagram = presentation.target(RepresentationOf.self) else { return }
        let context = Context(presentation: presentation)

        // Note: We do not have to remove presentation nodes where their represented objects were removed.
        //       This was taken care of automatic despawn through RepresentationOf removal policy.
        
        var originalToPresentation: [RuntimeID:RuntimeID] = [:]
        var existing: [RuntimeID:RuntimeEntity] = [:]

        for child in presentation.children {
            if let rep = child.target(RepresentationOf.self) {
                existing[rep.runtimeID] = child
            }
        }
        for entity in diagram.outgoing(Depicts.self) where entity.contains(DiagramBlock.self) {
            let nodeID: RuntimeID
            if let node = existing[entity.runtimeID] {
                nodeID = node.runtimeID
                syncBlockNode(node, from: entity, context: context)
            } else {
                nodeID = createBlockNode(representing: entity, context: context)
            }
            originalToPresentation[entity.runtimeID] = nodeID
        }

        for entity in diagram.outgoing(Depicts.self) where entity.contains(DiagramConnector.self) {
            if let node = existing[entity.runtimeID] {
                syncConnectorNode(node, from: entity, context: context, nodeMap: originalToPresentation)
            } else {
                createConnectorNode(representing: entity, context: context, nodeMap: originalToPresentation)
            }
        }

        presentation.setComponent(LayoutDirty())
        presentation.setComponent(InteractionDirty())
    }

    /// Create a diagram block node
    ///
    /// 1. Spawn a presentation block
    /// The created block has the following components and relationships:
    /// - ``PresentationNode``
    /// - ``BlockNode``
    /// - ``PositionComponent``
    /// - ``MemberOf`` relationship to a presentation which owns the node
    /// - ``ChildOf`` relationship to other presentation node or the presentation itself.
    ///
    /// Upon creation the block node is set as dirty with ``Diagram/DirtyContent/all``.
    ///
    func createBlockNode(representing representedEntity: RuntimeEntity, context: Context) -> RuntimeID {
        let block: DiagramBlock? = representedEntity.component()
        let position = context.toPresentationTransform.apply(to: block?.position ?? .zero)
        
        let node: RuntimeEntity = world.spawn(
            PresentationNode(),
            BlockNode(),
            NodeStyle(class: .block),
            LocalPosition(position: position),
            Interactivity.interactive,
            Visibility.visible,
            LayoutDirty(),
        )
        node.relate(MemberOf(), to: context.presentation.runtimeID)
        node.relate(ChildOf(), to: context.presentation.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        context.presentation.setComponent(LayoutDirty())

        updateBlockData(node, from: representedEntity)
        
        return node.runtimeID
    }

    func syncBlockNode(_ node: RuntimeEntity, from original: RuntimeEntity, context: Context) {
        updateBlockData(node, from: original)
        updateBlockGeometry(node, from: original, context: context)
    }

    /// - Parameters:
    ///     - representedEntity: Entity that the new presentation node will represent.
    ///     - presentation: Presentation of which the new entity will be part of.
    ///     - blockMap: Mapping between diagram block entities and presentation block entities.
    ///
    /// - Requires that the blocks are composed
    ///
    /// The created connector node entity has the following components and relationships:
    ///
    /// - ``PresentationNode``.
    /// - ``ConnectorNode``.
    /// - ``ConnectorWire``.
    /// - ``ConnectorStroke`` created from connector wire, origin and target block entities.
    /// - ``OwnedBy`` relationship to a presentation which owns the node
    /// - ``ChildOf`` relationship to other presentation node or the presentation itself.
    /// - ``ConnectorNode/Origin`` to the presentation node block representing connector origin.
    /// - ``ConnectorNode/Target`` to the presentation node block representing connector target.
    ///
    /// Upon creation the connector node is set as dirty with ``Diagram/DirtyContent/all``.
    ///
    func createConnectorNode(representing representedEntity: RuntimeEntity,
                             context: Context,
                             nodeMap: [RuntimeID:RuntimeID]) {
        guard let connector: DiagramConnector = representedEntity.component(),
              let originID = nodeMap[connector.originID],
              let origin = world.entity(originID),
              let targetID = nodeMap[connector.targetID],
              let target = world.entity(targetID)
        else { return }
        
        let styleClass: StyleClass
        switch connector.glyph.kind {
        case .thin(_): styleClass = .thinConnector
        case .fat(_): styleClass = .fatConnector
        }

        let node: RuntimeEntity = world.spawn(
            PresentationNode(),
            ConnectorNode(),
            NodeStyle(class: styleClass),
            Interactivity.interactive,
            Visibility.visible,
        )
        node.relate(MemberOf(), to: context.presentation.runtimeID)
        node.relate(ChildOf(), to: context.presentation.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        node.relate(ConnectorNode.Origin(), to: origin)
        node.relate(ConnectorNode.Target(), to: target)
        
        updateConnectorGeometry(node, from: representedEntity, context: context)
    }

    func syncConnectorNode(_ node: RuntimeEntity,
                           from original: RuntimeEntity,
                           context: Context,
                           nodeMap: [RuntimeID:RuntimeID])
    {
        guard let connector: DiagramConnector = original.component(),
              let originID = nodeMap[connector.originID],
              let origin = world.entity(originID),
              let targetID = nodeMap[connector.targetID],
              let target = world.entity(targetID)
        else { return }

        node.relate(ConnectorNode.Origin(), to: origin)
        node.relate(ConnectorNode.Target(), to: target)

        updateConnectorGeometry(node, from: original, context: context)
    }

    // MARK: - Update
    // Needs context (camera) — recomputes viewport-space geometry
    /// Update geometry of a particular presentation.
    ///
    /// Called when viewport of the presentation changes.
    ///
    public func updateGeometry(presentation: RuntimeEntity) {
        let context = Context(presentation: presentation)
        for child in presentation.children where child.contains(BlockNode.self) {
            guard let represented: RuntimeEntity = child.target(RepresentationOf.self)
            else { continue }
            updateBlockGeometry(child, from: represented)
        }
        for child in presentation.children where child.contains(ConnectorNode.self) {
            guard let represented: RuntimeEntity = child.target(RepresentationOf.self)
            else { continue }
            updateConnectorGeometry(child, from: represented, context: context)
        }
    }

    func updateBlockGeometry(_ node: RuntimeEntity, from represented: RuntimeEntity, context: Context? = nil) {
        let actualContext: Context
        if let context {
            actualContext = context
        }
        else {
            guard let presentation: RuntimeEntity = node.target(MemberOf.self) else { return }
            actualContext = Context(presentation: presentation)
        }
        updateBlockPosition(node, from: represented, context: actualContext)
    }

    func updateBlockPosition(_ node: RuntimeEntity, from represented: RuntimeEntity, context: Context) {
        guard let block: DiagramBlock = represented.component()
        else { return }

        let position: Vector2D
        if let preview: PreviewPosition = represented.component() {
            position = preview.position
        }
        else {
            position = block.position
        }
        let localPosition = context.toPresentationTransform.apply(to: position)
        node.setComponent(LocalPosition(position: localPosition))
    }

    /// Update the block node content from the entity the node represents.
    ///
    /// - Note: The caller is responsible to update layout, if necessary.
    ///
    func updateBlockData(_ node: RuntimeEntity, from represented: RuntimeEntity) {
        updateBlockPictogram(node, from: represented)
        updateBlockLabels(node, from: represented)
        updateValueIndicator(node, from: represented)
        updateIssueIndicator(node, from: represented)
        updateColorSwatch(node, from: represented)

        // TODO: [OPTIMISATION] Set only when relevant components changed
        node.setComponent(InteractionDirty())
        node.withChildrenRecursively {
            guard $0.contains(Interactivity.self) else { return }
            $0.setComponent(InteractionDirty())
        }
        if let presentation: RuntimeEntity = node.target(MemberOf.self) {
            presentation.setComponent(InteractionDirty())
        }
        // TODO: : [OPTIMISATION] Set only when really needed (pictogram changed or label changed)
        node.setComponent(LayoutDirty())
    }
    
    func updateBlockPictogram(_ node: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let pictogram = block.pictogram else {
            if let target: RuntimeEntity = node.target(PresentationNode.Pictogram.self) {
                target.despawn()
            }
            return
        }
        
        node.setComponent(pictogram.collisionShape)

        let pictogramNode: RuntimeEntity

        if let target: RuntimeEntity = node.target(PresentationNode.Pictogram.self) {
            pictogramNode = target
            pictogramNode.setComponent(PictogramNode(pictogram: pictogram))
        }
        else {
            pictogramNode = world.spawn(
                PresentationNode(),
                Visibility.visible,
                LocalPosition(position: .zero),
                PictogramNode(pictogram: pictogram),
            )
            pictogramNode.relate(ChildOf(), to: node)
            node.relate(PresentationNode.Pictogram(), to: pictogramNode)
        }
    }
    
    func updateBlockLabels(_ node: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        updateBlockLabel(node,
                         type: PresentationNode.PrimaryLabel(),
                         text: block.label,
                         style: NodeStyle(class: .primaryLabel))
        updateBlockLabel(node,
                         type: PresentationNode.SecondaryLabel(),
                         text: block.secondaryLabel,
                         style: NodeStyle(class: .secondaryLabel))
    }
    
    func updateBlockLabel<T: Relationship>(_ blockNode: RuntimeEntity,
                                           type labelType: T,
                                           text: String?,
                                           style: NodeStyle)
    {
        // Note: Collision shapes of labels are assigned in PresentationBuilder.layoutBlock(...)
        guard let text else {
            if let target: RuntimeEntity = blockNode.target(T.self) {
                target.setComponent(Visibility.hidden)
                target.setComponent(Interactivity.inert)
            }
            return
        }
        
        let labelNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockNode.target(T.self) {
            labelNode = target
            labelNode.setComponent(LabelNode(text: text, anchor: Vector2D(0.5,0.0)))
            target.setComponent(Visibility.visible)
            target.setComponent(Interactivity.interactive)
        }
        else {
            labelNode = world.spawn(
                PresentationNode(),
                Visibility.visible,
                Interactivity.interactive,
                LocalPosition(position: .zero),
                LabelNode(text: text, anchor: Vector2D(0.5,0.0)),
                style
            )
            labelNode.relate(ChildOf(), to: blockNode)
            blockNode.relate(labelType, to: labelNode)
        }
    }
    
    func updateValueIndicator(_ blockNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        let visibility: Visibility = representedEntity.contains(HasNumericIndicator.self) ? .visible : .hidden

        let child: RuntimeEntity

        if let target: RuntimeEntity = blockNode.target(PresentationNode.ValueIndicator.self) {
            child = target
            child.setComponent(visibility)
        }
        else {
            child = world.spawn(
                PresentationNode(),
                ValueIndicatorNode(
                    size: ValueIndicatorNode.DefaultSize,
                    orientation: .horizontal
                ),
                visibility,
                Interactivity.inert,
                LocalPosition(position: .zero),
                NodeStyle(class: .valueIndicator),
            )
            child.relate(ChildOf(), to: blockNode)
            blockNode.relate(PresentationNode.ValueIndicator(), to: child)
        }
        
        let shape = CollisionShape(position: .zero,
                                   shape: .rectangle(ValueIndicatorNode.DefaultSize))
        child.setComponent(shape)

    }
    
    func updateIssueIndicator(_ blockNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        let indicator: RuntimeEntity
        let visibility: Visibility = representedEntity.hasIssues ? .visible : .hidden
        let interactivity: Interactivity = representedEntity.hasIssues ? .interactive : .inert

        if let target: RuntimeEntity = blockNode.target(PresentationNode.IssueIndicator.self) {
            indicator = target
            target.setComponent(visibility)
            target.setComponent(interactivity)
            // TODO: HitRegion.shape(rect)
        }
        else {
            indicator = world.spawn(
                PresentationNode(),
                visibility,
                interactivity,
                LocalPosition(position: .zero),
                NodeStyle(class: .issueIndicator),
                IssueIndicatorNode(),
                // TODO: HitRegion.shape(rect)
            )
            indicator.relate(ChildOf(), to: blockNode)
            blockNode.relate(PresentationNode.IssueIndicator(), to: indicator)
        }
        // Touch region
        let shape = CollisionShape(position: .zero,
                                   shape: .circle(IssueIndicatorNode.DefaultSize))
        indicator.setComponent(shape)
    }
    
    func updateColorSwatch(_ blockNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }

        let swatch: RuntimeEntity

        if let target: RuntimeEntity = blockNode.target(PresentationNode.ColorSwatch.self) {
            swatch = target
        }
        else {
            swatch = world.spawn(
                PresentationNode(),
                Interactivity.inert,
                LocalPosition(position: .zero),
            )
            swatch.relate(ChildOf(), to: blockNode)
            blockNode.relate(PresentationNode.ColorSwatch(), to: swatch)
        }
        if let colorKey = block.accentColor {
            swatch.setComponent(ColorSwatchNode(colorKey: colorKey))
            swatch.setComponent(Visibility.visible)
        }
        else {
            swatch.setComponent(Visibility.hidden)
        }

        // TODO: Do we need hit region for color swatch? Maybe for inspector?
    }
    
    // TODO: Move the component documentation to ConnectorNode, also split to two scenarios: with and without represented entity
    /// Update connector wire and stroke geometry from connector glyph and two blocks the connector
    /// is connecting.
    ///
    /// - Parameters:
    ///     - connectorNode: Node to be updated.
    ///     - represented: Design object entity that the connector represents. If `nil` then
    ///       non-represented connector is assumed, such as new connector intent.
    ///     - context: composer context
    ///
    /// Situation:
    ///
    /// ```
    ///
    ///  +---------------------+           +--------------------+
    ///  | ConnectorNode       |           | DiagramConnector   | for glyph and midpoints
    ///  +---------------------+           +--------------------+
    ///  | RepresentationOf ?  |---------->| PreviewMidpoints ? | defaults to empty
    ///  +---------------------+           +--------------------+
    ///  | ConnectorGlyph ?    |
    ///  +---------------------+
    ///  | → Origin            |----+
    ///  +---------------------+    |      +---------------------+
    ///  | → Target            |----+----->| (any pres. node)    |
    ///  +---------------------+           +---------------------+
    ///                                    | LocalPosition ?     | defaults to (0,00
    ///                                    +---------------------+
    ///                                    | CollisionShape ?    | defaults to a point at position
    ///                                    +---------------------+
    ///
    /// ```
    ///
    /// Component and relationship requirements for the presentation node:
    ///
    /// - ``RepresentationOf`` (optional) – relationship to a diagram connector the presentation node
    ///   represents. Presentation node might not represent any particular design connector.
    /// - ``ConnectorNode/Origin``, ``ConnectorNode/Target`` (required):
    ///    connector origin and target presentation nodes.
    ///
    /// Presentation node without represented entity are usually transient. For example a connector intent
    /// during an interactive session when dragging a new connector.
    ///
    /// Component requirements for optional represented entity:
    ///
    /// - ``DiagramConnector`` (optional): used to get glyph (``ConnectorGlyph``) and midpoints.
    /// - ``PreviewMidpoints`` (optional): midpoints during interactive overriding
    ///   ``DiagramConnector/midpoints`` if present.
    ///
    /// Component requirements for connector origin and target entities:
    ///
    /// - ``PositionComponent`` – position of connector endpoint block.
    ///    If not present then zero point (0,0) is used.
    /// - ``CollisionShape`` – collision shape of endpoint blocks to determine touch points, if not
    ///   present, then the touch point will be endpoint's position.
    ///
    /// Note that origin and target entities do not have to be diagram blocks, they can be
    /// for example handles dragged during an interactive session.
    ///
    /// The function produces ``ConnectorGeometry`` and ``ConnectorWire`` components on the
    /// ``PresentationNode`` entity.
    ///
    /// Connector touch-points are determined from connector origin and target blocks and
    /// their pictograms. If the pictogram can not be determined, then position of the blocks is
    /// used. Position of the connected blocks is taken from ``PreviewPositionComponent`` if present,
    /// otherwise from ``PositionComponent``. If for some reason the position component is missing,
    /// the position defaults to zero.
    ///
    /// - SeeAlso: ``Geometry/rayIntersection(shape:position:from:direction:)``
    ///
    func updateConnectorGeometry(_ connectorNode: RuntimeEntity,
                                 from represented: RuntimeEntity? = nil,
                                 context providedContext: Context? = nil)
    {
        let context: Context
        if let providedContext {
            context = providedContext
        }
        else if let presentation: RuntimeEntity = connectorNode.target(MemberOf.self) {
            context = Context(presentation: presentation)
        }
        else {
            // TODO: Consider defaults
            return
        }

        let representedConnector: DiagramConnector? = represented?.component()
        
        let glyph: ConnectorGlyph

        // Glyph priority: ConnectorGlyph on entity > DiagramConnector of represented connector
        // Midpoints priority: Represented entity preview midpoints > repr. connector midpoints > []
        
        if let nodeGlyph: ConnectorGlyph = connectorNode.component() {
            glyph = nodeGlyph
        }
        else if let connector = representedConnector {
            glyph = connector.glyph
        }
        else {
            // No data – we do not know what to draw.
            connectorNode.removeComponent(ConnectorGeometry.self)
            connectorNode.removeComponent(ConnectorWire.self)
            connectorNode.removeComponent(ConnectorStroke.self)
            return
        }
        
        let worldMidpoints: [Vector2D]
        if let preview: PreviewMidpoints = represented?.component() {
            worldMidpoints = preview.midpoints
        }
        else {
            worldMidpoints = representedConnector?.midpoints ?? []
        }

        let midpoints = worldMidpoints.map { context.toPresentationTransform.apply(to: $0) }

        updateConnectorGeometry(connectorNode, midpoints: midpoints, glyph: glyph, context: context)
        updateConnectorStroke(connectorNode, glyph: glyph)
        connectorNode.setComponent(InteractionDirty())
        context.presentation.setComponent(InteractionDirty())
    }
    
    private func updateConnectorGeometry(_ node: RuntimeEntity,
                                         midpoints: [Vector2D],
                                         glyph: ConnectorGlyph,
                                         context: Context)
    {
        guard let origin: RuntimeEntity = node.target(ConnectorNode.Origin.self),
              let target: RuntimeEntity = node.target(ConnectorNode.Target.self)
        else { return }

        let lineType = glyph.lineType
        
        let originLocal: LocalPosition? = origin.component()
        let originPosition: Vector2D = originLocal?.position ?? .zero
        let targetLocal: LocalPosition? = target.component()
        let targetPosition: Vector2D = targetLocal?.position ?? .zero
        
        let originCastPoint = midpoints.first ?? targetPosition
        let originDirection = (originPosition - originCastPoint).normalized
        let targetCastPoint = midpoints.last ?? originPosition
        let targetDirection = (targetPosition - targetCastPoint).normalized
        
        let originCollision: CollisionShape? = origin.component()
        let targetCollision: CollisionShape? = target.component()
        
        let originTouch: Vector2D
        if let originCollision {
            let intersect = Geometry.rayIntersection(shape: originCollision.shape,
                                                     position: originPosition + originCollision.position,
                                                     from: originCastPoint,
                                                     direction: originDirection)
            originTouch = intersect ?? originPosition
        }
        else {
            originTouch = originPosition
        }
        
        let targetTouch: Vector2D
        if let targetCollision {
            let intersect = Geometry.rayIntersection(shape: targetCollision.shape,
                                                     position: targetPosition + targetCollision.position,
                                                     from: targetCastPoint,
                                                     direction: targetDirection)
            targetTouch = intersect ?? targetPosition
        }
        else {
            targetTouch = targetPosition
        }
        
        let path = Geometry.wirePath(from: originTouch,
                                     to: targetTouch,
                                     through: midpoints,
                                     lineType: lineType)
        let points = path.tessellate()

        let geometry = ConnectorGeometry(origin: originTouch,
                                         originDirection: originDirection,
                                         target: targetTouch,
                                         targetDirection: targetDirection,
                                         midpoints: midpoints)
        

        node.setComponent(geometry)
        node.setComponent(ConnectorWire(points: points))
    }

    func updateConnectorStroke(_ node: RuntimeEntity, glyph: ConnectorGlyph) {
        guard let geometry: ConnectorGeometry = node.component()
        else { return }
        
        let stroke: ConnectorStroke
        switch glyph.kind {
        case .fat(let kind):
            let outline = Geometry.fatConnectorStroke(
                geometry: geometry,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                kind: kind
            )
            stroke = ConnectorStroke(body: outline,
                                     headArrowhead: nil,
                                     tailArrowhead: nil,
                                     isFilled: true)
            
        case .thin(let kind):
            let paths = Geometry.thinConnectorStroke(
                geometry: geometry,
                tailSize: glyph.tailSize,
                headSize: glyph.headSize,
                lineType: glyph.lineType,
                kind: kind
            )
            
            stroke = ConnectorStroke(body: paths.body,
                                     headArrowhead: paths.head,
                                     tailArrowhead: paths.tail,
                                     isFilled: false)
        }
        node.setComponent(stroke)
        
    }
}
