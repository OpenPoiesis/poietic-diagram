//
//  SVGExporter.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

import PoieticCore

public struct OLDSVGDiagramStyle {
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


public class SVGExportDrawingContext {
    func setLineWidth() {}
}

public class SVGDiagramSceneRendererContext: RenderingContextProtocol {
    /// Prefix for `id` attribute of SVG symbols representing a pictogram.
    ///
    public var pictogramSymbolIDPrefix = "pictogram-"
    public var objectIDPrefix = "object-"

    var transformStack: [AffineTransform] = []
    var currentTransform: AffineTransform = .identity

    var symbols: [String:SVGSymbol] = [:]
    var elements: [SVGElement] = []

    /// Bounding box for the whole diagram.
    var bbox: Rect2D = Rect2D()

    var style: SVGDiagramStyle
    
    init(style: SVGDiagramStyle) {
        self.style = style
    }

    public func extendBoundingBox(_ box: Rect2D) {
        // TODO: Transform??
        self.bbox.union(box)
    }
    
    public func appendWithTransform(_ element: SVGElement) {
        if let element = element as? SVGGraphicElement {
            element.transform = SVGTransformList(currentTransform)
        }
        self.elements.append(element)
    }
    // Conformance methods
    public func save() {
        transformStack.append(currentTransform)
    }
    public func restore() {
        if let transform = transformStack.popLast() {
            self.currentTransform = transform
        }
        else {
            self.currentTransform = .identity
        }
    }

    public var transform: AffineTransform {
        get { return currentTransform }
    }

    public func setTransform(_ transform: AffineTransform) {
        self.currentTransform = transform
    }
    

    public func registerPictogramSymbol(_ pictogram: Pictogram) {
        let name = pictogram.name

        let path = SVGPath(pictogram.path)
        // TODO: Let the use of the symbol decide colors
//        path.fill = "none"
//        path.stroke = "black"
//        path.strokeWidth = style.pictogramLineWidth
        
        let group = SVGGroup()
        group.addChild(path)
        
        let symbol = SVGSymbol()
        symbol.addChild(group)
        
        symbol.id = "\(pictogramSymbolIDPrefix)\(name)"
        
        symbols[name] = symbol
    }

}

public class SVGDiagramSceneRenderer: DiagramSceneRenderer {
    public typealias Context = SVGDiagramSceneRendererContext

    let world: World
    let viewport: ViewportState

    let style: SVGDiagramStyle
    
    public init(world: World,
                viewport: ViewportState = ViewportState(offset: .zero, zoom: 1.0),
                style: SVGDiagramStyle? = nil)
    {
        self.world = world
        self.viewport = viewport
        self.style = style ?? SVGDiagramStyle.Default
    }
    
    public func render(_ diagram: RuntimeEntity, style: SVGDiagramStyle, to path: String) throws {
        let image = render(diagram, style: style)
        let writer = SVGWriter()
        try writer.writeToFile(image, path: path)
    }

    public func render(_ diagram: RuntimeEntity, style: SVGDiagramStyle) -> SVGImage {
        let context = SVGDiagramSceneRendererContext(style: style)
        self.render(diagram, context: context)
        
        let image = SVGImage()
        for element in context.elements {
            image.addChild(element)
        }
//        if let bbox {
//            image.viewBox = SVGViewBox(bbox)
//            image.width = bbox.width
//            image.height = bbox.height
//        }
        return image
    }
    
    public func renderBlock(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        guard let position: PositionComponent = entity.component(),
              let pictComp: PictogramCanvasNode = entity.component()
        else { return }
        
        // TODO: Color
        let pictogram = pictComp.pictogram
        let symbol = SVGUse()
        symbol.x = position.position.x
        symbol.y = position.position.y
        symbol.href = "#\(context.pictogramSymbolIDPrefix)\(pictogram.name)"
        if let id = entity.objectID {
            symbol.id =  context.objectIDPrefix + id.stringValue
        }
        
        let styleClass: StyleClass
        if let nodeStyle: CanvasNodeStyle = entity.component() {
            styleClass = nodeStyle.class
        }
        else {
            styleClass = .pictogram
        }
        
        if let pictogramStyle = style.classes[styleClass] {
            // TODO: Color
        }

        context.appendWithTransform(symbol)
        // TODO: Highlights (selection)
    }
    
