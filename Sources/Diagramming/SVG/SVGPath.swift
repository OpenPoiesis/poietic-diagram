//
//  SVGPath.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//


public class SVGPath: SVGGeometryElement {
    public enum Component {
        // Move commands
        case moveTo(x: Double, y: Double)
        case moveToRelative(dx: Double, dy: Double)
        
        // Line commands
        case lineTo(x: Double, y: Double)
        case lineToRelative(dx: Double, dy: Double)
        case horizontalLineTo(x: Double)
        case horizontalLineToRelative(dx: Double)
        case verticalLineTo(y: Double)
        case verticalLineToRelative(dy: Double)
        
        // Curve commands
        case curveTo(x1: Double, y1: Double, x2: Double, y2: Double, x: Double, y: Double)
        case curveToRelative(dx1: Double, dy1: Double, dx2: Double, dy2: Double, dx: Double, dy: Double)
        case smoothCurveTo(x2: Double, y2: Double, x: Double, y: Double)
        case smoothCurveToRelative(dx2: Double, dy2: Double, dx: Double, dy: Double)
        case quadraticCurveTo(x1: Double, y1: Double, x: Double, y: Double)
        case quadraticCurveToRelative(dx1: Double, dy1: Double, dx: Double, dy: Double)
        case smoothQuadraticCurveTo(x: Double, y: Double)
        case smoothQuadraticCurveToRelative(dx: Double, dy: Double)
        
        // Arc command
        case arcTo(rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, x: Double, y: Double)
        case arcToRelative(rx: Double, ry: Double, xAxisRotation: Double, largeArcFlag: Bool, sweepFlag: Bool, dx: Double, dy: Double)
        
        // Close path
        case closePath
        
        var command: String {
            switch self {
            case .moveTo: return "M"
            case .moveToRelative: return "m"
            case .lineTo: return "L"
            case .lineToRelative: return "l"
            case .horizontalLineTo: return "H"
            case .horizontalLineToRelative: return "h"
            case .verticalLineTo: return "V"
            case .verticalLineToRelative: return "v"
            case .curveTo: return "C"
            case .curveToRelative: return "c"
            case .smoothCurveTo: return "S"
            case .smoothCurveToRelative: return "s"
            case .quadraticCurveTo: return "Q"
            case .quadraticCurveToRelative: return "q"
            case .smoothQuadraticCurveTo: return "T"
            case .smoothQuadraticCurveToRelative: return "t"
            case .arcTo: return "A"
            case .arcToRelative: return "a"
            case .closePath: return "Z"
            }
        }
        // FIXME: Remove this, dissolve in rawValue string
        var parameters: [String] {
            switch self {
            case .moveTo(let x, let y):
                return [String(x), String(y)]
            case .moveToRelative(let dx, let dy):
                return [String(dx), String(dy)]
            case .lineTo(let x, let y):
                return [String(x), String(y)]
            case .lineToRelative(let dx, let dy):
                return [String(dx), String(dy)]
            case .horizontalLineTo(let x):
                return [String(x)]
            case .horizontalLineToRelative(let dx):
                return [String(dx)]
            case .verticalLineTo(let y):
                return [String(y)]
            case .verticalLineToRelative(let dy):
                return [String(dy)]
            case .curveTo(let x1, let y1, let x2, let y2, let x, let y):
                return [String(x1), String(y1), String(x2), String(y2), String(x), String(y)]
            case .curveToRelative(let dx1, let dy1, let dx2, let dy2, let dx, let dy):
                return [String(dx1), String(dy1), String(dx2), String(dy2), String(dx), String(dy)]
            case .smoothCurveTo(let x2, let y2, let x, let y):
                return [String(x2), String(y2), String(x), String(y)]
            case .smoothCurveToRelative(let dx2, let dy2, let dx, let dy):
                return [String(dx2), String(dy2), String(dx), String(dy)]
            case .quadraticCurveTo(let x1, let y1, let x, let y):
                return [String(x1), String(y1), String(x), String(y)]
            case .quadraticCurveToRelative(let dx1, let dy1, let dx, let dy):
                return [String(dx1), String(dy1), String(dx), String(dy)]
            case .smoothQuadraticCurveTo(let x, let y):
                return [String(x), String(y)]
            case .smoothQuadraticCurveToRelative(let dx, let dy):
                return [String(dx), String(dy)]
            case .arcTo(let rx, let ry, let xAxisRotation, let largeArcFlag, let sweepFlag, let x, let y):
                return [String(rx), String(ry), String(xAxisRotation),
                       largeArcFlag ? "1" : "0", sweepFlag ? "1" : "0", String(x), String(y)]
            case .arcToRelative(let rx, let ry, let xAxisRotation, let largeArcFlag, let sweepFlag, let dx, let dy):
                return [String(rx), String(ry), String(xAxisRotation),
                       largeArcFlag ? "1" : "0", sweepFlag ? "1" : "0", String(dx), String(dy)]
            case .closePath:
                return []
            }
        }
        
