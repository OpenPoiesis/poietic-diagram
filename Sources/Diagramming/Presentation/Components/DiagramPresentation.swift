//
//  DiagramPresentation.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//
import PoieticCore

/// Tag component for a diagram presentation root.
///
/// A diagram presentation is the **disposable, concrete visual representation of a diagram**
/// — a structured entity tree that carries everything needed for rendering and interaction.
/// It is a bridge between the abstract design model and a specific backend
///  (Cairo surface, SVG image, etc.).
///
/// Purpose:
///
/// - Provide a renderable structure for backends to draw
/// - Provide geometry for hit-testing and interaction
///
/// Ownership:
///
/// - Presentation is owned by a single view (or presenter). Two views of the same diagram use
///   separate presentations.
/// - A presentation represents exactly one diagram (through `RepresentationOf` towards ``Diagram``).
///
/// Required relationships:
///  - ``RepresentationOf`` with ``Diagram`` target.
///
/// Expected components:
///  - ``Camera``. If not present, then camera with offset (0,0) and zoom of 1 is used.
///
/// Ephemeral components:
/// - ``LayoutDirty`` – Set on data change, style change, presentation sync
/// - ``InteractionDirty`` – Set on geometry change, data change, presentation sync
/// - ``ProjectionDirty`` – Set on by Pan/zoom
///
/// ## Presentation Hierarchy
///
/// Presentation nodes are **shallow** — children are annotations and indicators, not recursive
/// block structures. The presentation root (``DiagramPresentation``) is NOT a `PresentationNode` — it has no position,
/// no style, no interactivity.
///
/// An example of a presentation hierarchy. The children are related to their parent through ``ChildOf``
/// relationship. Some of known children have specific named parent-to-child relationship.
///
/// ```
/// DiagramPresentation                        ← root, tag component
/// ├── BlockNode                  ← represents a DiagramBlock
/// │   ├── PictogramNode          ← draws the shape
/// │   ├── LabelNode (primary)    ← child, via `PrimaryLabel` relationship
/// │   ├── LabelNode (secondary)  ← child, via SecondaryLabel relationship
/// │   ├── ValueIndicatorNode     ← child, via ValueIndicator relationship
/// │   ├── IssueIndicatorNode     ← child, via IssueIndicator relationship
/// │   └── ColorSwatchNode        ← child, via ColorSwatch relationship
/// ├── ConnectorNode              ← top-level, represents a DiagramConnector
/// │   └── (no children — geometry is self-contained in components)
/// └── Handle entities (app-defined)   ← created by tools, ChildOf presentation
/// ```
///
/// Diagram presentation has children with ``PresentationNode`` tag.
///
///
/// ## Geometry
///
/// The node geometry is pre-computed by the ``PresentationBuilder`` once, and then reused for
/// rendering and interaction.
///
/// Geometry-related components are ``PositionComponent``, ``ConnectorWire``, ``ConnectorGeometry``.
/// Interaction geometry is stored in``HitRegion`` for interactive presentation nodes.
///
public struct DiagramPresentation: Component {
    public init() { /* Empty */ }
}

