//
//  Connector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

import PoieticCore

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
public class Connector: DiagramObject {
    public var objectID: ObjectID
    
    /// The starting point of the connector.
    public var originPoint: Vector2D
    public var targetPoint: Vector2D
//    public var originPoint: Vector2D
    
    /// The ending point of the connector.
//    public var targetPoint: Vector2D
    
    /// Optional intermediate waypoints the connector routes through.
    public var midpoints: [Vector2D]
    
    /// The connector style (thin or fat) with associated configuration.
    public var style: ConnectorStyle
    
    /// Visual styling properties for colours and line width.
    public var shapeStyle: ShapeStyle
    

    public init(objectID: ObjectID,
                originPoint: Vector2D,
                targetPoint: Vector2D,
                midpoints: [Vector2D] = [],
                style: ConnectorStyle = .thin(ThinConnectorStyle()),
                shapeStyle: ShapeStyle = ShapeStyle()) {
        self.objectID = objectID
        self.originPoint = originPoint
        self.targetPoint = targetPoint
        self.midpoints = midpoints
        self.style = style
        self.shapeStyle = shapeStyle
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
    /// - SeeAlso: ``adjacentEndpoints()``.
    ///
    public func arrowhadDirections() -> (origin: Vector2D, target: Vector2D) {
        
        let adjacentOrigin = midpoints.first ?? targetPoint
        let adjacentTarget = midpoints.last ?? originPoint

        return (origin: (originPoint - adjacentOrigin).normalized,
                target: (targetPoint - adjacentTarget).normalized)
    }

    /// Get the selection outline polygons.
    ///
    public func selectionOutline(width: Double = 4.0) -> BezierPath {
        // FIXME: [IMPORTANT] This is required so we can replace the Godot rendering
        fatalError("\(#function) not implemented")
    }
    public func containsTouch(at point: Vector2D, radius: Double=1.0) -> Bool {
        // FIXME: Implement this
        return false
    }

}
