//
//  Functions.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

import Foundation

/// Namespace for geometry functions
public enum Geometry {
   
    public static func offsetPolyline(_ points: [Vector2D], offset: Double, joinType: JoinType, miterLimit: Double = 2.0) -> [Vector2D] {
        guard points.count >= 2 else { return [] }
        
        var path: [Vector2D] = []
        let halfOffset = offset / 2.0
        
        // Compute offset segments
        var offsetSegments: [LineSegment] = []
        for i in 0..<points.count - 1 {
            let segment = LineSegment(from: points[i], to: points[i+1])
            offsetSegments.append(segment.offset(by: halfOffset))
        }
        
        path.append(offsetSegments[0].start)
        
        // Process joins between segments
        for i in 0..<offsetSegments.count - 1 {
            let seg1 = offsetSegments[i]
            let seg2 = offsetSegments[i+1]
            let jointPoint = points[i+1] // Original joint point
            
            // Compute intersection of the two offset segments
            if let intersect = seg1.intersection(with: seg2) {
                switch joinType {
                case .miter:
                    let miterLength = intersect.distance(to: jointPoint)
                    if miterLength <= halfOffset * miterLimit {
                        path.append(intersect)
                    }
                    else {
                        // Fallback to bevel if miter is too long
                        path.append(seg1.end)
                        path.append(seg2.start)
                    }
                case .bevel:
                    path.append(seg1.end)
                    path.append(seg2.start)
                case .round:
                    path.append(seg1.end)
                    path += roundJoin(from: seg1.end, to: seg2.start,
                                      around: jointPoint, radius: halfOffset)
                }
            }
            else {
                // Parallel or co-linear segments - just connect them
                path.append(seg1.end)
                path.append(seg2.start)
            }
        }
        
        // Add last segment
        if let lastSegment = offsetSegments.last {
            path.append(lastSegment.end)
        }
        
        return path
    }
    
    // Helper function to add a round join
    private static func roundJoin(from p1: Vector2D,
                                  to p2: Vector2D,
                                  around center: Vector2D,
                                  radius: Double) -> [Vector2D] {
        var path: [Vector2D] = []
        let angle1 = atan2(p1.y - center.y, p1.x - center.x)
        let angle2 = atan2(p2.y - center.y, p2.x - center.x)
        
        var startAngle = angle1
        var endAngle = angle2
        
        // Ensure we go the short way around
        if (endAngle - startAngle).truncatingRemainder(dividingBy: .pi * 2) > .pi {
            if startAngle < endAngle {
                startAngle += .pi * 2
            } else {
                endAngle += .pi * 2
            }
        }
        
        // Number of segments to approximate the arc
        let angleDelta = endAngle - startAngle
        let segments = max(3, Int(abs(angleDelta) / (.pi / 8)) + 1)
        
        for i in 1..<segments {
            let t = Double(i) / Double(segments)
            let angle = startAngle + angleDelta * t
            let point = center + Vector2D(cos(angle), sin(angle)) * radius
            path.append(point)
        }
        
        path.append(p2)
        return path
    }
    
    /// Find the touch point where a ray from an origin point through a shape center
    /// intersects the shape boundary.
    ///
    /// The ray originates at the `from` point and passes through the shape `position` (shape center).
    /// If the origin point is inside the shape, returns the exit point where the ray leaves the shape.
    /// If no intersection is found, returns the shape center as fallback.
    ///
    /// - Parameters:
    ///     - position: shape position
    ///     - from: The origin point of the ray
    ///
    /// - Returns: The touch point on the shape boundary when the ray intersects, or the shape
    ///            center when the ray does not intersect.
    ///
    public static func rayIntersection(shape: ShapeType,
                                       position: Vector2D,
                                       from rayOrigin: Vector2D,
                                       direction rayDirection: Vector2D) -> Vector2D? {
        switch shape {
        case .circle(let radius):
            return rayIntersection(circleAt: position, radius: radius,
                                 from: rayOrigin, direction: rayDirection)
            
        case .rectangle(let size):
            let rect = Rect2D(origin: position - size/2, size: size)
            return rayIntersection(rectangle: rect,
                                 from: rayOrigin, direction: rayDirection)
        case .convexPolygon(let points), .concavePolygon(let points):
            return rayIntersection(polygonPoints: points.map { $0 + position },
                                   from: rayOrigin, direction: rayDirection)
        }
    }

