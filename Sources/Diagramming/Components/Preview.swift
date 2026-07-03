//
//  Preview.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/11/2025.
//

import PoieticCore

// Components for interactive preview.
//
// Naming convention: all components start with Preview* prefix.


/// Component for user-interaction session of a connector.
///
/// - Important: The component must be destroyed when the drag or preview operation is concluded.
///
@available(*, deprecated, message: "Use PreviewPosition")
public struct BlockPreview: Component {
    public var position: Vector2D

    public init(position: Vector2D) {
        self.position = position
    }
}

/// Component for user-interaction session of a connector.
///
/// This connector should be used as an override for ``DiagramConnector`` when computing ``DiagramConnectorGeometry``.
///
/// - Important: The component must be destroyed when the drag or preview operation is concluded.
///
@available(*, deprecated, message: "Use PreviewMidpoints")
public struct ConnectorPreview: Component {
    public var midpoints: [Vector2D]
    public init(midpoints: [Vector2D]) {
        self.midpoints = midpoints
    }
}

public struct PreviewMidpoints: Component {
    public var midpoints: [Vector2D]
    public init(midpoints: [Vector2D]) {
        self.midpoints = midpoints
    }
}
