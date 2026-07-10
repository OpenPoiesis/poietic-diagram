//
//  Scene.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//
import PoieticCore

/// Tag component for a diagram scene root.
///
/// Children of a diagram scene are ``DiagramSceneNode``.
///
public struct DiagramCanvas: Component {
    // Empty (for now)
}


/// Tag component for all diagram canvas scene nodes.
///
public struct CanvasNode: Component {
    
    /// Relationship tag for primary label of a diagram scene node.
    ///
    /// Usually used for a block name, derived from ``DiagramBlock/label``.
    ///
    public struct PrimaryLabel: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

    /// Relationship tag for secondary label of a diagram scene node.
    ///
    /// Usually used for a block formula, derived from ``DiagramBlock/secondaryLabel``.
    ///
    public struct SecondaryLabel: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

    /// Relationship tag for a colour swatch node of a diagram scene node.
    ///
    /// Usually used for a block colour, derived from ``DiagramBlock/accentColor``.
    ///
    public struct ColorSwatch: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

    /// Relationship tag for a value indicator scene node.
    ///
    public struct ValueIndicator: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

    /// Relationship tag for a issue indicator scene node.
    ///
    public struct IssueIndicator: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

    /// Relationship tag for a pictogram scene node.
    ///
    public struct Pictogram: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

}


// MARK: - Block

/// Associated components:
/// - PictogramComponent
public struct BlockCanvasNode: Component { /* Tag component*/ }

public struct PictogramCanvasNode: Component {
    public let pictogram: Pictogram
}


public struct ColorSwatchCanvasNode: Component {
    public static let DefaultSize: Double = 10.0
    public let colorKey: AdaptableColorKey
    
    init(colorKey: AdaptableColorKey) {
        self.colorKey = colorKey
    }
}

/// Text label node.
///
/// - Note: Font and colour of the node are specified in ``CanvasNodeStyle`` component on the same
///   entity.
public struct LabelCanvasNode: Component {
    public let text: String
    public let anchor: Vector2D
    
    public init(text: String,
                anchor: Vector2D = .zero) {
        self.text = text
        self.anchor = anchor
    }
}

public struct IssueIndicatorCanvasNode: Component {
}

public struct ValueIndicatorCanvasNode: Component {
    static let DefaultSize = Vector2D(100, 20)
    /// Size of the value indicator in canvas/viewport coordinates.
    public let value: Double?
    public let bounds: ValueBounds
    public let size: Vector2D

    init(value: Double?, bounds: ValueBounds, size: Vector2D) {
        self.value = value
        self.bounds = bounds
        self.size = size
    }
}


// MARK: - Connector

/// Primary component of a canvas node representing a connector.
///
/// Associated components:
/// - ``ConnectorWire``
/// - ``ConnectorStroke``
///
public struct ConnectorCanvasNode: Component {
    /// Relationship tag for connector origin block. Relationship target is expected to be
    /// a ``BlockCanvasNode``.
    ///
    public struct Origin: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

    /// Relationship tag for connector target block. Relationship target is expected to be
    /// a ``BlockCanvasNode``.
    ///
    public struct Target: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    }

}

/// Primary geometry of a connector, regardless of connector glyph.
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
