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
        case .convexPolygon(let points), .concavePolygon(let points):
            Geometry.centroid(points: points) ?? .zero
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

    public func collide(with other: CollisionShape) -> Bool {
        switch (self.shape, other.shape) {
        // Simple cases - inline implementation
        case (.circle(let r1), .circle(let r2)):
            let distance = self.position.distance(to: other.position)
            return distance <= r1 + r2 + Double.standardEpsilon
            
        case (.circle(let radius), .rectangle(let size)):
            return circleRectangleCollision(circleCenter: self.position, radius: radius,
                                            rectangleCenter: other.position, size: size)
            
        case (.rectangle(let size), .circle(let radius)):
            return circleRectangleCollision(circleCenter: other.position, radius: radius,
                                            rectangleCenter: self.position, size: size)
            
        case (.rectangle(let size1), .rectangle(let size2)):
            return rectangleRectangleCollision(center1: self.position, size1: size1,
                                               center2: other.position, size2: size2)
            
        // Complex cases - delegate to helper methods
        case (.circle(let radius), .convexPolygon(let points)):
            return circleConvexPolygonCollision(circleCenter: self.position, radius: radius,
                                                polygonPosition: other.position, points: points)
            
        case (.convexPolygon(let points), .circle(let radius)):
            return circleConvexPolygonCollision(circleCenter: other.position, radius: radius,
                                                polygonPosition: self.position, points: points)
            
        case (.rectangle(let size), .convexPolygon(let points)):
            return rectangleConvexPolygonCollision(rectangleCenter: self.position, size: size,
                                                   polygonPosition: other.position, points: points)
            
        case (.convexPolygon(let points), .rectangle(let size)):
            return rectangleConvexPolygonCollision(rectangleCenter: other.position, size: size,
                                                   polygonPosition: self.position, points: points)
            
        case (.convexPolygon(let points1), .convexPolygon(let points2)):
            return convexPolygonConvexPolygonCollision(position1: self.position, points1: points1,
                                                       position2: other.position, points2: points2)
            
        // Cases involving concave polygons
        case (.circle(let radius), .concavePolygon(let points)):
            return circleConcavePolygonCollision(circleCenter: self.position, radius: radius,
                                                 polygonPosition: other.position, points: points)
            
        case (.concavePolygon(let points), .circle(let radius)):
            return circleConcavePolygonCollision(circleCenter: other.position, radius: radius,
                                                 polygonPosition: self.position, points: points)
            
        case (.rectangle(let size), .concavePolygon(let points)):
            return rectangleConcavePolygonCollision(rectangleCenter: self.position, size: size,
                                                    polygonPosition: other.position, points: points)
            
        case (.concavePolygon(let points), .rectangle(let size)):
            return rectangleConcavePolygonCollision(rectangleCenter: other.position, size: size,
                                                    polygonPosition: self.position, points: points)
            
        case (.convexPolygon(let convexPoints), .concavePolygon(let points)):
            return convexConcavePolygonCollision(convexPosition: self.position, convexPoints: convexPoints,
                                                 concavePosition: other.position, concavePoints: points)
            
        case (.concavePolygon(let points), .convexPolygon(let convexPoints)):
            return convexConcavePolygonCollision(convexPosition: other.position, convexPoints: convexPoints,
                                                 concavePosition: self.position, concavePoints: points)
            
        case (.concavePolygon(let points1), .concavePolygon(let points2)):
            return concaveConcavePolygonCollision(position1: self.position, points1: points1,
                                                  position2: other.position, points2: points2)
        }
    }
    
    /// Convert the shape to a bezier path.
    ///
    public func toPath() -> BezierPath {
        switch shape {
        case let .circle(radius):
            return BezierPath(circle: position, radius: radius)
        case let .rectangle(size):
            let rect = Rect2D(center: position, size: size)
            return BezierPath(rect: rect)
        case let .convexPolygon(points), let .concavePolygon(points):
            var path = BezierPath(polyline: points)
            if !path.isClosed {
                path.closeSubpath()
            }
            return path
        }
    }
}

// MARK: - Collision Detection Helper Methods

private func circleRectangleCollision(circleCenter: Vector2D, radius: Double,
                                      rectangleCenter: Vector2D, size: Vector2D) -> Bool {
    let halfSize = size / 2
    let rectMin = rectangleCenter - halfSize
    let rectMax = rectangleCenter + halfSize
    
    // Find closest point on rectangle to circle center
    let closestX = max(rectMin.x, min(circleCenter.x, rectMax.x))
    let closestY = max(rectMin.y, min(circleCenter.y, rectMax.y))
    let closest = Vector2D(closestX, closestY)
    
    let distance = circleCenter.distance(to: closest)
    return distance <= radius + Double.standardEpsilon
}

