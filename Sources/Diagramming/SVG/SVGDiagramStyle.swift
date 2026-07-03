//
//  SVGDiagramStyle.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/07/2026.
//

import PoieticCore

public struct SVGDiagramStyle: Sendable {
    public static let Default = SVGDiagramStyle(
        classes: [
            .pictogram:SVGShapeStyle(),
            .primaryLabel:SVGShapeStyle(fontName: "IBM Plex Sans", fontSize: 18.0, fontWeight: "600"),
            .secondaryLabel:SVGShapeStyle(fontName: "IBM Plex Sans", fontSize: 14.0, fontWeight: "200"),
        ]
    )

    public var classes: [StyleClass:SVGShapeStyle]
    public var adaptableColors: [AdaptableColorKey:String]
    public init(classes: [StyleClass:SVGShapeStyle], adaptableColors: [AdaptableColorKey:String] = [:]) {
        self.classes = classes
        self.adaptableColors = adaptableColors
    }
    public func adaptableColor(_ key: AdaptableColorKey) -> String {
        if let color = adaptableColors[key] {
            return color
        }
        else {
            return key.rawValue
        }
    }
}

