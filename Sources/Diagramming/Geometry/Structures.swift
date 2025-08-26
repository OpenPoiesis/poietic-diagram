//
//  Geometry.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/06/2025.
//

import Foundation

extension Double {
    /// Epsilon for double precision floating point according to IEEE 754 - 2008.
    public static let standardEpsilon = 2.22e-16
}

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
    
    public func cross(_ other: Vector2D) -> Double {
        (self.x * other.y) - (y * other.x)
    }
    public var prettyDescription: String {
        "(\(self.x), \(self.y))"
    }
}

/// A 2D rectangle represented by an origin point and size dimensions.
///
/// `Rect2D` provides a comprehensive set of operations for working with 2D rectangular regions,
/// including containment testing, union operations, and coordinate access. The rectangle is
/// defined using an origin point (bottom-left corner) and size vector (width, height).
///
/// The rectangle uses a standard 2D coordinate system where:
/// - Origin represents the bottom-left corner
/// - Positive x extends to the right
/// - Positive y extends upward
/// - Size components represent width (x) and height (y)
///
/// Usage example:
///
/// ```swift
/// let rect = Rect2D(x: 10, y: 20, width: 100, height: 50)
/// let center = rect.center  // Vector2D(60, 45)
/// let contains = rect.contains(Vector2D(50, 30))  // true
/// ```
///
public struct Rect2D: Equatable, Sendable, Codable {
    /// The bottom-left corner position of the rectangle.
    public var origin: Vector2D
    
    /// The width and height dimensions of the rectangle as a vector (width=x, height=y).
    public var size: Vector2D
    
    public init(origin: Vector2D = Vector2D.zero, size: Vector2D = Vector2D.zero) {
        self.origin = origin
        self.size = size
    }
    
    public init(center: Vector2D, size: Vector2D) {
        self.origin = center - size / 2
        self.size = size
    }
    
    /// Creates a rectangle with explicit x, y coordinates and width, height dimensions.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the bottom-left corner
    ///   - y: The y-coordinate of the bottom-left corner
    ///   - width: The width of the rectangle
    ///   - height: The height of the rectangle
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Vector2D(x, y)
        self.size = Vector2D(width, height)
    }
    
    /// The center point of the rectangle.
    public var center: Vector2D {
        return origin + size / 2.0
    }
    
    /// The minimum x-coordinate (left edge) of the rectangle.
    public var minX: Double { origin.x }
    
    /// The minimum y-coordinate (bottom edge) of the rectangle.
    public var minY: Double { origin.y }
    
    /// The maximum x-coordinate (right edge) of the rectangle.
    public var maxX: Double { origin.x + size.x }
    
    /// The maximum y-coordinate (top edge) of the rectangle.
    public var maxY: Double { origin.y + size.y }
    
    /// The width of the rectangle (equivalent to size.x).
    public var width: Double {size.x }
    
    /// The height of the rectangle (equivalent to size.y).
    public var height: Double { size.y }
    
    /// The bottom-left corner of the rectangle (same as origin).
    public var bottomLeft: Vector2D { origin }
    
    /// The bottom-right corner of the rectangle.
    public var bottomRight: Vector2D { Vector2D(maxX, minY) }
    
    /// The top-left corner of the rectangle.
    public var topLeft: Vector2D { Vector2D(minX, maxY) }
    
    /// The top-right corner of the rectangle.
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
    
    /// Returns a new rectangle translated by the given offset vector.
    ///
    /// - Parameter offset: The vector by which to translate the rectangle
    /// - Returns: A new rectangle with the same size but moved by the offset
    public func translated(_ offset: Vector2D) -> Rect2D {
        return Rect2D(origin: origin + offset, size: self.size)
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        
        self.origin = Vector2D(x, y)
        self.size = Vector2D(width, height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.x, forKey: .width)
        try container.encode(size.y, forKey: .height)
    }
}


/// A line segment defined by two endpoints in 2D space.
///
/// `LineSegment` provides a comprehensive set of geometric operations for working with straight
/// line segments, including intersection testing, geometric calculations, and transformations.
/// The segment is defined by its start and end points, with various computed properties for
/// common geometric operations.
///
/// ## Usage Example
/// ```swift
/// let segment = LineSegment(from: Vector2D(0, 0), to: Vector2D(10, 10))
/// let length = segment.length           // 14.14...
/// let midpoint = segment.midpoint       // Vector2D(5, 5)
/// let direction = segment.direction     // Vector2D(0.707, 0.707)
/// ```
///
/// ## Key Features
/// - Length and direction calculations
/// - Midpoint and parametric point evaluation
/// - Line-line and line-ray intersection testing
/// - Parallel offset and extension operations
/// - Normal vector computation for perpendicular operations
///
/// ## Geometric Operations
/// The structure supports various geometric transformations including:
/// - Intersection with other line segments or rays
/// - Parallel offset for creating margins or outlines
/// - Extension beyond endpoints
/// - Angle calculations between segments
///
public struct LineSegment: Equatable, Sendable {
    /// The starting point of the line segment.
    public var start: Vector2D
    
