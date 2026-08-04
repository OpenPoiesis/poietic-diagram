//
//  Preview.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/11/2025.
//

import PoieticCore

/// Component for user-interaction session of a entities, such as diagram block.
///
/// ``DiagramSceneComposer`` uses the component to override ``PositionComponent`` of diagram
/// blocks.
///
/// Interactive tools should set the component during interactive session, such as dragging, on
/// an entity that serves as a source of truth for visual entities.
///
/// Coordinates are typically design coordinates.
///
/// - Important: The component must be destroyed when the drag or preview operation is concluded.
///
public struct PreviewPositionComponent: Component {
    public init(position: Vector2D) {
        self.position = position
    }
    
    public var position: Vector2D
}

/// Component for user-interaction session of a connector.
///
/// It is used to override ``DiagramConnector/midpoints``.
///
/// Interactive tools should set the component during interactive session, such as dragging, on
/// an entity that serves as a source of truth for visual entities.
///
/// Coordinates are typically design coordinates.
///
/// - Important: The component must be destroyed when the drag or preview operation is concluded.
///
public struct PreviewMidpoints: Component {
    public var midpoints: [Vector2D]
    public init(midpoints: [Vector2D]) {
        self.midpoints = midpoints
    }
}
