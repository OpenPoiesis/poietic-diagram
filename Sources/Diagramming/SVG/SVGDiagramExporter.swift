//
//  SVGExporter.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

import PoieticCore

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
        self.bbox = self.bbox.union(box)
    }
    
    public func append(_ element: SVGElement) {
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
    

    /// Return symbol ID for given pictogram.
    ///
    /// If there is no symbol for given pictogram, new symbol is created.
    ///
    public func symbolForPictogram(_ pictogram: Pictogram) -> String {
        let pictogramID = String(describing: ObjectIdentifier(pictogram))
        if let symbol = symbols[pictogramID] {
            return symbol.id! // We always have symbol ID set
        }
        print("Registering symbol \(pictogram.name) -> \(pictogramID)")
        
        let name = pictogram.name
        let id = pictogramSymbolIDPrefix + name
        let path = SVGPath(pictogram.path)

        // TODO: Let the use of the symbol decide colors
        path.fill = "none"
        path.stroke = "black"
//        path.strokeWidth = style.pictogramLineWidth
        
        let group = SVGGroup()
        group.addChild(path)
        
        let symbol = SVGSymbol()
        symbol.addChild(group)
        symbol.id = id
        symbols[pictogramID] = symbol

        return id
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
    
    public func render(_ scene: RuntimeEntity, style: SVGDiagramStyle, to path: String) throws {
        let image = render(scene, style: style)
        let writer = SVGWriter()
        try writer.writeToFile(image, path: path)
    }

    public func render(_ scene: RuntimeEntity, style: SVGDiagramStyle) -> SVGImage {
        let context = SVGDiagramSceneRendererContext(style: style)
        self.render(scene, context: context)
        
        let image = SVGImage()
        
        for symbol in context.symbols.values {
            image.addChild(symbol)
        }
        
        for element in context.elements {
            image.addChild(element)
        }
        image.viewBox = SVGViewBox(context.bbox)
        image.width = context.bbox.width
        image.height = context.bbox.height

        return image
    }
    
    public func renderBlock(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        // TODO: Separate pictogram rendering into renderPictogram(...)
        guard let pictogramNode: RuntimeEntity = entity.target(CanvasNode.Pictogram.self),
              let pictComp: PictogramCanvasNode = pictogramNode.component()
        else { return }

        // TODO: Color
        let pictogram = pictComp.pictogram
        let symbolID = context.symbolForPictogram(pictogram)
        
        let symbol = SVGUse()
        symbol.x = context.currentTransform.origin.x
        symbol.y = context.currentTransform.origin.y
        symbol.href = "#" + symbolID
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

        context.append(symbol)
        let box = pictogram.pathBoundingBox.translated(context.currentTransform.origin)
        context.extendBoundingBox(box)
        // TODO: Highlights (selection)
    }
    
    public func renderPictogram(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        // TODO: Move code from render block here.
        debugPrint("WARNING: \(#function) not implemented")
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
            if stroke.isFilled { svgPath.fill = elementStyle?.fill }
            else { svgPath.fill = "none" }

            svgPath.stroke = elementStyle?.stroke
            svgPath.strokeWidth = elementStyle?.strokeWidth ?? 1.0
            group.addChild(svgPath)
        }
        if let path = stroke.headArrowhead {
            let svgPath = SVGPath(path)
            if stroke.isFilled { svgPath.fill = elementStyle?.fill }
            else { svgPath.fill = "none" }

            svgPath.stroke = elementStyle?.stroke
            svgPath.fill = elementStyle?.fill
            svgPath.strokeWidth = elementStyle?.strokeWidth ?? 1.0
            group.addChild(svgPath)
        }
        if let path = stroke.tailArrowhead {
            let svgPath = SVGPath(path)
            if stroke.isFilled { svgPath.fill = elementStyle?.fill }
            else { svgPath.fill = "none" }

            svgPath.stroke = elementStyle?.stroke
            svgPath.fill = elementStyle?.fill
            svgPath.strokeWidth = elementStyle?.strokeWidth ?? 1.0
            group.addChild(svgPath)
        }

        if let geometry: ConnectorGeometry = entity.component() {
            let circleO = SVGCircle(center: geometry.originPoint, radius: 4.0)
            circleO.stroke = "green"
            let circleT = SVGCircle(center: geometry.targetPoint, radius: 4.0)
            circleT.stroke = "red"
            group.addChild(circleO)
            group.addChild(circleT)
        }
        
        context.append(group)
    }

    public func renderLabel(_ entity: PoieticCore.RuntimeEntity, context: Context) {
        guard let label: LabelCanvasNode = entity.component()
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
        element.x = context.currentTransform.origin.x
        element.y = context.currentTransform.origin.y

        element.textAnchor = "middle"
        if let labelStyle = style.classes[styleClass] {
            element.fontSize = labelStyle.fontSize
            element.fontFamily = labelStyle.fontName
            element.fontWeight = labelStyle.fontWeight
            element.fontStyle = labelStyle.fontStyle
        }

        context.append(element)
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

        let length = style.metric(.colorSwatchSize, default: ColorSwatchCanvasNode.DefaultSize)
        let size = Vector2D(x: length, y: length)
        
        let element = SVGRectangle(rect: Rect2D(center: .zero, size: size))
        element.stroke = style.classes[styleClass]?.stroke
        element.fill = style.adaptableColor(swatch.colorKey)
        context.append(element)
    }
}
