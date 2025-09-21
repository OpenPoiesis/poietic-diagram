//
//  SVGText.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 13/08/2025.
//

public class SVGText: SVGGraphicElement {
    public var x: Double
    public var y: Double
    public var dx: Double?
    public var dy: Double?
    public var textContent: String?
    public var fontSize: Double
    public var fontFamily: String?
    public var fontStyle: String?
    public var fontWeight: String?
    public var fill: String?
    public var stroke: String?
    public var textAnchor: String?
    
    public init(id: String? = nil, position: Vector2D, text: String) {
        self.x = position.x
        self.y = position.y
        self.textContent = text
        self.fontSize = 12.0
        self.dx = nil
        self.dy = nil
        self.fontFamily = nil
        self.fontStyle = nil
        self.fontWeight = nil
        self.fill = nil
        self.stroke = nil
        self.textAnchor = nil
        super.init()
        self.id = id
    }
    
    public override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.x = SVGAttributeToLength(attributes["x"])
        self.y = SVGAttributeToLength(attributes["y"])
        self.dx = SVGAttributeToLength(attributes["dx"]) != 0.0 ? SVGAttributeToLength(attributes["dx"]) : nil
        self.dy = SVGAttributeToLength(attributes["dy"]) != 0.0 ? SVGAttributeToLength(attributes["dy"]) : nil
        self.fontSize = SVGAttributeToLength(attributes["font-size"], default: 12.0)
        self.fontFamily = attributes["font-family"]
        self.fontStyle = attributes["font-style"]
        self.fontWeight = attributes["font-weight"]
        self.fill = attributes["fill"]
        self.stroke = attributes["stroke"]
        self.textAnchor = attributes["text-anchor"]
        self.textContent = nil
        super.init(parent: parent, attributes: attributes)
    }
    
    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        attributes["x"] = String(x)
        attributes["y"] = String(y)
        if let dx { attributes["dx"] = String(dx) }
        if let dy { attributes["dy"] = String(dy) }
        attributes["font-size"] = String(fontSize)
        if let fontFamily { attributes["font-family"] = fontFamily }
        if let fontStyle { attributes["font-style"] = fontStyle }
        if let fontWeight { attributes["font-weight"] = fontWeight }
        if let fill { attributes["fill"] = fill }
        if let stroke { attributes["stroke"] = stroke }
        if let textAnchor { attributes["text-anchor"] = textAnchor }
        return attributes
    }
    
    public override func toBezierPath() -> BezierPath {
        return BezierPath()
    }
}