//
//  Geometry+arrows.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/11/2025.
//

// MARK: - Wire

extension Geometry {
    /// Returns the center wire path of a connector regardless of visual style.
    ///
    /// This method returns direct connection path that represents the centre line
    /// of the connector, without visual styling elements like arrowheads, stroke width,
    /// or fill polygons. The path follows the connector's line type (straight, curved,
    /// or orthogonal) and routes through all midpoints.
    ///
    /// This is useful for:
    /// - Touch detection and hit testing
    /// - Logical path analysis
    /// - Computing connector geometry independent of visual presentation
    ///
    /// - Returns: A `BezierPath` representing the center wire of the connector
    ///
    public static func wirePath(from originPoint: Vector2D,
                                to targetPoint: Vector2D,
                                through midpoints: [Vector2D],
                                lineType: LineType) -> BezierPath
    {
        let allPoints = [originPoint] + midpoints + [targetPoint]
        
        let path: BezierPath
        switch lineType {
        case .straight:
            path = BezierPath(polyline: allPoints)
        case .curved:
            path = BezierPath(curveThrough: allPoints)
        case .orthogonal:
            path = BezierPath(orthogonalPolylineThrough: allPoints)
        }
        return path
    }
    
    /// Compute touch points to origin and target blocks.
    ///
    /// The touch point is computed as a an intersection of block's collision shape and a
    /// ray originating from the first adjacent point to the endpoint. If no intersection is found,
    /// then the endpoint block position is returned for given endpoint.
    ///
    public static func touchPoints(originPosition: Vector2D,
                                   originShape: CollisionShape,
                                   targetPosition: Vector2D,
                                   targetShape: CollisionShape,
                                   midpoints: [Vector2D]) -> (origin: Vector2D, target: Vector2D){
        let originShapePosition = originPosition + originShape.position
        let originTouch = touchPoint(shape: originShape.shape,
                                     position: originShapePosition,
                                     from: midpoints.first ?? targetPosition,
                                     towards: originPosition)
        let targetShapePosition = targetPosition + targetShape.position
        let targetTouch = touchPoint(shape: targetShape.shape,
                                     position: targetShapePosition,
                                     from: midpoints.last ?? originPosition,
                                     towards: targetPosition)
        return (origin: originTouch, target:targetTouch)
    }
    // FIXME: Change to (from:touching:at:)
    public static func touchPoint(shape: ShapeType,
                                  position: Vector2D,
                                  from startPoint: Vector2D,
                                  towards endPoint: Vector2D) -> Vector2D {
        let direction = (endPoint - startPoint).normalized
        let touch = Geometry.rayIntersection(shape: shape,
                                             position: position,
                                             from: startPoint,
                                             direction: direction)
        return touch ?? endPoint
    }
}

// MARK: - Thin Connector

extension Geometry {
    /// Create a thin arrowhead (stroke-based) at the specified point
    public static func createThinArrowhead(at headPoint: Vector2D,
                                           direction: Vector2D,
                                           size: Double,
                                           type: ThinArrowheadType) -> Arrowhead {
        var path = BezierPath()
        let perpendicular = Vector2D(-direction.y, direction.x) // orthogonal in bottom-left coordinates
        
        switch type {
        case .none:
            break
            
        case .stick:
            let point1 = headPoint - (direction * size * 1.5) + (perpendicular * size/2)
            let point2 = headPoint - (direction * size * 1.5) - (perpendicular * size/2)
            path.move(to: point1)
            path.addLine(to: headPoint)
            path.addLine(to: point2)
            
        case .diamond:
            let back = headPoint - direction * size
            let side1 = headPoint - direction * (size / 2) + perpendicular * (size/2)
            let side2 = headPoint - direction * (size / 2) - perpendicular * (size/2)
            path.move(to: side1)
            path.addLine(to: headPoint)
            path.addLine(to: side2)
            path.addLine(to: back)
            path.addLine(to: side1)
            
        case .box:
            let c1 = headPoint - perpendicular * (size / 2)
            let c2 = c1 - direction * size
            let c3 = c2 + perpendicular * size
            let c4 = c3 + direction * size
            path.move(to: c1)
            path.addLine(to: c2)
            path.addLine(to: c3)
            path.addLine(to: c4)
            path.addLine(to: c1)
            
        case .bar:
            let point1 = headPoint - direction * (size / 2) - perpendicular * (size / 2)
            let point2 = headPoint - direction * (size / 2) + perpendicular * (size / 2)
            path.move(to: point1)
            path.addLine(to: point2)
            
        case .negative:
            let point1 = headPoint - perpendicular * (size / 2)
            let point2 = headPoint + perpendicular * (size / 2)
            path.move(to: point1)
            path.addLine(to: point2)
            
        case .nonNavigable:
            let c1 = headPoint - perpendicular * (size / 2)
            let c2 = c1 - direction * size
            let c3 = c2 + perpendicular * size
            let c4 = c3 + direction * size
            path.move(to: c1)
            path.addLine(to: c3)
            path.move(to: c2)
            path.addLine(to: c4)
            
        case .ball:
            let radius = size / 2
            let center = headPoint - direction * radius
            path = BezierPath(circle: center, radius: radius)
            
        case .ballCenter:
            let radius = size / 2
            path = BezierPath(circle: headPoint, radius: radius)
        }
        
        let offset = type.touchPointOffset(size)
        return Arrowhead(path: path, offset: offset)
    }
    