        var rawValue: String {
            let params = parameters.joined(separator: ",")
            return params.isEmpty ? command : "\(command)\(params)"
        }
    }

    public var d: String? {
        get {
            guard !components.isEmpty else { return nil }
            return components.map { $0.rawValue }.joined(separator: " ")
        }
        set {
            if let newValue {
                var scanner = StringScanner(newValue)
                components = scanner.scanSVGPathComponents() ?? []
            } else {
                components = []
            }
        }
    }
    
    public var components: [Component] = []
    
    public override var elementName: String { "path" }

    // Attributes-based initializer
    public override init(parent: SVGElement? = nil, attributes: [String: String]) {
        super.init(parent: parent, attributes: attributes)
        if let pathString = attributes["d"] {
            var scanner = StringScanner(pathString)
            components = scanner.scanSVGPathComponents() ?? []
        }
    }

    public init(_ bezier: BezierPath) {
        let components: [Component] = bezier.elements.map {
            switch $0 {
            case .moveTo(let point):
                return .moveTo(x: point.x, y: point.y)
            case .lineTo(let point):
                return .lineTo(x: point.x, y: point.y)
            case .curveTo(let end, let control1, let control2):
                return .curveTo(x1: control1.x, y1: control1.y, x2: control2.x, y2: control2.y, x: end.x, y: end.y)
            case .quadCurveTo(let control, let end):
                return .quadraticCurveTo(x1: control.x, y1: control.y, x: end.x, y: end.y)
            case .closePath:
                return .closePath
            }
        }
        self.components = components
        super.init(parent: nil)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if !components.isEmpty {
            attributes["d"] = self.d
        }
        return attributes
    }
    
