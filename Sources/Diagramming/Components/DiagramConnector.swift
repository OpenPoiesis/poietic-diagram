//
//  DiagramConnector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/07/2026.
//

import PoieticCore

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
/// Objects with `DiagramConnector` component are expected to have ``DiagramObject`` tag
/// as well.
///
/// ## Derived Components and Entities
///
/// Diagram connector is a logical component. Its visual representation are entities with
/// ``ConnectorCanvasNode`` that are related to the diagram connector via ``/PoieticCore/RepresentationOf``
/// relationship. The following components are derived from the diagram connector: ``ConnectorGeometry``,
/// ``ConnectorWire`` and ``ConnectorStroke``.
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
/// - SeeAlso:  ``DiagramObject``, ``Diagram``
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

/// Primary geometry of a connector, regardless of connector glyph.
///
/// Attached to entities with ``ConnectorCanvasNode`` by ``DiagramSceneComposer``.
///
/// - SeeAlso: ``ConnectorWire`` – used for hit testing and outlines,
///   ``ConnectorStroke`` – visual representation of a connector.
///
public struct ConnectorGeometry: Component {
    /// Points of a wire representation of the connector.
    /// Point of connector origin, typically a touch point with a collision shape of a block.
    public let originPoint: Vector2D
    /// Direction of an arrowhead towards the origin point.
    ///
    /// Usually computed from the first midpoint towards the origin or from the target point
    /// if there are no midpoints.
    public let originDirection: Vector2D

    /// Point of connector target, typically a touch point with a collision shape of a block.
    public let targetPoint: Vector2D
    /// Direction of an arrowhead towards the target point.
    ///
    /// Usually computed from the last midpoint towards the origin or from the origin point
    /// if there are no midpoints.
    public let targetDirection: Vector2D
    
    /// Midpoints used for body routing. The body is constructed from midpoints and ``LineType``.
    public let midpoints: [Vector2D]
    
    public init(origin: Vector2D,
                originDirection: Vector2D,
                target: Vector2D,
                targetDirection: Vector2D,
                midpoints: [Vector2D])
    {
        self.originPoint = origin
        self.originDirection = originDirection
        self.targetPoint = target
        self.targetDirection = targetDirection
        self.midpoints = midpoints
    }
}

/// Points of a connector wire used for hit testing and for selection outline.
/// Typically a tessellated points of a connector curve.
///
/// Attached to entities with ``ConnectorCanvasNode`` by ``DiagramSceneComposer``.
///
/// - SeeAlso: ``ConnectorGeometry``, ``ConnectorStroke``.
///
public struct ConnectorWire: Component {
    /// Points of a wire representation of the connector.
    ///
    /// Wire is a tessellated centre line that goes through mid-points.
    /// The array contains at least two points: the origin and the target point.
    ///
    public let points: [Vector2D]

    public init(points: [Vector2D])
    {
        self.points = points
    }
}

/// Visual representation of a connector.
///
/// Attached to entities with ``ConnectorCanvasNode`` by ``DiagramSceneComposer``.
/// Typically used by ``DiagramSceneRenderer``.
///
/// The connector stroke is created from ``ConnectorWire``, which describes basic connector
/// geometry and from ``ConnectorGlyph`` which defines actual shape and visual features of the
/// connector.
///
public struct ConnectorStroke: Component {
    public let body: BezierPath?
    public let headArrowhead: BezierPath?
    public let tailArrowhead: BezierPath?
    public let isFilled: Bool
}

// MARK: - Connector
// TODO: Remove in favour of ConnectorStroke
/// Geometry of of a thin connector.
public struct ThinConnectorPaths {
    public let tail: BezierPath
    public let body: BezierPath
    public let head: BezierPath
}

