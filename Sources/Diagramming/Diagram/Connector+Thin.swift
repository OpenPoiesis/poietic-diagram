//
//  Connector+Thin.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

/// Style configuration for thin (stroke-based) connectors.
///
/// Defines the visual properties for connectors drawn as stroked paths with separate arrowhead elements.
/// Supports different arrowhead types at both ends and various line drawing styles.
///
public struct ThinConnectorStyle: Sendable {
    /// The arrowhead type at the target endpoint.
    public var headType: ThinArrowheadType
    
    /// The arrowhead type at the origin endpoint.
    public var tailType: ThinArrowheadType
    
    /// The size of the arrowhead at the target endpoint in points.
    public var headSize: Double
    
    /// The size of the arrowhead at the origin endpoint in points.
    public var tailSize: Double
    
    /// The line drawing style for the connector body.
    public var lineType: LineType
    
    public init(headType: ThinArrowheadType = .stick,
                tailType: ThinArrowheadType = .none,
                headSize: Double = 10.0,
                tailSize: Double? = nil,
                lineType: LineType = .straight) {
        self.headType = headType
        self.tailType = tailType
        self.headSize = headSize
        self.tailSize = tailSize ?? headSize
        self.lineType = lineType
    }
}

/// A thin arrowhead represented as a stroke path with connection offset.
///
/// Contains the Bezier path for drawing the arrowhead and the offset distance
/// from the intended endpoint to where the connector line should actually connect.
///
public struct Arrowhead: Sendable {
    /// The Bezier path defining the arrowhead geometry.
    public let path: BezierPath
    
    /// Distance from intended endpoint to actual line connection point in points.
    public let offset: Double
    
    public init(path: BezierPath, offset: Double) {
        self.path = path
        self.offset = offset
    }
}

extension Connector {
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
    public func thinConnectorPaths(style: ThinConnectorStyle) -> [BezierPath] {
        var paths: [BezierPath] = []

        let (originDir, targetDir) = arrowhadDirections()
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
            path = Geometry.orthogonalPolyline(from: clippedOrigin, to: clippedTarget, through: midpoints)
        }
        
        paths.append(path)
        
        return paths
    }
    
    
}
