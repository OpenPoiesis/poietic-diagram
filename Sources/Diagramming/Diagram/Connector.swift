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
    public var objectID: ObjectID?
    public var tag: Int?
    
    /// ID of the origin object if the origin represents a design object.
    ///
    /// It is recommended to set the ID for connectors that are used in interactive
    /// user interfaces.
    ///
    public var originID: ObjectID?

    /// ID of the target object if the target represents a design object.
    ///
    /// It is recommended to set the ID for connectors that are used in interactive
    /// user interfaces.
    ///
    public var targetID: ObjectID?
    
    /// Reasonable offset from the connector line that is used for testing the touch point.
    /// 
    static let TouchOutlineOffset: Double = 10.0

    // TODO: Consider storing just allPoints where origin is first, and target is last. We construct allPoints quite frequently.
    /// The starting point of the connector.
    ///
    public var originPoint: Vector2D {
        didSet { _flush() }
    }
    public var targetPoint: Vector2D {
        didSet { _flush() }
    }
//    public var originPoint: Vector2D
    
    /// The ending point of the connector.
//    public var targetPoint: Vector2D
    
    /// Optional intermediate waypoints the connector routes through.
    public var midpoints: [Vector2D] {
        didSet { _flush() }
    }
    
    /// The connector style (thin or fat) with associated configuration.
    public var style: ConnectorStyle {
        didSet { _flush() }
    }
    
    /// Visual styling properties for colours and line width.
    public var shapeStyle: ShapeStyle
    
    // Cached
    internal var _tessellatedPoints: [Vector2D]?
    
    /// Points of a poly-line that roughly passes through the connector center. Used for touch
    /// detection
    ///
    var tessellatedWirePoints: [Vector2D] {
        if _tessellatedPoints == nil {
            let wire = wirePath()
            // Tessellate the path to convert curves into line segments for distance testing
            // Use a reasonable tolerance for touch detection - doesn't need to be pixel-perfect
            _tessellatedPoints = wire.tessellate(tolerance: 1.0)
        }
        return _tessellatedPoints!
    }
    
    /// Called whenever shape-related properties are changed (not visual style).
    internal func _flush() {
        _tessellatedPoints = nil
    }
    
    public init(objectID: ObjectID? = nil,
                tag: Int? = nil,
                originPoint: Vector2D,
                targetPoint: Vector2D,
                midpoints: [Vector2D] = [],
                style: ConnectorStyle = .thin(ThinConnectorStyle()),
                shapeStyle: ShapeStyle = ShapeStyle()) {
        self.objectID = objectID
        self.tag = tag
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

    @available(*, deprecated, message: "Use DiagramComposer.wire")
    public func wirePath() -> BezierPath {
        return DiagramComposer.wire(connectorStyle: style,
                                    from: originPoint,
                                    to: targetPoint,
                                    midpoints: midpoints)
    }

    /// Get the selection outline polygons.
    ///
    public func selectionOutline(width: Double = 4.0) -> BezierPath {
        // FIXME: [IMPORTANT] This is required so we can replace the Godot rendering
        fatalError("\(#function) not implemented")
    }
    /// Tests if a touch point (with optional radius) intersects with the connector.
    ///
    /// This method determines if a circular touch area intersects with the connector's
    /// logical path, accounting for the connector's visual thickness and an additional
    /// touch-friendly margin.
    ///
    /// The method works by:
    /// 1. Getting the connector's center wire path (handles all line types)
    /// 2. Tessellating curved segments into line segments for distance testing
    /// 3. Computing minimum distance from touch point to any path segment
    /// 4. Comparing against the connector's effective touch radius
    ///
    /// - Parameters:
    ///   - point: The center point of the touch area in diagram coordinates
    ///   - radius: The radius of the touch area (default: 1.0)
    /// - Returns: `true` if the touch area intersects with the connector, `false` otherwise
    ///
    /// ## Touch Calculation
    /// - **Fat connectors**: Uses half the connector width plus touch margin
    /// - **Thin connectors**: Uses only the touch margin (stroke width negligible)
    ///
    /// ## Example
    /// ```swift
    /// let connector = Connector(...)
    /// let touchPoint = Vector2D(100, 200)
    /// 
    /// if connector.containsTouch(at: touchPoint, radius: 5.0) {
    ///     // Handle connector selection
    /// }
    /// ```
    ///
    /// - SeeAlso: ``wirePath()`` for the underlying path used in touch detection
    ///
    public func containsTouch(at point: Vector2D, radius: Double = 1.0) -> Bool {
        // Calculate the effective touch radius based on connector style
        let offset: Double
        switch self.style {
        case .fat(let style): 
            offset = (style.width / 2) + Self.TouchOutlineOffset
        case .thin(_): 
            offset = Self.TouchOutlineOffset
        }
        
        // Test distance from touch point to each path segment
        for i in 0..<tessellatedWirePoints.count - 1 {
            let segment = LineSegment(from: tessellatedWirePoints[i], to: tessellatedWirePoints[i + 1])
            if segment.distance(to: point) <= (offset + radius) {
                return true
            }
        }
        
        return false
    }
}
