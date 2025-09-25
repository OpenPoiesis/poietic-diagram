//
//  SVGExporter.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

import PoieticCore

public struct SVGDiagramStyle {
    public var pictogramLineWidth: Double = 2.0
    public var primaryLabelFontFamily = "IBM Plex Sans"
    public var primaryLabelFontWeight = "600"
    public var primaryLabelFontSize = 18.0
    public var primaryLabelOffset = 20.0
    public var secondaryLabelFontFamily = "IBM Plex Sans"
    public var secondaryLabelFontSize = 14.0
    public var secondaryLabelFontWeight = "200"
    public var secondaryLabelOffset = 36.0

    public init() { }
}

public class SVGDiagramExporter {
    /// Prefix for `id` attribute of SVG symbols representing a pictogram.
    ///
    public var pictogramSymbolIDPrefix = "pictogram-"
    
    /// Prefix of the `id` attribute of diagram blocks.
    ///
    /// If the `id` attribute of a block is not nil, then the `id` attribute of the SVG element
    /// representing the block will be the prefix followed by the block ID.
    ///
    public var blockIDPrefix = "block-"
    
    /// Prefix of the `id` attribute of diagram connectors.
    ///
    /// If the `id` attribute of a connector is not nil, then the `id` attribute of the SVG element
    /// representing the connector will be the prefix followed by the block ID.
    ///
    public var connectorIDPrefix = "connector-"
    
    var bbox: Rect2D?
    var elements: [SVGElement]
    var symbols: [String:SVGSymbol]
    var style: SVGDiagramStyle
    
    /// Create a new SVG exporter using given style.
    ///
    /// - SeeAlso: ``export(diagram:to:debug:)``
    ///
    public init(style: SVGDiagramStyle = SVGDiagramStyle()) {
        self.bbox = nil
        self.elements = []
        self.symbols = [:]
        self.style = style
    }
    
    public func extendBoundingBox(_ box: Rect2D) {
        if let currentBox = self.bbox {
            self.bbox = currentBox.union(box)
        }
        else {
            self.bbox = box
        }
    }
    
    /// Export diagram into a file at path.
    ///
    /// - SeeAlso: ``export(diagram:debug:)``
    ///
    public func export(diagram: Diagram, to path: String, debug: Bool=false) throws {
        let image = export(diagram: diagram)
        let writer = SVGWriter()
        try writer.writeToFile(image, path: path)
    }
    
    /// Export a diagram into SVG image.
    ///
    /// If the ``debug`` flag is `true`, then debug elements such as collision shapes and masks
    /// are included in the image.
    ///
    public func export(diagram: Diagram, debug: Bool = false) -> SVGImage {
        let image = SVGImage()
        
        for block in diagram.blocks {
            composeBlock(block)
        }
        for connector in diagram.connectors {
            composeConnector(connector)
        }
        
        for symbol in symbols.values {
            image.addChild(symbol)
        }
        for element in elements {
            image.addChild(element)
        }
        if let bbox {
            image.viewBox = SVGViewBox(bbox)
            image.width = bbox.width
            image.height = bbox.height
        }
        
        return image
    }
    
    public func symbolForPictogram(_ pictogram: Pictogram) -> SVGSymbol {
        let name = pictogram.name
        if let symbol = symbols[name] {
            return symbol
        }
        
        let path = SVGPath(pictogram.path)
        path.fill = "none"
        path.stroke = "black"
        path.strokeWidth = style.pictogramLineWidth
        
        let group = SVGGroup()
        group.addChild(path)
        
        let symbol = SVGSymbol()
        symbol.addChild(group)
        
        symbol.id = "\(pictogramSymbolIDPrefix)\(name)"
        
        symbols[name] = symbol
        
        return symbol
    }
    
