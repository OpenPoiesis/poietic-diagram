//
//  StatusComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//

import PoieticCore

public struct PositionComponent: Component {
    public init(position: Vector2D) {
        self.position = position
    }
    
    public let position: Vector2D
    
}

/// Flag denoting whether an entity has been modified so that other related entities need to be
/// updated.
///
/// Typical use case: when a position of a diagram block is changed, a block entity is marked as
/// dirty so that the geometry of connectors is recomputed and visuals are updated.
///
struct IsDirty: Component { /* Tag component */ }

/// Component stating visibility of a scene node.
///
/// - SeeAlso: ``Interactivity``
public enum Visibility: Component {
    /// Scene node is visible, it is rendered onto a rendering surface.
    case visible
    /// Scene node is hidden, it is not rendered onto a rendering surface.
    case hidden

    /// Scene node visibility is inherited from its parent.
    ///
    /// - SeeAlso: ``ChildOf``
    case inherit
}

// TODO: ComputedInteractivity (final)
/// Component stating interactivity of a scene node.
///
/// Scene nodes flagged as interactive can be touched. Touch region is specified
/// in ``TouchRegion``.
///
/// - SeeAlso: ``Visibility``, ``TouchRegion``
///
public enum Interactivity: Component {
    /// Scene node is interactive and can be touched. The region within which the node can be
    /// touched is defined in ``TouchRegion`` component.
    ///
    case interactive
    
    /// Scene node is not interactive.
    case inert

    /// Scene node visibility is inherited from its parent.
    ///
    /// - SeeAlso: ``ChildOf``
    case inherit
}

/// Component specifying touch region of the component owning entity.
///
/// - SeeAlso: ``Interactivity``
///
public enum TouchRegion: Component {
    public static let DefaultHitRadius: Double = 4.0

    /// Touch region is defined by a collision shape. Used for blocks and annotations.
    ///
    case shape(CollisionShape)

    /// Touch region is defined by a thin wire. Used for connectors.
    ///
    case wire([Vector2D])
    
    /// Test whether the region was hit at given point. The point is in the region coordinates.
    ///
    /// - Returns: `true` if the hit point is within radius of the region.
    ///
    public func isHit(at point: Vector2D, radius: Double = Self.DefaultHitRadius) -> Bool {
        switch self {
        case .shape(let shape):
            let touchShape = CollisionShape(position: point, shape: .circle(radius))
            return shape.collide(with: touchShape)
        case .wire(let wire):
            for i in 0..<(wire.count-1) {
                let segment = LineSegment(from: wire[i], to: wire[i + 1])
                if segment.distance(to: point) < radius {
                    return true
                }
            }
            return false
        }
    }
}
