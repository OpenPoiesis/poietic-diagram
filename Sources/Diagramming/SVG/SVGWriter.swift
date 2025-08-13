//
//  SVGWriter.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//

import Foundation

public class SVGWriter {
    private let useIndentation: Bool
    
    public init(useIndentation: Bool = true) {
        self.useIndentation = useIndentation
    }
    
    public func write(_ image: SVGImage) -> String {
        let document = XMLDocument()
        document.version = "1.0"
        document.characterEncoding = "UTF-8"
        
        let rootElement = buildXMLElement(image)
        document.setRootElement(rootElement)
        
        let options: XMLNode.Options = useIndentation ? [.nodePrettyPrint] : []
        return document.xmlString(options: options)
    }
    
    public func writeToFile(_ image: SVGImage, path: String) throws {
        let svgString = write(image)
        try svgString.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    private func buildXMLElement(_ svgElement: SVGElement) -> XMLElement {
        let tagName = getElementTagName(svgElement)
        let xmlElement = XMLElement(name: tagName)
        
        // Set attributes
        for (key, value) in svgElement.rawAttributes {
            xmlElement.addAttribute(XMLNode.attribute(withName: key, stringValue: value) as! XMLNode)
        }
        
//        // Handle text content for descriptive elements
//        if let descriptiveElement = svgElement as? SVGDescriptiveElement,
//           let textContent = descriptiveElement.textContent, !textContent.isEmpty {
//            xmlElement.stringValue = textContent
//        }
        
        // Handle text content for SVGText elements
        if let textElement = svgElement as? SVGText,
           let textContent = textElement.textContent, !textContent.isEmpty {
            xmlElement.stringValue = textContent
        }
        
        // Add children recursively
        for child in svgElement.children() {
            xmlElement.addChild(buildXMLElement(child))
        }
        
        return xmlElement
    }
    
    private func getElementTagName(_ element: SVGElement) -> String {
        switch element {
        case is SVGImage:
            return "svg"
        case is SVGGroup:
            return "g"
        case is SVGSymbol:
            return "symbol"
        case is SVGUse:
            return "use"
//        case is SVGTitle:
//            return "title"
//        case is SVGDesc:
//            return "desc"
//        case is SVGMetadata:
//            return "metadata"
        case is SVGText:
            return "text"
        case let shape as SVGGeometryElement:
            return shape.elementName
        default:
            return "unknown"
        }
    }
}

// MARK: - Convenience Extensions

extension SVGWriter {
    /// Write with default formatting (pretty printed)
    public static func write(_ image: SVGImage) -> String {
        let writer = SVGWriter()
        return writer.write(image)
    }
    
    /// Write compact (no indentation)
    public static func writeCompact(_ image: SVGImage) -> String {
        let writer = SVGWriter(useIndentation: false)
        return writer.write(image)
    }
}
