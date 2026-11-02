//
//  PresentationNodes.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 07/08/2026.
//
import PoieticCore

/// Tag component for all diagram presentation nodes.
///
/// Presentation nodes are children of ``DiagramPresentation`` or other diagram presentation nodes. See diagram presentation
/// documentation with more information about hierarchy.
///
/// ## Related Components
///
/// | Component | Required? | Notes |
/// |---|---|---|
/// | Concrete presentation node | yes | Dispatch tag for rendering |
/// | ``LocalPosition`` | yes | Viewport coordinates. |
/// | ``NodeStyle`` | yes | Class + modifiers (`.selected`, `.preview`, `.allowed`, `.notAllowed`) |
/// | ``Interactivity`` | no | Interactive nodes. ``HitRegion`` is computed on nodes with ``Interactivity/interactive`` |
/// | ``Visibility`` | yes | Denotes whether the node is to be rendered (``Visibility/visible``) or not (``Visibility/hidden``) |
/// | ``CollisionShape`` | depends | Used to compute ``HitRegion`` for blocks, labels and indicators. |
/// | ``ConnectorWire`` | depends | Required by ``ConnectorNode``. Absolute wire path — recomputed on any geometry change. |
/// | ``ConnectorStroke`` | yes (connectors) | Filled/outlined wire path for rendering. |
/// | ``ConnectorGeometry`` | yes (connectors) | Internal — used to compute wire and stroke. |
///
/// ## Related Relationships
///
/// | Relationship | Required | Target |
/// |---|---|---|
/// | `ChildOf` | Yes | Presentation root (top-level) or parent node (children) |
/// | `MemberOf` | Yes | Presentation root |
/// | `RepresentationOf` | top-level only | The `DiagramBlock` or `DiagramConnector` entity. |
/// | `ConnectorNode.Origin` | ``ConnectorNode`` only | Origin block presentation node |
/// | `ConnectorNode.Target` | ``ConnectorNode`` only | Target block presentation node |

/// - Note: **LocalPosition** for connectors is usually zero, as connectors use midpoints which
/// are analogy to their position.
///
/// Relationships:
/// - ``ChildOf`` – parent node or ``DiagramPresentation``
/// - ``Owner`` – root of the canvas – ``DiagramPresentation`` entity
///
public struct PresentationNode: Component {
    /// Relationship tag for primary label of a diagram presentation node.
    ///
    /// Usually used for a block name, derived from ``DiagramBlock/label``.
    ///
    public struct PrimaryLabel: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for secondary label of a diagram presentation node.
    ///
    /// Usually used for a block formula, derived from ``DiagramBlock/secondaryLabel``.
    ///
    public struct SecondaryLabel: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a colour swatch node of a diagram presentation node.
    ///
    /// Usually used for a block colour, derived from ``DiagramBlock/accentColor``.
    ///
    public struct ColorSwatch: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a value indicator presentation node.
    ///
    public struct ValueIndicator: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a issue indicator presentation node.
    ///
    public struct IssueIndicator: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for a pictogram presentation presentation.
    ///
    public struct Pictogram: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }
    
    public init() { /* Empty */ }

}



// MARK: - Block

/// Primary component of an entity representing a block diagram presentation node.
///
/// Related components that are expected to be associated with the same entity:
///
/// - ``PresentationNode``
/// - ``BlockNode``
/// - ``LocalPosition`` – derived from ``DiagramBlock``
/// - ``PreviewPosition`` – associated during interactive preview, takes precedence before
///   the position component, if present
/// - ``Visibility``
/// - ``Interactivity``
/// - ``NodeStyle`` typically with class ``StyleClass/block``
/// - ``CollisionShape`` – to determine hit points for connector geometry and for hit testing
///    through the hit region component.
/// - ``HitRegion`` – derived from collision shape, in absolute presentation coordinates.
///
/// Relationships:
///
/// | Relationship | Target Entity | Primary Component |
/// |---|---|---|
/// | `ChildOf` | canvas node or presentation if it is root block | ``PresentationNode`` or ``DiagramPresentation``
/// | `OwnedBy` | presentation | ``DiagramPresentation``
/// | ``PresentationNode/Pictogram`` | block pictogram | ``PictogramNode``
/// | ``PresentationNode/Pictogram`` | block pictogram | ``PictogramNode``
/// | ``PresentationNode/PrimaryLabel`` | primary block label (name) | ``LabelNode``
/// | ``PresentationNode/SecondaryLabel`` | secondary block label (formula or value) | ``LabelNode``
/// | ``PresentationNode/ValueIndicator`` | value indicator | ``ValueIndicatorNode``
/// | ``PresentationNode/IssueIndicator`` | issue indicator | ``IssueIndicatorNode``
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
public struct BlockNode: Component {
    public init() { /* Empty */ }
}

public struct PictogramNode: Component {
    public let pictogram: Pictogram
    public init(pictogram: Pictogram) {
        self.pictogram = pictogram
    }
}


public struct ColorSwatchNode: Component {
    public static let DefaultSize: Double = 10.0
    public let colorKey: AdaptableColorKey
    
    init(colorKey: AdaptableColorKey) {
        self.colorKey = colorKey
    }
}

/// Text label node.
///
/// - Note: Font and colour of the node are specified in ``NodeStyle`` component on the same
///   entity.
public struct LabelNode: Component {
    public let text: String
    public let anchor: Vector2D
    
    public init(text: String,
                anchor: Vector2D = .zero) {
        self.text = text
        self.anchor = anchor
    }
}

public struct IssueIndicatorNode: Component {
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
public struct ValueIndicatorNode: Component {
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
/// | ``PresentationNode`` | owner | Required. Includes all relevant presentation node related components. |
/// | ``ConnectorGeometry`` | presentation builder | Used to compute wire and stroke. |
/// | ``ConnectorWire`` | presentation builder | Used to compute  ``HitRegion``. Absolute wire path — recomputed on any geometry change. |
/// | ``ConnectorStroke`` | presentation builder | Filled/outlined wire path for rendering. |
///
/// | Relationship | Target |
/// |---|---|
/// | `ChildOf` | Presentation root (top-level) or parent node (children) |
/// | `MemberOf` | Presentation root |
/// | `RepresentationOf` | The `DiagramBlock` or `DiagramConnector` entity. |
/// | ``ConnectorNode/Origin`` |  Origin block presentation node |
/// | ``ConnectorNode/Target`` |  Target block presentation node |
///
/// All relationships are required for the node to function properly.
///
/// - Note: ``LocalPosition`` is ignored on connector presentation nodes.
///
public struct ConnectorNode: Component {
    /// Relationship tag for connector origin block. Relationship target is expected to be
    /// a ``BlockNode``.
    ///
    public struct Origin: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    /// Relationship tag for connector target block. Relationship target is expected to be
    /// a ``BlockNode``.
    ///
    public struct Target: Relationship {
        public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
        public init() { /* Empty */ }
    }

    public init() { /* Empty */ }
}

