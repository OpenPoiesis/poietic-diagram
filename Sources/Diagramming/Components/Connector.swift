//
//  Connector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

import PoieticCore

/// Geometry of of a thin connector.
public struct ThinConnector {
    public let tail: BezierPath
    public let body: BezierPath
    public let head: BezierPath
}

/// A connector between two points with optional intermediate waypoints.
///
/// Connectors visually represent relationships or flows between diagram elements.
/// They can be rendered as either thin stroked paths or fat filled polygons,
/// with configurable arrowheads at either or both endpoints.
///
/// The connector supports:
///
/// - Direct connections between origin and target points
/// - Routing through intermediate midpoints
/// - Different visual styles (thin stroke vs fat polygon)
/// - Configurable arrowheads with various types and sizes
/// - Visual styling through ShapeStyle properties
///
public struct DiagramConnector: Component {
    internal init(representedObjectID: ObjectID? = nil,
                  originID: RuntimeEntityID,
                  targetID: RuntimeEntityID,
                  glyph: ConnectorGlyph,
                  midpoints: [Vector2D] = []) {
        self.representedObjectID = representedObjectID
        self.originID = originID
        self.targetID = targetID
        self.glyph = glyph
        self.midpoints = midpoints
    }
    
    public let representedObjectID: ObjectID?
    /// Name of connector style.
    ///
    /// Refers to a style defined in ``DiagramStyle/connectorStyles``.
    ///
    public let glyph: ConnectorGlyph
    
    /// ID of the origin diagram block.
    ///
    /// The  runtime entity must have ``DiagramBlock`` component.
    public let originID: RuntimeEntityID

    /// ID of the target diagram block.
    ///
    /// The  runtime entity must have ``DiagramBlock`` component.
    public let targetID: RuntimeEntityID
    
    /// Optional intermediate midpoints the connector routes through.
    public let midpoints: [Vector2D]
}

/// Created from ``ConnectorComponent`` and blocks by ``ConnectorGeometrySystem``.
///
/// - SeeAlso: ``ConnectorPreview``
///
/// - Note: When computing ``DiagramConnectorGeometry`` the ``ConnectorPreview`` and
///         ``BlockPreview`` components should be considered as an override.
///
public struct DiagramConnectorGeometry: Component {
    // TODO: Add dash style for line path
    // TODO: Add fill flags for head/tail

    public let originPoint: Vector2D
    public let targetPoint: Vector2D
    
    /// Points of a wire representation of the connector.
    ///
    /// Wire is a tessellated centre line that goes through mid-points.
    ///
    public let wire: BezierPath
    
    /// Bezier path of the line for a thin connector or outline for a thick connector.
    public let linePath: BezierPath?
    /// Bezier path to be filled for a thick connector.
    public let fillPath: BezierPath?
    /// Bezier path for tail arrow-head of a thin connector.
    public let tailArrowhead: BezierPath?
    /// Bezier path for head arrow-head of a thin connector.
    public let headArrowhead: BezierPath?
    
    /// Compute bounding box of the whole connector combining bounding boxes of all path properties.
    ///
    /// - Returns: Bounding box of all path properties or `nil` if there are no paths or when all
    ///            of the paths are empty.
    ///
    public func boundingBox() -> Rect2D? {
        var result: Rect2D? = nil

        if let path = linePath, let box = path.boundingBox {
            result = box
        }
        if let path = fillPath, let box = path.boundingBox {
            result = if let existing = result { existing.union(box) } else { box }
        }
        if let path = tailArrowhead, let box = path.boundingBox {
            result = if let existing = result { existing.union(box) } else { box }
        }
        if let path = headArrowhead, let box = path.boundingBox {
            result = if let existing = result { existing.union(box) } else { box }
        }
        return result
    }
    
    /// Simple outline for selection of the connector.
    ///
    /// Uses the wire points.
    ///
    public func outline(inflatedBy margin: Double = 10.0) -> BezierPath {
        return wire.inflated(by: margin)
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

