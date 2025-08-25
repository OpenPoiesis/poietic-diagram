//
//  Connector+Fat.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

/// Style configuration for fat (filled polygon) connectors.
///
/// Defines the visual properties for connectors drawn as single filled polygon shapes
/// with integrated arrowheads. The entire connector including arrowheads is rendered
/// as one continuous filled path.
///
public struct FatConnectorStyle: Sendable {
    /// The arrowhead type at the target endpoint.
    public var headType: FatArrowheadType
    
    /// The arrowhead type at the origin endpoint.
    public var tailType: FatArrowheadType
    
    /// The size of the arrowhead at the target endpoint in points.
    public var headSize: Double
    
    /// The size of the arrowhead at the origin endpoint in points.
    public var tailSize: Double
    
    /// The width of the connector body in points.
    public var width: Double
    
    /// How line segments are joined at corners in the polygon.
    public var joinType: JoinType
    
    public init(headType: FatArrowheadType = .regular,
                tailType: FatArrowheadType = .none,
                headSize: Double = 10.0,
                tailSize: Double? = nil,
                width: Double = 7.0,
                joinType: JoinType = .miter) {
        self.headType = headType
        self.tailType = tailType
        self.headSize = headSize
        self.tailSize = tailSize ?? headSize
        self.width = width
        self.joinType = joinType
    }
}

/// A fat arrowhead represented as a polygon with connection offset.
///
/// Contains the polygon points for the arrowhead and the offset distance
/// from the intended endpoint to where the connector body should connect.
///
public struct FatArrowhead {
    /// The polygon points defining the arrowhead geometry.
    public let polygon: [Vector2D]
    
    /// Distance from intended endpoint to actual connector body connection point in points.
    public let offset: Double
    
    public init(polygon: [Vector2D], offset: Double) {
        self.polygon = polygon
        self.offset = offset
    }
}

extension Connector {
    /// Create a bezier path of a fat (outlined) connector, including arrowheads.
    ///
    public func fatConnectorPath(style: FatConnectorStyle) -> BezierPath {
        
        let (originDir, targetDir) = arrowhadDirections()
        // FIXME: This is just a rename after refactor, use *point
        let (originTouch, targetTouch) = (originPoint, targetPoint)
        
        // TODO: Make fat arrowhead size two-dimensional. For now, we just use this magic ratio.
        let PleasantMagicScale = 1.5
        
        let clippedOrigin = originTouch - (originDir * style.tailType.touchPointOffset(style.tailSize * PleasantMagicScale))
        let clippedTarget = targetTouch - (targetDir * style.headType.touchPointOffset(style.headSize * PleasantMagicScale))

        let points =  [clippedOrigin] + midpoints + [clippedTarget]
        let pathThere = Geometry.offsetPolyline(points, offset: style.width, joinType: style.joinType)
        let pathBack = Geometry.offsetPolyline(points.reversed(), offset: style.width, joinType: style.joinType)

        var path = BezierPath()

        path.move(to: pathThere[0])
        
        for point in pathThere.dropFirst() {
            path.addLine(to: point)
        }

        switch style.headType {
        case .none:
            path.addLine(to: pathBack[0])
        case .regular:
            Self.appendFatArrowhead(path: &path,
                                    endpoint: targetTouch,
                                    direction: targetDir,
                                    connectIn: pathThere.last!,
                                    connectOut: pathBack.first!,
                                    size: style.headSize)
        }
        
        for point in pathBack.dropFirst() {
            path.addLine(to: point)
        }

        switch style.tailType {
        case .none:
            path.addLine(to: pathThere[0])
        case .regular:
            Self.appendFatArrowhead(path: &path,
                                    endpoint: originTouch,
                                    direction: originDir,
                                    connectIn: pathBack.last!,
                                    connectOut: pathThere.first!,
                                    size: style.tailSize)
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
