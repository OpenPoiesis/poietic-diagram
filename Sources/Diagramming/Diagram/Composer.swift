//
//  Composer.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 27/05/2026.
//

import PoieticCore

/*
 
  Document Event        | data | geometry | layout
 ────────────────────────+──────+---───────+---------
  Frame change          | yes  | yes      | yes
  Viewport change       | -    | yes(1)   | -
  Interactive preview   | -    | yes      | -
  Style change          | -    | -        | yes
  Notation change       | -    | yes      | -
  Simulation step       | yes  | -        | -
  Selection change      | -    | -        | -
 
 (1): Per-viewport/per-scene.
 
 */

// TODO: [REFACTORING]: Review interactivity and visibility
// TODO: [REFACTORING][IMPORTANT] Update modifiers flags, especially selection for block and connector (see below)

/// Object responsible for creating and synchronising a diagram scene with model.
///
/// Scene composer is a stateless bridge between diagram (model) and scene –
/// a structure with direct renderable representation.
///
/// Main functionality:
///
/// - _Create_ diagram scene from ``DiagramBlock`` and ``DiagramConnector`` objects.
/// - _Update_ geometry and other data.
/// - _Layout_ labels, indicators and other annotations.
///
/// The typical calls:
///
/// - _Create_: on new design frame, new entities. Creation is free from layout.
/// - _Update_: during interaction or on a simulation step.
/// - _Layout_: during interaction or style change which affects layout metrics,
///             including fonts and their sizes. Typically no need to call during interaction.
///
/// ## Interactivity
///
/// Diagram composer prepares canvas nodes for interactivity by setting ``CollisionShape`` (relative
/// coordinates to parent) or ``ConnectorWire`` (absolute coordinates) on interactive entities
/// together with ``Interactivity/interactive`` component.
///
/// It is up to the application to create and manage ``TouchRegion`` components.
///
public class DiagramSceneComposer {
    public let world: World
    
    public struct Context {
        public let scene: RuntimeEntity
        public let viewport: ViewportState
        public let toSceneTransform: AffineTransform

        /// Create a new composer context from a scene entity.
        ///
        /// Scene is expected to have a ``ViewportState`` component on it. If the component is
        /// missing, then default viewport state (zero offset, zoom 100%) is used.
        ///
        public init(scene: RuntimeEntity) {
            self.scene = scene
            self.viewport = scene.component() ?? ViewportState()
            self.toSceneTransform = AffineTransform(translation: -self.viewport.offset)
                .scaled(Vector2D(self.viewport.zoom, self.viewport.zoom))
        }
    }
    
    public init(world: World) {
        self.world = world
    }
    
    /// Creates a diagram entity from all diagram blocks and diagram connectors.
    ///
    /// - **Input**:
    ///     - Entities with component ``DiagramBlock`` and ``DiagramConnector``.
    /// - **Output**:
    ///     - New diagram entity with input entities related with ``Depicts`` relationship.
    ///
    /// - Returns: Created diagram entity.
    ///
    public static func createDiagramFromAll(world: World) -> RuntimeEntity {
        let diagram: RuntimeEntity = world.spawn(
            Diagram()
        )
        
        for entity: RuntimeEntity in world.query(DiagramBlock.self) {
            diagram.relate(Depicts(), to: entity)
        }
        for entity: RuntimeEntity in world.query(DiagramConnector.self) {
            diagram.relate(Depicts(), to: entity)
        }
        return diagram
    }
   
    // MARK: - Create
    /// Create a diagram scene for a given diagram entity.
    ///
    /// Result:
    /// - Scene root of type ``DiagramCanvas`` which represents the diagram entity through
    ///   ``/PoieticCore/RepresentationOf``.
    /// - Scene children
    ///     - ``BlockCanvasNode`` for each ``DiagramBlock``
    ///     - ``ConnectorCanvasNode`` for each ``DiagramConnector``
    ///
    /// Called on:
    /// - New diagram.
    ///
    public func createScene(diagram: RuntimeEntity, viewport: ViewportState = ViewportState()) -> RuntimeEntity {
        let scene: RuntimeEntity = world.spawn(
            DiagramScene(),
            viewport
        )
        // Represented block to scene node map
        var repToSceneMap: [RuntimeID:RuntimeID] = [:]
        
        scene.relate(RepresentationOf(), to: diagram)
        
        let context = Context(scene: scene)
        
        for entity in diagram.outgoing(Depicts.self) where entity.contains(DiagramBlock.self) {
            let node = createBlockNode(representing: entity, context: context)
            repToSceneMap[entity.runtimeID] = node
        }
        
        for entity in diagram.outgoing(Depicts.self) where entity.contains(DiagramConnector.self){
            createConnectorNode(representing: entity,
                                context: context,
                                sceneNodeMap: repToSceneMap)
        }
        return scene
    }
    
