//
//  SVGStyle.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 17/06/2026.
//


public struct SVGShapeStyle: Sendable {
    static let Default = SVGShapeStyle(
        stroke: nil,
        fill: nil,
        strokeWidth: 1.0,
        fontName: "Helvetica",
        fontSize: 10,
        fontWeight: nil,
        fontStyle: nil
    )

    public init(stroke: String? = nil,
                fill: String? = nil,
                strokeWidth: Double = 1.0,
                fontName: String? = nil,
                fontSize: Double = 10.0,
                fontWeight: String? = nil,
                fontStyle: String? = nil) {
        self.stroke = stroke
        self.fill = fill
        self.strokeWidth = strokeWidth
        self.fontName = fontName
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.fontStyle = fontStyle
    }
    
    public var stroke: String?
    public var fill: String?
    public var strokeWidth: Double

    public var fontName: String?
    public var fontSize: Double
    public var fontWeight: String?
    public var fontStyle: String?
}

#if false
/// Semantic style of a graphic defining its stroke and fill.
///
public struct SVGDiagramGraphicStyle {
    
    /// Semantic colour of a graphic's stroke.
    ///
    /// If `nil`, then the graphic is assumed to have no stroke.
    let strokeColor: String?

    /// Semantic colour of a graphic's fill.
    ///
    /// If `nil`, then the graphic is assumed to have no fill.
    let fillColor: String?
    
    /// Width of a stroke.
    ///
    /// Stroke width is ignored if ``strokeColorKey`` is nil.
    ///
    let strokeWidth: Double
    
    let fontName: String?
    let fontSize: Double
    let fontWeight: String
    let fontStyle: String
}
#endif
