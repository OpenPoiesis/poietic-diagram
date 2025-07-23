//
//  Connector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

/// Style variants for connectors.
///
/// Defines whether a connector should be drawn as thin stroked paths or fat filled polygons.
///
public enum ConnectorStyle {
    /// Thin connector drawn as stroked paths with separate arrowhead elements.
    case thin(ThinConnectorStyle)
    
    /// Fat connector drawn as a single filled polygon with integrated arrowheads.
    case fat(FatConnectorStyle)
}

/// A connector between two points with optional intermediate waypoints.
///
/// Connectors visually represent relationships or flows between diagram elements.
/// They can be rendered as either thin stroked paths or fat filled polygons,
/// with configurable arrowheads at either or both endpoints.
///
/// The connector supports:
///
/// - Direct connections between origin and target points
/// - Routing through intermediate midpoints
/// - Different visual styles (thin stroke vs fat polygon)
/// - Configurable arrowheads with various types and sizes
/// - Visual styling through ShapeStyle properties
///
public class Connector {
    /// The starting point of the connector.
    public var originPoint: Vector2D
    
    /// The ending point of the connector.
    public var targetPoint: Vector2D
    
    /// Optional intermediate waypoints the connector routes through.
    public var midpoints: [Vector2D]
    
    /// The base size used for arrowheads and other size-dependent elements.
    public var size: Double
    
    /// The connector style (thin or fat) with associated configuration.
    public var style: ConnectorStyle
    
    /// Visual styling properties for colours and line width.
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
