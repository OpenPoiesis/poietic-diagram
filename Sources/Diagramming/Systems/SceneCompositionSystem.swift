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
        print("⚙️🖼️ Running scene composition system")
        let composer = DiagramSceneComposer(world: world)
        updateData(world, composer: composer)
        updateLayout(world, composer: composer)
        updateGeometry(world, composer: composer)

        // Clean-up.
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            scene.removeComponent(Diagram.DirtyContent.self)
        }
        for node: RuntimeEntity in world.query(DiagramSceneNode.self) {
            node.removeComponent(Diagram.DirtyContent.self)
        }
    }
    
    func updateData(_ world: World, composer: DiagramSceneComposer) {
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            let dirty: Diagram.DirtyContent = scene.component() ?? []
            guard dirty.contains(.data) else { continue }
            print("  ⚙️📄 Scene data update")
            composer.updateData(scene: scene)
        }
    }
    func updateLayout(_ world: World, composer: DiagramSceneComposer) {
        for (scene, _, provider) in world.query(DiagramScene.self, SceneLayoutProvider.self) {
            let dirty: Diagram.DirtyContent = scene.component() ?? []
            guard dirty.contains(.layout) else { continue }
            print("  ⚙️✂️ Scene layout update")
            composer.layout(scene: scene, layout: provider.provider)
        }
    }
    func updateGeometry(_ world: World, composer: DiagramSceneComposer) {
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            let dirty: Diagram.DirtyContent = scene.component() ?? []
            guard dirty.contains(.geometry) else { continue }
            print("  ⚙️📐 geometry update")
            composer.updateGeometry(scene: scene)
        }
    }
}