    /// Create a collection of bezier paths for a thin connector and its arrowheads.
    ///
    public static func thinConnectorPaths(originPoint: Vector2D,
                                          targetPoint: Vector2D,
                                          midpoints: [Vector2D],
                                          headSize: Double,
                                          tailSize: Double,
                                          lineType: LineType,
                                          kind: ConnectorGlyph.Thin)
    -> ThinConnector {
        // Arrowhead directions
        let originDir = (originPoint - (midpoints.first ?? targetPoint)).normalized
        let targetDir = (targetPoint - (midpoints.last ?? originPoint)).normalized

        // Create arrowheads
        let headArrowhead = Self.createThinArrowhead(at: targetPoint,
                                                     direction: targetDir,
                                                     size: headSize,
                                                     type: kind.headType)
        
        let tailArrowhead = Self.createThinArrowhead(at: originPoint,
                                                     direction: originDir,
                                                     size: tailSize,
                                                     type: kind.tailType)
        
        // Calculate clipped endpoints
        let clippedOrigin = originPoint - (originDir * tailArrowhead.offset)
        let clippedTarget = targetPoint - (targetDir * headArrowhead.offset)
        
        let allPoints = [clippedOrigin] + midpoints + [clippedTarget]
        // Create main line
        let body: BezierPath
        switch lineType {
        case .straight:
            body = BezierPath(polyline: allPoints)
        case .curved:
            body = BezierPath(curveThrough: allPoints)
        case .orthogonal:
            body = BezierPath(orthogonalPolylineThrough: allPoints)
        }
        
        return ThinConnector(tail: tailArrowhead.path,
                             body: body,
                             head: headArrowhead.path)
    }
}

// MARK: - Fat Connector

extension Geometry {
    /// Create a bezier path of a fat (outlined) connector, including arrowheads.
    ///
    public static func fatConnectorPath(
        originPoint: Vector2D,
        targetPoint: Vector2D,
        midpoints: [Vector2D],
        headSize: Double,
        tailSize: Double,
        kind: ConnectorGlyph.Fat)
    -> BezierPath {
        // Arrowhead directions
        let originDir = (originPoint - (midpoints.first ?? targetPoint)).normalized
        let targetDir = (targetPoint - (midpoints.last ?? originPoint)).normalized

        // TODO: Make fat arrowhead size two-dimensional. For now, we just use this magic ratio.
        let PleasantMagicScale = 1.5
        
        let clippedOrigin = originPoint - (originDir * kind.tailType.touchPointOffset(tailSize * PleasantMagicScale))
        let clippedTarget = targetPoint - (targetDir * kind.headType.touchPointOffset(headSize * PleasantMagicScale))

        let points =  [clippedOrigin] + midpoints + [clippedTarget]

        let pathThere = Geometry.offsetPolyline(points, offset: kind.width, joinType: kind.joinType)
        let pathBack = Geometry.offsetPolyline(points.reversed(), offset: kind.width, joinType: kind.joinType)

        var path = BezierPath()

        path.move(to: pathThere[0])
        
        for point in pathThere.dropFirst() {
            path.addLine(to: point)
        }

        switch kind.headType {
        case .none:
            path.addLine(to: pathBack[0])
        case .regular:
            Self.appendFatArrowhead(path: &path,
                                    endpoint: targetPoint,
                                    direction: targetDir,
                                    connectIn: pathThere.last!,
                                    connectOut: pathBack.first!,
                                    size: headSize)
        }
        
        for point in pathBack.dropFirst() {
            path.addLine(to: point)
        }

        switch kind.tailType {
        case .none:
            path.addLine(to: pathThere[0])
        case .regular:
            Self.appendFatArrowhead(path: &path,
                                    endpoint: originPoint,
                                    direction: originDir,
                                    connectIn: pathBack.last!,
                                    connectOut: pathThere.first!,
                                    size: tailSize)
        }

        return path
    }
    
    private static func appendFatArrowhead(path: inout BezierPath,
                                           endpoint: Vector2D,
                                           direction: Vector2D,
                                           connectIn: Vector2D,
                                           connectOut: Vector2D,
                                           size: Double) {
        let perpendicular = direction.normal

        let p1 = connectIn - perpendicular * size
        let p2 = connectOut + perpendicular * size
        path.addLine(to: p2)
        path.addLine(to: endpoint)
        path.addLine(to: p1)
        path.addLine(to: connectOut)
    }

}

