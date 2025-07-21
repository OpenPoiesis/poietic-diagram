//
//  SVGPath.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//


public class SVGPath: SVGShape {
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
    override init(attributes: [String: String]) {
        super.init(attributes: attributes)
        if let pathString = attributes["d"] {
            var scanner = StringScanner(pathString)
            components = scanner.scanSVGPathComponents() ?? []
        }
    }

    init(_ bezier: BezierPath) {
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
        super.init()
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if !components.isEmpty {
            attributes["d"] = self.d
        }
        return attributes
    }
}