private func rectangleRectangleCollision(center1: Vector2D, size1: Vector2D,
                                         center2: Vector2D, size2: Vector2D) -> Bool {
    let halfSize1 = size1 / 2
    let halfSize2 = size2 / 2
    
    let min1 = center1 - halfSize1
    let max1 = center1 + halfSize1
    let min2 = center2 - halfSize2
    let max2 = center2 + halfSize2
    
    return max1.x >= min2.x - Double.standardEpsilon &&
           min1.x <= max2.x + Double.standardEpsilon &&
           max1.y >= min2.y - Double.standardEpsilon &&
           min1.y <= max2.y + Double.standardEpsilon
}

private func circleConvexPolygonCollision(circleCenter: Vector2D, radius: Double,
                                          polygonPosition: Vector2D, points: [Vector2D]) -> Bool {
    let worldPoints = points.map { $0 + polygonPosition }
    
    // Check if circle center is inside polygon
    if pointInsideConvexPolygon(point: circleCenter, points: worldPoints) {
        return true
    }
    
    // Check distance to each edge
    for i in 0..<worldPoints.count {
        let nextIndex = (i + 1) % worldPoints.count
        let edge = LineSegment(from: worldPoints[i], to: worldPoints[nextIndex])
        let distance = edge.distance(to: circleCenter)
        
        if distance <= radius + Double.standardEpsilon {
            return true
        }
    }
    
    return false
}

private func rectangleConvexPolygonCollision(rectangleCenter: Vector2D, size: Vector2D,
                                             polygonPosition: Vector2D, points: [Vector2D]) -> Bool {
    let rect = Rect2D(center: rectangleCenter, size: size)
    let worldPoints = points.map { $0 + polygonPosition }
    
    // Check if any rectangle corner is inside polygon
    if pointInsideConvexPolygon(point: rect.bottomLeft, points: worldPoints)
        || pointInsideConvexPolygon(point: rect.bottomRight, points: worldPoints)
        || pointInsideConvexPolygon(point: rect.topLeft, points: worldPoints)
        || pointInsideConvexPolygon(point: rect.topRight, points: worldPoints)
    {
        return true
    }
    
    // Check if any polygon corner is inside rectangle
    for point in worldPoints {
        if rect.contains(point) {
            return true
        }
    }
    
    // Check edge intersections using SAT
    return separatingAxisTestRectanglePolygon(rectangle: rect,
                                              points: worldPoints)
}

private func convexPolygonConvexPolygonCollision(position1: Vector2D, points1: [Vector2D],
                                                 position2: Vector2D, points2: [Vector2D]) -> Bool {
    let worldPoints1 = points1.map { $0 + position1 }
    let worldPoints2 = points2.map { $0 + position2 }
    
    // Use Separating Axis Theorem
    return separatingAxisTestConvexPolygons(points1: worldPoints1, points2: worldPoints2)
}

private func circleConcavePolygonCollision(circleCenter: Vector2D, radius: Double,
                                           polygonPosition: Vector2D, points: [Vector2D]) -> Bool {
    let worldPoints = points.map { $0 + polygonPosition }
    
    // Simple approach: check distance to each edge
    for i in 0..<worldPoints.count {
        let nextIndex = (i + 1) % worldPoints.count
        let edge = LineSegment(from: worldPoints[i], to: worldPoints[nextIndex])
        let distance = edge.distance(to: circleCenter)
        
        if distance <= radius + Double.standardEpsilon {
            return true
        }
    }
    
    // Check if circle center is inside polygon using ray casting
    return pointInsideConcavePolygon(point: circleCenter, points: worldPoints)
}