    /// The ending point of the line segment.
    public var end: Vector2D
    
    /// Creates a line segment between two points
    public init(from start: Vector2D, to end: Vector2D) {
        self.start = start
        self.end = end
    }

    /// Creates a line segment using individual coordinate components.
    ///
    /// - Parameters:
    ///   - fromX: The x-coordinate of the start point
    ///   - fromY: The y-coordinate of the start point
    ///   - toX: The x-coordinate of the end point
    ///   - toY: The y-coordinate of the end point
    public init(fromX: Vector2D.Scalar, fromY: Vector2D.Scalar,
                toX: Vector2D.Scalar, toY: Vector2D.Scalar) {
        self.start = Vector2D(fromX, fromY)
        self.end = Vector2D(toX, toY)
    }
    
    /// The Euclidean length of the line segment.
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
        return (start + end) / 2
    }

    /// Normal Vector (Perpendicular)
    ///
    /// Computes a perpendicular vector (e.g., for offsetting lines or computing right-hand-side
    public var normal: Vector2D {
        let dir = direction
        return Vector2D(-dir.y, dir.x)
    }
    /// Determines if this line segment intersects with another line segment.
    ///
    /// - Parameter other: The other line segment to test intersection with
    /// - Returns: `true` if the segments intersect, `false` if they are parallel, collinear, or do not intersect
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
    
    /// Computes the intersection point between this line segment and a ray.
    ///
    /// - Parameters:
    ///   - rayFrom: The starting point of the ray
    ///   - rayDirection: The direction vector of the ray (does not need to be normalized)
    /// - Returns: The intersection point if it exists, or `nil` if there is no intersection
    public func intersection(rayFrom: Vector2D, direction rayDirection: Vector2D) -> Vector2D? {
        // Use the standard line-line intersection algorithm
        // Ray: P1 + t * D1 where P1 = rayFrom, D1 = rayDirection, t >= 0
        // Segment: P2 + s * D2 where P2 = start, D2 = end - start, 0 <= s <= 1
        
        let p1 = rayFrom
        let d1 = rayDirection
        let p2 = start
        let d2 = end - start
        
        // Check if ray and segment are parallel using cross product
        let denominator = d1.cross(d2)
        guard abs(denominator) >= Double.standardEpsilon else {
            return nil // Parallel lines
        }
        
        // Solve for parameters using cross products
        let dp = p2 - p1
        let t = dp.cross(d2) / denominator  // Parameter for ray
        let s = dp.cross(d1) / denominator  // Parameter for segment
        
        // Check constraints: ray forward (t >= 0), segment within bounds (0 <= s <= 1)
        guard t >= 0.0 && s >= 0.0 && s <= 1.0 else {
            return nil
        }
        
        // Return intersection point
        return p1 + t * d1
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

    /// Returns a new line segment with start and end points swapped.
    ///
    /// This creates a line segment with the same geometry but opposite direction.
    ///
    /// - Returns: A new line segment from the original end point to the original start point
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
    
    /// Computes the shortest distance from a point to this line segment.
    ///
    /// The distance is measured perpendicularly from the point to the line segment.
    /// If the perpendicular from the point doesn't intersect the segment within its bounds,
    /// the distance to the nearest endpoint is returned instead.
    ///
    /// - Parameter point: The point to measure distance from
    /// - Returns: The shortest distance from the point to the line segment
    public func distanceToPoint(_ point: Vector2D) -> Double {
        let segmentVector = end - start
        let toPointVector = point - start
        
        // If segment has zero length, return distance to start point
        let segmentLengthSquared = segmentVector.dot(segmentVector)
        guard segmentLengthSquared > Double.standardEpsilon else {
            return start.distance(to: point)
        }
        
        // Calculate projection parameter t
        let t = toPointVector.dot(segmentVector) / segmentLengthSquared
        
        // Clamp t to [0, 1] to stay within segment bounds
        let clampedT = max(0, min(1, t))
        
        // Find closest point on segment
        let closestPoint = start + clampedT * segmentVector
        
        // Return distance to closest point
        return point.distance(to: closestPoint)
    }
}
