//
//  StatusComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//

import PoieticCore

/// Position of an entity.
///
/// Coordinates depend on the context of the entity. For design objects it is world coordinates,
/// for scene nodes ``SceneNode`` it is scene coordinates.
///
public struct PositionComponent: Component {
    public init(position: Vector2D) {
        self.position = position
    }
    
    public let position: Vector2D
}

/// Transient component for user-interaction session of a entities, such as diagram block.
///
/// **Read By:**
/// - ``DiagramSceneComposer`` uses the component to override ``PositionComponent`` of diagram
/// blocks.
/// **Set By:**
/// - Interactive tools, such as canvas tools in an application, should set the component
///   during interactive session, such as dragging. The preview position is set in world
///   coordinates on design objects.
///
/// Removal of the component is in application's responsibility.
///
public struct PreviewPositionComponent: Component {
    public init(position: Vector2D) {
        self.position = position
    }
    
    public var position: Vector2D
}

/// Transient component for user-interaction session of a connector.
///
/// It is used to override ``DiagramConnector/midpoints``.
///
/// **Read By:**
/// - ``DiagramSceneComposer`` uses the component to override ``PositionComponent`` of diagram
/// blocks.
/// **Set By:**
/// - Interactive tools, such as canvas tools in an application, should set the component
///   during interactive session, such as dragging a connector midpoint or when dragging a
///   selection that includes connectors. The preview position is set in world
///   coordinates on design objects.
///
/// Removal of the component is in application's responsibility.
///
public struct PreviewMidpoints: Component {
    public var midpoints: [Vector2D]
    public init(midpoints: [Vector2D]) {
        self.midpoints = midpoints
    }
}
