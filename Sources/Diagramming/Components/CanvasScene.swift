//
//  Scene.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//
import PoieticCore

// TODO: Nested relationship structures in CanvasNode: reconsider their location. Does not feel natural.
//

/// Tag component for a diagram scene root.
///
///  Expected components:
///  - ``ViewportState``
///  Expected relationships:
///  - ``RepresentationOf`` with ``Diagram`` target.
///
/// Children  of a diagram scene are ``DiagramSceneNode``.
///
///
public struct DiagramScene: Component {
    /// Flag component stating that the diagram scene requires re-layout.
    ///
    /// Set on:
    /// - frame change
    /// - style change
    ///
    public struct LayoutDirty: Component {}
    /// Flag component stating that the diagram scene requires re-computation of geometry.
    ///
    /// Set on:
    /// - frame change
    /// - viewport change
    /// - interactive preview
    /// - style change
    ///
    public struct GeometryDirty: Component {}
    // Empty (for now)
}


/// Tag component for all diagram canvas scene nodes.
///
/// Relationships:
/// - ``ChildOf`` – parent node or ``DiagramScene``
/// - ``Owner`` – root of the canvas – ``DiagramScene`` entity
///
public struct DiagramSceneNode: Component {
    
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

/// Primary component of an entity representing a block diagram scene node.
///
/// Related components that are expected to be associated with the same entity:
///
/// - ``CanvasNode``
/// - ``BlockCanvasNode``
/// - ``PositionComponent`` – derived from ``DiagramBlock``
/// - ``PreviewPositionComponent`` – associated during interactive preview, takes precedence before
///   the position component, if present
/// - ``Visibility``
/// - ``Interactivity``
/// - ``CanvasNodeStyle`` typically with class ``StyleClass/block``
/// - ``CollisionShape`` – to determine touch points for connector geometry and for hit testing
///    through the touch region component.
/// - ``TouchRegion`` – derived from collision shape, in absolute scene coordinates.
///
/// Relationships:
///
/// | Relationship | Target Entity | Primary Component |
/// |---|---|---|
/// | ``CanvasNode/ChildOf`` | canvas node or scene if it is root block | ``CanvasNode`` or ``DiagramScene``
/// | ``CanvasNode/OwnedBy`` | scene | ``DiagramScene``
/// | ``CanvasNode/Pictogram`` | block pictogram | ``PictogramCanvasNode``
/// | ``CanvasNode/Pictogram`` | block pictogram | ``PictogramCanvasNode``
/// | ``CanvasNode/PrimaryLabel`` | primary block label (name) | ``LabelCanvasNode``
/// | ``CanvasNode/SecondaryLabel`` | secondary block label (formula or value) | ``LabelCanvasNode``
/// | ``CanvasNode/ValueIndicator`` | value indicator | ``ValueIndicatorCanvasNode``
/// | ``CanvasNode/IssueIndicator`` | issue indicator | ``IssueIndicatorCanvasNode``
///
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

