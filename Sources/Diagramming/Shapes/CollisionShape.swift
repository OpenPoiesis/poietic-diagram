//
//  CollisionShape.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 29/07/2025.
//


public enum CollisionShape: Equatable, Sendable {
    case circle(Double)
    case ellipse(Double, Double)
    case rectangle(Vector2D)
    case polygon([Vector2D])

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
}

