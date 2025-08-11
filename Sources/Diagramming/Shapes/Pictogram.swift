//
//  Pictogram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/07/2025.
//

struct Magnet {
    public let position: Vector2D
}

/// Pictogram is a visual representation of a design object.
///
/// - ToDo: Make coordinates to be lower-left corner.
///
public final class Pictogram: Sendable, Codable {
    /// Name by which pictogram is referenced to.
    ///
    public let name: String
    
    /// Bezier path representing the pictogram.
    ///
    /// The path is to be drawn at diagram object's position. For example, if the path represents
    /// a circular shape, then the shape origin should be at (0, 0). If the path represents a
    /// rectangle, then the object position is the rectangle centre.
    ///
    /// - Note: The path is always drawn as a line and curve path without any fill.
    ///
    public let path: BezierPath
    
    /// Visual mask of the pictogram.
    ///
    /// Visual mask is used to obscure content below the pictogram, provide highlight shape or
    /// similar visual indication.
    ///
    /// - SeeAlso: ``origin``
    public let maskShape: CollisionShape
    
    /// Coordinate origin of the pictogram and its masks.
    ///
    /// The ``path``, ``maskShape`` and ``collisionShape``  are relative to the ``origin``.
    ///
    public let origin: Vector2D
    
    /// Box into which the whole pictogram fits.
    ///
    /// The box is relative to the ``origin``.
    ///
    public let boundingBox: Rect2D

    /// Shape to test collision with mouse pointer, gesture pointer or another pictogram.
    ///
    /// Collision shape is also used as a boundary for clipping connectors to or from the pictogram.
    ///
    /// By default, the collision shape is the same as the mask shape.
    ///
    /// - SeeAlso: ``origin``, ``maskShape``.
    ///
    public let collisionShape: CollisionShape
    
    /// Size of the pictogram derived from the path.
    ///
    /// If the path is empty, the size is zero.
    ///
    public var size: Vector2D {
        path.boundingBox?.size ?? .zero
    }
    
//    public let magnets: [Magnet]
    private enum CodingKeys: String, CodingKey {
        case name
        case path
        case maskShape = "mask_shape"
        case origin
        case boundingBox = "bounding_box"
        case collisionShape = "collision_shape"
    }

    // let decorations
    // let textAnnotations
    public init(_ name: String,
                path: BezierPath,
                maskShape: CollisionShape,
                origin: Vector2D = Vector2D(),
                boundingBox: Rect2D = Rect2D(),
                collisionShape: CollisionShape? = nil) {
        self.name = name
        self.path = path
        self.maskShape = maskShape
        self.origin = origin
        self.boundingBox = boundingBox
        self.collisionShape = collisionShape ?? maskShape
    }
    
}

