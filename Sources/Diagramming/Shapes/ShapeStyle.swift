//
//  ShapeStyle.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//


public struct ShapeStyle: Equatable {
    // TODO: Make colours optional, where nil = default
    public let lineWidth: Double
    public let lineColor: String
    public let fillColor: String

    public init(lineWidth: Double = 1.0,
                  lineColor: String = "black",
                  fillColor: String = "white") {
        self.lineWidth = lineWidth
        self.lineColor = lineColor
        self.fillColor = fillColor
    }
}
