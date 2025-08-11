//
//  CollisionShape.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 29/07/2025.
//


public enum CollisionShape: Equatable, Sendable, Codable {
    case circle(Double)
    case ellipse(Double, Double)
    case rectangle(Vector2D)
    case polygon([Vector2D])

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
        case .ellipse(let rx, let ry): return Vector2D(rx, ry) * 2
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
            let rx = try container.decode(Double.self, forKey: .rx)
            let ry = try container.decode(Double.self, forKey: .ry)
            self = .ellipse(rx, ry)
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
        case .ellipse(let rx, let ry):
            try container.encode("ellipse", forKey: .type)
            try container.encode(rx, forKey: .rx)
            try container.encode(ry, forKey: .ry)
        case .rectangle(let size):
            try container.encode("rectangle", forKey: .type)
            try container.encode(size.x, forKey: .width)
            try container.encode(size.y, forKey: .height)
        case .polygon(let points):
            try container.encode("polygon", forKey: .type)
            try container.encode(points, forKey: .points)
        }
    }

}