    /// Find intersection points of a line segment with a collision shape.
    ///
    public static func rayIntersection(shape: CollisionShape,
                                       from rayOrigin: Vector2D,
                                       direction rayDirection: Vector2D) -> Vector2D? {
        switch shape.shape {
        case .circle(let radius):
            return rayIntersection(circleAt: shape.position, radius: radius,
                                 from: rayOrigin, direction: rayDirection)
            
        case .rectangle(let size):
            let rect = Rect2D(origin: shape.position - size/2, size: size)
            return rayIntersection(rectangle: rect,
                                 from: rayOrigin, direction: rayDirection)
        case .convexPolygon(let points), .concavePolygon(let points):
            return rayIntersection(polygonPoints: points.map { $0 + shape.position },
                                   from: rayOrigin, direction: rayDirection)
        }
    }
    
    
    /// Find intersection point of a ray with a polygon boundary.
    ///
    /// Tests intersection with polygon edges, returning the closest intersection point.
    /// Uses the LineSegment.intersection(rayFrom:direction:) method for each polygon edge.
    ///
    /// - Parameter polygonPoints: The polygon vertices
    /// - Parameter from: The ray origin point
    /// - Parameter direction: The ray direction vector (does not need to be normalized)
    /// - Returns: The closest intersection point on the polygon boundary, or nil if no intersection found
    ///
    static func rayIntersection(polygonPoints: [Vector2D],
                                from rayOrigin: Vector2D,
                                direction rayDirection: Vector2D) -> Vector2D? {
        guard polygonPoints.count >= 3 else { return nil }
        
        var closestIntersection: Vector2D? = nil
        var closestDistance = Double.infinity
        
        // Test intersection with each polygon edge
        for i in 0..<polygonPoints.count {
            let nextIndex = (i + 1) % polygonPoints.count
            let edge = LineSegment(from: polygonPoints[i], to: polygonPoints[nextIndex])
            
            guard let intersection = edge.intersection(rayFrom: rayOrigin, direction: rayDirection) else {
                continue
            }
            let distance = rayOrigin.distance(to: intersection)
            
            if distance < closestDistance {
                closestIntersection = intersection
                closestDistance = distance
            }
        }
        
        return closestIntersection
    }
    
    public static func rayIntersection(circleAt center: Vector2D,
                                       radius: Double,
                                       from rayOrigin: Vector2D,
                                       direction rayDirection: Vector2D) -> Vector2D? {
        // Check for invalid inputs
        guard radius > 0 else { return nil }
        
        let co = rayOrigin - center
        let a = rayDirection.dot(rayDirection)
        
        // Check for zero direction vector
        guard a > 0 else { return nil }
        
        let b = 2 * rayDirection.dot(co)
        let c = co.dot(co) - radius * radius
        
        let discriminant = b * b - 4 * a * c
        
        // No intersection if discriminant is negative
        guard discriminant >= 0 else {
            return nil
        }
        
        let sqrtDiscriminant = discriminant.squareRoot()
        let denominator = 2 * a
        
        // Compute the two possible t values
        let t1 = (-b - sqrtDiscriminant) / denominator
        let t2 = (-b + sqrtDiscriminant) / denominator
        
        // Determine the smallest positive t (or smallest non-negative for ray starting on boundary)
        let t: Double
        if t1 >= 0 && t2 >= 0 {
            // Both intersections ahead, prefer the one that's not at origin
            let epsilon = 1e-10
            if abs(t1) < epsilon && t2 > epsilon {
                t = t2  // t1 is at ray origin, use t2 
            } else if abs(t2) < epsilon && t1 > epsilon {
                t = t1  // t2 is at ray origin, use t1
            } else {
                t = min(t1, t2)  // Use closest
            }
        } else if t1 >= 0 {
            t = t1
        } else if t2 >= 0 {
            t = t2
        } else {
            // Both intersections are behind the ray origin
            return nil
        }
        
        // Calculate the intersection point
        let intersectionPoint = rayOrigin + t * rayDirection
        return intersectionPoint
    }
    
