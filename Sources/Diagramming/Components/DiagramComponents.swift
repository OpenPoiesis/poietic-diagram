//
//  DiagramComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/04/2026.
//

import PoieticCore

/// Component representing a diagram entity.
///
/// Diagram parts are referenced rom the diagram through the ``Depicts`` relationship.
///
public struct Diagram: Component {
    // Empty component
}

/// Relationship for parts of a diagram.
///
/// - SeeAlso: ``Diagram``.
///
public struct Depicts: Relationship {
    public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    public static var outgoingCardinality: Cardinality { .many }
    public init() { /* Empty */ }
}

// MARK: - Block

/// Component for diagram blocks – a graphical shape which is usually represented by a pictogram
/// and which can be connected with other blocks using connectors.
///
/// - SeeAlso: ``DiagramConnector``, ``BlockCreationSystem``
///
public struct DiagramBlock: Component {
    /// Position of the diagram block in the diagram or parent's coordinates.
    ///
    /// Uses same coordinates as the represented object.
    ///
    public let position: Vector2D
    
    /// Pictogram that is rendered as the diagram block.
    ///
    /// The pictogram's origin is placed at block's ``position``.
    ///
    public let pictogram: Pictogram?

    /// Primary label that is displayed underneath the pictogram.
    ///
    /// Typically a block name.
    ///
    public let label: String?

    /// Secondary label displayed underneath the primary label.
    ///
    /// Typically a note, formula, some constant or other attribute providing more details about the
    /// block.
    ///
    public let secondaryLabel: String?

    // FIXME: Deprecate. This is historical leftover.
    /// Collision shape of the block relative to the block position.
    ///
    /// If the block does not have a pictogram, then a circle shape with radius zero is returned.
    ///
    /// - SeeAlso: ``Pictogram/collisionShape``
    ///
    @available(*, deprecated, message: "Use scene node collision shape.")
    public let collisionShape: CollisionShape
    // TODO: Separate to "color tag"
    /// Name of a primary colour.
    ///
    /// The colour name is from a list of adaptable colour names.
    ///
    public let accentColor: AdaptableColorKey?
    
    // TODO: Rename to notationTypeName
    public let visualTypeName: String?

    /// Top-center point of a label.
    public var labelAnchorPosition: Vector2D {
        if let box = pictogram?.pathBoundingBox {
            return Vector2D(position.x, position.y + box.topLeft.y)
        }
        else {
            return position
        }
    }
    
    public var errorIndicatorAnchorOffset: Vector2D {
        if let box = pictogram?.maskBoundingBox {
            return Vector2D(0, box.bottomLeft.y)
        }
        else {
            return .zero
        }
    }
    
    public var valueIndicatorAnchorOffset: Vector2D {
        if let box = pictogram?.maskBoundingBox {
            return Vector2D(0, box.bottomLeft.y)
        }
        else {
            return .zero
        }
    }

    /// Create a new block.
    ///
    public init(position: Vector2D,
                pictogram: Pictogram? = nil,
                label: String? = nil,
                secondaryLabel: String? = nil,
                accentColor: AdaptableColorKey? = nil,
                visualTypeName: String? = nil) {
        self.position = position
        self.pictogram = pictogram
        self.label = label
        self.secondaryLabel = secondaryLabel
        if let pictogram {
            self.collisionShape = pictogram.collisionShape
        }
        else {
            self.collisionShape = CollisionShape(position: .zero, shape: .circle(0.0))
        }
        self.visualTypeName = visualTypeName
        self.accentColor = accentColor
    }
}

// MARK: - Connector
// TODO: Remove in favour of ConnectorStroke
/// Geometry of of a thin connector.
public struct ThinConnectorPaths {
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
///
/// ## Interaction
///
/// During interactive session, such as dragging, the temporary state of midpoints of a connector
/// are stored on the same entity as the connector in the ``PreviewMidpointsComponent``.
///
///
/// ## Related components
///
/// - ``PreviewMidpointsComponent`` on same entity: Preview of midpoints during interactive session.
///   Midpoints are in design coordinates.
/// - ``ConnectorCanvasNode`` visual representation of the connector entity, specific for a viewport.
///    Relates to the original diagram connector through ``RepresentationOf`` relationship.
///
/// - Note: This is not a relationship component. From modelling perspective it is a visual
///   representation of a first-class model object. That the model object relates two other
///   model objects together is irrelevant for the concept of visual representation itself.
///
public struct DiagramConnector: Component {
    // TODO: Change origin/target to Relationship components to be consistent with the world data model
    internal init(originID: RuntimeID,
                  targetID: RuntimeID,
                  glyph: ConnectorGlyph,
                  midpoints: [Vector2D] = []) {
        self.originID = originID
        self.targetID = targetID
        self.glyph = glyph
        self.midpoints = midpoints
    }
    
    /// Name of connector style.
    ///
    /// Refers to a style defined in ``Notation/connectorGlyphs``.
    ///
    public let glyph: ConnectorGlyph
    
    /// ID of the origin diagram block.
    ///
    /// The  runtime entity must have ``DiagramBlock`` component.
    public let originID: RuntimeID

    /// ID of the target diagram block.
    ///
    /// The  runtime entity must have ``DiagramBlock`` component.
    public let targetID: RuntimeID
    
    /// Optional intermediate midpoints the connector routes through.
    public let midpoints: [Vector2D]
}

/// Created from ``DiagramConnector`` and blocks by ``ConnectorGeometrySystem``.
///
/// - SeeAlso: ``DiagramConnector``, ``ConnectorPreview``
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
        // TODO: Precompute. Have something like SelectionOutlineGeometry component.
        return wire.inflated(by: margin)
    }
}


