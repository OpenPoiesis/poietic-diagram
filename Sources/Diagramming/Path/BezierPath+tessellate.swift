//
//  BezierPath+tessellate.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 26/08/2025.
//

extension BezierPath {
    // MARK: - Tessellation
    
    /// Tessellate the path into line segments with adaptive point density
    ///
    /// - Parameters:
    ///   - maxStages: Maximum number of subdivision stages to prevent infinite recursion
    ///   - tolerance: Maximum distance deviation from straight line approximation in coordinate units
    /// - Returns: Array of points representing the tessellated path
    public func tessellate(maxStages: Int = 5, tolerance: Double = 0.5) -> [Vector2D] {
        var points: [Vector2D] = []
        var currentPos: Vector2D?
        var subpathStart: Vector2D?
        
        for element in elements {
            switch element {
            case .moveTo(let point):
                currentPos = point
                subpathStart = point
                points.append(point)
                
            case .lineTo(let point):
                if currentPos != nil {
                    points.append(point)
                    currentPos = point
                }
                
            case .curveTo(let end, let control1, let control2):
                if let current = currentPos {
                    let curvePoints = tessellateCubicCurve(
                        start: current,
                        control1: control1,
                        control2: control2,
                        end: end,
                        maxStages: maxStages,
                        tolerance: tolerance
                    )
                    // Skip the first point as it's the current position
                    if curvePoints.count > 1 {
                        points.append(contentsOf: curvePoints.dropFirst())
                    }
                    currentPos = end
                }
                
            case .quadCurveTo(let control, let end):
                if let current = currentPos {
                    let curvePoints = tessellateQuadraticCurve(
                        start: current,
                        control: control,
                        end: end,
                        maxStages: maxStages,
                        tolerance: tolerance
                    )
                    // Skip the first point as it's the current position
                    if curvePoints.count > 1 {
                        points.append(contentsOf: curvePoints.dropFirst())
                    }
                    currentPos = end
                }
                
            case .closePath:
                // Connect back to start if needed
                if let current = currentPos, let start = subpathStart {
                    if current.distance(to: start) > 1e-6 {
                        points.append(start)
                    }
                    currentPos = start
                }
            }
        }
        
        return points
    }
    
    // MARK: - Private Tessellation Implementation
    
    private func tessellateQuadraticCurve(start: Vector2D,
                                          control: Vector2D,
                                          end: Vector2D,
                                          maxStages: Int,
                                          tolerance: Double) -> [Vector2D] {
        
        var segments = [(start: Vector2D, control: Vector2D, end: Vector2D)]()
        segments.append((start, control, end))
        
        for _ in 0..<maxStages {
            var newSegments: [(start: Vector2D, control: Vector2D, end: Vector2D)] = []
            var needsSubdivision = false
            
            for segment in segments {
                if shouldSubdivideQuadratic(segment, tolerance: tolerance) {
                    let (left, right) = subdivideQuadraticCurve(segment)
                    newSegments.append(left)
                    newSegments.append(right)
                    needsSubdivision = true
                } else {
                    newSegments.append(segment)
                }
            }
            
            segments = newSegments
            if !needsSubdivision {
                break
            }
        }
        
        // Collect all points: start of first segment, then all end points
        var points = [start]
        for segment in segments {
            points.append(segment.end)
        }
        
        return points
    }
    
    private func tessellateCubicCurve(start: Vector2D,
                                      control1: Vector2D,
                                      control2: Vector2D,
                                      end: Vector2D,
                                      maxStages: Int,
                                      tolerance: Double) -> [Vector2D] {
        
        var segments = [(start: Vector2D, control1: Vector2D, control2: Vector2D, end: Vector2D)]()
        segments.append((start, control1, control2, end))
        
        for _ in 0..<maxStages {
            var newSegments: [(start: Vector2D, control1: Vector2D, control2: Vector2D, end: Vector2D)] = []
            var needsSubdivision = false
            
            for segment in segments {
                if shouldSubdivideCubic(segment, tolerance: tolerance) {
                    let (left, right) = subdivideCubicCurve(segment)
                    newSegments.append(left)
                    newSegments.append(right)
                    needsSubdivision = true
                } else {
                    newSegments.append(segment)
                }
            }
            
            segments = newSegments
            if !needsSubdivision {
                break
            }
        }
        
        // Collect all points: start of first segment, then all end points
        var points = [start]
        for segment in segments {
            points.append(segment.end)
        }
        
        return points
    }
    
