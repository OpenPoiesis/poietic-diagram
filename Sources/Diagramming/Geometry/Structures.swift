//
//  Geometry.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/06/2025.
//

import Foundation

public typealias Vector2D = SIMD2<Double>

extension Vector2D {
    /// Distance between two points
    public func distance(to other: Vector2D) -> Double {
        let diff = self - other
        return (diff * diff).sum().squareRoot()
    }
    
    /// Length (magnitude) of the vector
    public var length: Double {
        return (self * self).sum().squareRoot()
    }
    
    /// Normalised vector
    public var normalized: Vector2D {
        let len = length
        guard len > 0 else {
            return Vector2D.zero
        }
        return self / len
    }
    
    /// Returns the normal (perpendicular) vector, rotated 90° counterclockwise.
    /// The result is not normalised by default (preserves original length).
    public var normal: Vector2D {
        return Vector2D(-y, x) // Standard 2D normal (⊥)
    }

    /// Returns the normalised (unit-length) perpendicular vector.
    public var normalizedNormal: Vector2D {
        return normal.normalized
    }

    /// Dot product with another vector
    public func dot(_ other: Vector2D) -> Double {
        return (self * other).sum()
    }
    
    /// Linear interpolation between two points
    public func lerp(to other: Vector2D, t: Double) -> Vector2D {
        return self + (other - self) * t
    }
}

/// Structure representing a 2D rectangle.
///
public struct Rect2D {
    public var origin: Vector2D
    public var size: Vector2D
    
    public init(origin: Vector2D = Vector2D.zero, size: Vector2D = Vector2D.zero) {
        self.origin = origin
        self.size = size
    }
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Vector2D(x, y)
        self.size = Vector2D(width, height)
    }
    
    public var center: Vector2D {
        return origin + size / 2.0
    }
    
    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.x }
    public var maxY: Double { origin.y + size.y }
    public var width: Double {size.x }
    public var height: Double { size.y }
    
    public var bottomLeft: Vector2D { origin }
    public var bottomRight: Vector2D { Vector2D(maxX, minY) }
    public var topLeft: Vector2D { Vector2D(minX, maxY) }
    public var topRight: Vector2D { Vector2D(maxX, maxY) }
    
    /// Check if point is inside rectangle.
    public func contains(_ point: Vector2D) -> Bool {
        return point.x >= minX && point.x <= maxX &&
               point.y >= minY && point.y <= maxY
    }
    
    /// Union with another rectangle.
    public func union(_ other: Rect2D) -> Rect2D {
        let newMinX = min(minX, other.minX)
        let newMinY = min(minY, other.minY)
        let newMaxX = max(maxX, other.maxX)
        let newMaxY = max(maxY, other.maxY)
        
        return Rect2D(
            origin: Vector2D(newMinX, newMinY),
            size: Vector2D(newMaxX - newMinX, newMaxY - newMinY)
        )
    }
}


public struct LineSegment {
    public var start: Vector2D
    public var end: Vector2D
    
    /// Creates a line segment between two points
    public init(from start: Vector2D, to end: Vector2D) {
        self.start = start
        self.end = end
    }

    public var length: Double {
        (start - end).length
    }

    ///  Direction Vector.
    ///
    ///  Provides the normalized direction of the line (e.g., for computing normals or aligning objects).
    public var direction: Vector2D {
        return (end - start).normalized
    }

    /// Finds the center of the line segment (e.g., for placing labels or splitting).
    ///
    public var midpoint: Vector2D {
        return (start + end) * 0.5
    }

    /// Normal Vector (Perpendicular)
    ///
    /// Computes a perpendicular vector (e.g., for offsetting lines or computing right-hand-side
    public var normal: Vector2D {
        let dir = direction
        return Vector2D(-dir.y, dir.x)
    }
    public func intersects(_ other: LineSegment) -> Bool {
        let p1 = start
        let p2 = end
        let p3 = other.start
        let p4 = other.end

        let denom = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y)
        guard denom != 0 else { return false } // Parallel or collinear

        let ua = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / denom
        let ub = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / denom

        return (ua >= 0 && ua <= 1) && (ub >= 0 && ub <= 1)
    }

    /// Computes the intersection point between two line segments (if it exists).
    /// Returns `nil` if the segments are parallel, collinear, or do not intersect.
    public func intersection(with other: LineSegment) -> Vector2D? {
        let p1 = self.start
        let p2 = self.end
        let p3 = other.start
        let p4 = other.end

        // Calculate denominator for parametric equations
        let denom = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y)

        // If denominator is zero, lines are parallel or collinear (no unique intersection)
        guard denom != 0 else { return nil }

        // Compute parameters `t` and `u` for the two lines
        let tNumer = (p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)
        let uNumer = (p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)
        let t = tNumer / denom
        let u = uNumer / denom

        // Check if intersection lies within both segments (0 ≤ t ≤ 1, 0 ≤ u ≤ 1)
        guard t >= 0 && t <= 1 && u >= 0 && u <= 1 else { return nil }

        // Return the intersection point
        return Vector2D(
            x: p1.x + t * (p2.x - p1.x),
            y: p1.y + t * (p2.y - p1.y)
        )
    }

    /// Parametric Position (t-value) Along the Line Segment
    ///
    /// Evaluates a point along the line at a given parameter `t ∈ [0, 1]`
    /// (e.g., for interpolation or subdivision).
    ///
    public func point(at t: Double) -> Vector2D {
        let clamped = min(max(t, 0), 1)
        return start.lerp(to: end, t: clamped)
    }

    /// Reversed Line Segment
    ///
    /// Creates a parallel line at a given distance (e.g., for generating outlines or margins).
    public func reversed() -> LineSegment {
        return LineSegment(from: end, to: start)
    }
    
    /// Offset Line Segment (Parallel Shift)
    ///
    /// Creates a parallel line at a given distance (e.g., for generating outlines or margins).
    public func offset(by distance: Double) -> LineSegment {
        let n = normal * distance
        return LineSegment(from: start + n, to: end + n)
    }

    
    /// Computes the angle between two line segments in radians
    public func angle(to other: LineSegment) -> Double {
        let angle1 = atan2(direction.y, direction.x)
        let angle2 = atan2(other.direction.y, other.direction.x)
        return (angle2 - angle1).truncatingRemainder(dividingBy: 2 * .pi)
    }
    
    /// Returns a new line segment extended by a certain distance at both ends
    public func extended(by distance: Double) -> LineSegment {
        let extensionVector = direction * distance
        return LineSegment(from: start - extensionVector, to: end + extensionVector
        )
    }
}
