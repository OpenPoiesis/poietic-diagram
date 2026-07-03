//
//  ConnectorGeometrySystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/11/2025.
//

import PoieticCore

/// System that computes connector geometry from ``DiagramConnector`` and ``DiagramBlock``.
///
///
/// - **Input:**
///     - World objects with the ``DiagramConnector`` component.
///     - Optional ``ConnectorPreview`` for the same objects.
///     - Optional ``Notation`` singleton. If not provided, default empty notation is used.
/// - **Output:** ``DiagramConnectorGeometry``.
/// - **Forgiveness:**
///     - Ignores objects where origin or target entities do not exist or if they do not have
///       ``DiagramBlock``.
///     - If no ``Notation`` singleton is found, then default empty notation is used.
///
/// When you create your own ``DiagramConnector`` system, make sure that it includes
/// ``ConnectorGeometrySystem`` in its dependency list:
///
/// ```swift
/// public struct MyConnectorCreationSystem: System {
///     public static let dependencies: [SystemDependency] = [
///         .before(ConnectorGeometrySystem.self),
///     ]
///     // ... body of the system goes here
/// }
/// ```
///

public struct ConnectorGeometrySystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(DiagramObjectsFromTraitsSystem.self),
    ]

    public init(_ world: World) {}

    public func update(_ world: World) throws (InternalSystemError) {
        for (entity, connector) in world.query(DiagramConnector.self) {
            try update(entity, connector: connector, world: world)
        }
    }

    public func update(_ entity: RuntimeEntity,
                       connector: DiagramConnector,
                       world: World)
    throws (InternalSystemError) {
        // Get origin/target blocks
        guard let origin = world.entity(connector.originID),
              let originBlock: DiagramBlock = origin.component(),
              let target = world.entity(connector.targetID),
              let targetBlock: DiagramBlock = target.component()
        else { return }
        
        let originPreview: BlockPreview? = origin.component()
        let targetPreview: BlockPreview? = target.component()
        let preview: ConnectorPreview? = entity.component()
        let midpoints = preview?.midpoints ?? connector.midpoints

        let (originTouch, targetTouch) = Geometry.touchPoints(
            originPosition: originPreview?.position ?? originBlock.position,
            originShape: originBlock.collisionShape,
            targetPosition: targetPreview?.position ?? targetBlock.position,
            targetShape: targetBlock.collisionShape,
            midpoints: midpoints
        )

        let geometry = DiagramConnectorGeometry(originTouch: originTouch,
                                                targetTouch: targetTouch,
                                                midpoints: midpoints,
                                                glyph: connector.glyph)

        entity.setComponent(geometry)
    }
}

@available(*, deprecated, message: "Use canvas scene nodes")
extension DiagramConnectorGeometry {
    public init(originTouch: Vector2D,
                targetTouch: Vector2D,
                midpoints: [Vector2D] = [],
                glyph: ConnectorGlyph)
    {
        let wirePath = Geometry.wirePath(from: originTouch,
                                         to: targetTouch,
                                         through: midpoints,
                                         lineType: glyph.lineType)
        
        switch glyph.kind {
        case .fat(let kind):
            let outline = Geometry.fatConnectorPath(
                originPoint: originTouch,
                targetPoint: targetTouch,
                midpoints: midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                kind: kind
            )
            
            self.originPoint = originTouch
            self.targetPoint = targetTouch
            self.wire = wirePath
            self.linePath = outline
            self.fillPath = outline
            self.tailArrowhead = nil
            self.headArrowhead = nil
            
        case .thin(let kind):
            let paths = Geometry.thinConnectorPaths(
                originPoint: originTouch,
                targetPoint: targetTouch,
                midpoints: midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                lineType: glyph.lineType,
                kind: kind
            )
            
            self.originPoint = originTouch
            self.targetPoint = targetTouch
            self.wire = wirePath
            self.linePath = paths.body
            self.fillPath = nil
            self.tailArrowhead = paths.tail
            self.headArrowhead = paths.head
        }
    }
}


/// System that updates diagram scene trees.
///
///
/// - **Input:**
///     - World entities with ``DiagramCanvas`` component and their children.
/// - **Output:** New or updated ``CanvasNode`` entities.
/// - **Forgiveness:**
///     - not much
///
public struct DiagramUpdateSystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(DiagramObjectsFromTraitsSystem.self),
    ]
    
    public init(_ world: World) {}
    
    public func update(_ world: World) throws (InternalSystemError) {
        for (entity, connector) in world.query(Diagram.self) {
            let viewport: ViewportState = entity.component() ?? ViewportState()
            createDiagram(root: entity, viewport: viewport)
        }
        
        // updateGeometry()
    }
    public func createDiagram(root: RuntimeEntity, viewport: ViewportState) {
        for child in root.children {
            
        }
    }
}
