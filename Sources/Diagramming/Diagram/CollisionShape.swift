//
//  CollisionShape.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 29/07/2025.
//


public struct CollisionShape: Equatable, Codable, Sendable {
    /// Position within owner's coordinates.
    ///
    /// - Note: For polygon shape the position is typically zero. The polygon points have relative
    ///         position to the parent.
    ///
    public let position: Vector2D
    public let shape: ShapeType
    
    /// Center of the shape.
    ///
    /// For circle and rectangle shape it is the shape position. For polygon it is centroid of
    /// the polygon. If the polygon is empty, the center defaults to zero.
    ///
    public var center: Vector2D {
        switch shape {
            
        case .circle(_): position
        case .rectangle(_): position
        case .polygon(let points): Geometry.centroid(points: points) ?? .zero
        }
    }
    
    public init(position: Vector2D, shape: ShapeType) {
        self.position = position
        self.shape = shape
    }
    
    // TODO: Remove in favour of common pictogram transform when rendering
    public func scaled(_ scale: Double) -> CollisionShape {
        return CollisionShape(
            position: position * scale,
            shape: shape.scaled(scale)
        )
    }
}

/// Shape of a diagram block used for masks and collisions.
///
public enum ShapeType: Equatable, Sendable, Codable {
    case circle(Double)
    case rectangle(Vector2D)
    case polygon([Vector2D])

    var typeName: String {
        switch self {
        case .circle(_): "circle"
        case .rectangle(_): "rectangle"
        case .polygon(_): "polygon"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case radius
        case rx
        case ry
        case width
        case height
        case points
    }

    public var size: Vector2D {
        switch self {
        case .circle(let radius): return Vector2D(radius, radius) * 2
        case .rectangle(let size): return size
        case .polygon(let points):
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "circle":
            let radius = try container.decode(Double.self, forKey: .radius)
            self = .circle(radius)
        case "ellipse":
            // TODO: Remove ellipse
            // Use box, we are no longer supporting ellipses
            let rx = try container.decode(Double.self, forKey: .rx)
            let ry = try container.decode(Double.self, forKey: .ry)
            self = .rectangle(Vector2D(rx, ry))
        case "rectangle":
            let width = try container.decode(Double.self, forKey: .width)
            let height = try container.decode(Double.self, forKey: .height)
            self = .rectangle(Vector2D(width, height))
        case "polygon":
            let points = try container.decode([Vector2D].self, forKey: .points)
            self = .polygon(points)

        default:
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Invalid shape type '\(type)'")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .circle(let radius):
            try container.encode("circle", forKey: .type)
            try container.encode(radius, forKey: .radius)
        case .rectangle(let size):
            try container.encode("rectangle", forKey: .type)
            try container.encode(size.x, forKey: .width)
            try container.encode(size.y, forKey: .height)
        case .polygon(let points):
            try container.encode("polygon", forKey: .type)
            try container.encode(points, forKey: .points)
        }
    }

    public func scaled(_ scale: Double) -> ShapeType {
        switch self {
        case .circle(let radius):
            return .circle(radius * scale)
        case .rectangle(let size):
            return .rectangle(size * scale)
        case .polygon(let points):
            let scaledPoints = points.map { $0 * scale }
            return .polygon(scaledPoints)
        }
    }
}

