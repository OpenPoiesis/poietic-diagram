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
