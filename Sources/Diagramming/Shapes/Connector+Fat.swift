//
//  Connector+Fat.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 23/07/2025.
//

/// Connector drawn as filled polygons
public struct FatConnectorStyle {
    public var headType: FatArrowheadType
    public var tailType: FatArrowheadType
    public var headSize: Double
    public var tailSize: Double
    public var width: Double
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

public struct FatArrowhead {
    public let polygon: [Vector2D]
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
        // TODO: Make fat arrowhead size two-dimensional. For now, we just use this magic ratio.
        let PleasantMagicScale = 1.5
        
        let clippedOrigin = originPoint - (originDir * style.tailType.touchPointOffset(style.tailSize * PleasantMagicScale))
        let clippedTarget = targetPoint - (targetDir * style.headType.touchPointOffset(style.headSize * PleasantMagicScale))

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
                                    endpoint: targetPoint,
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
                                    endpoint: originPoint,
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