    /// Convert this SVG path to a BezierPath
    ///
    /// This method converts SVG path components to BezierPath elements, handling coordinate
    /// transformations and converting SVG-specific commands to their BezierPath equivalents.
    /// Relative commands are converted to absolute coordinates by tracking the current position.
    ///
    /// - Returns: A BezierPath representing this SVG path
    ///
    public override func toBezierPath() -> BezierPath {
        var bezierPath = BezierPath()
        var currentPoint = Vector2D(0, 0)
        var subpathStart = Vector2D(0, 0)
        var lastControlPoint: Vector2D?
        
        for component in components {
            switch component {
            case .moveTo(let x, let y):
                let point = Vector2D(x, y)
                bezierPath.move(to: point)
                currentPoint = point
                subpathStart = point
                lastControlPoint = nil
                
            case .moveToRelative(let dx, let dy):
                let point = currentPoint + Vector2D(dx, dy)
                bezierPath.move(to: point)
                currentPoint = point
                subpathStart = point
                lastControlPoint = nil
                
            case .lineTo(let x, let y):
                let point = Vector2D(x, y)
                bezierPath.addLine(to: point)
                currentPoint = point
                lastControlPoint = nil
                
            case .lineToRelative(let dx, let dy):
                let point = currentPoint + Vector2D(dx, dy)
                bezierPath.addLine(to: point)
                currentPoint = point
                lastControlPoint = nil
                
            case .horizontalLineTo(let x):
                let point = Vector2D(x, currentPoint.y)
                bezierPath.addLine(to: point)
                currentPoint = point
                lastControlPoint = nil
                
            case .horizontalLineToRelative(let dx):
                let point = currentPoint + Vector2D(dx, 0)
                bezierPath.addLine(to: point)
                currentPoint = point
                lastControlPoint = nil
                
            case .verticalLineTo(let y):
                let point = Vector2D(currentPoint.x, y)
                bezierPath.addLine(to: point)
                currentPoint = point
                lastControlPoint = nil
                
            case .verticalLineToRelative(let dy):
                let point = currentPoint + Vector2D(0, dy)
                bezierPath.addLine(to: point)
                currentPoint = point
                lastControlPoint = nil
                
            case .curveTo(let x1, let y1, let x2, let y2, let x, let y):
                let control1 = Vector2D(x1, y1)
                let control2 = Vector2D(x2, y2)
                let endPoint = Vector2D(x, y)
                bezierPath.addCurve(to: endPoint, control1: control1, control2: control2)
                currentPoint = endPoint
                lastControlPoint = control2
                
            case .curveToRelative(let dx1, let dy1, let dx2, let dy2, let dx, let dy):
                let control1 = currentPoint + Vector2D(dx1, dy1)
                let control2 = currentPoint + Vector2D(dx2, dy2)
                let endPoint = currentPoint + Vector2D(dx, dy)
                bezierPath.addCurve(to: endPoint, control1: control1, control2: control2)
                currentPoint = endPoint
                lastControlPoint = control2
                
            case .smoothCurveTo(let x2, let y2, let x, let y):
                let control2 = Vector2D(x2, y2)
                let endPoint = Vector2D(x, y)
                // First control point is reflection of last control point
                let control1 = lastControlPoint != nil ? 
                    currentPoint + (currentPoint - lastControlPoint!) : currentPoint
                bezierPath.addCurve(to: endPoint, control1: control1, control2: control2)
                currentPoint = endPoint
                lastControlPoint = control2
                
            case .smoothCurveToRelative(let dx2, let dy2, let dx, let dy):
                let control2 = currentPoint + Vector2D(dx2, dy2)
                let endPoint = currentPoint + Vector2D(dx, dy)
                // First control point is reflection of last control point
                let control1 = lastControlPoint != nil ? 
                    currentPoint + (currentPoint - lastControlPoint!) : currentPoint
                bezierPath.addCurve(to: endPoint, control1: control1, control2: control2)
                currentPoint = endPoint
                lastControlPoint = control2
                
            case .quadraticCurveTo(let x1, let y1, let x, let y):
                let control = Vector2D(x1, y1)
                let endPoint = Vector2D(x, y)
                bezierPath.addQuadCurve(to: endPoint, control: control)
                currentPoint = endPoint
                lastControlPoint = control
                
            case .quadraticCurveToRelative(let dx1, let dy1, let dx, let dy):
                let control = currentPoint + Vector2D(dx1, dy1)
                let endPoint = currentPoint + Vector2D(dx, dy)
                bezierPath.addQuadCurve(to: endPoint, control: control)
                currentPoint = endPoint
                lastControlPoint = control
                
            case .smoothQuadraticCurveTo(let x, let y):
                let endPoint = Vector2D(x, y)
                // Control point is reflection of last control point
                let control = lastControlPoint != nil ? 
                    currentPoint + (currentPoint - lastControlPoint!) : currentPoint
                bezierPath.addQuadCurve(to: endPoint, control: control)
                currentPoint = endPoint
                lastControlPoint = control
                
            case .smoothQuadraticCurveToRelative(let dx, let dy):
                let endPoint = currentPoint + Vector2D(dx, dy)
                // Control point is reflection of last control point
                let control = lastControlPoint != nil ? 
                    currentPoint + (currentPoint - lastControlPoint!) : currentPoint
                bezierPath.addQuadCurve(to: endPoint, control: control)
                currentPoint = endPoint
                lastControlPoint = control
                
            case .arcTo(_, _, _, _, _, let x, let y):
                // For now, convert arcs to lines (proper arc-to-bezier conversion is complex)
                let endPoint = Vector2D(x, y)
                bezierPath.addLine(to: endPoint)
                currentPoint = endPoint
                lastControlPoint = nil
                
            case .arcToRelative(_, _, _, _, _, let dx, let dy):
                // For now, convert arcs to lines (proper arc-to-bezier conversion is complex)
                let endPoint = currentPoint + Vector2D(dx, dy)
                bezierPath.addLine(to: endPoint)
                currentPoint = endPoint
                lastControlPoint = nil
                
            case .closePath:
                bezierPath.closeSubpath()
                currentPoint = subpathStart
                lastControlPoint = nil
            }
        }
        
        return bezierPath
    }
}
