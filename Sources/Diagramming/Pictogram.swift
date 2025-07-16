//
//  Pictogram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/07/2025.
//

struct Magnet {
    public let position: Vector2D
}

public enum CollisionShape {
    case circle(Double)
    case rectangle(Vector2D)
    case convexPolygon([Vector2D])
    
    public var size: Vector2D {
        switch self {
        case .circle(let radius): return Vector2D(radius * 2, radius * 2)
        case .rectangle(let size): return size
        case .convexPolygon(let points):
            let (minX, minY, maxX, maxY) = points.reduce( (0.0, 0.0, 0.0, 0.0) ) {
                (result, point) in
                (min(result.0, point.x),
                 min(result.1, point.y),
                 max(result.2, point.x),
                 max(result.3, point.y))
            }
            return Vector2D(maxX - minX, maxY - minY)
        }
    }
}

/// Pictogram is a visual representation of a design object.
///
/// - ToDo: Make coordinates to be lower-left corner.
///
public class Pictogram {
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
    /// Origin of the pictogram's mask shape and collision shape.
    public let origin: Vector2D
    
    /// Box into which the whole pictogram fits.
    public let boundingBox: Rect2D

    /// Shape to test collision with mouse pointer, gesture pointer or another pictogram.
    ///
    /// - SeeAlso: ``origin``
    ///
    public let collisionShape: CollisionShape
    
//    public let magnets: [Magnet]

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

