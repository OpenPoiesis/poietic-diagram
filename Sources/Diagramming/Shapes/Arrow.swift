//
//  Arrow.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

public enum ThinArrowheadType: CaseIterable {
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

    /// Offset of the point where the arrow line touches the head from the arrow endpoint.
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

public enum FatArrowheadType: CaseIterable {
    case none
    case regular
    
    public func touchPointOffset(_ size: Double) -> Double {
        switch self {
        case .none:
            return 0
        case .regular:
            return size
        }
    }
}
