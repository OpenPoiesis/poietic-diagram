//
//  SVGElement.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 17/06/2025.
//


/// Base class for all SVG elements.
///
public class SVGElement {
    public var id: String?
    public var `class`: String?
    public var style: String?
    public var visibility: Bool?
    
    /// The parent SVG element that contains this element
    public weak var parent: SVGElement?

    public init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        self.parent = parent
        self.id = attributes["id"]
        self.class = attributes["class"]
        self.style = attributes["style"]
        
        if let visibility = attributes["visibility"] {
            self.visibility = visibility == "visible"
        }
    }

    /// Returns an array of child elements.
    public func children() -> [SVGElement] {
        return []
    }

    // MARK: - Tree Traversal Methods

    public func findAll(_ predicate: (SVGElement) -> Bool) -> [SVGElement] {
        var result: [SVGElement] = []
        for child in children() {
            if predicate(child) {
                result.append(child)
            }
            result += child.findAll(predicate)
        }
        return result
    }

    /// Search for first element matching predicate.
    public func first(where predicate: (SVGElement) -> Bool) -> SVGElement? {
        for child in children() {
            if predicate(child) {
                return child
            }
            else if let first = child.first(where: predicate) {
                return first
            }
        }
        return nil
    }

    /// Returns the element at the given path of element IDs.
    func get(path: [String]) -> SVGElement? {
        guard let matchID = path.first else { return nil }
        guard let child = children().first(where: {$0.id == matchID}) else {
            return nil
        }

        let tail = Array(path.dropFirst())
        if tail.isEmpty {
            return child
        }
        else {
            return child.get(path: tail)
        }
    }

    var rawAttributes: [String:String] {
        var attributes: [String:String] = [:]
        attributes["id"] = id
        attributes["class"] = `class`
        if let visibility {
            attributes["visibility"] = visibility ? "visible" : "hidden"
        }
        attributes["style"] = style
        return attributes
    }
    
    // MARK: - Parent Traversal Methods
    
    /// Returns the root SVG element by traversing up the parent chain
    public func getRootElement() -> SVGElement {
        var current: SVGElement = self
        while let parent = current.parent {
            current = parent
        }
        return current
    }
    
    /// Returns all ancestor elements from immediate parent to root
    public func getAncestors() -> [SVGElement] {
        var ancestors: [SVGElement] = []
        var current = self.parent
        while let parent = current {
            ancestors.append(parent)
            current = parent.parent
        }
        return ancestors
    }
    
    /// Returns true if this element is a descendant of the given element
    public func isDescendantOf(_ element: SVGElement) -> Bool {
        var current = self.parent
        while let parent = current {
            if parent === element {
                return true
            }
            current = parent.parent
        }
        return false
    }
}

/// Abstract base class for SVG elements that can have transforms (groups, shapes, use elements)
public class SVGGraphicElement: SVGElement {
    public var transform: SVGTransform?
    
    public override init(parent: SVGElement? = nil, attributes: [String: String] = [:]) {
        super.init(parent: parent, attributes: attributes)
        if let transformString = attributes["transform"] {
            self.transform = SVGTransform(transformString)
        }
    }
    
    override var rawAttributes: [String:String] {
        var attributes: [String:String] = super.rawAttributes
        if let transform { attributes["transform"] = transform.rawValue }
        return attributes
    }
    
    /// Returns the cumulative transform combining all ancestor transforms and this element's transform
    /// according to SVG specification order (ancestor to descendant, left to right within each element)
    public func cumulativeTransform() -> SVGTransform {
        var allComponents: [SVGTransform.Component] = []
        
        // Collect all ancestor elements with transforms, from root to this element
        let ancestors = getAncestors().reversed() // Root first, then down to parent
        
        // Add transform components from ancestors first (root to parent)
        for ancestor in ancestors {
            if let graphicAncestor = ancestor as? SVGGraphicElement,
               let ancestorTransform = graphicAncestor.transform {
                allComponents.append(contentsOf: ancestorTransform.components)
            }
        }
        
        // Finally, add this element's transform components
        if let selfTransform = self.transform {
            allComponents.append(contentsOf: selfTransform.components)
        }
        
        // Create new SVGTransform with combined components
        var result = SVGTransform("")
        result.components = allComponents
        return result
    }
}
