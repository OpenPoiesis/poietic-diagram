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
///     - If ``Diagram/DirtyContent`` component is not set, then empty set (all clean) is
///     assumed.
/// - **Issues collected:** No issues generated.
///
public struct SceneCompositionSystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(TraitsToDiagramObjectsSystem.self),
    ]
    
    public init(_ world: World) {  /* Nothing here for now */  }
    
    public func update(_ world: World) throws(InternalSystemError) {
        let composer = DiagramSceneComposer(world: world)
        flagTouchedObjects(world)
        updateData(world, composer: composer)
        updateHighlights(world)
        updateLayout(world, composer: composer)
        updateGeometry(world, composer: composer)

    }
    /// Transform ``ObjectTouched`` flag into dirty content.
    func flagTouchedObjects(_ world: World) {
        for entity: RuntimeEntity in world.query(ObjectTouched.self) {
            // TODO: Filter only diagram object entities. Enable once we know for sure the component is set.
            // guard entity.contains(DiagramObject.self) else { continue }
            entity.setComponent(DirtyContent.all)
        }
    }
    
    func updateData(_ world: World, composer: DiagramSceneComposer) {
        for sceneNode: RuntimeEntity in world.query(BlockCanvasNode.self) {
            guard let represented: RuntimeEntity = sceneNode.target(RepresentationOf.self),
                  let flags: DirtyContent = represented.component(),
                  flags.contains(.data)
            else { continue }
            composer.updateBlockData(sceneNode, from: represented)
        }
        // No connector data to be updated here yet.
    }

    func updateHighlights(_ world: World) {
        // TODO: Use something like SelectionDirty world singleton
        for sceneNode: RuntimeEntity in world.query(CanvasNode.self) {
            guard let represented: RuntimeEntity = sceneNode.target(RepresentationOf.self)
            else { continue }
            
            if represented.contains(IsSelected.self) {
                sceneNode.modify(CanvasNodeStyle.self) { $0.modifiers.insert(.selected) }
            } else {
                sceneNode.modify(CanvasNodeStyle.self) { $0.modifiers.remove(.selected) }
            }
        }
    }
    
    /// Update geometry of scene nodes.
    ///
    /// - Block Nodes:
    ///     - when represented entity is dirty
    ///     - when scene has ``ViewportDirty``
    /// - Connector Nodes:
    ///     - when represented entity is dirty
    ///     - when scene has ``ViewportDirty``
    ///     - when either origin or target
    func updateGeometry(_ world: World, composer: DiagramSceneComposer) {
        var dirtyBlocks: Set<RuntimeID> = Set()
        
        // TODO: Update WHEN: original is geometry dirty OR scene is geometry dirty
        for sceneNode: RuntimeEntity in world.query(BlockCanvasNode.self) {
            guard let represented: RuntimeEntity = sceneNode.target(RepresentationOf.self)
            else { continue }

            var isDirty: Bool = false

            if let flags: DirtyContent = represented.component() {
                isDirty = flags.contains(.geometry)
            }
            if let scene: RuntimeEntity = sceneNode.target(MemberOf.self) {
                isDirty = isDirty || scene.contains(ViewportDirty.self)
            }
                  
            guard isDirty else { continue }
            
            dirtyBlocks.insert(represented.runtimeID)
            composer.updateBlockGeometry(sceneNode, from: represented)
        }
        
        for sceneNode: RuntimeEntity in world.query(ConnectorCanvasNode.self) {
            guard let represented: RuntimeEntity = sceneNode.target(RepresentationOf.self)
            else { continue }

            var isDirty: Bool = false
            if let flags: DirtyContent = represented.component() {
                isDirty = flags.contains(.geometry)
            }
            if let scene: RuntimeEntity = sceneNode.target(MemberOf.self) {
                isDirty = isDirty || scene.contains(ViewportDirty.self)
            }
            if let connector: DiagramConnector = represented.component() {
                isDirty = dirtyBlocks.contains(connector.originID) ||
                            dirtyBlocks.contains(connector.targetID)

            }

            guard isDirty else { continue }
            
            composer.updateConnectorGeometry(sceneNode, from: represented)
        }
    }

    func updateLayout(_ world: World, composer: DiagramSceneComposer) {
        for (scene, _, provider) in world.query(DiagramScene.self, SceneLayoutProvider.self) {
            guard scene.contains(LayoutDirty.self)
            else { continue }

            composer.layout(scene: scene, layout: provider.provider)
        }
    }

//    func updateData(_ world: World, composer: DiagramSceneComposer) {
//        for scene: RuntimeEntity in world.query(DiagramScene.self) {
//            let dirty: Diagram.DirtyContent = scene.component() ?? []
//            guard dirty.contains(.data) else { continue }
//            print("  ⚙️📄 Scene data update")
//            composer.updateData(scene: scene)
//        }
//    }
//    func updateLayout(_ world: World, composer: DiagramSceneComposer) {
//        for (scene, _, provider) in world.query(DiagramScene.self, SceneLayoutProvider.self) {
//            let dirty: Diagram.DirtyContent = scene.component() ?? []
//            guard dirty.contains(.layout) else { continue }
//            print("  ⚙️✂️ Scene layout update")
//            composer.layout(scene: scene, layout: provider.provider)
//        }
//    }
//    func updateGeometry(_ world: World, composer: DiagramSceneComposer) {
//        for scene: RuntimeEntity in world.query(DiagramScene.self) {
//            let dirty: Diagram.DirtyContent = scene.component() ?? []
//            guard dirty.contains(.geometry) else { continue }
//            print("  ⚙️📐 geometry update")
//            composer.updateGeometry(scene: scene)
//        }
//    }
}
