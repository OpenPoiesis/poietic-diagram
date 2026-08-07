//
//  SVGDiagramStyle.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/07/2026.
//

import PoieticCore

public struct SVGDiagramStyle: Sendable {
    public static let DefaultFontSize: Double = 10.0

    public static let Default = SVGDiagramStyle(
        classes: [
            .normal:SVGShapeStyle(stroke: "black", fill: "gray"),
            .pictogram:SVGShapeStyle(),
            .primaryLabel:SVGShapeStyle(fontName: "IBM Plex Sans", fontSize: 18.0, fontWeight: "600"),
            .secondaryLabel:SVGShapeStyle(fontName: "IBM Plex Sans", fontSize: 14.0, fontWeight: "200", fontStyle: "italic"),
            .thinConnector:SVGShapeStyle(stroke: "black"),
            .fatConnector:SVGShapeStyle(stroke: "blue", fill: "azure"),
        ],
        metrics: [
            .primaryLabelPadding: 6.0,
            .secondaryLabelPadding: 2.0,
        ]
    )

    public var classes: [StyleClass:SVGShapeStyle]
    public var metrics: [DiagramLayoutMetric:Double]
    public var adaptableColors: [AdaptableColorKey:String]

    public init(classes: [StyleClass:SVGShapeStyle],
                adaptableColors: [AdaptableColorKey:String] = [:],
                metrics: [DiagramLayoutMetric:Double] = [:]) {
        self.classes = classes
        self.adaptableColors = adaptableColors
        self.metrics = metrics
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

extension SVGDiagramStyle: LayoutProvider {
    public func metric(_ metric: DiagramLayoutMetric, default defaultValue: Double) -> Double {
        return metrics[metric] ?? defaultValue
    }
    /// Rough estimate of text size.
    ///
    /// We treat the text as monospaced with character width being the same as font size
    /// (same units) and text height being 1.2 of font size to have safe padding.
    ///
    public func textExtents(_ text: String, class styleClass: StyleClass) -> Rect2D {
        let fontSize: Double = self.classes[styleClass]?.fontSize ?? Self.DefaultFontSize
        
        let width: Double = Double(text.count) * fontSize
        let height: Double = fontSize * 1.2
        
        return Rect2D(origin: .zero, size: Vector2D(x: width, y: height))
        
    }
}
