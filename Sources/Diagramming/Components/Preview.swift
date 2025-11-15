//
//  Preview.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/11/2025.
//

import PoieticCore

// TODO: Keep one: Position or Delta
/// Component for user-interaction sessions when a block or a larger selection is being moved.
public struct PreviewPosition: Component {
    /// Current position of the moved object.
    public var position: Vector2D
}

/// Component for user-interaction sessions when a block or a larger selection is being moved.
public struct PreviewDelta: Component {
    /// Current delta from the original position of the moved object.
    public var positionDelta: Vector2D
}
