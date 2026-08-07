//
//  Scene.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//
import PoieticCore

/// Tag component for a diagram scene root.
///
/// A diagram scene is the **concrete visual representation of a diagram**
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
/// - Scene is owned by a single view (or presenter). Two views of the same diagram use
///   separate scenes.
/// - A scene represents exactly one diagram (through `RepresentationOf` towards ``Diagram``).
///
/// Required relationships:
///  - ``RepresentationOf`` with ``Diagram`` target.
///
/// Expected components:
///  - ``ViewportState``. If not present, then viewport with offset (0,0) and zoom of 1 is used.
///
/// Ephemeral components:
/// - ``LayoutDirty`` – Set on data change, style change, scene sync
/// - ``InteractionDirty`` – Set on geometry change, data change, scene sync
/// - ``ViewportDirty`` – Set on by Pan/zoom
///
/// ## Scene Hierarchy
///
/// Scene nodes are **shallow** — children are annotations and indicators, not recursive
/// block structures. The scene root (`DiagramScene`) is NOT a `SceneNode` — it has no position,
/// no style, no interactivity.
///
/// An example of a scene hierarchy. The children are related to their parent through ``ChildOf``
/// relationship. Some of known children have specific named parent-to-child relationship.
///
/// ```
/// DiagramScene                        ← root, tag component
/// ├── BlockSceneNode                  ← represents a DiagramBlock
/// │   ├── PictogramSceneNode          ← draws the shape
/// │   ├── LabelSceneNode (primary)    ← child, via `PrimaryLabel` relationship
/// │   ├── LabelSceneNode (secondary)  ← child, via SecondaryLabel relationship
/// │   ├── ValueIndicatorSceneNode     ← child, via ValueIndicator relationship
/// │   ├── IssueIndicatorSceneNode     ← child, via IssueIndicator relationship
/// │   └── ColorSwatchSceneNode        ← child, via ColorSwatch relationship
/// ├── ConnectorSceneNode              ← top-level, represents a DiagramConnector
/// │   └── (no children — geometry is self-contained in components)
/// └── Handle entities (app-defined)   ← created by tools, ChildOf scene
/// ```
///
/// Diagram scene has children with ``SceneNode`` tag.
///
///
/// ## Geometry
///
/// The node geometry is pre-computed by the ``DiagramSceneComposer`` once, and then reused for
/// rendering and interaction.
///
/// Geometry-related components are ``PositionComponent``, ``ConnectorWire``, ``ConnectorGeometry``.
/// Interaction geometry is stored in``TouchRegion`` for interactive scene nodes.
///
public struct DiagramScene: Component {
    public init() { /* Empty */ }
}

