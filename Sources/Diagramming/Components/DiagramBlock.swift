//
//  DiagramBlock.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/07/2026.
//
import PoieticCore

/// Component for diagram blocks – a graphical shape which is usually represented by a pictogram
/// and which can be connected with other blocks using connectors.
///
/// Objects with `DiagramBlock` component are expected to have ``DiagramObject`` tag
/// as well.
///
/// - SeeAlso: ``DiagramConnector``, ``DiagramObject``, ``BlockCreationSystem``
///
public struct DiagramBlock: Component {
    /// Position of the diagram block in the diagram or parent's coordinates.
    ///
    /// Uses same coordinates as the represented object.
    ///
    public let position: Vector2D
    
    /// Pictogram that is rendered as the diagram block.
    ///
    /// The pictogram's origin is placed at block's ``position``.
    ///
    public let pictogram: Pictogram?

    /// Primary label that is displayed underneath the pictogram.
    ///
    /// Typically a block name.
    ///
    public let label: String?

    /// Secondary label displayed underneath the primary label.
    ///
    /// Typically a note, formula, some constant or other attribute providing more details about the
    /// block.
    ///
    public let secondaryLabel: String?

    /// Name of a primary colour.
    ///
    /// The colour name is from a list of adaptable colour names.
    ///
    public let accentColor: AdaptableColorKey?
    
    // TODO: Rename to notationTypeName
    public let visualTypeName: String?

    /// Top-center point of a label.
    public var labelAnchorPosition: Vector2D {
        if let box = pictogram?.pathBoundingBox {
            return Vector2D(position.x, position.y + box.bottomLeft.y)
        }
        else {
            return position
        }
    }
    
    public var errorIndicatorAnchorOffset: Vector2D {
        if let box = pictogram?.maskBoundingBox {
            return Vector2D(0, box.topLeft.y)
        }
        else {
            return .zero
        }
    }
    
    public var valueIndicatorAnchorOffset: Vector2D {
        if let box = pictogram?.maskBoundingBox {
            return Vector2D(0, box.topLeft.y)
        }
        else {
            return .zero
        }
    }

    /// Create a new block.
    ///
    public init(position: Vector2D,
                pictogram: Pictogram? = nil,
                label: String? = nil,
                secondaryLabel: String? = nil,
                accentColor: AdaptableColorKey? = nil,
                visualTypeName: String? = nil) {
        self.position = position
        self.pictogram = pictogram
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.visualTypeName = visualTypeName
        self.accentColor = accentColor
    }
}

