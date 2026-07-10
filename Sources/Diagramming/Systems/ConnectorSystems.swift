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
        throw InternalSystemError(self, message: "Connector geometry system has been removed")
    }

    public func update(_ entity: RuntimeEntity,
                       connector: DiagramConnector,
                       world: World)
    throws (InternalSystemError) {
        // Get origin/target blocks
//        let geometry = DiagramConnectorGeometry(originTouch: originTouch,
//                                                targetTouch: targetTouch,
//                                                midpoints: midpoints,
//                                                glyph: connector.glyph)

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
