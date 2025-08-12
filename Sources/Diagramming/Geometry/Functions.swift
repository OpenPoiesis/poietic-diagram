//
//  Functions.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

import Foundation

/// Namespace for geometry functions
public enum Geometry {
   
    /// Create a poly-line from ``start`` to ``end`` that goes through midpoints.
    ///
    /// The poly-line alternates between horizontal and vertical orientation.
    ///
    public static func orthogonalPolyline(from start: Vector2D,
                                          to end: Vector2D,
                                          through midpoints: [Vector2D]) -> BezierPath {
        let points = midpoints + [end]
        var isHorizontal: Bool = true
        var current = start
        var path = BezierPath()
        path.move(to: start)
        
        for nextPoint in points {
            if isHorizontal {
                path.addLine(to: Vector2D(nextPoint.x, current.y))
                path.addLine(to: Vector2D(nextPoint.x, nextPoint.y))
            }
            else {
                path.addLine(to: Vector2D(current.x, nextPoint.y))
                path.addLine(to: Vector2D(nextPoint.x, nextPoint.y))
                current = nextPoint
            }
            isHorizontal = !isHorizontal
        }
        
        return path
    }

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
    
    /// Find intersection points of a line segment with a collision shape.
    ///
    public static func rayIntersects(shape: CollisionShape,
                                     from rayOrigin: Vector2D,
                                     direction rayDirection: Vector2D) -> Vector2D? {
        switch shape.shape {
        case .circle(let radius):
            return rayIntersects(circleAt: shape.position, radius: radius,
                                 from: rayOrigin, direction: rayDirection)
            
        case .rectangle(let size):
            let rect = Rect2D(origin: shape.position - size/2, size: size)
            return rayIntersects(rectangle: rect,
                                 from: rayOrigin, direction: rayDirection)
        case .polygon(let points):
            return rayIntersects(polygonPoints: points,
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
    static func rayIntersects(polygonPoints: [Vector2D],
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
    
    public static func rayIntersects(circleAt center: Vector2D,
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
    
    public static func rayIntersects(rectangle rect: Rect2D,
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

}
