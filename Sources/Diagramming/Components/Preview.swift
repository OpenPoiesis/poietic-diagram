//
//  Preview.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/11/2025.
//

import PoieticCore

// NOTE: These protocols and components are being incubated, they are not final.

/// Protocol to mark components that should be removed after a preview/dragging session ends.
public protocol PreviewComponent: Component {
    // Empty component protocol
}

public struct VisuallyDirty: Component {
    // Empty component, serves just as a flag.
    public init() {}
}

/// Component for user-interaction session of a connector.
///
/// - Important: The component must be destroyed when the drag or preview operation is concluded.
///
public struct BlockPreview: Component {
    public var position: Vector2D

    public init(position: Vector2D) {
        self.position = position
    }
}


public struct MidpointHandle: Component {
    public var index: Int
    public var position: Vector2D
}

/// Component for user-interaction sessions when a block or a larger selection is being moved.
public struct PreviewDelta: Component {
    /// Current delta from the original position of the moved object.
    public var positionDelta: Vector2D
}
