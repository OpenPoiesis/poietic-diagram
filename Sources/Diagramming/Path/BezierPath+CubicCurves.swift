//
//  BezierPath+CubicCurves.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 22/07/2025.
//

/// Represents a cubic Bezier curve control point.
///
/// Contains the position and relative control points for creating smooth cubic Bezier curves.
/// The control points are relative to the position (not absolute coordinates).
///
/// - SeeAlso: ``BezierPath/toCubicCurves()``
/// 
public struct CubicCurvePoint {
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
    /// Convert bezier path to a collection of cubic bezier curves.
    ///
    /// Each curve is specified by position, in-control point and out-control point where the
    /// control points are relative to the curve point position.
    ///
    /// Move-to path elements break the path into multiple curves.
    ///
    /// Example use-case is Godot Curve2D.
    ///
    public func toCubicCurves() -> [[CubicCurvePoint]] {
        var curves: [[CubicCurvePoint]] = []
        var points: [CubicCurvePoint] = []
        var position: Vector2D = .zero
        
        for element in elements {
            switch element {
            case .moveTo(let point):
                if !points.isEmpty {
                    curves.append(points)
                    points.removeAll()
                }
                points.append(CubicCurvePoint(point, in: .zero, out: .zero))
                position = point

            case .lineTo(let endPoint):
                points.append(CubicCurvePoint(endPoint, in: .zero, out: .zero))
                position = endPoint
                
            case .curveTo(let endPoint, let control1, let control2):
                if let lastPoint = points.popLast() {
                    points.append(CubicCurvePoint(lastPoint.position,
                                                 in: lastPoint.inControl,
                                                 out: control1 - lastPoint.position))
                }
                points.append(CubicCurvePoint(endPoint, in: control2 - endPoint, out: .zero))
                position = endPoint
                
            case .quadCurveTo(let control, let endPoint):
                // Convert quadratic to cubic using the utility function
                let startPoint = position
                let (control1, control2) = Geometry.quadraticToCubicControls(
                    start: startPoint, 
                    control: control, 
                    end: endPoint
                )
                
                // Update the out-control of the last point
                if let lastPoint = points.popLast() {
                    points.append(CubicCurvePoint(lastPoint.position,
                                                 in: lastPoint.inControl,
                                                 out: control1 - lastPoint.position))
                }
                points.append(CubicCurvePoint(endPoint, in: control2 - endPoint, out: .zero))
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
