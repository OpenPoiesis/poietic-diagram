//
//  Connector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

public enum ConnectorStyle {
    case thin(ThinConnectorStyle)
    case fat(FatConnectorStyle)
}

/// Base class for all connector types
public class Connector {
    public var originPoint: Vector2D
    public var targetPoint: Vector2D
    public var midpoints: [Vector2D]
    public var size: Double
    public var style: ConnectorStyle
    public var shapeStyle: ShapeStyle
    

    public init(originPoint: Vector2D = .zero,
                targetPoint: Vector2D = .zero,
                midpoints: [Vector2D] = [],
                size: Double = 10.0,
                style: ConnectorStyle = .thin(ThinConnectorStyle()),
                shapeStyle: ShapeStyle = ShapeStyle()) {
        self.originPoint = originPoint
        self.targetPoint = targetPoint
        self.midpoints = midpoints
        self.size = size
        self.style = style
        self.shapeStyle = shapeStyle
    }
    
    public func setEndpoints(origin: Vector2D, target: Vector2D) {
        self.originPoint = origin
        self.targetPoint = target
    }
    
    /// Bezier paths forming the connector.
    ///
    /// Use the paths to draw the connector.
    ///
    public func paths() -> [BezierPath] {
        switch style {
        case .thin(let style):
            return thinConnectorPaths(style: style)
        case .fat(let style):
            return [fatConnectorPath(style: style)]
        }
        
    }
    
    /// Get directions for the origin and target arrowheads, considering the midpoints if present.
    ///
    public func arrowhadDirections() -> (origin: Vector2D, target: Vector2D) {
        let targetDir: Vector2D
        let originDir: Vector2D
        
        if let first = midpoints.first, let last = midpoints.last {
            targetDir = (targetPoint - last).normalized
            originDir = (originPoint - first).normalized
        }
        else {
            targetDir = (targetPoint - originPoint).normalized
            originDir = (originPoint - targetPoint).normalized
        }
        return (origin: originDir, target: targetDir)
    }

    /// Get the selection outline polygons.
    ///
    public func getSelectionOutline(width: Double = 4.0) -> [[Vector2D]] {
        fatalError("\(#function) not implemented")
    }
}
