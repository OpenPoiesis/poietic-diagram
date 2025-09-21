//
//  Pictogram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/07/2025.
//

/// Visual representation of an object in a diagram.
///
/// The pictogram is described by its curves and additional metadata:
/// - ``path``: Bezier curves used to draw the pictogram.
/// - ``mask``: Visual mask, typically to provide space around the pictogram or to use for
///   drawing a selection outline.
/// - ``collisionShape``: Simplified shape used for detecting touch points of connectors
///   and to detect touches in an user interface.
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
    /// - Note: The path is always drawn as a line and curve path without any fill. It is never
    ///         intended to be presented as filled.
    ///
    public let path: BezierPath
    
    /// Visual mask of the pictogram.
    ///
    /// Visual mask is used to obscure content below the pictogram, provide highlight shape or
    /// similar visual indication.
    ///
    /// - Note: The bezier path representing the mask is assumed to be a closed path or composed
    ///   of closed sub-paths. It is always presented as filled.
    ///
    /// - SeeAlso: ``collisionShape``
    ///
    public let mask: BezierPath
    
    /// Box into which the all pictogram curves fit.
    ///
    /// Bounding box for mask might differ, usually is larger. See ``maskBoundingBox``.
    ///
    /// If the path is empty, then the bounding box is a zero-sized rectangle.
    ///
    public var pathBoundingBox: Rect2D {
        path.boundingBox ?? Rect2D()
    }

    /// Box into which the pictogram mask fits.
    ///
    /// Bounding box for curves might differ and is usually smaller. See ``pathBoundingBox``.
    ///
    /// If the mask is empty, then the bounding box is a zero-sized rectangle.
    ///
    public var maskBoundingBox: Rect2D {
        mask.boundingBox ?? Rect2D()
    }

    /// Shape to test collision with mouse pointer, gesture pointer or another pictogram.
    ///
    /// Collision shape is also used as a boundary for clipping connectors to or from the pictogram.
    ///
    /// By default, the collision shape is the same as the mask shape.
    ///
    /// - SeeAlso: ``origin``, ``maskShape``.
    ///
    public let collisionShape: CollisionShape
    
    //    public let magnets: [Magnet]
    private enum CodingKeys: String, CodingKey {
        case name
        case path
        case mask
        case collisionShape = "collision_shape"
    }
    
    // let decorations
    // let textAnnotations
    // TODO: Swap mask with collision - derive mask from collision
    public init(_ name: String,
                path: BezierPath,
                collisionShape: CollisionShape,
                mask: BezierPath? = nil) {
        self.name = name
        self.path = path
        self.collisionShape = collisionShape
        if let mask {
            self.mask = mask
        }
        else {
            self.mask = collisionShape.toPath()
        }
    }
    
    /// Creates a circle pictogram of given radius centred at the pictogram origin.
    ///
    /// The collision shape and the mask are set to the same circle shape.
    public convenience init(_ name: String, circleWithRadius radius: Double) {
        self.init(
            name,
            path: BezierPath(circle: .zero, radius: radius),
            collisionShape: CollisionShape(position: .zero, shape: .circle(radius))
        )
    }

    /// Creates a square pictogram of given size centred at the pictogram origin.
    ///
    /// The collision shape and the mask are set to the same square shape.
    public convenience init(_ name: String, squareOfSize size: Double) {
        let halfSize = size / 2.0
        self.init(
            name,
            path: BezierPath(rect: Rect2D(x: -halfSize, y: -halfSize, width: size, height: size)),
            collisionShape: CollisionShape(position: .zero, shape: .rectangle(Vector2D(size, size)))
        )
    }

    /// Get a scaled version of the pictogram
    public func scaled(_ scale: Double) -> Pictogram {
        let trans = AffineTransform(scale: Vector2D(scale, scale))
        return Pictogram(
            name,
            path: path.transform(trans),
            collisionShape: collisionShape.scaled(scale),
            mask: mask.transform(trans),
        )
    }
}

