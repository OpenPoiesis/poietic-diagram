//
//  SVGReader.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 04/08/2025.
//

import Foundation

/// Error types for SVG reading operations
public enum SVGReaderError: Error {
    case unsupportedElement(String)
    case invalidXML(String)
    case parsingError(String)
}

/// SVG reader that parses XML data and creates SVG element tree
public class SVGReader: NSObject {
    
    private var elementStack: [SVGElement] = []
    private var currentElement: SVGElement?
    private var rootElement: SVGElement?
    
    /// Parse SVG data and return the root element
    public func read(data: Data) throws -> SVGElement {
        elementStack.removeAll()
        currentElement = nil
        rootElement = nil
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            if let error = parser.parserError {
                throw SVGReaderError.invalidXML(error.localizedDescription)
            } else {
                throw SVGReaderError.invalidXML("Unknown XML parsing error")
            }
        }
        
        guard let root = rootElement else {
            throw SVGReaderError.parsingError("No root element found")
        }
        
        return root
    }
    
    /// Parse SVG string and return the root element
    public func read(string: String) throws -> SVGElement {
        guard let data = string.data(using: .utf8) else {
            throw SVGReaderError.invalidXML("Invalid UTF-8 encoding")
        }
        return try read(data: data)
    }
    
    /// Create SVG element from XML element name and attributes
    private func createElement(name: String, attributes: [String: String], parent: SVGElement?) throws -> SVGElement {
        switch name {
        case "svg":
            return SVGImage(parent: parent, attributes: attributes)
        case "g":
            return SVGGroup(parent: parent, attributes: attributes)
        case "use":
            return SVGUse(parent: parent, attributes: attributes)
        case "symbol":
            return SVGSymbol(parent: parent, attributes: attributes)
        case "path":
            return SVGPath(parent: parent, attributes: attributes)
        case "circle":
            return SVGCircle(parent: parent, attributes: attributes)
        case "ellipse":
            return SVGEllipse(parent: parent, attributes: attributes)
        case "line":
            return SVGLine(parent: parent, attributes: attributes)
        case "polygon":
            return SVGPolygon(parent: parent, attributes: attributes)
        case "polyline":
            return SVGPolyline(parent: parent, attributes: attributes)
        case "rect":
            return SVGRectangle(parent: parent, attributes: attributes)
        default:
            // TODO: Add clipPath
            throw SVGReaderError.unsupportedElement("Unsupported SVG element: \(name)")
        }
    }
}

// MARK: - XMLParserDelegate

extension SVGReader: XMLParserDelegate {
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        do {
            let element = try createElement(name: elementName, attributes: attributeDict, parent: currentElement)
            
            // Set as root if this is the first element
            if rootElement == nil {
                rootElement = element
            }
            
            // Add to parent if there is one
            if let parent = currentElement {
                if let group = parent as? SVGGroup {
                    group.addChild(element)
                } else if let image = parent as? SVGImage {
                    image.addChild(element)
                } else if let symbol = parent as? SVGSymbol {
                    symbol.addChild(element)
                }
            }
            
            // Push to stack and set as current
            elementStack.append(element)
            currentElement = element
            
        } catch {
            // Let the parser continue but stop processing
            parser.abortParsing()
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // Pop from stack
        if !elementStack.isEmpty {
            elementStack.removeLast()
            currentElement = elementStack.last
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // Error handling is done in the main read method
    }
    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        // Error handling is done in the main read method
    }
}