    /// Create a diagram block node
    ///
    /// 1. Spawn a scene block
    /// The created block has the following components and relationships:
    /// - ``CanvasNode``
    /// - ``BlockCanvasNode``
    /// - ``PositionComponent``
    /// - ``MemberOf`` relationship to a scene which owns the node
    /// - ``ChildOf`` relationship to other scene node or the scene itself.
    ///
    /// Upon creation the block node is set as dirty with ``Diagram/DirtyContent/all``.
    ///
    func createBlockNode(representing representedEntity: RuntimeEntity, context: Context) -> RuntimeID {
        let block: DiagramBlock? = representedEntity.component()
        let position = context.toSceneTransform.apply(to: block?.position ?? .zero)
        let isSelected = representedEntity.contains(IsSelected.self)
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            BlockCanvasNode(),
            CanvasNodeStyle(class: .block, modifiers: isSelected ? .selected : .none),
            PositionComponent(position: position),
            Interactivity.interactive,
            Visibility.visible,
            LayoutDirty(),
        )
        node.relate(MemberOf(), to: context.scene.runtimeID)
        node.relate(ChildOf(), to: context.scene.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        context.scene.setComponent(LayoutDirty())

        updateBlockData(node, from: representedEntity)
        
        return node.runtimeID
    }

    /// - Parameters:
    ///     - representedEntity: Entity that the new scene node will represent.
    ///     - scene: Scene of which the new entity will be part of.
    ///     - blockMap: Mapping between diagram block entities and scene block entities.
    ///
    /// - Requires that the blocks are composed
    ///
    /// The created connector node entity has the following components and relationships:
    ///
    /// - ``CanvasNode``.
    /// - ``ConnectorCanvasNode``.
    /// - ``ConnectorWire``.
    /// - ``ConnectorStroke`` created from connector wire, origin and target block entities.
    /// - ``OwnedBy`` relationship to a scene which owns the node
    /// - ``ChildOf`` relationship to other scene node or the scene itself.
    /// - ``ConnectorCanvasNode/Origin`` to the scene node block representing connector origin.
    /// - ``ConnectorCanvasNode/Target`` to the scene node block representing connector target.
    ///
    /// Upon creation the connector node is set as dirty with ``Diagram/DirtyContent/all``.
    ///
    func createConnectorNode(representing representedEntity: RuntimeEntity,
                             context: Context,
                             sceneNodeMap: [RuntimeID:RuntimeID]) {
        guard let connector: DiagramConnector = representedEntity.component(),
              let originID = sceneNodeMap[connector.originID],
              let origin = world.entity(originID),
              let targetID = sceneNodeMap[connector.targetID],
              let target = world.entity(targetID)
        else { return }
        
        let isSelected = representedEntity.contains(IsSelected.self)

        let styleClass: StyleClass
        switch connector.glyph.kind {
        case .thin(_): styleClass = .thinConnector
        case .fat(_): styleClass = .fatConnector
        }

        let style = CanvasNodeStyle(
            class: styleClass,
            modifiers: isSelected ? .selected : .none
        )

        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            ConnectorCanvasNode(),
            style,
            Interactivity.interactive,
            Visibility.visible,
        )
        node.relate(MemberOf(), to: context.scene.runtimeID)
        node.relate(ChildOf(), to: context.scene.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        node.relate(ConnectorCanvasNode.Origin(), to: origin)
        node.relate(ConnectorCanvasNode.Target(), to: target)
        
        updateConnectorGeometry(node, from: representedEntity, context: context)
    }

    // MARK: - Update
    
    /// Update scene data that is not related to geometry.
    ///
    /// - SeeAlso: ``updateGeometry(scene:)``
    ///
    @available(*, deprecated, message: "Use SceneCompositionSystem for world-wide update")
    public func updateData(scene: RuntimeEntity) {
        for child in scene.children where child.contains(BlockCanvasNode.self) {
            guard let represented: RuntimeEntity = child.target(RepresentationOf.self) else { continue }
            updateBlockData(child, from: represented)
        }
    }

