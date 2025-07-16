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

    init(attributes: [String: String] = [:]) {
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
}
