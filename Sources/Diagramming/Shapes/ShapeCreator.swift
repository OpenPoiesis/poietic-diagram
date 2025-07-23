//
//  ShapeGeometry.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

import Foundation

public enum LineType: CaseIterable {
    case straight
    case curved
    case orthogonal
}

public enum JoinType: CaseIterable {
    case miter    // Sharp corners
    case round    // Rounded corners  
    case bevel    // Cut-off corners
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

public struct FatArrowhead {
    public let polygon: [Vector2D]
    public let offset: Double
    
    public init(polygon: [Vector2D], offset: Double) {
        self.polygon = polygon
        self.offset = offset
    }
}

public struct PolylineOutline {
    public let leftPath: BezierPath
    public let rightPath: BezierPath
    public let startLeftCorner: Vector2D
    public let startRightCorner: Vector2D
    public let endLeftCorner: Vector2D
    public let endRightCorner: Vector2D
    
    public init(leftPath: BezierPath, rightPath: BezierPath,
                startLeftCorner: Vector2D, startRightCorner: Vector2D,
                endLeftCorner: Vector2D, endRightCorner: Vector2D) {
        self.leftPath = leftPath
        self.rightPath = rightPath
        self.startLeftCorner = startLeftCorner
        self.startRightCorner = startRightCorner
        self.endLeftCorner = endLeftCorner
        self.endRightCorner = endRightCorner
    }
}

public class Geometry {
    public static func arrowhadDirections(origin: Vector2D,
                                          target: Vector2D,
                                          midpoints: [Vector2D]
    ) -> (origin: Vector2D, target: Vector2D) {
        let targetDir: Vector2D
        let originDir: Vector2D
        
        if let first = midpoints.first, let last = midpoints.last {
            targetDir = (target - last).normalized
            originDir = (origin - first).normalized
        }
        else {
            targetDir = (target - origin).normalized
            originDir = (origin - target).normalized
        }
        return (origin: originDir, target: targetDir)
    }

    public static func createFatArrow(origin: Vector2D,
                                      target: Vector2D,
                                      style: FatConnectorStyle,
                                      midpoints: [Vector2D] = []
    ) -> BezierPath {
        
        let (originDir, targetDir) = Self.arrowhadDirections(origin: origin,
                                                             target: target,
                                                             midpoints: midpoints)
        // TODO: Make fat arrowhead size two-dimensional. For now, we just use this magic ratio.
        let PleasantMagicScale = 1.5
        
        let clippedOrigin = origin - (originDir * style.tailType.touchPointOffset(style.tailSize * PleasantMagicScale))
        let clippedTarget = target - (targetDir * style.headType.touchPointOffset(style.headSize * PleasantMagicScale))

        let points =  [clippedOrigin] + midpoints + [clippedTarget]
        let pathThere = Self.offsetPolyline(points, offset: style.width, joinType: style.joinType)
        let pathBack = Self.offsetPolyline(points.reversed(), offset: style.width, joinType: style.joinType)

        var path = BezierPath()

        path.move(to: pathThere[0])
        
        for point in pathThere.dropFirst() {
            path.addLine(to: point)
        }

        switch style.headType {
        case .none:
            path.addLine(to: pathBack[0])
        case .regular:
            appendFatArrowhead(path: &path,
                               endpoint: target,
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
            appendFatArrowhead(path: &path,
                               endpoint: origin,
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