    func composeBlock(_ block: Block, debug: Bool=false) {
        let result = SVGGroup()
        
        guard let pictogram = block.pictogram else {
            return
        }

        // DEBUG
        if debug {
            let origin = SVGCircle(center: block.position, radius: 5)
            origin.setStyle(fill: "none", stroke: "lightblue")
            result.addChild(origin)
        
            let debugGroup = debugGroup(pictogram,
                                        id: "debug-\(block.objectID)",
                                        position: block.position)
            if debugGroup.transform == nil {
                debugGroup.transform = SVGTransformList()
            }
            debugGroup.transform?.append(
                .translate(tx: block.position.x,
                           ty: block.position.y)
            )
            result.addChild(debugGroup)
        }

        // MAIN CONTENT
        
        let _ = symbolForPictogram(pictogram)
        let pathBox = pictogram.maskBoundingBox.translated(block.position)
        self.extendBoundingBox(pathBox)
        
        let use = SVGUse()
        use.x = block.position.x
        use.y = block.position.y
        use.href = "#\(pictogramSymbolIDPrefix)\(pictogram.name)"
        if let id = block.objectID {
            use.id = "\(blockIDPrefix)\(id)"
        }
        else {
            use.id = "\(blockIDPrefix)-nil"
        }
        
        result.addChild(use)
        
        if let label = block.label {
            let text = SVGText()
            text.textContent = label
            text.x = pathBox.center.x
            // Note: Flip here when using flipped coordinates
            text.y = pathBox.maxY + style.primaryLabelOffset
            text.fontSize = style.primaryLabelFontSize
            text.textAnchor = "middle"
            text.fontFamily = style.primaryLabelFontFamily
            text.fontWeight = style.primaryLabelFontWeight
            result.addChild(text)
        }
        if let label = block.secondaryLabel {
            let text = SVGText()
            text.textContent = label
            text.x = pathBox.center.x
            // Note: Flip here when using flipped coordinates
            text.y = pathBox.maxY + style.secondaryLabelOffset
            text.textAnchor = "middle"
            text.fontSize = style.secondaryLabelFontSize
            text.fontFamily = style.secondaryLabelFontFamily
            text.fontStyle = "italic"
            text.fontWeight = style.secondaryLabelFontWeight
            result.addChild(text)
        }

        
        elements.append(result)
    }
    
    func composeConnector(_ connector: Connector) {
        let paths = connector.paths()
        let group = SVGGroup()
        if let id = connector.objectID {
            group.id = "\(connectorIDPrefix)\(id)"
        }
        else {
            group.id = "\(connectorIDPrefix)-nil"
        }

        for path in paths {
            if let box = path.boundingBox {
                self.extendBoundingBox(box)
            }

            let svgPath = SVGPath(path)
            svgPath.fill = "none"
            svgPath.stroke = connector.shapeStyle.lineColor
            group.addChild(svgPath)
        }
        elements.append(group)
    }
    
    func debugGroup(_ pictogram: Pictogram, id: String, position: Vector2D) -> SVGGroup {
        let box = pictogram.path.boundingBox!
        let result: SVGGroup = SVGGroup()
        result.id = "debug-\(id)-pictogram"
        
        let bbox = SVGRectangle()
        bbox.x = box.origin.x
        bbox.y = box.origin.y
        bbox.width = box.width
        bbox.height = box.height
        bbox.setStyle(fill:"none", stroke: "green", strokeWidth: 2.0)
        result.addChild(bbox)
        
        let mask = SVGPath(pictogram.mask)
        mask.setStyle(fill:"azure", stroke: "blue", strokeWidth: 1.0)
        result.addChild(mask)
        
        let shape = pictogram.collisionShape.shape.toSVGElement()
        shape.setStyle(fill:"none", stroke: "orange", strokeWidth: 4.0)
        shape.transform = SVGTransformList([
            .translate(tx: pictogram.collisionShape.position.x,
                       ty: pictogram.collisionShape.position.y)
        ])
        result.addChild(shape)
        
        return result
    }
}

