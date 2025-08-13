# Diagramming

Diagramming is a Swift package for making schemas composed of blocks and connectors. This is a part
of [OpenPoiesis Project](https://github.com/openpoiesis/).

Main features:

- Pictogram collections with geometry and pictogram layout metadata
- Connector to shape touch point calculation using collision shapes
- Connector vector representation (path) calculation
- Extraction of pictograms from SVG images
- Export of diagrams into SVG

 Note: Functionality requirements are driven by the needs of the Open Poiesis applications, such as
 [Poietic Playground](https://github.com/openpoiesis/poietic-playground)
 and [Poietic Tool](https://github.com/OpenPoiesis/poietic-tool).

**IMPORTANT: This is a prototype**

## Pictogram Creation

The package contains a tool called `pictogram`, which can be used to:

- Extract pictogram from a SVG file
- Create a pictogram collection (used by Poietic applications)
- Preview a pictogram (convert it to a SVG file)
- Create a pictogram catalog sheet for previewing

Use `pictogram --help` to learn more.


Building the tool:

```
swift build
```

Running the pictogram tool:

```
swift run pictogram --help
```

### Anatomy of Pictogram as SVG

Pictogram is described by:

- Bezier path
- Collision shape
- Mask shape (usually the same as the collision shape)
- Origin point
- Bounding box

The pictogram can be defined in a SVG file where the structure must follow the following
requirements:

- Pictogram path is stored in an element with ID `pictogram` (required)
    - Must contain only direct graphic elements (no `use`, no `text`)
    - All style (fill, line) is ignored
    - Path is considered a wire-frame
- Pictogram shape is stored in an element with ID `shape` (required)
    - Must be either a group `g` element or a simple shape element.
    - Allowed shapes: `circle`, `ellipse` (converted to rectangle), `rectangle`,
      `polygon`, `polyline` (treated as polygon), `path` (must contain only line-to elements)
- Origin point with ID `origin` (optional)
    - Must be a circle element, where the origin will be the circle center

The pictogram is extracted from SVG as follows:

1. Path is extracted from element with ID `pictogram` by converting the element and its children to
  bezier path.
    1. Element is converted to bezier path
    2. All transformations from the root element will be combined and applied to the path
    3. For group elements all paths will be combined into a single path.
2. Shape is extracted from element with ID `shape`.
3. Origin point is extracted from element with ID `origin`.
    - If origin is not present, then center of the shape is used.
    - If the shape is a polygon, then centroid of the polygon is used.
3. Bounding box is computed from the combined bezier path.

## Author

- [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
