//
//  Composer.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 27/05/2026.
//

import PoieticCore

/// Object responsible for creating and synchronising a diagram scene with model.
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
    public let viewport: ViewportState
    public let toSceneTransform: AffineTransform
    
    
    /// Mapping between diagram objects and their scene counterparts.
    var diagramToScene: [RuntimeID:RuntimeID] = [:]
    
    public init(world: World, viewport: ViewportState) {
        self.world = world
        self.viewport = viewport
        self.toSceneTransform = AffineTransform(scale: Vector2D(viewport.zoom, viewport.zoom))
                                .translated(viewport.offset)
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
    public func createScene(diagram: RuntimeEntity) -> RuntimeEntity {
        debugPrint("=== Creating scene")
        let scene: RuntimeEntity = world.spawn(
            DiagramCanvas()
        )
        // Represented block to scene node map
        var repToSceneMap: [RuntimeID:RuntimeID] = [:]
        
        scene.relate(RepresentationOf(), to: diagram)

        for entity in diagram.outgoing(Depicts.self) where entity.contains(DiagramBlock.self) {
            let node = createBlockNode(representing: entity, scene: scene.runtimeID)
            repToSceneMap[entity.runtimeID] = node
        }

        for entity in diagram.outgoing(Depicts.self) where entity.contains(DiagramConnector.self){
            createConnectorNode(representing: entity, scene: scene.runtimeID, blockMap: repToSceneMap)
        }
        debugPrint("<-- Created scene with \(scene.children.count) children")
        return scene
    }
    
    public func updateDiagramObjectRepresentations() {
        // TODO: Check for dirty, update dirty only
        for node: RuntimeEntity in world.query(BlockCanvasNode.self) {
            guard let representedEntity: RuntimeEntity = node.target(RepresentationOf.self)
            else { continue }
            
            updateBlockNode(node, from: representedEntity)
        }

        for node: RuntimeEntity in world.query(ConnectorCanvasNode.self) {
            guard let representedEntity: RuntimeEntity = node.target(RepresentationOf.self)
            else { continue }
            
            updateConnectorNode(node, from: representedEntity)
        }

    }
    /// Create a diagram block node
    ///
    /// 1. Spawn a scene block
    /// 2. Create children:
    ///  - label
    func createBlockNode(representing representedEntity: RuntimeEntity, scene: RuntimeID) -> RuntimeID {
        let block: DiagramBlock? = representedEntity.component()
        let position = toSceneTransform.apply(to: block?.position ?? .zero)
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            BlockCanvasNode(),
            PositionComponent(position: position),
        )
        node.relate(ChildOf(), to: scene)
        node.relate(RepresentationOf(), to: representedEntity)
        
        self.diagramToScene[representedEntity.runtimeID] = node.runtimeID
        
        updateBlockNode(node, from: representedEntity)
        
        return node.runtimeID
    }
    
    /// Update the block node content from the entity the node represents.
    ///
    /// - Note: The caller is responsible to update layout, if necessary.
    ///
    func updateBlockNode(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        updateBlockPictogram(sceneNode, from: representedEntity)
        updateBlockLabel(sceneNode, from: representedEntity)
        updateValueIndicator(sceneNode, from: representedEntity)
        updateIssueIndicator(sceneNode, from: representedEntity)
        updateColorSwatch(sceneNode, from: representedEntity)
    }

    func updateBlockPictogram(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        print("??? Update pictogram")
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let pictogram = block.pictogram else {
            if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.Pictogram.self) {
                target.despawn()
            }
            return
        }
        
        print("--- Update pictogram: \(pictogram)")
        let scaledPictogram = pictogram.scaled(viewport.zoom)
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
    
    func updateBlockLabel(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }
        
        guard let text = block.label else {
            if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.PrimaryLabel.self) {
                target.despawn()
            }
            return
        }
        
        let labelNode: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.PrimaryLabel.self) {
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
                LabelCanvasNode(text: text, anchor: Vector2D(0.5,0.0))
                // TODO: TouchRegion.shape(rect)
            )
            labelNode.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.PrimaryLabel(), to: labelNode)
        }
    }

    func updateValueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
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
                ValueIndicatorCanvasNode(value: nil,
                                         bounds: ValueBounds(min: 0, max: 1, baseline: 0),
                                         size: ValueIndicatorCanvasNode.DefaultSize)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.ValueIndicator(), to: child)
        }
    }

    func updateIssueIndicator(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
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
                IssueIndicatorCanvasNode(),
                // TODO: TouchRegion.shape(rect)
            )
            child.relate(ChildOf(), to: blockSceneNode)
            blockSceneNode.relate(CanvasNode.IssueIndicator(), to: child)
        }
    }

    func updateColorSwatch(_ blockSceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
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
    
    // MARK: - Connector
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
                             scene: RuntimeID,
                             blockMap: [RuntimeID:RuntimeID]) {
        guard let connector: DiagramConnector = representedEntity.component(),
              let originID = blockMap[connector.originID],
              let origin = world.entity(originID),
              let targetID = blockMap[connector.targetID],
              let target = world.entity(targetID)
        else { return }

        // 1. Wire
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            ConnectorCanvasNode(),
        )
        node.relate(ChildOf(), to: scene)
        node.relate(RepresentationOf(), to: representedEntity)
        node.relate(ConnectorCanvasNode.Origin(), to: origin)
        node.relate(ConnectorCanvasNode.Target(), to: target)
        
        updateConnectorNode(node, from: representedEntity)
    }
    
    func updateConnectorNode(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity)
    {
        updateConnectorWire(sceneNode, from: representedEntity)
        updateConnectorStroke(sceneNode, from: representedEntity)
    }
    
    func updateConnectorWire(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let representedEntity: RuntimeEntity = sceneNode.target(RepresentationOf.self),
              let representedConnector: DiagramConnector = representedEntity.component(),
              let origin: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Origin.self),
              let target: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Target.self)
        else { return }
        // TODO: Use PreviewMidpoints
        let midpoints = representedConnector.midpoints.map { toSceneTransform.apply(to: $0) }

        let wire = Self.makeWire(origin: origin,
                                 target: target,
                                 midpoints: midpoints,
                                 lineType: representedConnector.glyph.lineType)
        sceneNode.setComponent(wire)
        
    }
    func updateConnectorStroke(_ sceneNode: RuntimeEntity, from representedEntity: RuntimeEntity) {
        guard let connector: DiagramConnector = representedEntity.component(),
              let wire: ConnectorWire = sceneNode.component()
        else { return }
        
        let stroke: ConnectorStroke
        let glyph = connector.glyph
        switch glyph.kind {
        case .fat(let kind):
            let outline = Geometry.fatConnectorPath(
                originPoint: wire.originPoint,
                targetPoint: wire.targetPoint,
                midpoints: connector.midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                kind: kind
            )
            stroke = ConnectorStroke(body: outline,
                                     headArrowhead: nil,
                                     tailArrowhead: nil,
                                     isFilled: true)
            
        case .thin(let kind):
            let paths = Geometry.thinConnectorPaths(
                originPoint: wire.originPoint,
                targetPoint: wire.targetPoint,
                midpoints: connector.midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                lineType: glyph.lineType,
                kind: kind
            )
            
            stroke = ConnectorStroke(body: paths.body,
                                     headArrowhead: paths.tail,
                                     tailArrowhead: paths.head,
                                     isFilled: false)
        }
        sceneNode.setComponent(stroke)
        
    }

    /// Make a connector wire between origin and target entities which are expected to be a diagram
    /// scene entities.
    ///
    /// - Parameters:
    ///     - origin: Connector origin diagram canvas node, typically ``BlockCanvasNode``.
    ///     - origin: Connector target diagram canvas node, typically ``BlockCanvasNode``.
    ///     - midpoints: List of connector midpoints.
    ///     - lineType: wire path type, used for bezier path computation.
    ///       See also: ``Geometry/wirePath(from:to:through:lineType:)``
    ///
    /// Expected components and their compensation in both origin and target:
    /// - ``PositionComponent`` is expected and used for block position. If not present then zero
    ///   point is used.
    /// - ``CollisionShape`` is expected and used for block collision shape. If not present then
    ///   the touch point is the block position point.
    ///
    /// - SeeAlso: ``Geometry/rayIntersection(shape:position:from:direction:)``
    ///
    static func makeWire(origin: RuntimeEntity,
                         target: RuntimeEntity,
                         midpoints: [Vector2D],
                         lineType: LineType) -> ConnectorWire
    {
        let originPositionComponent: PositionComponent? = origin.component()
        let originPosition = originPositionComponent?.position ?? .zero

        let targetPositionComponent: PositionComponent? = target.component()
        let targetPosition = targetPositionComponent?.position ?? .zero

        let originCastPoint = midpoints.first ?? targetPosition
        let originDirection = (originPosition - originCastPoint).normalized
        let targetCastPoint = midpoints.last ?? originPosition
        let targetDirection = (targetPosition - targetCastPoint).normalized

        let originTouch: Vector2D
        if let originShape: CollisionShape = origin.component() {
            let intersect = Geometry.rayIntersection(shape: originShape.shape,
                                                     position: originPosition + originShape.position,
                                                     from: originCastPoint,
                                                     direction: originDirection)
            originTouch = intersect ?? originPosition
        }
        else {
            originTouch = originPosition
        }
        
        let targetTouch: Vector2D
        if let targetShape: CollisionShape = target.component() {
            let intersect = Geometry.rayIntersection(shape: targetShape.shape,
                                                     position: targetPosition + targetShape.position,
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

        let wire = ConnectorWire(origin: originTouch,
                                 originDirection: originDirection,
                                 target: targetTouch,
                                 targetDirection: targetDirection,
                                 points: path.tessellate())
        return wire
    }
}
