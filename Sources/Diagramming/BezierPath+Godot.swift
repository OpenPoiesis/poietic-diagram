//
//  BezierPath+Godot.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 22/07/2025.
//

/// Represents Godot Curve2D point.
///
/// Members of the structure correspond to the Curve2D function
/// `add_point(position: Vector2, in: Vector2 = Vector2(0, 0), out: Vector2 = Vector2(0, 0))`
///
public struct GodotCurvePoint {
    public let position: Vector2D
    public let inControl: Vector2D
    public let outControl: Vector2D
    
    public init(_ position: Vector2D, in inControl: Vector2D, out outControl: Vector2D) {
        self.position = position
        self.inControl = inControl
        self.outControl = outControl
    }
}

extension BezierPath {
    /// Convert bezier path to a collection of bezier curves as used by Godot game engine.
    ///
    /// Godot curve is specified by position, in-control point and out-control point where the
    /// control points are relative to the curve point position.
    ///
    /// Move-to path elements break the path into multiple curves.
    ///
    public func godotCurves() -> [[GodotCurvePoint]] {
        var curves: [[GodotCurvePoint]] = []
        var points: [GodotCurvePoint] = []
        var position: Vector2D = .zero
        
        for element in elements {
            switch element {
            case .moveTo(let point):
                if !points.isEmpty {
                    curves.append(points)
                    points.removeAll()
                }
                points.append(GodotCurvePoint(point, in: .zero, out: .zero))
                position = point

            case .lineTo(let endPoint):
                points.append(GodotCurvePoint(endPoint, in: .zero, out: .zero))
                position = endPoint
                
            case .curveTo(let endPoint, let control1, let control2):
                if let lastPoint = points.popLast() {
                    points.append(GodotCurvePoint(lastPoint.position,
                                                 in: lastPoint.inControl,
                                                 out: control1 - lastPoint.position))
                }
                points.append(GodotCurvePoint(endPoint, in: control2 - endPoint, out: .zero))
                position = endPoint
                
            case .quadCurveTo(let control, let endPoint):
                // Convert quadratic to cubic by duplicating the control point
                // For quadratic Bezier, the control point affects both in and out
                let startPoint = position
                
                // Convert quadratic control to cubic controls
                // Quadratic: P(t) = (1-t)²P₀ + 2t(1-t)P₁ + t²P₂
                // Cubic equivalent: control1 = P₀ + ⅔(P₁ - P₀), control2 = P₂ + ⅔(P₁ - P₂)
                let control1 = startPoint + (control - startPoint) * (2.0/3.0)
                let control2 = endPoint + (control - endPoint) * (2.0/3.0)
                
                // Update the out-control of the last point
                if let lastPoint = points.popLast() {
                    points.append(GodotCurvePoint(lastPoint.position,
                                                 in: lastPoint.inControl,
                                                 out: control1 - lastPoint.position))
                }
                points.append(GodotCurvePoint( endPoint, in: control2 - endPoint, out: Vector2D()))
                position = endPoint
                
            case .closePath:
                // The path should naturally close, no additional points needed
                // Godot handles this automatically when the curve loops back
                break
            }
        }
        
        if !points.isEmpty {
            curves.append(points)
        }
        
        return curves
    }
}
