//
//  Arrow.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

/// Arrowhead style for thin (stroke-based) connectors.
///
/// Each arrowhead type provides different visual representations for connector endpoints.
/// The arrowheads are drawn as separate stroke paths and can have different sizes at head and tail.
///
public enum ThinArrowheadType: CaseIterable, Sendable, Equatable {
    /// No arrow-head
    case none
    /// Simple stick arrowhead
    case stick
    /// Diamond-shaped arrowhead
    case diamond
    /// Box-shaped arrowhead, a square
    case box
    /// Bar or tee-shaped arrowhead (negative control)
    case bar
    /// X-like cross
    case nonNavigable
    /// Negative control (a bar at the endpoint)
    case negative
    /// Ball touching the endpoint
    case ball
    /// Ball centred at the endpoint
    case ballCenter

    /// Returns the offset distance from the arrow endpoint to where the line should connect to the arrowhead.
    ///
    /// Returns the offset distance from the arrow endpoint to where the line should connect to the arrowhead.
    ///
    /// - Parameter size: The size of the arrowhead
    /// - Returns: The offset distance in points
    ///
    public func touchPointOffset(_ size: Double) -> Double {
        switch self {
        case .none, .stick, .bar, .negative, .nonNavigable:
            return 0
        case .diamond, .box, .ball:
            return size
        case .ballCenter:
            return size / 2
        }
    }
}

/// Arrowhead styles for fat (filled polygon) connectors.
///
/// These arrowheads are integrated into the main connector polygon rather than being separate elements.
/// Used for filled connector styles where the entire connector is drawn as a single filled shape.
///
public enum FatArrowheadType: CaseIterable, Sendable {
    /// No arrowhead.
    case none
    
    /// Standard triangular arrowhead integrated into the filled connector polygon.
    case regular
    
    /// Returns the offset distance from the arrow endpoint to where the connector body should connect.
    ///
    /// - Parameter size: The size of the arrowhead
    /// - Returns: The offset distance in points
    ///
    public func touchPointOffset(_ size: Double) -> Double {
        switch self {
        case .none:
            return 0
        case .regular:
            return size
        }
    }
}
