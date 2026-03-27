//
//  Preview.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/11/2025.
//

import PoieticCore

// NOTE: These protocols and components are being incubated, they are not final.

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

/// Component for user-interaction session of a connector.
///
/// This connector should be used as an override for ``DiagramConnector`` when computing ``DiagramConnectorGeometry``.
///
/// - Important: The component must be destroyed when the drag or preview operation is concluded.
///
public struct ConnectorPreview: Component {
    public var midpoints: [Vector2D]
    public init(midpoints: [Vector2D]) {
        self.midpoints = midpoints
    }
}

