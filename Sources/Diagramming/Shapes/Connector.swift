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
public enum ConnectorStyle: Sendable {
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
    public var id: Diagram.ElementID? = nil
    
    /// The starting point of the connector.
    public var originPoint: Vector2D
    
    /// The ending point of the connector.
    public var targetPoint: Vector2D
    
    /// Optional intermediate waypoints the connector routes through.
    public var midpoints: [Vector2D]
    
    /// The connector style (thin or fat) with associated configuration.
    public var style: ConnectorStyle
    
    /// Visual styling properties for colours and line width.
    public var shapeStyle: ShapeStyle
    

    public init(id: Diagram.ElementID? = nil,
                originPoint: Vector2D = .zero,
                targetPoint: Vector2D = .zero,
                midpoints: [Vector2D] = [],
                style: ConnectorStyle = .thin(ThinConnectorStyle()),
                shapeStyle: ShapeStyle = ShapeStyle()) {
        self.id = id
        self.originPoint = originPoint
        self.targetPoint = targetPoint
        self.midpoints = midpoints
        self.style = style
        self.shapeStyle = shapeStyle
    }
   
    // TODO: This is ported from Godot Poietic Playground
    public func update(originShape: CollisionShape, originPosition: Vector2D, targetShape: CollisionShape, targetPosition: Vector2D) {
        
        let (originSegment, targetSegment) = endpointSegments()
        let originIntersects = Geometry.shapeTouchPoint(from: originSegment.start,
                                                        shape: originShape,
                                                        shapePosition: originPosition)
        let targetIntersects = Geometry.shapeTouchPoint(from: targetSegment.start,
                                                        shape: targetShape,
                                                        shapePosition: targetPosition)
        
        self.originPoint = originIntersects
        self.targetPoint = targetIntersects
        
        
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
    
    /// Get line segments pointing to the connector's endpoints.
    ///
    /// Both segments end at respective endpoint. If the connector has midpoints, then the segments
    /// originate in first midpoint for connector origin and last midpoint for connector target.
    /// If the connector does not have midpoints, then the origin segment originates in target
    /// and vice versa.
    ///
    public func endpointSegments() -> (origin: LineSegment, target: LineSegment) {
        let originSegment: LineSegment
        let targetSegment: LineSegment

        if let first = midpoints.first, let last = midpoints.last {
            originSegment = LineSegment(from: first, to: originPoint)
            targetSegment = LineSegment(from: last, to: targetPoint)
        }
        else {
            originSegment = LineSegment(from: targetPoint, to: originPoint)
            targetSegment = LineSegment(from: originPoint, to: targetPoint)
        }
        return (origin: originSegment, target: targetSegment)
    }

    public func adjacentSegmentPoints(origin: Vector2D, target: Vector2D, midpoints: [Vector2D]) -> (origin: Vector2D, target: Vector2D) {
        let originAdj: Vector2D
        let targetAdj: Vector2D

        if let first = midpoints.first, let last = midpoints.last {
            targetAdj = first
            originAdj = last
        }
        else {
            targetAdj = origin
            originAdj = target
        }
        return (origin: originAdj, target: targetAdj)
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
