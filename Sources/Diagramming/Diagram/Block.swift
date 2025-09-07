//
//  Block.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 31/07/2025.
//

import PoieticCore

/// Diagram block – a graphical shape which is usually represented by a pictogram and which
/// can be connected with other blocks using connectors.
///
/// - SeeAlso: ``Connector``
/// 
public class Block: DiagramObject {
    public var objectID: ObjectID?
    public var tag: Int?

    /// Position of the diagram block in the diagram or parent's coordinates.
    ///
    /// When the block is represented by a pictogram, then the ``Pictogram/origin`` is placed at
    /// the block position coordinates.
    ///
    public var position: Vector2D {
        didSet { _collisionShape = nil }
    }
    
    /// Pictogram that is rendered as the diagram block.
    ///
    /// The pictogram's origin is placed at block's ``position``.
    ///
    public var pictogram: Pictogram?  {
        didSet { _collisionShape = nil }
    }
    
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

    public var _collisionShape: CollisionShape?

    /// Get the collision shape of the block.
    ///
    /// If the block does not have a pictogram, then a circle shape with radius zero is returned.
    ///
    /// Position of the collision shape is in the diagram or block's parent coordinates.
    ///
    public var collisionShape: CollisionShape {
        if let _collisionShape {
            return _collisionShape
        }
        
        if let pictogram {
            _collisionShape = CollisionShape(
                position: position + pictogram.collisionShape.position - pictogram.origin,
                shape: pictogram.collisionShape.shape
            )
        }
        else {
            _collisionShape = CollisionShape(position: position, shape: .circle(0.0))

        }
        return _collisionShape!
    }
    
    /// Create a new block.
    ///
    public init(objectID: ObjectID? = nil,
                tag: Int? = nil,
                position: Vector2D = .zero,
                pictogram: Pictogram? = nil,
                label: String? = nil,
                secondaryLabel: String? = nil)
    {
        self.objectID = objectID
        self.tag = tag
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
    
    public func containsTouch(at point: Vector2D, radius: Double=1.0) -> Bool {
        let touch = CollisionShape(position: point, shape: .circle(radius))
        return touch.collide(with: collisionShape)
    }

}
