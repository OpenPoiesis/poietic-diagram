//
//  Arrow.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

public enum ThinArrowheadType: CaseIterable {
    /// No arrow-head
    case none
    /// Simple stick arrowhead
    case stick
    /// Diamond-shaped arrowhead
    case diamond
    /// Box-shaped arrowhead, a square
    case box
    /// Bar or tee-shaped arrowhead (negative control)
    case bar
    /// X-like cross
    case nonNavigable
    /// Negative control (a bar at the endpoint)
    case negative
    /// Ball touching the endpoint
    case ball
    /// Ball centred at the endpoint
    case ballCenter

    /// Offset of the point where the arrow line touches the head from the arrow endpoint.
    ///
    public func touchPointOffset(_ size: Double) -> Double {
        switch self {
        case .none, .stick, .bar, .negative, .nonNavigable:
            return 0
        case .diamond, .box, .ball:
            return size
        case .ballCenter:
            return size / 2
        }
    }
}

public enum FatArrowheadType: CaseIterable {
    case none
    case regular
    public func touchPointOffset(_ size: Double) -> Double {
        switch self {
        case .none:
            return 0
        case .regular:
            return size
        }
    }
}

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
    
    public static func createThinConnector(origin originPoint: Vector2D,
                                           target targetPoint: Vector2D,
                                           midpoints: [Vector2D] = [],
                                           style: ThinConnectorStyle,
    ) -> [BezierPath] {
        var paths: [BezierPath] = []

        let (originDir, targetDir) = Self.arrowhadDirections(origin: originPoint,
                                                             target: targetPoint,
                                                             midpoints: midpoints)
        // Create arrowheads
        let headArrowhead = Self.createThinArrowhead(at: targetPoint,
                                                     direction: targetDir,
                                                     size: style.headSize,
                                                     type: style.headType)
        
        let tailArrowhead = Self.createThinArrowhead(at: originPoint,
                                                     direction: originDir,
                                                     size: style.tailSize,
                                                     type: style.tailType)
        
        if !headArrowhead.path.isEmpty {
            paths.append(headArrowhead.path)
        }
        if !tailArrowhead.path.isEmpty {
            paths.append(tailArrowhead.path)
        }
        
        // Calculate clipped endpoints
        let clippedOrigin = originPoint - (originDir * tailArrowhead.offset)
        let clippedTarget = targetPoint - (targetDir * headArrowhead.offset)
        
        // Create main line
        let path: BezierPath
        switch style.lineType {
        case .straight:
            path = BezierPath(polyline: [clippedOrigin] + midpoints + [clippedTarget])
        case .curved:
            path = BezierPath(curveThrough: [clippedOrigin] + midpoints + [clippedTarget])
        case .orthogonal:
            path = Self.createOrthogonalConnector(start: clippedOrigin,
                                                  end: clippedTarget,
                                                  midpoints: midpoints)
        }
        
        paths.append(path)
        
        return paths
    }
    
    
    public static func createOrthogonalConnector(start: Vector2D,
                                                 end: Vector2D,
                                                 midpoints: [Vector2D]) -> BezierPath {
        let points = midpoints + [end]
        var isHorizontal: Bool = true
        var current = start
        var path = BezierPath()
        path.move(to: start)
        
        for nextPoint in points {
            if isHorizontal {
                path.addLine(to: Vector2D(nextPoint.x, current.y))
                path.addLine(to: Vector2D(nextPoint.x, nextPoint.y))
            }
            else {
                path.addLine(to: Vector2D(current.x, nextPoint.y))
                path.addLine(to: Vector2D(nextPoint.x, nextPoint.y))
                current = nextPoint
            }
            isHorizontal = !isHorizontal
        }
        
        return path
    }
}
