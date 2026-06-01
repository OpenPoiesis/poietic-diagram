//
//  Composer.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 27/05/2026.
//

import PoieticCore

class DiagramSceneComposer {
    let world: World
    let viewport: ViewportInfo
    let toSceneTransform: AffineTransform
    
    init(world: World, viewport: ViewportInfo) {
        self.world = world
        self.viewport = viewport
        self.toSceneTransform = AffineTransform(scale: Vector2D(viewport.zoomLevel, viewport.zoomLevel))
                                .translated(viewport.offset)
    }
    
    /// Create a diagram scene in the world
    func createScene() {
        let root: RuntimeID! = nil

        for entity: RuntimeEntity in world.query(DiagramBlock.self) {
            createBlockNode(representing: entity, parent: root)
        }

        for entity: RuntimeEntity in world.query(DiagramConnector.self) {
            createConnectorNode(representing: entity, parent: root)
        }
    }
    /// Create a diagram block node
    ///
    /// 1. Spawn a scene block
    /// 2. Create children:
    ///  - label
    func createBlockNode(representing representedEntity: RuntimeEntity, parent: RuntimeID) {
        guard let block: DiagramBlock = representedEntity.component()
        else { return }

        let position = toSceneTransform.apply(to: block.position)
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            BlockCanvasNode(),
            PositionComponent(position: position),
        )
        node.relate(ChildOf(), to: parent)
        node.relate(RepresentationOf(), to: representedEntity)

        syncBlockPictogram(representedEntity, blockSceneNode: node)
        syncBlockLabel(representedEntity, blockSceneNode: node)
        syncValueIndicator(representedEntity, blockSceneNode: node)
        syncIssueIndicator(representedEntity, blockSceneNode: node)
        syncColorSwatch(representedEntity, blockSceneNode: node)
    }
    
    func syncBlockPictogram(_ blockEntity: RuntimeEntity, blockSceneNode: RuntimeEntity) {
        guard let block: DiagramBlock = blockEntity.component()
        else { return }
        
        guard let pictogram = block.pictogram else {
            if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.Pictogram.self) {
                target.despawn()
            }
            return
        }
        
        let scaledPictogram = pictogram.scaled(viewport.zoomLevel)
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
            pictogramNode.relate(ChildOf(), to: blockEntity)
            blockEntity.relate(CanvasNode.Pictogram(), to: pictogramNode)
        }
    }
    
    func syncBlockLabel(_ blockEntity: RuntimeEntity, blockSceneNode: RuntimeEntity) {
        guard let block: DiagramBlock = blockEntity.component()
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
            labelNode.relate(ChildOf(), to: blockEntity)
            blockEntity.relate(CanvasNode.PrimaryLabel(), to: labelNode)
        }
    }

    func syncValueIndicator(_ blockEntity: RuntimeEntity, blockSceneNode: RuntimeEntity) {
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
            child.relate(ChildOf(), to: blockEntity)
            blockEntity.relate(CanvasNode.ValueIndicator(), to: child)
        }
    }

    func syncIssueIndicator(_ blockEntity: RuntimeEntity, blockSceneNode: RuntimeEntity) {
        let child: RuntimeEntity
        
        if let target: RuntimeEntity = blockSceneNode.target(CanvasNode.IssueIndicator.self) {
            child = target
            //            child.setComponent(IssueIndicatorCanvasNode())
            // TODO: TouchRegion.shape(rect)
        }
        else {
            let visibility: Visibility = blockEntity.hasIssues ? .visible : .hidden
            let interactivity = visibility
            child = world.spawn(
                CanvasNode(),
                visibility,
                interactivity,
                PositionComponent(position: .zero),
                IssueIndicatorCanvasNode(),
                // TODO: TouchRegion.shape(rect)
            )
            child.relate(ChildOf(), to: blockEntity)
            blockEntity.relate(CanvasNode.IssueIndicator(), to: child)
        }
    }

    func syncColorSwatch(_ blockEntity: RuntimeEntity, blockSceneNode: RuntimeEntity) {
        guard let block: DiagramBlock = blockEntity.component()
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
                ColorSwatchCanvasNode(colorKey: colorKey),
            )
            child.relate(ChildOf(), to: blockEntity)
            blockEntity.relate(CanvasNode.ColorSwatch(), to: child)
        }
    }
    
    // MARK: - Connector
    /// - Requires that the blocks are composed
    ///
    /// Connector Canvas Node:
    /// - CanvasNode()
    /// - ConnectorCanvasNode()
    /// - ConnectorStrokeCanvasNode(body, head, tail, filled?)
    /// - ConnectorWire()
    ///
    func createConnectorNode(representing representedEntity: RuntimeEntity, parent: RuntimeID) {
        guard let connector: DiagramConnector = representedEntity.component(),
              let origin = world.entity(connector.originID),
              let target = world.entity(connector.targetID)
        else { return }

        // 1. Wire
        
        let node: RuntimeEntity = world.spawn(
            CanvasNode(),
            ConnectorCanvasNode(),
        )
        node.relate(ChildOf(), to: parent)
        node.relate(RepresentationOf(), to: representedEntity)
        node.relate(ConnectorCanvasNode.Origin(), to: origin)
        node.relate(ConnectorCanvasNode.Target(), to: target)
    }

    func updateConnectorWire(sceneNode: RuntimeEntity) {
        guard let representedEntity: RuntimeEntity = sceneNode.target(RepresentationOf.self),
              let representedConnector: DiagramConnector = representedEntity.component(),
              let origin: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Origin.self),
              let target: RuntimeEntity = sceneNode.target(ConnectorCanvasNode.Target.self)
        else { return }
        
        let midpoints = representedConnector.midpoints.map { toSceneTransform.apply(to: $0) }

        let wire = Self.makeWire(origin: origin,
                                 target: target,
                                 midpoints: midpoints,
                                 lineType: representedConnector.glyph.lineType)
        sceneNode.setComponent(wire)
        
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