    public static func rayIntersection(rectangle rect: Rect2D,
                                       from rayOrigin: Vector2D,
                                       direction rayDirection: Vector2D) -> Vector2D? {
        // Check for zero direction vector
        if abs(rayDirection.x) < Double.standardEpsilon && abs(rayDirection.y) < Double.standardEpsilon {
            return nil
        }
        
        // Calculate t values for intersection with x-aligned planes
        var tMin: Double
        var tMax: Double
        
        if abs(rayDirection.x) < Double.standardEpsilon {
            // Ray is parallel to x-aligned planes
            if rayOrigin.x < rect.minX || rayOrigin.x > rect.maxX {
                return nil // Ray misses rectangle entirely
            }
            tMin = -Double.infinity
            tMax = Double.infinity
        } else {
            let invDirX = 1.0 / rayDirection.x
            tMin = (rect.minX - rayOrigin.x) * invDirX
            tMax = (rect.maxX - rayOrigin.x) * invDirX
            
            if invDirX < 0 {
                swap(&tMin, &tMax)
            }
        }
        
        // Calculate t values for intersection with y-aligned planes
        var tyMin: Double
        var tyMax: Double
        
        if abs(rayDirection.y) < Double.standardEpsilon {
            // Ray is parallel to y-aligned planes
            if rayOrigin.y < rect.minY || rayOrigin.y > rect.maxY {
                return nil // Ray misses rectangle entirely
            }
            tyMin = -Double.infinity
            tyMax = Double.infinity
        } else {
            let invDirY = 1.0 / rayDirection.y
            tyMin = (rect.minY - rayOrigin.y) * invDirY
            tyMax = (rect.maxY - rayOrigin.y) * invDirY
            
            if invDirY < 0 {
                swap(&tyMin, &tyMax)
            }
        }
        
        // Find the earliest time where the ray enters and latest time where it exits the rectangle
        let tEnter = max(tMin, tyMin)
        let tExit = min(tMax, tyMax)
        
        // If the ray misses the rectangle entirely or exits before entering
        if tEnter > tExit || tExit < 0 {
            return nil
        }
        
        // If the intersection is behind the ray origin, use tExit instead
        let t = tEnter >= 0 ? tEnter : tExit
        
        // If both intersections are behind the ray origin
        if t < 0 {
            return nil
        }
        
        // Calculate the intersection point
        let intersection = rayOrigin + rayDirection * t
        return intersection
    }
    
    /// Calculate the centroid (arithmetic mean) of a set of points.
    ///
    /// The centroid is the average position of all points, calculated as the sum of all
    /// point coordinates divided by the number of points.
    ///
    /// - Parameter points: Array of 2D points
    /// - Returns: The centroid point, or nil if the array is empty
    ///
    public static func centroid(points: [Vector2D]) -> Vector2D? {
        guard !points.isEmpty else {
            return nil
        }
        
        let sum = points.reduce(Vector2D.zero) { $0 + $1 }
        return sum / Double(points.count)
    }
    
