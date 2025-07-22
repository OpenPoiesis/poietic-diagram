//
//  ShapeGeometry.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

public enum LineType: CaseIterable {
    case straight
    case curved
    case orthogonal
}


public enum FatArrowheadType: CaseIterable {
    case none
    case regular
}

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
}

public struct Arrowhead {
    public let path: BezierPath
    /// Distance from intended endpoint to actual line connection point
    public let offset: Double
    
    public init(path: BezierPath, offset: Double) {
        self.path = path
        self.offset = offset
    }
}

public class ShapeGeometry {
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
//            path.addLine(to: c4)
//            path.addLine(to: c1)
//        case .nonNavigable:  // X-shaped
//            let c1 = headPoint - direction * size - perpendicular * (size / 2)
//            let c2 = c1 + direction * (size * 2)
//            let c3 = c2 + perpendicular * size
//            let c4 = c3 - direction * (size * 2)
//            path.move(to: c1)
//            path.addLine(to: c3)
//            path.move(to: c2)
//            path.addLine(to: c4)
            
        case .ball:
            let radius = size / 2
            let center = headPoint - direction * radius
            path = BezierPath(circle: center, radius: radius)
            
        case .ballCenter:
            let radius = size / 2
            path = BezierPath(circle: headPoint, radius: radius)
        }
        
        let offset = getTouchPointOffset(size: size, type: type)
        return Arrowhead(path: path, offset: offset)
    }
    
    /// Create a fat arrowhead (filled polygon) at the specified point
    public static func createFatArrowhead(at headPoint: Vector2D,
                                          direction: Vector2D,
                                          size: Double,
                                          type: FatArrowheadType) -> (polygon: [Vector2D], offset: Double) {
        // TODO: Make return value a struct
        let perpendicular = Vector2D(-direction.y, direction.x)
        
        switch type {
        case .none:
            return ([], 0)
            
        case .regular:
            let p1 = headPoint - (direction * size) + (perpendicular * size / 2)
            let p2 = headPoint - (direction * size) - (perpendicular * size / 2)
            let polygon = [p2, p1, headPoint, p2]
            return (polygon, size)
        }
    }
    
    /// Get the offset distance for where the line should connect to the arrowhead
    private static func getTouchPointOffset(size: Double, type: ThinArrowheadType) -> Double {
        switch type {
        case .none, .stick, .bar, .negative, .nonNavigable:
            return 0
        case .diamond, .box, .ball:
            return size
        case .ballCenter:
            return size / 2
        }
    }
    
    public static func createThinArrow(origin originPoint: Vector2D,
                                 target targetPoint: Vector2D,
                                 midpoints: [Vector2D] = [],
                                 headType: ThinArrowheadType = .stick,
                                 tailType: ThinArrowheadType = .none,
                                 lineType: LineType = .straight,
                                 size: Double = 10.0) -> [BezierPath] {
        var paths: [BezierPath] = []
        // Calculate directions
        let targetDirection: Vector2D
        let originDirection: Vector2D
        
        if let first = midpoints.first, let last = midpoints.last {
            targetDirection = (targetPoint - last).normalized
            originDirection = (originPoint - first).normalized
        }
        else {
            targetDirection = (targetPoint - originPoint).normalized
            originDirection = (originPoint - targetPoint).normalized
        }
        
        // Create arrowheads
        let headArrowhead = Self.createThinArrowhead(at: targetPoint,
                                                direction: targetDirection,
                                                size: size,
                                                type: headType)
        
        let tailArrowhead = Self.createThinArrowhead(at: originPoint,
                                                direction: originDirection,
                                                size: size,
                                                type: tailType)
        
        if !headArrowhead.path.isEmpty {
            paths.append(headArrowhead.path)
        }
        if !tailArrowhead.path.isEmpty {
            paths.append(tailArrowhead.path)
        }
        
        // Calculate clipped endpoints
        let clippedOrigin = originPoint - (originDirection * tailArrowhead.offset)
        let clippedTarget = targetPoint - (targetDirection * headArrowhead.offset)
        
        // Create main line
        let mainLine: BezierPath
        switch lineType {
        case .straight:
            mainLine = Self.createStraightLine(origin: clippedOrigin,
                                             target: clippedTarget,
                                             midpoints: midpoints)
        case .curved:
            mainLine = Self.createCurvedLine(origin: clippedOrigin,
                                             target: clippedTarget,
                                             midpoints: midpoints)
        case .orthogonal:
            mainLine = Self.createOrthogonalLine(origin: clippedOrigin,
                                                 target: clippedTarget,
                                                 midpoints: midpoints)
        }
        
        paths.append(mainLine)
        
        return paths
    }
    public static func createStraightLine(origin: Vector2D,
                                          target: Vector2D,
                                          midpoints: [Vector2D]) -> BezierPath {
        var path = BezierPath()
        
        path.move(to: origin)
        for midpoint in midpoints {
            path.addLine(to: midpoint)
        }
        path.addLine(to: target)
        return path
    }

    public static func createCurvedLine(origin: Vector2D,
                                        target: Vector2D,
                                        midpoints: [Vector2D]) -> BezierPath {
        var path = BezierPath()
        
        if midpoints.isEmpty {
            // Simple curved line between two points
            let controlOffset = (target - origin).length * 0.3
            let perpendicular = Vector2D(-(target - origin).normalized.y, (target - origin).normalized.x)
            let control1 = origin + perpendicular * controlOffset
            let control2 = target + perpendicular * controlOffset
            
            path.move(to: origin)
            path.addCurve(to: target, control1: control1, control2: control2)
        } else {
            // Catmull-Rom style interpolation with midpoint
            let midpoint = midpoints[0] // Use first midpoint for now
            path.move(to: origin)
            path.addCurve(to: midpoint,
                          control1: origin,
                          control2: origin + (midpoint - origin) / 6.0)
            path.addCurve(to: target,
                          control1: midpoint + (target - origin) / 6.0,
                          control2: target - (target - midpoint) / 6.0)
        }
        
        return path
    }
    
    public static func createOrthogonalLine(origin: Vector2D,
                                      target: Vector2D,
                                      midpoints: [Vector2D]) -> BezierPath {
        var path = BezierPath()
        path.move(to: origin)
        
        // TODO: Add curved corners. Requires corner radius as parameter.
        if midpoints.isEmpty {
            let midX = (origin.x + target.x) / 2
            path.addLine(to: Vector2D(midX, origin.y))
            path.addLine(to: Vector2D(midX, target.y))
        } else {
            // Use provided midpoints
            for point in midpoints {
                path.addLine(to: point)
            }
        }
        
        path.addLine(to: target)
        return path
    }

}
