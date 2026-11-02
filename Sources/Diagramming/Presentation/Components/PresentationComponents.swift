//
//  PresentationComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 07/08/2026.
//

import PoieticCore

/// A presentation node component stating visibility of a presentation node.
///
/// - SeeAlso: ``Interactivity``
public enum Visibility: Component {
    /// Presentation node is visible, it is rendered onto a rendering surface.
    case visible
    /// Presentation node is hidden, it is not rendered onto a rendering surface.
    case hidden
}

/// Component stating interactivity of a presentation node.
///
/// Presentation nodes flagged as interactive can be hit. Hit region is specified
/// in ``HitRegion``.
///
/// - SeeAlso: ``Visibility``, ``HitRegion``
///
public enum Interactivity: Component {
    /// Presentation node is interactive and can be hit. The region within which the node can be
    /// hit is defined in ``HitRegion`` component.
    ///
    case interactive
    
    /// Presentation node is not interactive.
    case inert
}

/// Presentation node component specifying hit region of the component owning entity.
///
/// - SeeAlso: ``Interactivity``, ``InteractionDirty``
///
public enum HitRegion: Component {
    public static let DefaultHitRadius: Double = 4.0

    /// Hit region is defined by a collision shape. Used for blocks and annotations.
    ///
    case shape(CollisionShape)

    /// Hit region is defined by a thin wire. Used for connectors.
    ///
    case wire([Vector2D])
    
    /// Test whether the region was hit at given point. The point is in the region coordinates.
    ///
    /// - Returns: `true` if the hit point is within radius of the region.
    ///
    public func isHit(at point: Vector2D, radius: Double = Self.DefaultHitRadius) -> Bool {
        switch self {
        case .shape(let shape):
            let hitShape = CollisionShape(position: point, shape: .circle(radius))
            return shape.collide(with: hitShape)
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

/// Flag component of a presentation node stating that the diagram presentation requires re-layout.
///
public struct LayoutDirty: Component { public init() { /* Empty */ } }

/// Flag component of a presentation node stating that the viewport of a given presentation changed.
/// For example on panning or zooming.
public struct ProjectionDirty: Component { public init() { /* Empty */ } }

/// Flag component of a presentation node for tagging visual entities that require re-computation of ``HitRegion``
///
public struct InteractionDirty: Component { public init() { /* Empty */ } }

/// Presentation node component containing offset used as an adjustment by renderers (presenters) for
/// positions computed by backend-agnostic functions.
///
public struct RenderingOffset: Component {
    public let offset: Vector2D

    public init(position: Vector2D) {
        self.offset = position
    }
}