    // Needs context (viewport) — recomputes viewport-space geometry
    /// Update geometry of a particular scene.
    ///
    /// Called when viewport of the scene changes.
    ///
    @available(*, deprecated, message: "Use SceneCompositionSystem for world-wide update")
    public func updateGeometry(scene: RuntimeEntity) {
        let context = Context(scene: scene)
        for child in scene.children where child.contains(BlockCanvasNode.self) {
            guard let represented: RuntimeEntity = child.target(RepresentationOf.self)
            else { continue }
            updateBlockGeometry(child, from: represented)
        }
        for child in scene.children where child.contains(ConnectorCanvasNode.self) {
            guard let represented: RuntimeEntity = child.target(RepresentationOf.self)
            else { continue }
            updateConnectorGeometry(child, from: represented, context: context)
        }
    }

    func updateBlockGeometry(_ node: RuntimeEntity, from represented: RuntimeEntity) {
        // TODO: Consider defaults (no scene)
        guard let scene: RuntimeEntity = node.target(MemberOf.self) else { return }
        updateBlockPosition(node, from: represented, context: Context(scene: scene))
    }

    func updateBlockPosition(_ node: RuntimeEntity, from represented: RuntimeEntity, context: Context) {
        guard let block: DiagramBlock = represented.component()
        else { return }

        let position: Vector2D
        if let preview: PreviewPositionComponent = represented.component() {
            position = preview.position
        }
        else {
            position = block.position
        }
        let viewportPosition = context.toSceneTransform.apply(to: position)
        node.setComponent(PositionComponent(position: viewportPosition))
    }

    /// Update the block node content from the entity the node represents.
    ///
    /// - Note: The caller is responsible to update layout, if necessary.
    ///
    func updateBlockData(_ sceneNode: RuntimeEntity, from represented: RuntimeEntity) {
        updateBlockPictogram(sceneNode, from: represented)
        updateBlockLabels(sceneNode, from: represented)
        updateValueIndicator(sceneNode, from: represented)
        updateIssueIndicator(sceneNode, from: represented)
        updateColorSwatch(sceneNode, from: represented)

        // TODO: Set only when relevant components changed
        sceneNode.setComponent(InteractionDirty())
        sceneNode.withChildrenRecursively {
            guard $0.contains(Interactivity.self) else { return }
            $0.setComponent(InteractionDirty())
        }
        // TODO: [REFACTORING][IMPORTANT] Update modifiers flags, especially selection
  
//        if represented.contains(IsSelected.self) {
//            sceneNode.modify(CanvasNodeStyle.self) {
//                $0.modifiers.insert(.selected)
//            }
//        }
//        else {
//            sceneNode.modify(CanvasNodeStyle.self) {
//                $0.modifiers.remove(.selected)
//            }
//        }
    }
    
    func updateBlockPictogram(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        // TODO: Do not forget to mark as geometry dirty when pictogram changes
        // TODO: Do not forget to consider dirty geometry in connector update or mark the connector dirty

        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        // FIXME: [REFACTORING] Do not despawn, Just hide
        guard let pictogram = block.pictogram else {
            if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.Pictogram.self) {
                target.despawn()
            }
            return
        }
        
        blockSceneNode.setComponent(pictogram.collisionShape)

