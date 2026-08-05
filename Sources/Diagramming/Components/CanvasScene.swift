//
//  Scene.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//
import PoieticCore

/// Tag component for a diagram scene root.
///
///  Required relationships:
///  - ``RepresentationOf`` with ``Diagram`` target.
///
///  Expected components:
///  - ``ViewportState``. If not present, then viewport with offset (0,0) and zoom of 1 is used.
///
/// Children  of a diagram scene are ``DiagramSceneNode``.
///
public struct DiagramScene: Component {
    public init() { /* Empty */ }
}

/// Flag component stating that the diagram scene requires re-layout.
///
public struct LayoutDirty: Component { public init() {} }
/// Flag stating that the viewport of a given scene was changed.
public struct ViewportDirty: Component { public init() {} }

// TODO: Nested relationship structures in SceneNode: reconsider their location. Does not feel natural on one hand, on the other, we do not want to pollute the global namespace.

/// Tag component for all diagram canvas scene nodes.
///
/// Relationships:
/// - ``ChildOf`` – parent node or ``DiagramScene``
/// - ``Owner`` – root of the canvas – ``DiagramScene`` entity
///
public struct SceneNode: Component {
    /// Relationship tag for primary label of a diagram scene node.
    ///
    /// Usually used for a block name, derived from ``DiagramBlock/label``.
    ///
    public struct PrimaryLabel: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for secondary label of a diagram scene node.
    ///
    /// Usually used for a block formula, derived from ``DiagramBlock/secondaryLabel``.
    ///
    public struct SecondaryLabel: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a colour swatch node of a diagram scene node.
    ///
    /// Usually used for a block colour, derived from ``DiagramBlock/accentColor``.
    ///
    public struct ColorSwatch: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a value indicator scene node.
    ///
    public struct ValueIndicator: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a issue indicator scene node.
    ///
    public struct IssueIndicator: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a pictogram scene node.
    ///
    public struct Pictogram: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }
    
    public init() { /* Empty */ }

}


// MARK: - Block

/// Primary component of an entity representing a block diagram scene node.
///
/// Related components that are expected to be associated with the same entity:
///
/// - ``SceneNode``
/// - ``BlockSceneNode``
/// - ``PositionComponent`` – derived from ``DiagramBlock``
/// - ``PreviewPositionComponent`` – associated during interactive preview, takes precedence before
///   the position component, if present
/// - ``Visibility``
/// - ``Interactivity``
/// - ``SceneNodeStyle`` typically with class ``StyleClass/block``
/// - ``CollisionShape`` – to determine touch points for connector geometry and for hit testing
///    through the touch region component.
/// - ``TouchRegion`` – derived from collision shape, in absolute scene coordinates.
///
/// Relationships:
///
/// | Relationship | Target Entity | Primary Component |
/// |---|---|---|
/// | ``SceneNode/ChildOf`` | canvas node or scene if it is root block | ``SceneNode`` or ``DiagramScene``
/// | ``SceneNode/OwnedBy`` | scene | ``DiagramScene``
/// | ``SceneNode/Pictogram`` | block pictogram | ``PictogramSceneNode``
/// | ``SceneNode/Pictogram`` | block pictogram | ``PictogramSceneNode``
/// | ``SceneNode/PrimaryLabel`` | primary block label (name) | ``LabelSceneNode``
/// | ``SceneNode/SecondaryLabel`` | secondary block label (formula or value) | ``LabelSceneNode``
/// | ``SceneNode/ValueIndicator`` | value indicator | ``ValueIndicatorSceneNode``
/// | ``SceneNode/IssueIndicator`` | issue indicator | ``IssueIndicatorSceneNode``
///
public struct BlockSceneNode: Component {
    public init() { /* Empty */ }
}

public struct PictogramSceneNode: Component {
    public let pictogram: Pictogram
    public init(pictogram: Pictogram) {
        self.pictogram = pictogram
    }
}


public struct ColorSwatchSceneNode: Component {
    public static let DefaultSize: Double = 10.0
    public let colorKey: AdaptableColorKey
    
    init(colorKey: AdaptableColorKey) {
        self.colorKey = colorKey
    }
}

/// Text label node.
///
/// - Note: Font and colour of the node are specified in ``SceneNodeStyle`` component on the same
///   entity.
public struct LabelSceneNode: Component {
    public let text: String
    public let anchor: Vector2D
    
    public init(text: String,
                anchor: Vector2D = .zero) {
        self.text = text
        self.anchor = anchor
    }
}

public struct IssueIndicatorSceneNode: Component {
    public static let DefaultSize: Double = 10.0
    public init() { /* Empty */ }
}

/// Visual indicator of a numeric value in form of a bar.
///
/// Probes value using ``RuntimeEntity/numericProbe(:)``
/// of represented object (``ChildOf`` -> ``RepresentationOf``):
///
public struct ValueIndicatorSceneNode: Component {
    public static let DefaultSize = Vector2D(100, 20)
    /// Size of the value indicator in canvas/viewport coordinates.
    public let size: Vector2D
    public let orientation: Orientation

    public enum Orientation {
        case horizontal
        case vertical
    }

    public init(size: Vector2D, orientation: Orientation = .horizontal) {
        self.size = size
        self.orientation = orientation
    }
}


// MARK: - Connector

/// Primary component of a canvas node representing a connector.
///
/// Associated components:
/// - ``ConnectorWire``
/// - ``ConnectorStroke``
///
public struct ConnectorSceneNode: Component {
    /// Relationship tag for connector origin block. Relationship target is expected to be
    /// a ``BlockSceneNode``.
    ///
    public struct Origin: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for connector target block. Relationship target is expected to be
    /// a ``BlockSceneNode``.
    ///
    public struct Target: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    public init() { /* Empty */ }
}

