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
    
    public static let defaultThin: ConnectorStyle = .thin(ThinConnectorStyle())
    public static let defaultFat: ConnectorStyle = .fat(FatConnectorStyle())

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
    public var id: Diagram.ElementKey? = nil
    
    /// The starting point of the connector.
    public var origin: Block
    public var target: Block
//    public var originPoint: Vector2D
    
    /// The ending point of the connector.
//    public var targetPoint: Vector2D
    
    /// Optional intermediate waypoints the connector routes through.
    public var midpoints: [Vector2D]
    
    /// The connector style (thin or fat) with associated configuration.
    public var style: ConnectorStyle
    
    /// Visual styling properties for colours and line width.
    public var shapeStyle: ShapeStyle
    

    public init(id: Diagram.ElementKey? = nil,
                origin: Block,
                target: Block,
                midpoints: [Vector2D] = [],
                style: ConnectorStyle = .thin(ThinConnectorStyle()),
                shapeStyle: ShapeStyle = ShapeStyle()) {
        self.id = id
        self.origin = origin
        self.target = target
        self.midpoints = midpoints
        self.style = style
        self.shapeStyle = shapeStyle
    }
   
    /// Compute touch points to origin and target blocks.
    ///
    /// The touch point is computed as a an intersection of block's collision shape and a
    /// ray originating from the first adjacent point to the endpoint. If no intersection is found,
    /// then the endpoint block position is returned for given endpoint.
    ///
    public func touchPoints() -> (origin: Vector2D, target: Vector2D) {
        let adjacent = adjacentEndpoints()
        let originDirection = (origin.position - adjacent.origin).normalized
        let targetDirection = (target.position - adjacent.target).normalized

        // TODO: We are re-computing points for polygon shapes on each call here
        // TODO: We are re-computing collision shape
        let originTouch = Geometry.rayIntersection(shape: origin.collisionShape.shape,
                                                   position: origin.collisionShape.position,
                                                   from: adjacent.origin,
                                                   direction: originDirection)
        let targetTouch = Geometry.rayIntersection(shape: target.collisionShape.shape,
                                                   position: target.collisionShape.position,
                                                   from: adjacent.target,
                                                   direction: targetDirection)
        return (origin: originTouch ?? origin.position, target: targetTouch ?? target.position)
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
    
    /// Get points that are adjacent to the endpoints of the connector.
    ///
    /// Adjacent point to the origin is the first midpoint or the target position if there are
    /// no midpoints. Analogously, adjacent point to the target is the last midpoint or the
    /// origin position.
    ///
    /// - SeeAlso: ``arrowhadDirections()``
    ///
    public func adjacentEndpoints() -> (origin: Vector2D, target: Vector2D) {
        return (origin: midpoints.first ?? target.position,
                target: midpoints.last ?? origin.position)
    }

    /// Get directions for the origin and target arrowheads, considering the midpoints if present.
    ///
    /// - SeeAlso: ``adjacentEndpoints()``.
    ///
    public func arrowhadDirections() -> (origin: Vector2D, target: Vector2D) {
        let adjacent = adjacentEndpoints()

        return (origin: (origin.position - adjacent.origin).normalized,
                target: (target.position - adjacent.target).normalized)
    }

    /// Get the selection outline polygons.
    ///
    public func selectionOutline(width: Double = 4.0) -> BezierPath {
        // FIXME: [IMPORTANT] This is required so we can replace the Godot rendering
        fatalError("\(#function) not implemented")
    }
}
