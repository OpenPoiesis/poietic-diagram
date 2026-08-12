//
//  SceneInteractionSystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 26/07/2026.
//

import PoieticCore

/// System that computes absolute touch regions for interactive scene nodes.
///
/// The system traverses all scenes and finds nodes with ``Interactivity`` component and one of
/// geometry components: ``CollisionShape`` or ``ConnectorWire``. Computes ``TouchRegion`` component
/// with absolute scene coordinates.
///
/// If an application uses handles to manipulate visual objects, the handles must follow the
/// component requirements above.
///
/// This system is intended to be run when:
/// - plane changes (on transaction)
/// - viewport changes
/// - style or notation changes
///
///
///
/// ## Coordinates
///
/// | Component | Coordinates | Relative To |
/// |---|---|---|
/// | `PositionComponent` | relative | parent node |
/// | `CollisionShape` | relative | component owning node |
/// | `ConnectorWire` | absolute | – |
/// | `TouchRegion` | absolute | – |
///
/// - **Input:**
///     - ``DiagramScene`` scene hierarchy root entity.
///     - ``InteractionDirty`` tag set on the scene.
///     - ``DiagramSceneNode`` scene node entities (children of scene or other nodes).
///         - ``Interactivity``: required component, regardless of value.
///         - ``PositionComponent``: optional – see defaults below.
///         - Requires one of: ``CollisionShape`` or ``ConnectorWire`` components.
///         - ``ChildOf`` relationship is used for scene hierarchy.
/// - **Updates:** Scene nodes and their children ``DiagramSceneNode``.
/// - **Output:**
///     - Sets ``TouchRegion`` with absolute coordinates to a ``DiagramSceneNode`` entity, if
///       the entity is included in interactivity
///     - Removes ``TouchRegion`` on nodes without ``Interactivity`` component.
/// - **Defaults:**
///     - If ``PositionComponent`` is missing, then it defaults to zero (0,0) position.
/// - **Order:** Runs after ``SceneCompositionSystem``, if the system is present in the same
///   schedule.
///
public struct SceneInteractionSystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(SceneCompositionSystem.self),
    ]
    
    public init(_ world: World) {  /* Nothing here for now */  }
    
    public func update(_ world: World) throws(InternalSystemError) {
        for scene: RuntimeEntity in world.query(DiagramScene.self) {
            guard scene.contains(InteractionDirty.self) else { continue }
            computeTouchRegions(scene: scene)

            // Clean-up
            scene.removeComponent(InteractionDirty.self)
            scene.withChildrenRecursively {
                $0.removeComponent(InteractionDirty.self)
            }
        }
    }
    
    func computeTouchRegions(scene: RuntimeEntity) {
        computeTouchRegions(node: scene, parentPosition: .zero)
    }
    
    func computeTouchRegions(node: RuntimeEntity, parentPosition: Vector2D) {
        let positionComponent: PositionComponent? = node.component()
        let positionOffset = parentPosition + (positionComponent?.position ?? .zero)

        if node.contains(Interactivity.self) {
            if let shape: CollisionShape = node.component() {
                let offsetShape = shape.translated(positionOffset)
                node.setComponent(TouchRegion.shape(offsetShape))
            }
            else if let wire: ConnectorWire = node.component() {
                // Wires are absolute.
                node.setComponent(TouchRegion.wire(wire.points))
            }
        }
        else {
            node.removeComponent(TouchRegion.self)
        }
        
        for child in node.children where child.contains(SceneNode.self) {
            computeTouchRegions(node: child, parentPosition: positionOffset)
        }
    }
}
