//
//  BezierPath+inflate.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 26/08/2025.
//

import Foundation

// TODO: This extension was created with assistance of a LLM. Needs attention of a human knowledgeable of geometry.
// TODO: I am slowly giving this attention. Needs more.

extension BezierPath {
    /// Creates a new path that is inflated by the specified margin, creating a rounded outline.
    ///
    /// This method handles multiple subpaths independently and uses proper geometric
    /// algorithms to create smooth rounded corners with Bezier curve approximations.
    ///
    /// - Parameters:
    ///   - margin: The distance to inflate the path outward (must be positive)
    ///   - tolerance: Tessellation tolerance for curved paths (smaller = higher quality)
    ///   - joinType: Type of join to use at corners (.round, .miter, .bevel)
    /// - Returns: A new Bezier path representing the inflated outline
    ///
    /// ## Example
    /// ```swift
    /// let originalPath = BezierPath(rect: Rect2D(x: 0, y: 0, width: 100, height: 50))
    /// let outlinePath = originalPath.inflated(by: 5.0, tolerance: 0.5)
    /// // outlinePath is now a rounded rectangle 5 points larger on all sides
    /// ```
    public func inflated(by margin: Double, tolerance: Double = 0.5, joinType: JoinType = .round) -> BezierPath {
        guard margin > 0 else { return self }
        
        // Handle multiple subpaths independently
        let subpaths = self.subpaths()
        var result = BezierPath()
        
        for subpath in subpaths {
            let inflatedSubpath = inflateSubpath(subpath, margin: margin, tolerance: tolerance, joinType: joinType)
            result.addPath(inflatedSubpath)
        }
        
        return result
    }
    
    // MARK: - Private Implementation
    
    private func inflateSubpath(_ subpath: BezierPath, margin: Double, tolerance: Double, joinType: JoinType) -> BezierPath {
        // Get polygon points from subpath
        let points: [Vector2D]
        
        if let polygonPoints = subpath.asStrictPolygon() {
            // Use exact polygon points for straight-line paths
            points = polygonPoints
        } else {
            // Tessellate curved paths with specified tolerance
            points = subpath.tessellate(tolerance: tolerance)
        }
        
        guard points.count >= 3 else { return subpath }
        
        // Check if path is closed (either explicitly or by having same start/end points)
        let isClosed = subpath.isClosed || (points.first?.distance(to: points.last!) ?? Double.infinity) < 1e-6
        
        if isClosed {
            return Geometry.inflateClosedPolygon(points, margin: margin, joinType: joinType)
        } else {
            return Geometry.inflateOpenPath(points, margin: margin, joinType: joinType)
        }
    }
}

extension Geometry {
    // TODO: Consider making public
    static func inflateClosedPolygon(_ points: [Vector2D], margin: Double, joinType: JoinType) -> BezierPath {
        let offsetPoints = Geometry.offsetPolyline(points, offset: margin * 2, joinType: joinType)
        
        guard !offsetPoints.isEmpty else { return BezierPath() }
        
        var result = BezierPath()
        result.move(to: offsetPoints[0])
        
        for i in 1..<offsetPoints.count {
            result.addLine(to: offsetPoints[i])
        }
        
        result.closeSubpath()
        return result
    }
    
    // TODO: Consider making public
    static func inflateOpenPath(_ points: [Vector2D], margin: Double, joinType: JoinType) -> BezierPath {
        guard points.count >= 2 else { return BezierPath() }
        
        // Create offset lines on both sides
        let positiveOffset = Geometry.offsetPolyline(points, offset: margin, joinType: joinType)
        let negativeOffset = Geometry.offsetPolyline(points.reversed(), offset: margin, joinType: joinType).reversed()
        
        var result = BezierPath()
        
        if let firstPoint = positiveOffset.first {
            result.move(to: firstPoint)
        }
        
        // Positive offset line
        for i in 1..<positiveOffset.count {
            result.addLine(to: positiveOffset[i])
        }
        
        // Add end cap
        if let lastPoint = points.last, points.count >= 2 {
            let previous = points[points.count - 2]
            let direction = (lastPoint - previous).normalized
            
            // Perpendicular vector (rotated 90° counter-clockwise)
            let perpendicular = Vector2D(-direction.y, direction.x)
            
            // The two cap endpoints
            let positiveCapPoint = lastPoint + perpendicular * margin  // Connects to positive offset
            let negativeCapPoint = lastPoint - perpendicular * margin  // Connects to negative offset
            
            // Calculate angles
            let startAngle = atan2(positiveCapPoint.y - lastPoint.y, positiveCapPoint.x - lastPoint.x)
            let endAngle = atan2(negativeCapPoint.y - lastPoint.y, negativeCapPoint.x - lastPoint.x)
            
            // Use cross product to determine which side is "outside"
            // Cross product of direction and perpendicular tells us orientation
            // If cross > 0, perpendicular is to the left of direction, etc.
            // The cap should go around the side opposite to the direction
            // This determines clockwise vs counter-clockwise
            let clockwise = direction.cross(perpendicular) > 0
            
            result.addArc(center: lastPoint, radius: margin,
                         startAngle: startAngle, endAngle: endAngle,
                         clockwise: clockwise)
        }
        
        // Negative offset line (reversed)
        for point in negativeOffset.reversed() {
            result.addLine(to: point)
        }
        
        // Add start cap
        if let firstPoint = points.first, points.count >= 2 {
            let next = points[1]
            let direction = (next - firstPoint).normalized
            
            let perpendicular = Vector2D(-direction.y, direction.x)
            
            // At the start, we go from negative to positive to maintain orientation
            let positiveCapPoint = firstPoint + perpendicular * margin
            let negativeCapPoint = firstPoint - perpendicular * margin
            
            let startAngle = atan2(negativeCapPoint.y - firstPoint.y, negativeCapPoint.x - firstPoint.x)
            let endAngle = atan2(positiveCapPoint.y - firstPoint.y, positiveCapPoint.x - firstPoint.x)
            
            // At the start, the "outside" is the opposite of the end
            // So we flip the clockwise flag
            let clockwise = direction.cross(perpendicular) > 0
            
            result.addArc(center: firstPoint, radius: margin,
                         startAngle: startAngle, endAngle: endAngle,
                         clockwise: clockwise)
        }
        
        result.closeSubpath()
        return result
    }
}

