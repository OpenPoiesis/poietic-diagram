//
//  StatusComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//

import PoieticCore

/// Position of an entity in hierarchical structures within its parent or owning entity.
///
public struct LocalPosition: Component {
    public init(position: Vector2D) {
        self.position = position
    }
    
    public let position: Vector2D
}

/// Transient component for user-interaction session of a entities, such as diagram block.
///
/// **Read By:**
/// - ``PresentationBuilder`` uses the component to override ``DiagramBlock/position`` of diagram
///   blocks.
/// **Set By:**
/// - Interactive tools, such as canvas tools in an application, should set the component
///   during interactive session, such as dragging. The preview position is set in world
///   coordinates on design objects.
///
/// Removal of the component is in application's responsibility.
///
public struct PreviewPosition: Component {
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
/// - ``PresentationBuilder`` uses the component to override ``DiagramConnector/midpoints`` of
///   diagram connectors.
///   
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
