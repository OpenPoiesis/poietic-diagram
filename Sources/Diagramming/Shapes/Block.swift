//
//  Block.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 31/07/2025.
//

public class Block {
    public var id: Diagram.ElementID?
    public var position: Vector2D
    public var pictogram: Pictogram?
    public var label: String?
    public var secondaryLabel: String?
    // public var variation: String
    
    public init(id: Diagram.ElementID? = nil, position: Vector2D = .zero, pictogram: Pictogram? = nil,
                label: String? = nil, secondaryLabel: String? = nil) {
        self.id = id
        self.position = position
        self.pictogram = pictogram
        self.label = label
        self.secondaryLabel = secondaryLabel
    }

    /// Box that encapsulates the pictogram.
    public var pictogramBoundingBox: Rect2D {
        guard let pictogram else {
            return Rect2D(origin: position, size: .zero)
        }
        return Rect2D(
            origin: position - pictogram.origin + pictogram.boundingBox.origin,
//            origin: position - pictogram.boundingBox.origin,
            size: pictogram.boundingBox.size
        )
    }

    
    public func touchPoint(fromPoint: Vector2D) -> Vector2D {
        // TODO: Add magnet
        return position
    }
}