    private func shouldSubdivideCubic(
        _ segment: (start: Vector2D, control1: Vector2D, control2: Vector2D, end: Vector2D),
        tolerance: Double
    ) -> Bool {
        // Calculate midpoint of curve using De Casteljau's algorithm
        let t = 0.5
        let curveMidpoint = evaluateCubicCurve(
            start: segment.start,
            control1: segment.control1,
            control2: segment.control2,
            end: segment.end,
            t: t
        )
        
        // Calculate midpoint of chord (straight line between endpoints)
        let chordMidpoint = segment.start.lerp(to: segment.end, t: 0.5)
        
        // Measure perpendicular distance from curve to chord
        let deviation = curveMidpoint.distance(to: chordMidpoint)
        
        // Subdivide if the curve deviates more than tolerance from straight line
        return deviation > tolerance
    }
    
    private func subdivideCubicCurve(
        _ segment: (start: Vector2D, control1: Vector2D, control2: Vector2D, end: Vector2D)
    ) -> (left: (start: Vector2D, control1: Vector2D, control2: Vector2D, end: Vector2D),
          right: (start: Vector2D, control1: Vector2D, control2: Vector2D, end: Vector2D)) {
        
        // De Casteljau's algorithm for cubic subdivision at t=0.5
        let p0 = segment.start
        let p1 = segment.control1
        let p2 = segment.control2
        let p3 = segment.end
        
        // First level
        let q0 = p0.lerp(to: p1, t: 0.5)
        let q1 = p1.lerp(to: p2, t: 0.5)
        let q2 = p2.lerp(to: p3, t: 0.5)
        
        // Second level
        let r0 = q0.lerp(to: q1, t: 0.5)
        let r1 = q1.lerp(to: q2, t: 0.5)
        
        // Third level (final subdivision point)
        let s = r0.lerp(to: r1, t: 0.5)
        
        let left = (start: p0, control1: q0, control2: r0, end: s)
        let right = (start: s, control1: r1, control2: q2, end: p3)
        
        return (left, right)
    }
    
    private func evaluateCubicCurve(start: Vector2D,
                                    control1: Vector2D,
                                    control2: Vector2D,
                                    end: Vector2D,
                                    t: Double) -> Vector2D
    {
        let t2 = t * t
        let t3 = t2 * t
        let mt = 1.0 - t
        let mt2 = mt * mt
        let mt3 = mt2 * mt
        
        return start * mt3
                + control1 * (3.0 * mt2 * t)
                + control2 * (3.0 * mt * t2)
                + end * t3
    }
    
    private func shouldSubdivideQuadratic(
        _ segment: (start: Vector2D, control: Vector2D, end: Vector2D),
        tolerance: Double
    ) -> Bool {
        // Calculate midpoint of curve using De Casteljau's algorithm
        let t = 0.5
        let curveMidpoint = evaluateQuadraticCurve(
            start: segment.start,
            control: segment.control,
            end: segment.end,
            t: t
        )
        
        // Calculate midpoint of chord (straight line between endpoints)
        let chordMidpoint = segment.start.lerp(to: segment.end, t: 0.5)
        
        // Measure perpendicular distance from curve to chord
        let deviation = curveMidpoint.distance(to: chordMidpoint)
        
        // Subdivide if the curve deviates more than tolerance from straight line
        return deviation > tolerance
    }
    
    private func subdivideQuadraticCurve(
        _ segment: (start: Vector2D, control: Vector2D, end: Vector2D)
    ) -> (left: (start: Vector2D, control: Vector2D, end: Vector2D),
          right: (start: Vector2D, control: Vector2D, end: Vector2D)) {
        
        // De Casteljau's algorithm for quadratic subdivision at t=0.5
        let p0 = segment.start
        let p1 = segment.control
        let p2 = segment.end
        
        let q0 = p0.lerp(to: p1, t: 0.5)
        let q1 = p1.lerp(to: p2, t: 0.5)
        
        let r = q0.lerp(to: q1, t: 0.5)
        
        let left = (start: p0, control: q0, end: r)
        let right = (start: r, control: q1, end: p2)
        
        return (left, right)
    }
    
    private func evaluateQuadraticCurve(start: Vector2D,
                                        control: Vector2D,
                                        end: Vector2D,
                                        t: Double) -> Vector2D
    {
        let t2 = t * t
        let mt = 1.0 - t
        let mt2 = mt * mt
        
        return start * mt2
                + control * (2.0 * mt * t)
                + end * t2
    }
    

}
