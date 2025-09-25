//
//  SVGGroup.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 14/07/2025.
//


/// Group element ('g')
public class SVGGroup: SVGGraphicElement {
    
    public var _children: [SVGElement]
    
    public init(parent: SVGElement? = nil, children: [SVGElement] = []) {
        self._children = children
        super.init(parent: parent)
    }
    
    // Attributes-based initializer
    override init(parent: SVGElement? = nil, attributes: [String: String]) {
        self._children = []
        super.init(parent: parent, attributes: attributes)
    }

    public override func children() -> [SVGElement] {
        return _children
    }
    
    public func addChild(_ child: SVGElement) {
        self._children.append(child)
        child.parent = self
    }

    override var rawAttributes: [String:String] {
        return super.rawAttributes
    }
    
    public override func toBezierPath() -> BezierPath {
        var path = BezierPath()
        for child in _children {
            guard let child = child as? SVGGraphicElement else {
                continue
            }
            path += child.toBezierPath()
        }
        return path
    }
}

public class SVGUse: SVGGraphicElement {
    public var x: Double?
    public var y: Double?
    public var width: Double?
    public var height: Double?
    public var href: String?
    
    // Attributes-based initializer
    public override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        super.init(parent: parent, attributes: attributes)
        if let value = attributes["x"] {
            self.x = stringToSVGLength(value)
        }
        if let value = attributes["y"] {
            self.y = stringToSVGLength(value)
        }
        if let value = attributes["width"] {
            self.width = stringToSVGLength(value)
        }
        if let value = attributes["height"] {
            self.height = stringToSVGLength(value)
        }
        self.href = attributes["href"] ?? attributes["xlink:href"]
    }
    
    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if let x { attributes["x"] = String(x) }
        if let y { attributes["y"] = String(y) }
        if let width { attributes["width"] = String(width) }
        if let height { attributes["height"] = String(height) }
        if let href { attributes["href"] = href }
        return attributes
    }
}

public class SVGSymbol: SVGElement {
    public var width: Double?
    public var height: Double?
    public var viewBox: SVGViewBox?
    public var preserveAspectRatio: String?
    
    public var _children: [SVGElement]
    
    // Attributes-based initializer
    public override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self._children = []
        super.init(parent: parent, attributes: attributes)
        if let value = attributes["width"] {
            self.width = stringToSVGLength(value)
        }
        if let value = attributes["height"] {
            self.height = stringToSVGLength(value)
        }
        if let string = attributes["viewBox"] {
            self.viewBox = SVGViewBox(string: string)
        }
        self.preserveAspectRatio = attributes["preserveAspectRatio"]
    }
    
    public override func children() -> [SVGElement] {
        return _children
    }

    public func addChild(_ child: SVGElement) {
        self._children.append(child)
        child.parent = self
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if let width { attributes["width"] = String(width) }
        if let height { attributes["height"] = String(height) }
        if let viewBox { attributes["viewBox"] = viewBox.rawValue }
        if let preserveAspectRatio { attributes["preserveAspectRatio"] = preserveAspectRatio }
        return attributes
    }
}
