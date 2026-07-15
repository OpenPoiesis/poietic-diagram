//
//  Composer.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 27/05/2026.
//

import PoieticCore

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
            self.toSceneTransform = AffineTransform(scale: Vector2D(self.viewport.zoom, self.viewport.zoom))
                .translated(self.viewport.offset)
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
    public func createDiagramFromAll() -> RuntimeEntity {
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
    /// 2. Create children:
    ///  - label
    func createBlockNode(representing representedEntity: RuntimeEntity, context: Context) -> RuntimeID {
        let block: DiagramBlock? = representedEntity.component()
        let position = context.toSceneTransform.apply(to: block?.position ?? .zero)
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            BlockCanvasNode(),
            PositionComponent(position: position),
        )
        node.relate(ChildOf(), to: context.scene.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        
        updateBlockNode(node, from: representedEntity, context: context)
        
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
    /// - ``ChildOf`` relationship to the ``scene``
    /// - ``ConnectorCanvasNode/Origin`` to the scene node block representing connector origin.
    /// - ``ConnectorCanvasNode/Target`` to the scene node block representing connector target.
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
        
        // 1. Wire
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            ConnectorCanvasNode(),
        )
        node.relate(ChildOf(), to: context.scene.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        node.relate(ConnectorCanvasNode.Origin(), to: origin)
        node.relate(ConnectorCanvasNode.Target(), to: target)
        
        updateConnectorNode(node, from: representedEntity, context: context)
    }

    // MARK: - Update
    
    /// Updates all scenes in the world.
    ///
    /// What is updated:
    /// - All block canvas nodes from their represented entities.
    /// - All connector canvas nodes from their represented entities.
    ///
    public func updateScenes() {
        // TODO: Alternative names: updateAll(), updateAllScenes(), updateAllSceneNodes()
        // TODO: Check for dirty, update dirty only
        for node: RuntimeEntity in world.query(BlockCanvasNode.self) {
            guard let representedEntity: RuntimeEntity = node.target(RepresentationOf.self),
                  let scene: RuntimeEntity = node.target(OwnedBy.self)
            else { continue }
            let context = Context(scene: scene)
            updateBlockNode(node, from: representedEntity, context: context)
        }
        
        for node: RuntimeEntity in world.query(ConnectorCanvasNode.self) {
            guard let representedEntity: RuntimeEntity = node.target(RepresentationOf.self),
                    let scene: RuntimeEntity = node.target(OwnedBy.self)
            else { continue }
            
            let context = Context(scene: scene)
            updateConnectorNode(node, from: representedEntity, context: context)
        }
        
    }
    /// Update the block node content from the entity the node represents.
    ///
    /// - Note: The caller is responsible to update layout, if necessary.
    ///
    func updateBlockNode(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
        updateBlockPictogram(sceneNode, from: representedEntity, context: context)
        updateBlockLabels(sceneNode, from: representedEntity, context: context)
        updateValueIndicator(sceneNode, from: representedEntity, context: context)
        updateIssueIndicator(sceneNode, from: representedEntity, context: context)
        updateColorSwatch(sceneNode, from: representedEntity, context: context)
        // TODO: [REFACTORING][IMPORTANT] Update modifiers flags, especially selection
    }
    
    func updateBlockPictogram(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let pictogram = block.pictogram else {
            if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.Pictogram.self) {
                target.despawn()
            }
            return
        }
        
        let scaledPictogram = pictogram // FIXME: [REFACTORING] pictogram.scaled(context.viewport.zoom)
        let pictogramNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.Pictogram.self) {
            pictogramNode = target
            pictogramNode.setComponent(PictogramCanvasNode(pictogram: scaledPictogram))
            pictogramNode.setComponent(TouchRegion.shape(scaledPictogram.collisionShape))
        }
        else {
            pictogramNode = world.spawn(
                CanvasNode(),
                Visibility.visible,
                Interactivity.interactive,
                PositionComponent(position: .zero),
                PictogramCanvasNode(pictogram: scaledPictogram),
                TouchRegion.shape(scaledPictogram.collisionShape),
                scaledPictogram.collisionShape, // Collision shape for connector geometry
            )
            pictogramNode.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.Pictogram(), to: pictogramNode)
        }
    }
    
    func updateBlockLabels(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
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
                                           style: CanvasNodeStyle) {
        guard let text else {
            if let target: RuntimeEntity = blockSceneNode.target(T.self) {
                target.despawn()
            }
            return
        }
        
        let labelNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(T.self) {
            labelNode = target
            labelNode.setComponent(LabelCanvasNode(text: text, anchor: Vector2D(0.5,0.0)))
            // TODO: TouchRegion.shape(rect)
        }
        else {
            labelNode = world.spawn(
                CanvasNode(),
                Visibility.visible,
                Interactivity.interactive,
                PositionComponent(position: .zero),
                LabelCanvasNode(text: text, anchor: Vector2D(0.5,0.0)),
                style
                
                // TODO: TouchRegion.shape(rect)
            )
            labelNode.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(labelType, to: labelNode)
        }
    }
    
    func updateValueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
        let child: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.ValueIndicator.self) {
            child = target
            child.setComponent(ValueIndicatorCanvasNode(value: nil,
                                                        bounds: ValueBounds(min: 0, max: 1, baseline: 0),
                                                        size: ValueIndicatorCanvasNode.DefaultSize))
            // TODO: TouchRegion.shape(rect)
        }
        else {
            child = world.spawn(
                CanvasNode(),
                Visibility.visible,
                Interactivity.inert,
                PositionComponent(position: .zero),
                CanvasNodeStyle(class: .valueIndicator),
                ValueIndicatorCanvasNode(value: nil,
                                         bounds: ValueBounds(min: 0, max: 1, baseline: 0),
                                         size: ValueIndicatorCanvasNode.DefaultSize)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.ValueIndicator(), to: child)
        }
    }
    
    func updateIssueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
        let child: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.IssueIndicator.self) {
            child = target
            //            child.setComponent(IssueIndicatorCanvasNode())
            // TODO: TouchRegion.shape(rect)
        }
        else {
            let visibility: Visibility = representedEntity.hasIssues ? .visible : .hidden
            let interactivity = visibility
            child = world.spawn(
                CanvasNode(),
                visibility,
                interactivity,
                PositionComponent(position: .zero),
                CanvasNodeStyle(class: .issueIndicator),
                IssueIndicatorCanvasNode(),
                // TODO: TouchRegion.shape(rect)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.IssueIndicator(), to: child)
        }
    }
    
    func updateColorSwatch(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let colorKey = block.accentColor else {
            if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.ColorSwatch.self) {
                target.despawn()
            }
            return
        }
        
        let child: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.ColorSwatch.self) {
            child = target
            child.setComponent(ColorSwatchCanvasNode(colorKey: colorKey))
        }
        else {
            child = world.spawn(
                CanvasNode(),
                Visibility.visible,
                Interactivity.inert,
                PositionComponent(position: .zero),
                ColorSwatchCanvasNode(colorKey: colorKey)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.ColorSwatch(), to: child)
        }
    }
    
    
    func updateConnectorNode(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context)
    {
        updateConnectorGeometry(sceneNode, from: representedEntity, context: context)
        updateConnectorStroke(sceneNode, from: representedEntity)
        // TODO: [REFACTORING][IMPORTANT] Update modifiers flags, especially selection
    }
    
    /// Update connector wire and stroke geometry from connector glyph and two blocks the connector
    /// is connecting.
    ///
    /// - Parameters:
    ///     - sceneNode: Node to be updated.
    ///     - representedEntity: Entity the scene node represents and which the scene node is
    ///       updated from. For components requirements see below.
    ///
    /// Component requirements:
    ///
    /// - ``sceneNode``: no components required.
    /// - ``representedEntity``:
    ///     - ``DiagramConnector`` (required): used to get glyph (``ConnectorGlyph``) and midpoints.
    ///     - ``PreviewMidpoints`` (optional): midpoints during interactive overriding
    ///        ``DiagramConnector/midpoints`` if present.
    ///     - Relationship ``ConnectorCanvasNode/Origin`` and ``ConnectorCanvasNode/Target`` that
    ///       point to connector origin and target entities, which are expected to have
    ///       ``BlockCanvasNode`` component to determine connector touch points.
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
    func updateConnectorGeometry(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity, context: Context) {
        guard let representedConnector: DiagramConnector = representedEntity.component(),
              let origin: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Origin.self),
              let target: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Target.self)
        else { return }
        // TODO: Use PreviewMidpoints
        let worldMidpoints: [Vector2D]
        if let preview: PreviewMidpoints = representedEntity.component() {
            worldMidpoints = preview.midpoints
        }
        else {
            worldMidpoints = representedConnector.midpoints
        }
        // Scene midpoints
        let midpoints = worldMidpoints.map { context.toSceneTransform.apply(to: $0) }
        
        let lineType = representedConnector.glyph.lineType
        
        let originPosition: Vector2D = Self.positionWithPreview(of: origin)
        let targetPosition: Vector2D = Self.positionWithPreview(of: target)
        
        let originCastPoint = midpoints.first ?? targetPosition
        let originDirection = (originPosition - originCastPoint).normalized
        let targetCastPoint = midpoints.last ?? originPosition
        let targetDirection = (targetPosition - targetCastPoint).normalized
        
        let originCollision: CollisionShape?
        
        if let originPictogram: RuntimeEntity = origin.target(CanvasNode.Pictogram.self) {
            originCollision = originPictogram.component()
        }
        else {
            originCollision = origin.component()
        }
        
        let targetCollision: CollisionShape?
        
        if let targetPictogram: RuntimeEntity = target.target(CanvasNode.Pictogram.self) {
            targetCollision = targetPictogram.component()
        }
        else {
            targetCollision = target.component()
        }
        
        
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
        
        let geometry = ConnectorGeometry(origin: originTouch,
                                         originDirection: originDirection,
                                         target: targetTouch,
                                         targetDirection: targetDirection,
                                         midpoints: midpoints)
        sceneNode.setComponent(geometry)
        
        let wire = ConnectorWire(points: path.tessellate())
        sceneNode.setComponent(wire)
        
    }
    func updateConnectorStroke(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        // FIXME: [IMPORTANT] Midpoints in connector are not transformed to viewport. Use midpoints from wire (but we need to add midpoints to wire).
        guard let connector: DiagramConnector = representedEntity.component(),
              let geometry: ConnectorGeometry = sceneNode.component()
        else { return }
        
        let stroke: ConnectorStroke
        let glyph = connector.glyph
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
    
    static func positionWithPreview(of entity: RuntimeEntity) -> Vector2D {
        let position: Vector2D
        if let preview: PreviewPositionComponent = entity.component() {
            position = preview.position
        }
        else if let original: PositionComponent = entity.component() {
            position = original.position
        }
        else {
            position = .zero
        }
        return position
    }
}