private func rectangleConcavePolygonCollision(rectangleCenter: Vector2D, size: Vector2D,
                                              polygonPosition: Vector2D, points: [Vector2D]) -> Bool {
    let worldPoints = points.map { $0 + polygonPosition }
    let rect = Rect2D(center: rectangleCenter, size: size)
    
    // Check if any rectangle corner is inside polygon
    if pointInsideConcavePolygon(point: rect.bottomLeft, points: worldPoints)
        || pointInsideConcavePolygon(point: rect.bottomRight, points: worldPoints)
        || pointInsideConcavePolygon(point: rect.topRight, points: worldPoints)
        || pointInsideConcavePolygon(point: rect.topLeft, points: worldPoints)
    {
        return true
    }
    
    // Check if any polygon corner is inside rectangle
    for point in worldPoints {
        if rect.contains(point) {
            return true
        }
    }
    
    // Check for edge intersections
    let bottomEdge = LineSegment(from: rect.bottomLeft, to: rect.bottomRight)
    let rightEdge = LineSegment(from: rect.bottomRight, to: rect.topRight)
    let topEdge = LineSegment(from: rect.topRight, to: rect.topLeft)
    let leftEdge = LineSegment(from: rect.topLeft, to: rect.bottomLeft)
    
    for i in 0..<worldPoints.count {
        let nextIndex = (i + 1) % worldPoints.count
        let polygonEdge = LineSegment(from: worldPoints[i], to: worldPoints[nextIndex])
        
        if polygonEdge.intersects(bottomEdge)
            || polygonEdge.intersects(rightEdge)
            || polygonEdge.intersects(topEdge)
            || polygonEdge.intersects(leftEdge)
        {
            return true
        }
    }
    
    return false
}

private func convexConcavePolygonCollision(convexPosition: Vector2D, convexPoints: [Vector2D],
                                         concavePosition: Vector2D, concavePoints: [Vector2D]) -> Bool {
    let worldConvexPoints = convexPoints.map { $0 + convexPosition }
    let worldConcavePoints = concavePoints.map { $0 + concavePosition }
    
    // Check if any convex polygon vertex is inside concave polygon
    for point in worldConvexPoints {
        if pointInsideConcavePolygon(point: point, points: worldConcavePoints) {
            return true
        }
    }
    
    // Check if any concave polygon vertex is inside convex polygon
    for point in worldConcavePoints {
        if pointInsideConvexPolygon(point: point, points: worldConvexPoints) {
            return true
        }
    }
    
    // Check for edge intersections
    let convexEdges = Geometry.toSegments(polygon: worldConvexPoints)
    let concaveEdges = Geometry.toSegments(polygon: worldConcavePoints)
    
    for convexEdge in convexEdges {
        for concaveEdge in concaveEdges {
            if convexEdge.intersects(concaveEdge) {
                return true
            }
        }
    }
    
    return false
}

private func concaveConcavePolygonCollision(position1: Vector2D, points1: [Vector2D],
                                          position2: Vector2D, points2: [Vector2D]) -> Bool {
    let worldPoints1 = points1.map { $0 + position1 }
    let worldPoints2 = points2.map { $0 + position2 }
    
    // Check if any vertex from polygon1 is inside polygon2
    for point in worldPoints1 {
        if pointInsideConcavePolygon(point: point, points: worldPoints2) {
            return true
        }
    }
    
    // Check if any vertex from polygon2 is inside polygon1
    for point in worldPoints2 {
        if pointInsideConcavePolygon(point: point, points: worldPoints1) {
            return true
        }
    }
    
    // Check for edge intersections
    let edges1 = Geometry.toSegments(polygon: worldPoints1)
    let edges2 = Geometry.toSegments(polygon: worldPoints2)
    
    for edge1 in edges1 {
        for edge2 in edges2 {
            if edge1.intersects(edge2) {
                return true
            }
        }
    }
    
    return false
}

// MARK: - Utility Methods

private func pointInsideConvexPolygon(point: Vector2D, points: [Vector2D]) -> Bool {
    guard points.count >= 3 else { return false }
    
    var sign: FloatingPointSign? = nil
    
    for i in 0..<points.count {
        let nextIndex = (i + 1) % points.count
        let edge = points[nextIndex] - points[i]
        let toPoint = point - points[i]
        let crossProduct = edge.cross(toPoint)
        
        if abs(crossProduct) < Double.standardEpsilon {
            continue // Point is on edge
        }
        
        if let sign {
            if crossProduct.sign != sign {
                return false // Point is on wrong side
            }
        } else {
            sign = crossProduct.sign
        }
    }
    
    return true
}

private func pointInsideConcavePolygon(point: Vector2D, points: [Vector2D]) -> Bool {
    guard points.count >= 3 else { return false }
    
    var intersectionCount = 0
    let rayDirection = Vector2D(1, 0) // Ray pointing right
    
    for i in 0..<points.count {
        let nextIndex = (i + 1) % points.count
        let edge = LineSegment(from: points[i], to: points[nextIndex])
        
        if let _ = edge.intersection(rayFrom: point, direction: rayDirection) {
            intersectionCount += 1
        }
    }
    
    return intersectionCount % 2 == 1
}

