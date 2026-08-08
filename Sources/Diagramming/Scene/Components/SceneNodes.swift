//
//  SceneNodes.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 07/08/2026.
//
import PoieticCore

/// Tag component for all diagram canvas scene nodes.
///
/// Scene nodes are children of ``DiagramScene`` or other diagram scene nodes. See diagram scene
/// documentation with more information about hierarchy.
///
/// ## Related Components
///
/// | Component | Required? | Notes |
/// |---|---|---|
/// | Concrete scene node | yes | Dispatch tag for rendering |
/// | `PositionComponent` | yes | Viewport coordinates. |
/// | `SceneNodeStyle` | yes | Class + modifiers (`.selected`, `.preview`, `.allowed`, `.notAllowed`) |
/// | `Interactivity` | no | Interactive nodes. ``TouchRegion`` is computed on nodes with ``Interactivity/interactive`` |
/// | `Visibility` | yes | Denotes whether the node is to be rendered (``Visibility/visible``) or not (``Visibility/hidden``) |
/// | `CollisionShape` | depends | Used to compute ``TouchRegion`` for blocks, labels and indicators. |
/// | `ConnectorWire` | depends | Required by ``ConnectorSceneNode``. Absolute wire path — recomputed on any geometry change. |
/// | `ConnectorStroke` | yes (connectors) | Filled/outlined wire path for rendering. |
/// | `ConnectorGeometry` | yes (connectors) | Internal — used to compute wire and stroke. |
///
/// ## Related Relationships
///
/// | Relationship | Required | Target |
/// |---|---|---|
/// | `ChildOf` | Yes | Scene root (top-level) or parent node (children) |
/// | `MemberOf` | Yes | Scene root |
/// | `RepresentationOf` | top-level only | The `DiagramBlock` or `DiagramConnector` entity. |
/// | `ConnectorSceneNode.Origin` | ``ConnectorSceneNode`` only | Origin block scene node |
/// | `ConnectorSceneNode.Target` | ``ConnectorSceneNode`` only | Target block scene node |

/// - Note: **PositionComponent** for connectors is usually zero, as connectors use midpoints which
/// are analogy to their position.
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
///
/// ## Styling
///
/// The typical block node has style class ``StyleClass/block``.
///
/// Styling metrics used for layout:
///
/// - Primary label padding from the block bottom: ``DiagramLayoutMetric/primaryLabelPadding``
/// - Secondary label padding from primary label: ``DiagramLayoutMetric/secondaryLabelPadding``
/// - Padding of the value indicator from the top ``DiagramLayoutMetric/valueIndicatorPadding``
///
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
/// Styling metrics: ``DiagramLayoutMetric/valueIndicatorPadding
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
/// Related components:
///
/// | Component | Created By | Notes |
/// |---|---|---|
/// | ``SceneNode`` | owner | Required. Includes all relevant scene node related components. |
/// | ``ConnectorGeometry`` | Scene Composer | Used to compute wire and stroke. |
/// | ``ConnectorWire`` | Scene Composer | Used to compute  ``TouchRegion``. Absolute wire path — recomputed on any geometry change. |
/// | ``ConnectorStroke`` | Scene Composer | Filled/outlined wire path for rendering. |
///
/// | Relationship | Target |
/// |---|---|
/// | `ChildOf` | Scene root (top-level) or parent node (children) |
/// | `MemberOf` | Scene root |
/// | `RepresentationOf` | The `DiagramBlock` or `DiagramConnector` entity. |
/// | ``ConnectorSceneNode/Origin`` |  Origin block scene node |
/// | ``ConnectorSceneNode/Target`` |  Target block scene node |
///
/// All relationships are required for the node to function properly.
///
/// - Note: ``PositionComponent`` is ignored on connector scene nodes.
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

