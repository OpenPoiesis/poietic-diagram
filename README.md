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

Example output diagram:

![Example Stock-and-Flow diagram generated with poietic-tool](Documentation/example-output-diagram.svg)

## Tool

The package comes with an utility `pictogram` that is used to extract pictograms from SVG files and
to build pictogram collections.

Installation:

```
./install
```

Use:
```
OVERVIEW: Tool to manipulate pictograms for Diagramming and Poietic tools

USAGE: pictogram <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  extract                 Extract pictogram
  collect                 Create a pictogram collection
  preview                 Create an image from a pictogram
  catalog                 Create a catalog preview of pictograms

  See 'pictogram help <subcommand>' for detailed help.
```

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
- Mask shape
- Collision shape
- Origin point
- Bounding box

The SVG must contain elements (groups) with the following IDs:

- `pictogram` (required) - Pictogram path
    - Can be a `g` group element or any direct graphic element, no `use`, no `text`.
    - All style (fill, line) is ignored
    - Path is considered a wire-frame
- `collision` (required) - Collision shape
    - Must be either a group `g` element or a simple shape element.
    - Allowed shapes: `circle`, `ellipse` (converted to rectangle), `rectangle`,
      `polygon`, `polyline` (treated as polygon), `path` (must contain only line-to elements)
- `origin` – Origin point
    - Must be a circle element, where the origin will be the circle center
    - Specifies pictogram origin. If not provided, then center of the collision shape is used.
- `mask` – Selection outline mask
    - Can be a `g` group element or any direct graphic element, no `use`, no `text`.
    - All style (fill, line) is ignored
    - Path is considered a filled curve

The pictogram is extracted from SVG as follows:

1. Path is extracted from element with ID `pictogram` by converting the element and its children to
  bezier path.
    1. Element is converted to bezier path
    2. All transformations from the root element will be combined and applied to the path
    3. For group elements all paths will be combined into a single path.
2. Collision is extracted from element with ID `collision`.
3. Mask is extracted from element with ID `collision`.
4. Origin point is extracted from element with ID `origin`.
    - If origin is not present, then center of the shape is used.
    - If the shape is a polygon, then centroid of the polygon is used.
5. Path, mask and collision shape are offset by the origin.

## See Also:

- [Poietic Assets](https://github.com/OpenPoiesis/poietic-assets) – collection of sources for
  assets used in the Open Poiesis project

## Author

- [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
