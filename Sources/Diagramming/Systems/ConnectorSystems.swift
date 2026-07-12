//
//  ConnectorGeometrySystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/11/2025.
//

import PoieticCore

#if false

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
#endif
