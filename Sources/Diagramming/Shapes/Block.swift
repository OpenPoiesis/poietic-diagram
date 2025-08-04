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
    // public var variation: String
    
    public init(id: Diagram.ElementID? = nil, position: Vector2D = .zero, pictogram: Pictogram? = nil) {
        self.id = id
        self.position = position
        self.pictogram = pictogram
    }

    public func touchPoint(fromPoint: Vector2D) -> Vector2D {
        // TODO: Add magnet
        return position
    }
}
