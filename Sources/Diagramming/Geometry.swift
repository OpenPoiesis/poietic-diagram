//
//  Geometry.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/06/2025.
//

public typealias Vector2D = SIMD2<Double>

extension Vector2D {
    /// Distance between two points
    public func distance(to other: Vector2D) -> Double {
        let diff = self - other
        return (diff * diff).sum().squareRoot()
    }
    
    /// Length (magnitude) of the vector
    public var length: Double {
        return (self * self).sum().squareRoot()
    }
    
    /// Normalised vector
    public var normalized: Vector2D {
        let len = length
        guard len > 0 else {
            return Vector2D.zero
        }
        return self / len
    }
    
    /// Dot product with another vector
    public func dot(_ other: Vector2D) -> Double {
        return (self * other).sum()
    }
    
    /// Linear interpolation between two points
    public func lerp(to other: Vector2D, t: Double) -> Vector2D {
        return self + (other - self) * t
    }
}

public struct Rect2D {
    public var origin: Vector2D
    public var size: Vector2D
    
    public init(origin: Vector2D = Vector2D.zero, size: Vector2D = Vector2D.zero) {
        self.origin = origin
        self.size = size
    }
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = Vector2D(x, y)
        self.size = Vector2D(width, height)
    }
    
    public var center: Vector2D {
        return origin + size / 2.0
    }
    
    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.x }
    public var maxY: Double { origin.y + size.y }
    public var width: Double {size.x }
    public var height: Double { size.y }
    
    public var bottomLeft: Vector2D { origin }
    public var bottomRight: Vector2D { Vector2D(maxX, minY) }
    public var topLeft: Vector2D { Vector2D(minX, maxY) }
    public var topRight: Vector2D { Vector2D(maxX, maxY) }
    
    /// Check if point is inside rectangle.
    public func contains(_ point: Vector2D) -> Bool {
        return point.x >= minX && point.x <= maxX &&
               point.y >= minY && point.y <= maxY
    }
    
    /// Union with another rectangle.
    public func union(_ other: Rect2D) -> Rect2D {
        let newMinX = min(minX, other.minX)
        let newMinY = min(minY, other.minY)
        let newMaxX = max(maxX, other.maxX)
        let newMaxY = max(maxY, other.maxY)
        
        return Rect2D(
            origin: Vector2D(newMinX, newMinY),
            size: Vector2D(newMaxX - newMinX, newMaxY - newMinY)
        )
    }
}
