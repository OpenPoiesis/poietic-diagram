//
//  HitRegionSystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 26/07/2026.
//

import PoieticCore

/// System that computes absolute hit regions for interactive presentation nodes.
///
/// The system traverses all presentations and finds nodes with ``Interactivity`` component and one of
/// geometry components: ``CollisionShape`` or ``ConnectorWire``. Computes ``HitRegion`` component
/// with absolute presentation coordinates.
///
/// If an application uses handles to manipulate visual objects, the handles must follow the
/// component requirements above.
///
/// This system is intended to be run when:
/// - plane changes (on transaction)
/// - camera changes
/// - style or notation changes
///
///
///
/// ## Coordinates
///
/// | Component | Coordinates | Relative To |
/// |---|---|---|
/// | `LocalPosition` | relative | parent node |
/// | `CollisionShape` | relative | component owning node |
/// | `ConnectorWire` | absolute | – |
/// | `HitRegion` | absolute | – |
///
/// - **Input:**
///     - ``DiagramPresentation`` presentation hierarchy root entity.
///     - ``InteractionDirty`` tag set on the presentation.
///     - ``PresentationNode`` presentation node entities (children of presentation or other nodes).
///         - ``Interactivity``: required component, regardless of value.
///         - ``LocalPosition``: optional – see defaults below.
///         - Requires one of: ``CollisionShape`` or ``ConnectorWire`` components.
///         - ``ChildOf`` relationship is used for presentation hierarchy.
/// - **Updates:** Presentation nodes and their children ``PresentationNode``.
/// - **Output:**
///     - Sets ``HitRegion`` with absolute coordinates to a ``PresentationNode`` entity, if
///       the entity is included in interactivity
///     - Removes ``HitRegion`` on nodes without ``Interactivity`` component.
/// - **Defaults:**
///     - If ``LocalPosition`` is missing, then it defaults to zero (0,0) position.
/// - **Order:** Runs after ``PresentationUpdateSystem``, if the system is present in the same
///   schedule.
///
public struct HitRegionSystem: System {
    public static let dependencies: [SystemDependency] = [
        .after(PresentationUpdateSystem.self),
    ]
    
    public static func update(_ world: World) throws(InternalSystemError) {
        for presentation: RuntimeEntity in world.query(DiagramPresentation.self) {
            guard presentation.contains(InteractionDirty.self) else { continue }
            computeHitRegions(presentation: presentation)

            // Clean-up
            presentation.removeComponent(InteractionDirty.self)
            presentation.withChildrenRecursively {
                $0.removeComponent(InteractionDirty.self)
            }
        }
    }
    
    static func computeHitRegions(presentation: RuntimeEntity) {
        computeHitRegions(node: presentation, parentPosition: .zero)
    }
    
    static func computeHitRegions(node: RuntimeEntity, parentPosition: Vector2D) {
        let localPosition: LocalPosition? = node.component()
        let positionOffset = parentPosition + (localPosition?.position ?? .zero)

        if node.contains(Interactivity.self) {
            if let shape: CollisionShape = node.component() {
                let offsetShape = shape.translated(positionOffset)
                node.setComponent(HitRegion.shape(offsetShape))
            }
            else if let wire: ConnectorWire = node.component() {
                // Wires are absolute.
                node.setComponent(HitRegion.wire(wire.points))
            }
        }
        else {
            node.removeComponent(HitRegion.self)
        }
        
        for child in node.children where child.contains(PresentationNode.self) {
            computeHitRegions(node: child, parentPosition: positionOffset)
        }
    }
}
