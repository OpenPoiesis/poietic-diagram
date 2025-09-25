//
//  BezierPath+inflate.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 26/08/2025.
//

import Foundation

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
            return inflateClosedPolygon(points, margin: margin, joinType: joinType)
        } else {
            return inflateOpenPath(points, margin: margin, joinType: joinType)
        }
    }
    
    private func inflateClosedPolygon(_ points: [Vector2D], margin: Double, joinType: JoinType) -> BezierPath {
        // Use the existing offsetPolyline method from Geometry
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
    
    private func inflateOpenPath(_ points: [Vector2D], margin: Double, joinType: JoinType) -> BezierPath {
        guard points.count >= 2 else { return BezierPath() }
        
        // Create offset lines on both sides
        let positiveOffset = Geometry.offsetPolyline(points, offset: margin, joinType: joinType)
        let negativeOffset = Geometry.offsetPolyline(points.reversed(), offset: margin, joinType: joinType).reversed()
        
        var result = BezierPath()
        
        // Start at first point of positive offset
        if let firstPoint = positiveOffset.first {
            result.move(to: firstPoint)
        }
        
        // Add positive offset line
        for i in 1..<positiveOffset.count {
            result.addLine(to: positiveOffset[i])
        }
        
        // Add rounded end cap
        if let lastPositive = positiveOffset.last, let lastNegative = negativeOffset.last {
            addRoundedCap(to: &result, from: lastPositive, to: lastNegative, center: points.last!, radius: margin)
        }
        
        // Add negative offset line (reversed)
        for point in negativeOffset.reversed() {
            result.addLine(to: point)
        }
        
        // Add rounded start cap
        if let firstNegative = negativeOffset.first, let firstPositive = positiveOffset.first {
            addRoundedCap(to: &result, from: firstNegative, to: firstPositive, center: points.first!, radius: margin)
        }
        
        result.closeSubpath()
        return result
    }
    
    private func addRoundedCap(to path: inout BezierPath, from startPoint: Vector2D, to endPoint: Vector2D, center: Vector2D, radius: Double) {
        // Calculate the arc to connect the two offset points around the center
        let startAngle = atan2(startPoint.y - center.y, startPoint.x - center.x)
        let endAngle = atan2(endPoint.y - center.y, endPoint.x - center.x)
        
        // Ensure we take the shorter arc (semicircle)
        var angleDelta = endAngle - startAngle
        if angleDelta > .pi {
            angleDelta -= 2 * .pi
        } else if angleDelta < -.pi {
            angleDelta += 2 * .pi
        }
        
        // Use proper Bezier curve approximation for the arc
        addArc(to: &path, center: center, radius: radius, startAngle: startAngle, endAngle: endAngle)
    }
    
    // TODO: Move to BezierPath + document
    private func addArc(to path: inout BezierPath, center: Vector2D, radius: Double, startAngle: Double, endAngle: Double) {
        let angleDelta = endAngle - startAngle
        let segments = max(1, Int(abs(angleDelta) / (.pi / 2)) + 1)
        
        for i in 0..<segments {
            let t1 = Double(i) / Double(segments)
            let t2 = Double(i + 1) / Double(segments)
            
            let angle1 = startAngle + angleDelta * t1
            let angle2 = startAngle + angleDelta * t2
            
            let p1 = center + Vector2D(cos(angle1), sin(angle1)) * radius
            let p2 = center + Vector2D(cos(angle2), sin(angle2)) * radius
            
            // Calculate control points for Bezier approximation of arc segment
            let segmentAngle = angleDelta / Double(segments)
            let alpha = 4.0 / 3.0 * tan(segmentAngle / 4.0)
            let control1 = p1 + Vector2D(-sin(angle1), cos(angle1)) * alpha * radius
            let control2 = p2 + Vector2D(sin(angle2), -cos(angle2)) * alpha * radius
            
            if i == 0 {
                // First segment - line to start point if not already there
                let currentPos = path.currentPoint ?? Vector2D.zero
                if currentPos.distance(to: p1) > 1e-6 {
                    path.addLine(to: p1)
                }
            }
            path.addCurve(to: p2, control1: control1, control2: control2)
        }
    }
}
