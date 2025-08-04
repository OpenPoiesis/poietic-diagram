//
//  SVGShape.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 17/06/2025.
//

// FIXME: [IMPORTANT] Make properties non-optional

public let DefaultSVGLengthDPI = 96.0

/// Converts a string containing a SVG length to pixels (user units).
///
/// Converts a length described as string with optional absolute units specifier into a length
/// in pixels. Absolute units considered are: `px`, `in`, `pt`, `cm`, `mm`, `pc`. Relative units
/// (such as `em` or percentage) result in ``nil`` return value.
///
public func stringToSVGLength(_ string: String, dpi: Double = DefaultSVGLengthDPI) -> Double? {
    var scanner = StringScanner(string)
    return scanner.scanSVGLength(dpi: dpi)
}
public func SVGAttributeToLength(_ string: String?, dpi: Double = DefaultSVGLengthDPI, default defaultValue: Double = 0.0) -> Double {
    guard let string else {
        return defaultValue
    }
    var scanner = StringScanner(string)
    return scanner.scanSVGLength(dpi: dpi) ?? defaultValue
}

public func stringToSVGPoints(_ string: String, dpi: Double = DefaultSVGLengthDPI) -> [Vector2D]? {
    var scanner = StringScanner(string)
    var points: [Vector2D] = []
    guard let numbers = scanner.scanSVGCommaSeparatedLengths() else {
        return nil
    }
    guard numbers.count.isMultiple(of: 2) else {
        return nil
    }
    for i in stride(from: 0, to: numbers.count, by: 2) {
        let point = Vector2D(numbers[i], numbers[i+1])
        points.append(point)
    }
    return points
}

// Base class for shape elements
public class SVGGeometryElement: SVGGraphicElement {
    public var elementName: String { "shape" }

    public var fill: String?
    public var stroke: String?
    public var strokeWidth: Double
    public var strokeLineCap: String?
    public var strokeLineJoin: String?
    
    public override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.fill = attributes["fill"]
        self.stroke = attributes["stroke"]
        self.strokeWidth = SVGAttributeToLength(attributes["stroke-width"], default: 1.0)
        self.strokeLineCap = attributes["stroke-linecap"]
        self.strokeLineJoin = attributes["stroke-linejoin"]
        
        super.init(parent: parent, attributes: attributes)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if let fill { attributes["fill"] = fill }
        if let stroke { attributes["stroke"] = stroke }
        attributes["stroke-width"] = String(strokeWidth)
        if let strokeLineCap { attributes["stroke-linecap"] = String(strokeLineCap) }
        if let strokeLineJoin { attributes["stroke-linejoin"] = String(strokeLineJoin) }
        return attributes
    }
}

// Specific shape elements
public class SVGCircle: SVGGeometryElement {
    public override var elementName: String { "circle" }

    public var cx: Double
    public var cy: Double
    public var r: Double
    
    override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.cx = SVGAttributeToLength(attributes["cx"])
        self.cy = SVGAttributeToLength(attributes["cy"])
        self.r = SVGAttributeToLength(attributes["r"])
        super.init(parent: parent, attributes: attributes)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        attributes["cx"] = String(cx)
        attributes["cy"] = String(cy)
        attributes["r"] = String(r)
        return attributes
    }
}

public class SVGEllipse: SVGGeometryElement {
    public override var elementName: String { "ellipse" }

    public var cx: Double
    public var cy: Double
    public var rx: Double
    public var ry: Double
    
    override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.cx = SVGAttributeToLength(attributes["cx"])
        self.cy = SVGAttributeToLength(attributes["cy"])
        self.rx = SVGAttributeToLength(attributes["rx"])
        self.ry = SVGAttributeToLength(attributes["ry"])
        super.init(parent: parent, attributes: attributes)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        attributes["cx"] = String(cx)
        attributes["cy"] = String(cy)
        attributes["rx"] = String(rx)
        attributes["ry"] = String(ry)
        return attributes
    }
}

public class SVGLine: SVGGeometryElement {
    public override var elementName: String { "line" }

    public var x1: Double
    public var y1: Double
    public var x2: Double
    public var y2: Double

    override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.x1 = SVGAttributeToLength(attributes["x1"])
        self.y1 = SVGAttributeToLength(attributes["y1"])
        self.x2 = SVGAttributeToLength(attributes["x2"])
        self.y2 = SVGAttributeToLength(attributes["y2"])
        super.init(parent: parent, attributes: attributes)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        attributes["x1"] = String(x1)
        attributes["y1"] = String(y1)
        attributes["x2"] = String(x2)
        attributes["y2"] = String(y2)
        return attributes
    }
}

public class SVGPolygon: SVGGeometryElement {
    public override var elementName: String { "polygon" }

    public var points: [Vector2D] = []
    
    override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        super.init(parent: parent, attributes: attributes)
        if let string = attributes["points"], let points = stringToSVGPoints(string) {
            self.points = points
        }
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if !points.isEmpty {
            attributes["points"] = points.map { $0.rawSVGValue }.joined(separator: " ")
        }
        return attributes
    }
}

public class SVGPolyline: SVGGeometryElement {
    public override var elementName: String { "polyline" }

    public var points: [Vector2D] = []
    
    override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        super.init(parent: parent, attributes: attributes)
        if let string = attributes["points"], let points = stringToSVGPoints(string) {
            self.points = points
        }
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if !points.isEmpty {
            attributes["points"] = points.map { $0.rawSVGValue }.joined(separator: " ")
        }
        return attributes
    }
}

public class SVGRectangle: SVGGeometryElement {
    public override var elementName: String { "rect" }

    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var rx: Double
    public var ry: Double

    override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.x = SVGAttributeToLength(attributes["x"])
        self.y = SVGAttributeToLength(attributes["y"])
        self.width = SVGAttributeToLength(attributes["width"])
        self.height = SVGAttributeToLength(attributes["height"])
        self.rx = SVGAttributeToLength(attributes["rx"])
        self.ry = SVGAttributeToLength(attributes["ry"])
        super.init(parent: parent, attributes: attributes)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        attributes["x"] = String(x)
        attributes["y"] = String(y)
        attributes["width"] = String(width)
        attributes["height"] = String(height)
        attributes["rx"] = String(rx)
        attributes["ry"] = String(ry)
        return attributes
    }
}
