# Pictogram Command-line Tool

The _Diagramming_ package comes with a command-line utility `pictogram` that is used to extract
pictograms from SVG files and to build notations (pictogram collections).

Functionality:

- Extract pictogram from a SVG file 
- Create a pictogram collection (used by Poietic applications)
- Preview a pictogram (convert it to a SVG file)
- Create a pictogram catalog sheet for previewing

## Notes on Pictograms

Pictograms here are single line symbols without filled shapes. They are intended to be used for
screen rendering, vector graphics and for pen-plotting.

## Commands

| Command | Description |
+---+---+
| `extract` | Extract a single pictogram from a SVG file into a pictogram JSON file |
| `collect` | Create a collection of pictograms from multiple pictogram JSON files |
| `preview` | Create a SVG preview of a pictogram |
| `catalog` | Create a SVG catalog preview of multiple pictograms |
| `help` | See all available commands |


## Pictogram Creation

To create a pictogram from a SVG file use the `extract` command:

```bash
pictogram extract block.svg
```

Pictogram is described by:

- Bezier path
- Mask shape
- Collision shape
- Origin point
- Bounding box

The SVG must contain elements (groups) with the following IDs (`id` property):

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

## Example

A pictogram of a rectangle with a circle, let us call it `pictogram.svg`:

```svg
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="320" height="220" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" xmlns:serif="http://www.serif.com/" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;">
    <g id="Stock">
        <g id="pictogram">
            <rect x="0.0" y="0.0" width="300" height="200"/>
            <circle cx="150" cy="100" r="50"/>
        </g>
        <g id="mask">
            <rect x="-10.0" y="-10.0" width="320" height="220"/>
        </g>
        <g id="collision">
            <rect x="0.0" y="0.0" width="300" height="200"/>
        </g>
    </g>
</svg>
```

The following will create a pictogram file and then back pictogram preview from the pictogram file:

```sh
pictogram extract --pretty -o pictogram.json pictogram.svg
pictogram preview -o pictogram-preview.svg pictogram.json
```

Look at `pictogram-preview.svg` to see annotated pictogram.


## See Also:

- [Poietic Assets](https://github.com/OpenPoiesis/poietic-assets) – collection of sources for
  assets used in the Open Poiesis project

