//
//  Block.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 31/07/2025.
//

import PoieticCore

// TODO: Consider using PreviewDelta
public struct PreviewPosition: Component {
    public var position: Vector2D
}

public struct PreviewDelta: Component {
    public var positionDelta: Vector2D
}

/// Diagram block – a graphical shape which is usually represented by a pictogram and which
/// can be connected with other blocks using connectors.
///
/// - SeeAlso: ``Connector``
/// 
public class Block {
    public var objectID: ObjectID?
    public var tag: Int?

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

    /// Collision shape of the block relative to the block position.
    ///
    /// If the block does not have a pictogram, then a circle shape with radius zero is returned.
    ///
    /// - SeeAlso: ``Pictogram/collisionShape``
    /// 
    public var collisionShape: CollisionShape {
        pictogram?.collisionShape
        ?? CollisionShape(position: position, shape: .circle(0.0))
    }
    
    
    /// Name of a primary colour.
    ///
    /// The colour name is from a list of adaptable colour names.
    ///
    public var colorName: String?

    /// Create a new block.
    ///
    public init(objectID: ObjectID? = nil,
                tag: Int? = nil,
                position: Vector2D = .zero,
                pictogram: Pictogram? = nil,
                label: String? = nil,
                secondaryLabel: String? = nil,
                colorName: String? = nil)
    {
        self.objectID = objectID
        self.tag = tag
        self.position = position
        self.pictogram = pictogram
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.colorName = colorName

    }

    public func containsTouch(at point: Vector2D, radius: Double=1.0) -> Bool {
        let relativePoint = point - position
        let touch = CollisionShape(position: relativePoint, shape: .circle(radius))
        return touch.collide(with: collisionShape)
    }

}

public struct BlockPositionComponent: Component {
    public let position: Vector2D = .zero
}

public struct BlockComponent: NEWDiagramObject, Component {
    
    public let representedObjectID: ObjectID?
    /// Position of the block within its parent.
    ///
    /// Uses same coordinates as the represented object.
    ///
    /// The position property is also used to update represented object's position when block is
    /// moved on a canvas.
    ///
    public let position: Vector2D
    
    public let pictogram: Pictogram?
    public let label: String?
    public let secondaryLabel: String?
    public let collisionShape: CollisionShape
    // TODO: Separate to "color tag"
    public let accentColorName: String?
    public let visualTypeName: String?

    public init(representedObjectID: ObjectID? = nil,
                position: Vector2D,
                pictogram: Pictogram? = nil,
                label: String? = nil,
                secondaryLabel: String? = nil,
                accentColorName: String? = nil,
                visualTypeName: String? = nil) {
        self.representedObjectID = representedObjectID
        self.position = position
        self.pictogram = pictogram
        self.label = label
        self.secondaryLabel = secondaryLabel
        if let pictogram {
            self.collisionShape = pictogram.collisionShape
        }
        else {
            self.collisionShape = CollisionShape(position: position, shape: .circle(0.0))
        }
        self.visualTypeName = visualTypeName
    }
}
