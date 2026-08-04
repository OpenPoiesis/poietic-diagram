//
//  ShapeStyle.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

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