    /// Determines if a polygon defined by the given vertices is convex.
    ///
    /// A polygon is convex if:
    /// 1. It has no self-intersections
    /// 2. All interior angles are less than 180 degrees (consistent winding direction)
    ///
    /// The algorithm works by:
    /// 1. Checking for self-intersections between all non-adjacent edges (O(n²))
    /// 2. Verifying consistent winding direction using cross products (O(n))
    ///    - Computes edge vectors for consecutive vertex pairs
    ///    - Calculates cross products between consecutive edge vectors
    ///    - Ensures all non-zero cross products have the same sign
    ///
    /// Degenerate cases return false:
    /// - Fewer than 3 points (not a polygon)
    /// - All points collinear (degenerate polygon)
    /// - Self-intersecting polygons
    ///
    /// - Parameter points: Array of 2D vertices defining the polygon in order
    /// - Returns: `true` if the polygon is convex, `false` otherwise
    ///
    /// - Complexity: O(n²) where n is the number of vertices, due to self-intersection checks.
    ///   For convex polygons (common case), early termination makes it closer to O(n).
    ///
    /// ## Example
    /// ```swift
    /// let square = [Vector2D(0, 0), Vector2D(1, 0), Vector2D(1, 1), Vector2D(0, 1)]
    /// let isConvex = Geometry.isConvex(points: square) // true
    ///
    /// // Self-intersecting polygon (bowtie shape)
    /// let bowtie = [Vector2D(0, 0), Vector2D(2, 2), Vector2D(0, 2), Vector2D(2, 0)]
    /// let isConvex2 = Geometry.isConvex(points: bowtie) // false
    /// ```
    public static func isConvex(polygon points: [Vector2D]) -> Bool {
        guard points.count >= 3 else {
            return false // A polygon needs at least 3 points
        }
        
        var sign: FloatingPointSign? = nil
        let n = points.count
        var allCollinear = true
        let segments = toSegments(polygon: points)

        // First, check for self-intersections (which make the polygon non-convex)
        for i in 0..<n {
            let seg1 = segments[i]

            // Only check against segments that aren't adjacent
            for j in (i + 2)..<(n + i - 1) {
                let seg2 = segments[j % n]
                
                // Skip segments that share a vertex
                if seg1.start == seg2.start || seg1.start == seg2.end ||
                   seg1.end == seg2.start || seg1.end == seg2.end {
                    continue
                }
                
                if seg1.intersects(seg2) {
                    return false
                }
            }
        }

        
        for i in 0..<n {
            // Get three consecutive vertices (wrapping around)
            let p1 = points[i]
            let p2 = points[(i + 1) % n]
            let p3 = points[(i + 2) % n]
            
            // Compute edge vectors
            let edge1 = p2 - p1
            let edge2 = p3 - p2
            
            // Compute cross product to determine turn direction
            let crossProduct = edge1.cross(edge2)
            
            // Skip near-zero cross products (collinear points)
            if abs(crossProduct) < Double.standardEpsilon {
                continue
            }
            allCollinear = false

            // Check if this is our first non-zero cross product
            if let sign {
                if crossProduct.sign != sign {
                    return false // Found a turn in the opposite direction
                }
            }
            else {
                sign = crossProduct.sign
            }
        }
        // If all points are collinear, the polygon is not convex
        if allCollinear {
            return false
        }
        else {
            return true // All turns were in the same direction
        }
    }
    
    /// Converts a polygon's vertices into an array of connected line segments.
    ///
    /// This method creates line segments between consecutive vertices of the polygon,
    /// including a closing segment between the last vertex and the first vertex to
    /// form a complete closed shape.
    ///
    /// - Parameter points: An array of `Vector2D` points representing the polygon's vertices.
    /// - Returns: An array of `LineSegment` objects representing the polygon's edges.
    ///            Returns an empty array if there are fewer than 2 points.
    ///
    /// ## Complexity
    /// O(n) where n is the number of vertices.
    ///
    /// ## Example
    /// ```swift
    /// let triangle = [
    ///     Vector2D(0, 0),
    ///     Vector2D(1, 0),
    ///     Vector2D(0.5, 1)
    /// ]
    /// let segments = Geometry.toSegments(polygon: triangle)
    /// // Returns 3 segments forming a closed triangle
    /// ```
    ///
    /// ## Notes
    /// - For a valid polygon, the segments will form a continuous closed path.
    /// - The order of segments follows the order of vertices in the input array.
    public static func toSegments(polygon points: [Vector2D]) -> [LineSegment] {
        guard points.count >= 2 else {
            return []
        }
        
        var segments: [LineSegment] = []
        
        // Create segments between consecutive points
        for i in 0..<points.count {
            let nextIndex = (i + 1) % points.count
            segments.append(LineSegment(from: points[i], to: points[nextIndex]))
        }
        
        return segments
    }
    
    
}
