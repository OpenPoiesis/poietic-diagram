//
//  ShapeStyle.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//


/// Visual styling properties for shapes and connectors.
///
/// Defines appearance characteristics including stroke width, stroke colour, and fill colour.
/// Used by connectors and other drawable elements to control their visual presentation.
///
public struct ShapeStyle: Equatable, Sendable {
    // TODO: Make colours optional, where nil = default
    
    /// The width of the stroke/outline in points.
    public let lineWidth: Double
    
    /// The colour of the stroke/outline as a string.
    public let lineColor: String
    
    /// The fill colour for closed shapes as a string.
    public let fillColor: String

    public init(lineWidth: Double = 1.0,
                lineColor: String = "black",
                fillColor: String = "white") {
        self.lineWidth = lineWidth
        self.lineColor = lineColor
        self.fillColor = fillColor
    }
}

/// Defines different line rendering styles for connectors.
///
/// Controls how lines are drawn between connector endpoints and through midpoints.
///
public enum LineType: CaseIterable, Sendable {
    /// Direct straight line connections between points.
    case straight
    
    /// Smooth curved line connections using Bezier curves that pass through midpoints.
    case curved
    
    /// Right-angled connections using only horizontal and vertical segments.
    case orthogonal
}

/// Defines how line segments are joined together at corners.
///
/// Used in fat connectors to control the appearance of polygon joins where line segments meet.
///
public enum JoinType: CaseIterable, Sendable {
    /// Sharp corners that create pointed joins.
    case miter
    
    /// Rounded corners that create curved joins.
    case round
    
    /// Cut-off corners that create angled flat joins.
    case bevel
}
