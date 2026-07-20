//
//  SceneCompositionSystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 20/07/2026.
//

import PoieticCore

/// System that composes and updates diagram scenes.
///
/// The system performs the following:
///
/// 1. Update data on all scenes and their nodes.
/// 2. Update layout for scenes which have ``SceneLayoutProvider`` component set
/// 3. Update geometry of all scenes.
/// 4. Cleans-up diagram dirty content flags.
///
/// This system is intended to be run on each application update cycle.
///
/// - **Input:**
///     - ``DiagramScene`` entities and their children.
///         - Considers ``Diagram.DirtyContent`` flag if present.
///     - ``NotationRules`` singleton, empty rules are used if not found.
/// - **Updates:** Scene nodes and their children ``DiagramSceneNode``.
/// - **Output:** Nothing new created.
/// - **Defaults:**
///     - ``SceneLayoutProvider`` must be present if layout is requested, otherwise layout phase is
///       omitted.
///     - If ``Diagram/DirtyContent`` component is not set, then ``Diagram/DirtyContent/all`` is
///     assumed.
/// - **Issues collected:** No issues generated.
///
public struct SceneCompositionSystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(DiagramObjectsFromTraitsSystem.self),
    ]

    public init(_ world: World) {  /* Nothing here for now */  }

    public func update(_ world: World) throws(InternalSystemError) {
        let composer = DiagramSceneComposer(world: world)
        // 1. Update Data.
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            let dirty: Diagram.DirtyContent = scene.component() ?? .all
            guard dirty.contains(.data) else { continue }
            composer.updateData(scene: scene)
        }

        // 2. Update Layout.
        for (scene, _, provider) in world.query(DiagramScene.self, SceneLayoutProvider.self) {
            let dirty: Diagram.DirtyContent = scene.component() ?? .all
            guard dirty.contains(.layout) else { continue }
            composer.layout(scene: scene, layout: provider.provider)
        }
        
        // 3. Update Geometry.
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            let dirty: Diagram.DirtyContent = scene.component() ?? .all
            guard dirty.contains(.geometry) else { continue }
            composer.updateGeometry(scene: scene)
        }
        
        // 4. Clean-up.
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            scene.removeComponent(Diagram.DirtyContent.self)
        }
        for node: RuntimeEntity in world.query(DiagramSceneNode.self) {
            node.removeComponent(Diagram.DirtyContent.self)
        }
    }
}