        let pictogramNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.Pictogram.self) {
            pictogramNode = target
            pictogramNode.setComponent(PictogramCanvasNode(pictogram: pictogram))
        }
        else {
            pictogramNode = world.spawn(
                CanvasNode(),
                Visibility.visible,
                PositionComponent(position: .zero),
                PictogramCanvasNode(pictogram: pictogram),
            )
            pictogramNode.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.Pictogram(), to: pictogramNode)
        }
    }
    
    func updateBlockLabels(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        updateBlockLabel(blockSceneNode,
                         type: CanvasNode.PrimaryLabel(),
                         text: block.label,
                         style: CanvasNodeStyle(class: .primaryLabel))
        updateBlockLabel(blockSceneNode,
                         type: CanvasNode.SecondaryLabel(),
                         text: block.secondaryLabel,
                         style: CanvasNodeStyle(class: .secondaryLabel))
    }
    
    func updateBlockLabel<T: Relationship>(_ blockSceneNode: RuntimeEntity,
                                           type labelType: T,
                                           text: String?,
                                           style: CanvasNodeStyle)
    {
        // Note: Collision shapes of labels are assigned in DiagramSceneComposer.layoutBlock(...)
        guard let text else {
            if let target: RuntimeEntity = blockSceneNode.target(T.self) {
                target.setComponent(Visibility.hidden)
                target.setComponent(Interactivity.inert)
            }
            return
        }
        
        let labelNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(T.self) {
            labelNode = target
            labelNode.setComponent(LabelCanvasNode(text: text, anchor: Vector2D(0.5,0.0)))
            target.setComponent(Visibility.visible)
            target.setComponent(Interactivity.interactive)
        }
        else {
            labelNode = world.spawn(
                CanvasNode(),
                Visibility.visible,
                Interactivity.interactive,
                PositionComponent(position: .zero),
                LabelCanvasNode(text: text, anchor: Vector2D(0.5,0.0)),
                style
            )
            labelNode.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(labelType, to: labelNode)
        }
    }
    
    func updateValueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        let sample: NumericValueSample? = representedEntity.component()
        let stats: NumericValueStats? = representedEntity.component()
        let displayBounds: DisplayValueBounds? = representedEntity.component()
        let bounds: ValueBounds
        if let stats {
            bounds = ValueBounds(min: stats.min, max: stats.max, limit: displayBounds)
        }
        else {
            bounds = ValueBounds(min: displayBounds?.min ?? 0, max: displayBounds?.max ?? 1)
        }
        let visibility: Visibility = representedEntity.contains(HasNumericIndicator.self) ? .visible : .hidden

        
        let child: RuntimeEntity
        let indicatorComponent = ValueIndicatorCanvasNode(
            value: sample?.value,
            bounds: bounds,
            size: ValueIndicatorCanvasNode.DefaultSize
        )

        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.ValueIndicator.self) {
            child = target
            child.setComponent(indicatorComponent)
            child.setComponent(visibility)
        }
        else {
            child = world.spawn(
                CanvasNode(),
                indicatorComponent,
                visibility,
                Interactivity.inert,
                PositionComponent(position: .zero),
                CanvasNodeStyle(class: .valueIndicator),
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.ValueIndicator(), to: child)
        }
        
        // Touch region
        let shape = CollisionShape(position: .zero,
                                   shape: .rectangle(ValueIndicatorCanvasNode.DefaultSize))
        child.setComponent(shape)

    }
    
    func updateIssueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        let indicator: RuntimeEntity
        let visibility: Visibility = representedEntity.hasIssues ? .visible : .hidden
        let interactivity: Interactivity = representedEntity.hasIssues ? .interactive : .inert

        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.IssueIndicator.self) {
            indicator = target
            target.setComponent(visibility)
            target.setComponent(interactivity)
            // TODO: TouchRegion.shape(rect)
        }
        else {
            indicator = world.spawn(
                CanvasNode(),
                visibility,
                interactivity,
                PositionComponent(position: .zero),
                CanvasNodeStyle(class: .issueIndicator),
                IssueIndicatorCanvasNode(),
                // TODO: TouchRegion.shape(rect)
            )
            indicator.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.IssueIndicator(), to: indicator)
        }
        // Touch region
        let shape = CollisionShape(position: .zero,
                                   shape: .circle(IssueIndicatorCanvasNode.DefaultSize))
        indicator.setComponent(shape)
    }
    
    func updateColorSwatch(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }

        let swatch: RuntimeEntity

        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.ColorSwatch.self) {
            swatch = target
        }
        else {
            swatch = world.spawn(
                CanvasNode(),
                Interactivity.inert,
                PositionComponent(position: .zero),
            )
            swatch.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.ColorSwatch(), to: swatch)
        }
        if let colorKey = block.accentColor {
            swatch.setComponent(ColorSwatchCanvasNode(colorKey: colorKey))
            swatch.setComponent(Visibility.visible)
        }
        else {
            swatch.setComponent(Visibility.hidden)
        }

        // TODO: Do we need touch region for color swatch? Maybe for inspector?
    }
    
    // TODO: Move the component documentation to ConnectorSceneNode, also split to two scenarios: with and without represented entity
    /// Update connector wire and stroke geometry from connector glyph and two blocks the connector
    /// is connecting.
    ///
    /// - Parameters:
    ///     - sceneNode: Node to be updated.
    ///     - represented: Design object entity that the connector represents. If `nil` then
    ///       non-represented connector is assumed, such as new connector intent.
    ///     - context: composer context
    ///
    /// Situation:
    ///
    /// ```
    ///
    ///  +---------------------+           +--------------------+
    ///  | ConnectorCanvasNode |           | DiagramConnector   | for glyph and midpoints
    ///  +---------------------+           +--------------------+
    ///  | RepresentationOf ?  |---------->| PreviewMidpoints ? | defaults to empty
    ///  +---------------------+           +--------------------+
    ///  | ConnectorGlyph ?    |
    ///  +---------------------+
    ///  | → Origin            |----+
    ///  +---------------------+    |      +---------------------+
    ///  | → Target            |----+----->| (any scene node)    |
    ///  +---------------------+           +---------------------+
    ///                                    | PositionComponent ? | defaults to (0,00
    ///                                    +---------------------+
    ///                                    | CollisionShape ?    | defaults to a point at position
    ///                                    +---------------------+
    ///
    /// ```
    ///
    /// Component and relationship requirements for the scene node:
    ///
    /// - ``RepresentationOf`` (optional) – relationship to a diagram connector the scene node
    ///   represents. Scene node might not represent any particular design connector.
    /// - ``ConnectorCanvasNode/Origin``, ``ConnectorCanvasNode/Target`` (required):
    ///    connector origin and target scene nodes.
    ///
    /// Scene node without represented entity are usually transient. For example a connector intent
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
    /// ``sceneNode`` entity.
    ///
    /// Connector touch-points are determined from connector origin and target blocks and
    /// their pictograms. If the pictogram can not be determined, then position of the blocks is
    /// used. Position of the connected blocks is taken from ``PreviewPositionComponent`` if present,
    /// otherwise from ``PositionComponent``. If for some reason the position component is missing,
    /// the position defaults to zero.
    ///
    /// - SeeAlso: ``Geometry/rayIntersection(shape:position:from:direction:)``
    ///
    func updateConnectorGeometry(_ sceneNode: RuntimeEntity,
                                 from represented: RuntimeEntity? = nil,
                                 context providedContext: Context? = nil)
    {
        let context: Context
        if let providedContext {
            context = providedContext
        }
        else if let scene: RuntimeEntity = sceneNode.target(MemberOf.self) {
            context = Context(scene: scene)
        }
        else {
            // TODO: Consider defaults
            return
        }

        let representedConnector: DiagramConnector? = represented?.component()
        
        let glyph: ConnectorGlyph

        // Glyph priority: ConnectorGlyph on entity > DiagramConnector of represented connector
        // Midpoints priority: Represented entity preview midpoints > repr. connector midpoints > []
        
        if let sceneNodeGlyph: ConnectorGlyph = sceneNode.component() {
            glyph = sceneNodeGlyph
        }
        else if let connector = representedConnector {
            glyph = connector.glyph
        }
        else {
            // No data – we do not know what to draw.
            sceneNode.removeComponent(ConnectorGeometry.self)
            sceneNode.removeComponent(ConnectorWire.self)
            sceneNode.removeComponent(ConnectorStroke.self)
            return
        }
        
        let worldMidpoints: [Vector2D]
        if let preview: PreviewMidpoints = represented?.component() {
            worldMidpoints = preview.midpoints
        }
        else {
            worldMidpoints = representedConnector?.midpoints ?? []
        }

        // Scene midpoints
        let midpoints = worldMidpoints.map { context.toSceneTransform.apply(to: $0) }

        updateConnectorGeometry(sceneNode, midpoints: midpoints, glyph: glyph, context: context)
        updateConnectorStroke(sceneNode, glyph: glyph)
        // TODO: [REFACTORING][IMPORTANT] Update modifiers flags, especially selection
    }
    
    func updateConnectorGeometry(_ sceneNode: RuntimeEntity,
                                    midpoints: [Vector2D],
                                    glyph: ConnectorGlyph,
                                    context: Context)
    {
        guard let origin: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Origin.self),
              let target: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Target.self)
        else { return }

        let lineType = glyph.lineType
        
        let originPositionComp: PositionComponent? = origin.component()
        let originPosition: Vector2D = originPositionComp?.position ?? .zero
        let targetPositionComp: PositionComponent? = target.component()
        let targetPosition: Vector2D = targetPositionComp?.position ?? .zero
        
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
        

        sceneNode.setComponent(geometry)
        sceneNode.setComponent(ConnectorWire(points: points))
    }

    func updateConnectorStroke(_ sceneNode: RuntimeEntity, glyph: ConnectorGlyph) {
        guard let geometry: ConnectorGeometry = sceneNode.component()
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
        sceneNode.setComponent(stroke)
        
    }
}