private func separatingAxisTestConvexPolygons(points1: [Vector2D], points2: [Vector2D]) -> Bool {
    // Test axes from both polygons
    let allPoints = [points1, points2]
    
    for polygonPoints in allPoints {
        for i in 0..<polygonPoints.count {
            let nextIndex = (i + 1) % polygonPoints.count
            let edge = polygonPoints[nextIndex] - polygonPoints[i]
            let axis = edge.normalizedNormal
            
            // Project both polygons onto this axis
            let (min1, max1) = projectPolygonOntoAxis(points: points1, axis: axis)
            let (min2, max2) = projectPolygonOntoAxis(points: points2, axis: axis)
            
            // Check for separation
            if max1 < min2 - Double.standardEpsilon || max2 < min1 - Double.standardEpsilon {
                return false // Separating axis found
            }
        }
    }
    
    return true // No separating axis found - polygons collide
}

private func separatingAxisTestRectanglePolygon(rectangle rect: Rect2D,
                                                points: [Vector2D]) -> Bool {
    let corners = [
        rect.bottomLeft, rect.bottomRight, rect.topRight, rect.topLeft
    ]
    
    // Test rectangle axes (x and y)
    let rectAxes = [Vector2D(1, 0), Vector2D(0, 1)]
    
    for axis in rectAxes {
        let (rectMin, rectMax) = projectPolygonOntoAxis(points: corners, axis: axis)
        let (polyMin, polyMax) = projectPolygonOntoAxis(points: points, axis: axis)
        
        if rectMax < polyMin - Double.standardEpsilon || polyMax < rectMin - Double.standardEpsilon {
            return false
        }
    }
    
    // Test polygon edge normals
    for i in 0..<points.count {
        let nextIndex = (i + 1) % points.count
        let edge = points[nextIndex] - points[i]
        let axis = edge.normalizedNormal
        
        let (rectMin, rectMax) = projectPolygonOntoAxis(points: corners, axis: axis)
        let (polyMin, polyMax) = projectPolygonOntoAxis(points: points, axis: axis)
        
        if rectMax < polyMin - Double.standardEpsilon || polyMax < rectMin - Double.standardEpsilon {
            return false
        }
    }
    
    return true
}

private func projectPolygonOntoAxis(points: [Vector2D], axis: Vector2D) -> (Double, Double) {
    guard let firstPoint = points.first else { return (0, 0) }
    
    let firstProjection = firstPoint.dot(axis)
    var minProjection = firstProjection
    var maxProjection = firstProjection
    
    for i in 1..<points.count {
        let projection = points[i].dot(axis)
        minProjection = min(minProjection, projection)
        maxProjection = max(maxProjection, projection)
    }
    
    return (minProjection, maxProjection)
}

/// Shape of a diagram block used for masks and collisions.
///
public enum ShapeType: Equatable, Sendable, Codable {
    case circle(Double)
    case rectangle(Vector2D)
//    case polygon([Vector2D])
    case convexPolygon([Vector2D])
    case concavePolygon([Vector2D])

    public var typeName: String {
        switch self {
        case .circle(_): "circle"
        case .rectangle(_): "rectangle"
        case .convexPolygon(_): "convexPolygon"
        case .concavePolygon(_): "concavePolygon"
        }
    }
   
    /// Order in which the shape type is compared to other shape to match for collision.
    ///
    var collisionOrder: Int {
        switch self {
        case .circle(_): 0
        case .rectangle(_): 1
        case .convexPolygon(_): 2
        case .concavePolygon(_): 3
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
        case .convexPolygon(let points), .concavePolygon(let points):
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
            if Geometry.isConvex(polygon: points) {
                self = .convexPolygon(points)
            }
            else {
                self = .concavePolygon(points)
            }
        case "convexPolygon":
            let points = try container.decode([Vector2D].self, forKey: .points)
            self = .convexPolygon(points)
        case "concavePolygon":
            let points = try container.decode([Vector2D].self, forKey: .points)
            self = .concavePolygon(points)

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
        case .convexPolygon(let points):
            try container.encode("convexPolygon", forKey: .type)
            try container.encode(points, forKey: .points)
        case .concavePolygon(let points):
            try container.encode("concavePolygon", forKey: .type)
            try container.encode(points, forKey: .points)
        }
    }

    public func scaled(_ scale: Double) -> ShapeType {
        switch self {
        case .circle(let radius):
            return .circle(radius * scale)
        case .rectangle(let size):
            return .rectangle(size * scale)
        case .convexPolygon(let points):
            let scaledPoints = points.map { $0 * scale }
            return .convexPolygon(scaledPoints)
        case .concavePolygon(let points):
            let scaledPoints = points.map { $0 * scale }
            return .concavePolygon(scaledPoints)
        }
    }
}

