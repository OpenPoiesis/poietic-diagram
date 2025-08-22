//
//  BezierPath+advanced.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 22/07/2025.
//

extension BezierPath {
    /// Create a curved line through multiple points using Catmull-Rom style interpolation.
    ///
    /// This creates a smooth curve that passes through all the given points by calculating
    /// control points based on the neighboring points, similar to Godot's Curve2D approach.
    ///
    /// - Parameters:
    ///   - points: Array of points to curve through (minimum 2 points required)
    ///   - tension: Controls the curve tension (0.0 = straight lines, 1.0 = maximum curve)
    /// - Returns: A new BezierPath containing the curved line
    ///
    public init(curveThrough points: [Vector2D], tension: Double = 1.0/6.0) {
        self.init()
        guard points.count >= 2 else {
            return
        }
        
        self.move(to: points[0])
        
        guard points.count > 2 else /* == 2 */ {
            // Simple line for two points
            self.addLine(to: points[1])
            return
        }
        
        // For each segment between consecutive points, create a cubic curve
        for i in 0..<(points.count - 1) {
            let current = points[i]
            let next = points[i + 1]
            
            // Calculate control points using Catmull-Rom interpolation principle
            let (outControl, inControl) = calculateControlPoints(
                at: i,
                in: points,
                tension: tension
            )
            
            self.addCurve(to: next, control1: current + outControl, control2: next + inControl)
        }
    }
    public init(polyline points: [Vector2D]) {
        self.init()
        guard let first = points.first else {
            return
        }
        
        self.move(to: first)
        for point in points.dropFirst() {
            self.addLine(to: point)
        }
    }

    /// Create a poly-line from ``start`` to ``end`` that goes through midpoints.
    ///
    /// The poly-line alternates between horizontal and vertical orientation.
    ///
    public init(orthogonalPolylineThrough points: [Vector2D]) {
        self.init()
        guard var current = points.first else {
            return
        }
        var isHorizontal: Bool = true
        move(to: current)
        
        for nextPoint in points.dropFirst() {
            if isHorizontal {
                addLine(to: Vector2D(nextPoint.x, current.y))
                addLine(to: Vector2D(nextPoint.x, nextPoint.y))
            }
            else {
                addLine(to: Vector2D(current.x, nextPoint.y))
                addLine(to: Vector2D(nextPoint.x, nextPoint.y))
                current = nextPoint
            }
            isHorizontal = !isHorizontal
        }
    }

}

/// Calculate control points for a segment using Catmull-Rom style interpolation
///
private func calculateControlPoints(at index: Int,
                                    in points: [Vector2D],
                                    tension: Double) -> (Vector2D, Vector2D) {
    let current = points[index]
    let next = points[index + 1]
    
    // Determine previous point for tangent calculation
    let prev: Vector2D
    if index > 0 {
        // Use the actual previous point
        prev = points[index - 1]
    }
    else {
        // For the first point, extrapolate backwards from the current segment direction
        prev = current - (next - current)
    }
    
    // Determine after point for tangent calculation
    let after: Vector2D
    if index + 2 < points.count {
        // Use the actual point after next
        after = points[index + 2]
    }
    else {
        // For the last segment, extrapolate forwards from the current segment direction
        after = next + (next - current)
    }
    
    // Calculate tangent vectors (similar to Godot's approach)
    let currentTangent = (next - prev) * tension
    let nextTangent = (after - current) * tension
    
    // Out control for current point, in control for next point
    return (currentTangent, -nextTangent)
}

