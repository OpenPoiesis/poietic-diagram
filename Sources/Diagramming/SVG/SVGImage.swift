//
//  SVGImage.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//


/// Root element of an image.
///
public class SVGImage: SVGElement {
    public var width: Double?
    public var height: Double?
    public var viewBox: SVGViewBox?

    public var _children: [SVGElement]
    
    // Attributes-based initializer
    public override init(parent: SVGElement? = nil, attributes: [String: String]=[:]) {
        self._children = []
        super.init(parent: parent, attributes: attributes)
        self.width = SVGAttributeToLength(attributes["width"])
        self.height = SVGAttributeToLength(attributes["height"])
        if let string = attributes["viewBox"] {
            self.viewBox = SVGViewBox(string: string)
        }
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
        return attributes
    }
}
