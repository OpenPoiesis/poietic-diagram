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
    /// Returns all intersection points where the line segment crosses the boundary of the shape.
    /// The shape is positioned at the given shapePosition offset.
    ///
    /// - Parameter segment: The line segment to test for intersections
    /// - Parameter shape: The collision shape to intersect with
    /// - Parameter shapePosition: The position offset of the shape
    /// - Returns: Array of intersection points, empty if no intersections found
    ///
    public static func intersectLineWithShape(segment: LineSegment,
                                              shape: CollisionShape,
                                              shapePosition: Vector2D
    ) -> [Vector2D] {
        switch shape {
        case .circle(let radius):
            return intersectLineWithCircle(segment: segment, center: shapePosition, radius: radius)
        
        case .ellipse(let rx, let ry):
            // For now, approximate ellipse with circle using average radius
            let avgRadius = (rx + ry) / 2
            return intersectLineWithCircle(segment: segment, center: shapePosition, radius: avgRadius)
        
        case .rectangle(let size):
            return intersectLineWithRectangle(segment: segment, 
                                              center: shapePosition, 
                                              size: size)
        
        case .polygon(let points):
            return intersectLineWithPolygon(segment: segment, 
                                            polygonPoints: points.map { $0 + shapePosition })
        }
    }
    
    /// Find intersection points of a line segment with a circle.
    ///
    /// - Parameter segment: The line segment to test
    /// - Parameter center: The center point of the circle  
    /// - Parameter radius: The radius of the circle
    /// - Returns: Array of intersection points (0, 1, or 2 points)
    ///
    private static func intersectLineWithCircle(segment: LineSegment, 
                                                center: Vector2D, 
                                                radius: Double) -> [Vector2D] {
        let d = segment.end - segment.start
        let f = segment.start - center
        
        let a = d.dot(d)
        let b = 2 * f.dot(d)
        let c = f.dot(f) - radius * radius
        
        let discriminant = b * b - 4 * a * c
        
        guard discriminant >= 0 else { return [] }
        
        let sqrtDiscriminant = discriminant.squareRoot()
        let t1 = (-b - sqrtDiscriminant) / (2 * a)
        let t2 = (-b + sqrtDiscriminant) / (2 * a)
        
        var intersections: [Vector2D] = []
        
        if t1 >= 0 && t1 <= 1 {
            intersections.append(segment.point(at: t1))
        }
        
        if t2 >= 0 && t2 <= 1 && abs(t2 - t1) > 1e-10 {
            intersections.append(segment.point(at: t2))
        }
        
        return intersections
    }
    
    /// Find intersection points of a line segment with a rectangle.
    ///
    /// - Parameter segment: The line segment to test
    /// - Parameter center: The center point of the rectangle
    /// - Parameter size: The size (width, height) of the rectangle
    /// - Returns: Array of intersection points
    ///
    private static func intersectLineWithRectangle(segment: LineSegment,
                                                   center: Vector2D,
                                                   size: Vector2D) -> [Vector2D] {
        var intersections: [Vector2D] = []
        
        let halfSize = size / 2
        let minCorn = center - halfSize
        let maxCorn = center + halfSize

        let bottom = LineSegment(fromX: minCorn.x, fromY: minCorn.y, toX: maxCorn.x, toY: minCorn.y)
        let right = LineSegment(fromX: maxCorn.x, fromY: minCorn.y, toX: maxCorn.x, toY: maxCorn.y)
        let top = LineSegment(fromX: maxCorn.x, fromY: maxCorn.y, toX: minCorn.x, toY: maxCorn.y)
        let left = LineSegment(fromX: minCorn.x, fromY: maxCorn.y, toX: minCorn.x, toY: minCorn.y)

        if let point = segment.intersection(with: bottom) {
            intersections.append(point)
        }
        if let point = segment.intersection(with: right) {
            intersections.append(point)
        }
        if let point = segment.intersection(with: top) {
            intersections.append(point)
        }
        if let point = segment.intersection(with: left) {
            intersections.append(point)
        }

        return intersections
    }
    
    /// Find intersection points of a line segment with a polygon.
    ///
    /// - Parameter segment: The line segment to test
    /// - Parameter polygonPoints: The vertices of the polygon (already positioned)
    /// - Returns: Array of intersection points
    ///
    private static func intersectLineWithPolygon(segment: LineSegment,
                                                 polygonPoints: [Vector2D]) -> [Vector2D] {
        guard polygonPoints.count >= 3 else { return [] }
        
        var intersections: [Vector2D] = []
        
        for i in 0..<polygonPoints.count {
            let nextIndex = (i + 1) % polygonPoints.count
            let edge = LineSegment(from: polygonPoints[i], to: polygonPoints[nextIndex])
            
            if let intersection = segment.intersection(with: edge) {
                intersections.append(intersection)
            }
        }
        
        return intersections
    }
    
    /// Find the touch point where a ray from an origin point through a shape center intersects the shape boundary.
    ///
    /// The ray originates at the `from` point and passes through the `shapePosition` (shape center).
    /// If the origin point is inside the shape, returns the exit point where the ray leaves the shape.
    /// If no intersection is found, returns the shape center as fallback.
    ///
    /// - Parameter from: The origin point of the ray
    /// - Parameter shape: The collision shape to find touch point on
    /// - Parameter shapePosition: The center position of the shape (ray passes through this point)
    /// - Returns: The touch point on the shape boundary
    ///
    public static func shapeTouchPoint(from: Vector2D,
                                       shape: CollisionShape,  
                                       shapePosition: Vector2D) -> Vector2D {
        switch shape {
        case .circle(let radius):
            return touchPointCircle(from: from, center: shapePosition, radius: radius)
            
        case .ellipse(let rx, let ry):
            return touchPointEllipse(from: from, center: shapePosition, rx: rx, ry: ry)
            
        case .rectangle(let size):
            return touchPointRectangle(from: from, center: shapePosition, size: size)
            
        case .polygon(let points):
            return touchPointPolygon(from: from, center: shapePosition, points: points)
        }
    }
    
    /// Find touch point on a circle boundary.
    ///
    /// Uses direct geometric calculation - much more efficient than quadratic formula approach.
    ///
    /// - Parameter from: The ray origin point  
    /// - Parameter center: The center of the circle
    /// - Parameter radius: The radius of the circle
    /// - Returns: The touch point on the circle boundary
    ///
    private static func touchPointCircle(from: Vector2D, 
                                         center: Vector2D, 
                                         radius: Double) -> Vector2D {
        let direction = -(center - from).normalized
        return center + direction * radius
    }
    
    /// Find touch point on an ellipse boundary.
    ///
    /// Uses parametric ellipse equation to find intersection with ray from origin through center.
    ///
    /// - Parameter from: The ray origin point
    /// - Parameter center: The center of the ellipse
    /// - Parameter rx: The x-radius (horizontal radius) of the ellipse
    /// - Parameter ry: The y-radius (vertical radius) of the ellipse
    /// - Returns: The touch point on the ellipse boundary
    ///
    private static func touchPointEllipse(from: Vector2D,
                                          center: Vector2D,
                                          rx: Double,
                                          ry: Double) -> Vector2D {
        let direction = -(center - from).normalized
        
        // For an ellipse centered at origin with equation x²/rx² + y²/ry² = 1
        // and a ray in direction (dx, dy), the intersection point is:
        // t = 1 / sqrt((dx/rx)² + (dy/ry)²)
        // where t is the parameter along the direction vector
        
        let dx = direction.x
        let dy = direction.y
        
        let t = 1.0 / sqrt((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry))
        
        return center + direction * t
    }
    
    /// Find touch point on a rectangle boundary.
    ///
    /// Determines which edge the ray hits based on direction and calculates intersection directly.
    ///
    /// - Parameter from: The ray origin point
    /// - Parameter center: The center of the rectangle  
    /// - Parameter size: The size (width, height) of the rectangle
    /// - Returns: The touch point on the rectangle boundary
    ///
    private static func touchPointRectangle(from: Vector2D,
                                            center: Vector2D,
                                            size: Vector2D) -> Vector2D {
        let direction = (from - center).normalized
        let halfSize = size / 2
        
        // Calculate t values for intersection with each axis-aligned boundary
        let tX: Double
        if direction.x != 0 {
            switch direction.x.sign {
            case .plus: tX = halfSize.x / direction.x
            case .minus: tX = -halfSize.x / direction.x
            }
        } else {
            tX = Double.infinity
        }
        
        let tY: Double
        if direction.y != 0 {
            switch direction.y.sign {
            case .plus: tY = halfSize.y / direction.y
            case .minus: tY = -halfSize.y / direction.y
            }
        } else {
            tY = Double.infinity
        }
        
        // Use the smaller t value (closer intersection)
        let t = min(abs(tX), abs(tY))
        
        if abs(tX) < abs(tY) {
            // Hit vertical edge (left or right)
            let edgeX: Double
            if direction.x > 0 {
                edgeX = center.x + halfSize.x
            } else {
                edgeX = center.x - halfSize.x
            }
            return Vector2D(edgeX, center.y + direction.y * t)
        } else {
            // Hit horizontal edge (top or bottom)
            let edgeY: Double
            if direction.y > 0 {
                edgeY = center.y + halfSize.y
            } else {
                edgeY = center.y - halfSize.y
            }
            return Vector2D(center.x + direction.x * t, edgeY)
        }
    }
    
    /// Find touch point on a polygon boundary.
    ///
    /// Tests intersection with polygon edges, returning the first exit point found.
    ///
    /// - Parameter from: The ray origin point
    /// - Parameter center: The center of the polygon (for positioning)
    /// - Parameter points: The polygon vertices (relative to center)
    /// - Returns: The touch point on the polygon boundary
    ///
    private static func touchPointPolygon(from: Vector2D,
                                          center: Vector2D, 
                                          points: [Vector2D]) -> Vector2D {
        guard points.count >= 3 else { return center }
        
        // Position polygon points in world space
        let worldPoints = points.map { $0 + center }
        
        // Create ray as a very long line segment
        let rayDirection = (center - from).normalized
        let rayEnd = center + rayDirection * 10000 // Arbitrarily long ray
        let ray = LineSegment(from: from, to: rayEnd)
        
        var closestIntersection: Vector2D?
        var closestDistance = Double.infinity
        
        // Test intersection with each polygon edge
        for i in 0..<worldPoints.count {
            let nextIndex = (i + 1) % worldPoints.count
            let edge = LineSegment(from: worldPoints[i], to: worldPoints[nextIndex])
            
            if let intersection = ray.intersection(with: edge) {
                let distance = from.distance(to: intersection)
                
                // Only consider intersections that are beyond the center (exit points)
                let distanceToCenter = from.distance(to: center)
                if distance >= distanceToCenter && distance < closestDistance {
                    closestIntersection = intersection
                    closestDistance = distance
                }
            }
        }
        
        return closestIntersection ?? center
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
