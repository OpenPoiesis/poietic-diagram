# ``Diagramming``

Diagramming is an OpenPoiesis project package for representing and composing diagrams from design
objects.

## Overview

Diagramming is a Swift package for making schemas composed of blocks, connectors and various
annotations from an underlying model design.

Main features:

- **Notation**: collection of pictograms and connector glyphs that define visual representation of a design.
  - **Pictograms**: visual symbol with geometry, collision shape, mask and other layout related metadata.
  - **Connector Glyphs**: visual description of a connector between two diagram blocks (objects).
- **Presentation** is the _concrete visual representation of a diagram_ — a disposable,
  structured entity tree that contains everything needed for rendering and interaction. 
  It is a bridge between the abstract design model and a specific backend (Cairo surface, SVG image, etc.).
- **Geometry**: collection of geometry functions with a special focus on computation of connector
  touch points, arrow-heads, and routing through mid-points.
- **SVG Rendering**: Export of diagrams into a SVG image.

Utility features:

- Extraction of pictograms from SVG images, to create custom notations. Command-line tool named
  `pictogram` makes the functionality available.

- SeeAlso: - <doc:PictogramTool>

## Topics

### Diagram

- ``Diagram``
- ``Depicts``
- ``DiagramBlock``
- ``DiagramConnector``
- ``DirtyContent``

### Notation

- ``Notation``
- ``Pictogram``
- ``ConnectorGlyph``
- ``NotationRules``
- ``PictogramCollection``
- ``LineType``
- ``JoinType``
- ``CollisionShape``
- ``ThinArrowheadType``
- ``FatArrowheadType``
- ``Arrowhead``

### Presentation

- ``DiagramPresentation``
- ``Camera``

- ``PresentationNode``
- ``BlockNode``
- ``ConnectorNode``
- ``PictogramNode``
- ``ColorSwatchNode``
- ``LabelNode``
- ``IssueIndicatorNode``
- ``ValueIndicatorNode``
- ``Visibility``
- ``Interactivity``
- ``HitRegion``
- ``LayoutDirty``
- ``ViewportDirty``
- ``InteractionDirty``

### Presentation Builder

- ``PresentationBuilder``
- ``DiagramLayoutMetric``
- ``LayoutProvider``
- ``LayoutProvider``

### Style

- ``CanvasNodeStyle``
- ``StyleClass``
- ``StyleModifierSet``

### Rendering

- ``DiagramPresenter``
- ``RenderingOffset``

### Geometry

- ``AffineTransform``
- ``Geometry``
- ``Vector2D``
- ``Rect2D``
- ``LineSegment``

### SVG

- ``SVGDiagramStyle``
- ``SVGShapeStyle``
- ``SVGDiagramPresenter``
