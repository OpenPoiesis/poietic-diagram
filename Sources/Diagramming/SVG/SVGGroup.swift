//
//  SVGGroup.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 14/07/2025.
//


/// Group element ('g')
public class SVGGroup: SVGElement {
    public var transform: SVGTransform?
    
    public var _children: [SVGElement]
    
    public init(children: [SVGElement] = []) {
        self._children = children
        super.init()
    }
    
    // Attributes-based initializer
    override init(attributes: [String: String]) {
        self._children = []
        super.init(attributes: attributes)
        if let string = attributes["transform"] {
            self.transform = SVGTransform(string)
        }
    }

    public override func children() -> [SVGElement] {
        return _children
    }
    
    public func addChild(_ child: SVGElement) {
        self._children.append(child)
    }

    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if let transform { attributes["transform"] = transform.rawValue }
        return attributes
    }
}

public class SVGUse: SVGElement {
    public var x: Double?
    public var y: Double?
    public var width: Double?
    public var height: Double?
    public var href: String?
    public var transform: SVGTransform?
    
    // Attributes-based initializer
    override init(attributes: [String: String]) {
        super.init(attributes: attributes)
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
        
        if let transformString = attributes["transform"] {
            self.transform = SVGTransform(transformString)
        }
    }
    
    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if let x { attributes["x"] = String(x) }
        if let y { attributes["y"] = String(y) }
        if let width { attributes["width"] = String(width) }
        if let height { attributes["height"] = String(height) }
        if let href { attributes["href"] = href }
        if let transform { attributes["transform"] = transform.rawValue }
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
    override init(attributes: [String: String]) {
        self._children = []
        super.init(attributes: attributes)
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
