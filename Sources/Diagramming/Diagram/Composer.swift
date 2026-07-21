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
    /// The created block has the following components and relationships:
    /// - ``CanvasNode``
    /// - ``BlockCanvasNode``
    /// - ``PositionComponent``
    /// - ``OwnedBy`` relationship to a scene which owns the node
    /// - ``ChildOf`` relationship to other scene node or the scene itself.
    ///
    /// Upon creation the block node is set as dirty with ``Diagram/DirtyContent/all``.
    ///
    func createBlockNode(representing representedEntity: RuntimeEntity, context: Context) -> RuntimeID {
        let block: DiagramBlock? = representedEntity.component()
        let position = context.toSceneTransform.apply(to: block?.position ?? .zero)
        
        let node: RuntimeEntity = world.spawn(
            DiagramSceneNode(),
            BlockCanvasNode(),
            PositionComponent(position: position),
            Diagram.DirtyContent.all,
        )
        node.relate(OwnedBy(), to: context.scene.runtimeID)
        node.relate(ChildOf(), to: context.scene.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)

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
        
        // 1. Wire
        
        let node: RuntimeEntity = world.spawn(
            DiagramSceneNode(),
            ConnectorCanvasNode(),
            Diagram.DirtyContent.all,
        )
        node.relate(OwnedBy(), to: context.scene.runtimeID)
        node.relate(ChildOf(), to: context.scene.runtimeID)
        node.relate(RepresentationOf(), to: representedEntity)
        node.relate(ConnectorCanvasNode.Origin(), to: origin)
        node.relate(ConnectorCanvasNode.Target(), to: target)
        
        updateConnectorNode(node, from: representedEntity, context: context)
    }

    // MARK: - Update
    
    /// Update scene data that is not related to geometry.
    ///
    /// - SeeAlso: ``updateGeometry(scene:)``
    ///
    @available(*, deprecated, message: "Use updateSceneData(scene) and/or SceneCompositionSystem")
    public func updateSceneData() {
        // TODO: Just dirty data. Should we make force: Bool version? or dirtyOnly: Bool = true?
        for node: RuntimeEntity in world.query(BlockCanvasNode.self) {
            guard let represented: RuntimeEntity = node.target(RepresentationOf.self) else { continue }
            updateBlockData(node, from: represented)
        }
        // Connectors have no data-only update (glyph doesn't change at runtime)
    }

    /// Update scene data that is not related to geometry.
    ///
    /// - SeeAlso: ``updateGeometry(scene:)``
    ///
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
    public func updateGeometry(scene: RuntimeEntity) {
        let context = Context(scene: scene)
        for child in scene.children where child.contains(BlockCanvasNode.self) {
            updateBlockPosition(child, context: context)
        }
        for child in scene.children where child.contains(ConnectorCanvasNode.self) {
            guard let represented: RuntimeEntity = child.target(RepresentationOf.self) else { continue }
            updateConnectorGeometry(child, from: represented, context: context)
            updateConnectorStroke(child, from: represented)
        }
    }

    /// Update geometry of all scenes and their nodes.
    ///
    /// Called on frame change or on interactive preview – both affect all scenes.
    public func updateGeometry() {
        for entity: RuntimeEntity in world.query(BlockCanvasNode.self) {
            guard let scene: RuntimeEntity = entity.target(OwnedBy.self)
            else { continue }
            let context = Context(scene: scene)
            updateBlockPosition(entity, context: context)
        }
        for entity: RuntimeEntity in world.query(ConnectorCanvasNode.self) {
            guard let scene: RuntimeEntity = entity.target(OwnedBy.self),
                  let represented: RuntimeEntity = entity.target(RepresentationOf.self)
            else { continue }
            let context = Context(scene: scene)
            updateConnectorGeometry(entity, from: represented, context: context)
            updateConnectorStroke(entity, from: represented)
        }
    }

    func updateBlockPosition(_ node: RuntimeEntity, context: Context) {
        guard let represented: RuntimeEntity = node.target(RepresentationOf.self),
              let block: DiagramBlock = represented.component()
        else { return }

        let position: Vector2D
        if let preview: PreviewPositionComponent = node.component() {
            position = preview.position
        }
        else if let original: PositionComponent = node.component() {
            // TODO: [Remove this comment] We are not using this yet, but let us put it here for instant future-proofing when block.position is removed
            position = original.position
        }
        else {
            position = block.position
        }
        let viewportPosition = context.toSceneTransform.apply(to: position)
        node.setComponent(PositionComponent(position: viewportPosition))
    }

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
            updateBlockData(node, from: representedEntity)
            updateBlockPosition(node, context: context)
        }

        // We need to update connectors after the blocks, to get correct touch points.
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
    func updateBlockData(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        updateBlockPictogram(sceneNode, from: representedEntity)
        updateBlockLabels(sceneNode, from: representedEntity)
        updateValueIndicator(sceneNode, from: representedEntity)
        updateIssueIndicator(sceneNode, from: representedEntity)
        updateColorSwatch(sceneNode, from: representedEntity)
        // TODO: [REFACTORING][IMPORTANT] Update modifiers flags, especially selection
    }
    
    func updateBlockPictogram(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        // TODO: Do not forget to mark as geometry dirty when pictogram changes
        // TODO: Do not forget to consider dirty geometry in connector update or mark the connector dirty

        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let pictogram = block.pictogram else {
            if let target: RuntimeEntity = blockSceneNode.target(DiagramSceneNode.Pictogram.self) {
                target.despawn()
            }
            return
        }
        
        let pictogramNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(DiagramSceneNode.Pictogram.self) {
            pictogramNode = target
            pictogramNode.setComponent(PictogramCanvasNode(pictogram: pictogram))
            pictogramNode.setComponent(TouchRegion.shape(pictogram.collisionShape))
        }
        else {
            pictogramNode = world.spawn(
                DiagramSceneNode(),
                Visibility.visible,
                Interactivity.interactive,
                PositionComponent(position: .zero),
                PictogramCanvasNode(pictogram: pictogram),
                TouchRegion.shape(pictogram.collisionShape),
                pictogram.collisionShape, // Collision shape for connector geometry
            )
            pictogramNode.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(DiagramSceneNode.Pictogram(), to: pictogramNode)
        }
    }
    
    func updateBlockLabels(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        updateBlockLabel(blockSceneNode,
                         type: DiagramSceneNode.PrimaryLabel(),
                         text: block.label,
                         style: CanvasNodeStyle(class: .primaryLabel))
        updateBlockLabel(blockSceneNode,
                         type: DiagramSceneNode.SecondaryLabel(),
                         text: block.secondaryLabel,
                         style: CanvasNodeStyle(class: .secondaryLabel))
    }
    
    func updateBlockLabel<T: Relationship>(_ blockSceneNode: RuntimeEntity,
                                           type labelType: T,
                                           text: String?,
                                           style: CanvasNodeStyle) {
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
            // TODO: TouchRegion.shape(rect)
        }
        else {
            labelNode = world.spawn(
                DiagramSceneNode(),
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

        if let target: RuntimeEntity = blockSceneNode.target(DiagramSceneNode.ValueIndicator.self) {
            child = target
            child.setComponent(indicatorComponent)
            child.setComponent(visibility)
            // TODO: TouchRegion.shape(rect)
        }
        else {
            child = world.spawn(
                DiagramSceneNode(),
                indicatorComponent,
                visibility,
                Interactivity.inert,
                PositionComponent(position: .zero),
                CanvasNodeStyle(class: .valueIndicator),
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(DiagramSceneNode.ValueIndicator(), to: child)
        }
    }
    
    func updateIssueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        let child: RuntimeEntity
        let visibility: Visibility = representedEntity.hasIssues ? .visible : .hidden
        let interactivity: Interactivity = representedEntity.hasIssues ? .interactive : .inert

        if let target: RuntimeEntity = blockSceneNode.target(DiagramSceneNode.IssueIndicator.self) {
            child = target
            target.setComponent(visibility)
            target.setComponent(interactivity)
            // TODO: TouchRegion.shape(rect)
        }
        else {
            child = world.spawn(
                DiagramSceneNode(),
                visibility,
                interactivity,
                PositionComponent(position: .zero),
                CanvasNodeStyle(class: .issueIndicator),
                IssueIndicatorCanvasNode(),
                // TODO: TouchRegion.shape(rect)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(DiagramSceneNode.IssueIndicator(), to: child)
        }
    }
    
    func updateColorSwatch(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let colorKey = block.accentColor else {
            if let target: RuntimeEntity = blockSceneNode.target(DiagramSceneNode.ColorSwatch.self) {
                target.despawn()
            }
            return
        }
        
        let child: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(DiagramSceneNode.ColorSwatch.self) {
            child = target
            child.setComponent(ColorSwatchCanvasNode(colorKey: colorKey))
        }
        else {
            child = world.spawn(
                DiagramSceneNode(),
                Visibility.visible,
                Interactivity.inert,
                PositionComponent(position: .zero),
                ColorSwatchCanvasNode(colorKey: colorKey)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(DiagramSceneNode.ColorSwatch(), to: child)
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
        
        let originPositionComp: PositionComponent? = origin.component()
        let originPosition: Vector2D = originPositionComp?.position ?? .zero
        let targetPositionComp: PositionComponent? = target.component()
        let targetPosition: Vector2D = targetPositionComp?.position ?? .zero
        
        let originCastPoint = midpoints.first ?? targetPosition
        let originDirection = (originPosition - originCastPoint).normalized
        let targetCastPoint = midpoints.last ?? originPosition
        let targetDirection = (targetPosition - targetCastPoint).normalized
        
        let originCollision: CollisionShape?
        
        if let originPictogram: RuntimeEntity = origin.target(DiagramSceneNode.Pictogram.self) {
            originCollision = originPictogram.component()
        }
        else {
            originCollision = origin.component()
        }
        
        let targetCollision: CollisionShape?
        
        if let targetPictogram: RuntimeEntity = target.target(DiagramSceneNode.Pictogram.self) {
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
}
