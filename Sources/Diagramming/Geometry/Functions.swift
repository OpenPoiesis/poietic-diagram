//
//  Functions.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

import Foundation

/// Namespace for geometry functions
enum Geometry {
   
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
}