    public func renderPictogram(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        fatalError("\(#function) Not implemented")
    }
    public func renderConnector(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        guard let stroke: ConnectorStroke = entity.component()
        else { return }
        
        let group = SVGGroup()
        if let id = entity.objectID {
            group.id =  context.objectIDPrefix + id.stringValue
        }

        let styleClass: StyleClass
        if let nodeStyle: CanvasNodeStyle = entity.component() {
            styleClass = nodeStyle.class
        }
        else {
            styleClass = .normal
        }
        let elementStyle = style.classes[styleClass]
        
        if let path = stroke.body {
            let svgPath = SVGPath(path)
            svgPath.stroke = elementStyle?.stroke
            if stroke.isFilled {
                svgPath.fill = elementStyle?.fill
            }
            svgPath.strokeWidth = elementStyle?.strokeWidth ?? 1.0
            group.addChild(svgPath)
        }
        if let path = stroke.headArrowhead {
            let svgPath = SVGPath(path)
            svgPath.stroke = elementStyle?.stroke
            svgPath.fill = elementStyle?.fill
            svgPath.strokeWidth = elementStyle?.strokeWidth ?? 1.0
            group.addChild(svgPath)
        }
        if let path = stroke.tailArrowhead {
            let svgPath = SVGPath(path)
            svgPath.stroke = elementStyle?.stroke
            svgPath.fill = elementStyle?.fill
            svgPath.strokeWidth = elementStyle?.strokeWidth ?? 1.0
            group.addChild(svgPath)
        }
        context.appendWithTransform(group)
    }

    public func renderLabel(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        guard let position: PositionComponent = entity.component(),
              let label: LabelCanvasNode = entity.component()
        else { return }
        let styleClass: StyleClass
        if let nodeStyle: CanvasNodeStyle = entity.component() {
            styleClass = nodeStyle.class
        }
        else {
            styleClass = .label
        }
        
        let element = SVGText()
        element.textContent = label.text
        element.x = position.position.x
        // Note: Flip here when using flipped coordinates
        element.y = position.position.y

        if let labelStyle = style.classes[styleClass] {
            element.fontSize = labelStyle.fontSize
            element.textAnchor = "middle"
            element.fontFamily = labelStyle.fontName
            element.fontWeight = labelStyle.fontWeight
        }
        context.appendWithTransform(element)
    }
    
    public func renderValueIndicator(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        // TODO: Implement this
    }
    
    public func renderIssueIndicator(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        // TODO: Implement this
    }

    public func renderColorSwatch(_ entity: RuntimeEntity, context: Context) {
        guard let swatch: ColorSwatchCanvasNode = entity.component()
        else { return }
        let styleClass: StyleClass
        if let nodeStyle: CanvasNodeStyle = entity.component() {
            styleClass = nodeStyle.class
        }
        else {
            styleClass = .colorSwatch
        }

        let element = SVGRectangle(rect: Rect2D(center: .zero, size: swatch.size))
        element.stroke = style.classes[styleClass]?.stroke
        element.fill = style.adaptableColor(swatch.colorKey)
        context.appendWithTransform(element)
    }
    

}

#if false

// TODO: Change to System
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
    /// - SeeAlso: ``export(world:debug:)``
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
    /// - SeeAlso: ``export(world:debug:)``
    ///
    public func export(world: World, to path: String, debug: Bool=false) throws {
        let image = export(world: world)
        let writer = SVGWriter()
        try writer.writeToFile(image, path: path)
    }
    
    public func entityIDString(_ id: RuntimeID, in world: World) -> String {
        if let objectID = world.entity(id)?.objectID {
            "o" + objectID.stringValue
        }
        else {
            "e" + id.description

        }
    }
    /// Export a diagram into SVG image.
    ///
    /// If the debug flag is `true`, then debug elements such as collision shapes and masks
    /// are included in the image.
    ///
    public func export(world: World, debug: Bool = false) -> SVGImage {
        let image = SVGImage()
        
        for (entity, block) in world.query(DiagramBlock.self) {
            composeBlock(id: entityIDString(entity.runtimeID, in: world), block: block)
        }
        for (entity, geometry) in world.query(DiagramConnectorGeometry.self) {
            composeConnector(id: entityIDString(entity.runtimeID, in: world), geometry: geometry)
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
    
    func composeBlock(id: String, block: DiagramBlock, debug: Bool=false) {
        guard let pictogram = block.pictogram else { return }
        
        let result = SVGGroup()

        // DEBUG
        if debug {
            let origin = SVGCircle(center: block.position, radius: 5)
            origin.setStyle(fill: "none", stroke: "lightblue")
            result.addChild(origin)
        
            let debugGroup = debugGroup(pictogram,
                                        id: "debug-\(id)",
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
        use.id =  blockIDPrefix + id
        
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
    
    func composeConnector(id: String, geometry: DiagramConnectorGeometry) {
        let group = SVGGroup()
        group.id = connectorIDPrefix + id

        if let box = geometry.boundingBox() {
            self.extendBoundingBox(box)
        }
        // TODO: Add stroke and fill colours
        
        if let path = geometry.linePath {
            let svgPath = SVGPath(path)
            svgPath.fill = "none"
            svgPath.stroke = "black"
            group.addChild(svgPath)
        }
        if let path = geometry.fillPath {
            let svgPath = SVGPath(path)
            svgPath.fill = "none"
            svgPath.stroke = "black"
            group.addChild(svgPath)
        }
        if let path = geometry.headArrowhead {
            let svgPath = SVGPath(path)
            svgPath.fill = "none"
            svgPath.stroke = "black"
            group.addChild(svgPath)
        }
        if let path = geometry.tailArrowhead {
            let svgPath = SVGPath(path)
            svgPath.fill = "none"
            svgPath.stroke = "black"
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

#endif
