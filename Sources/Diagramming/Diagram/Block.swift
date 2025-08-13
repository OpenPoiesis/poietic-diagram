//
//  Block.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 31/07/2025.
//

/// Diagram block – a graphical shape which is usually represented by a pictogram and which
/// can be connected with other blocks using connectors.
///
/// - SeeAlso: ``Connector``
/// 
public class Block {
    /// ID of the diagram block that uniquely identifies the block within the diagram.
    public var id: Diagram.ElementID?

    /// Position of the diagram block in the diagram or parent's coordinates.
    ///
    /// When the block is represented by a pictogram, then the ``Pictogram/origin`` is placed at
    /// the block position coordinates.
    ///
    public var position: Vector2D
    
    /// Pictogram that is rendered as the diagram block.
    ///
    /// The pictogram's origin is placed at block's ``position``.
    ///
    public var pictogram: Pictogram?
    
    /// Primary label that is displayed underneath the pictogram.
    ///
    /// Typically a block name.
    ///
    public var label: String?
    
    /// Secondary label displayed underneath the primary label.
    ///
    /// Typically a note, formula, some constant or other attribute providing more details about the
    /// block.
    ///
    public var secondaryLabel: String?

    /// Create a new block.
    ///
    public init(id: Diagram.ElementID? = nil, position: Vector2D = .zero, pictogram: Pictogram? = nil,
                label: String? = nil, secondaryLabel: String? = nil) {
        self.id = id
        self.position = position
        self.pictogram = pictogram
        self.label = label
        self.secondaryLabel = secondaryLabel
    }

    /// Box that encapsulates the pictogram in the diagram coordinates.
    public var pictogramBoundingBox: Rect2D {
        guard let pictogram else {
            return Rect2D(origin: position, size: .zero)
        }
        return Rect2D(
            origin: position - pictogram.origin + pictogram.boundingBox.origin,
            size: pictogram.boundingBox.size
        )
    }
}
