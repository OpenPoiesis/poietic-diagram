//
//  Connector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//

import PoieticCore

/// Parameter edge: origin, target, edge[midpoints]
/// Flow:
///     origin: origin stock
///     target: target stock
///     midpoints: origin edge midpoints + flow position + target edge midpoints
///
public struct ConnectorComponent: NEWDiagramObject, Component {
    internal init(representedObjectID: ObjectID? = nil,
                  originID: RuntimeEntityID,
                  targetID: RuntimeEntityID,
                  glyph: ConnectorGlyph,
                  midpoints: [Vector2D] = []) {
        self.representedObjectID = representedObjectID
        self.originID = originID
        self.targetID = targetID
        self.glyph = glyph
        self.midpoints = midpoints
    }
    
    public let representedObjectID: ObjectID?
    /// Name of connector style.
    ///
    /// Refers to a style defined in ``DiagramStyle/connectorStyles``.
    ///
    public let glyph: ConnectorGlyph
    
    /// Runtime entity with ``BlockComponent``.
    public let originID: RuntimeEntityID
    /// Runtime entity with ``BlockComponent``.
    public let targetID: RuntimeEntityID
    
    public let midpoints: [Vector2D]
}

/// Created from ``ConnectorComponent`` + style
public struct ConnectorGeometryComponent: Component {
    public let wirePoints: [Vector2D]
    public let linePath: BezierPath?
    public let fillPath: BezierPath?
    public let tailArrowhead: BezierPath?
    public let headArrowhead: BezierPath?
}

public struct ThinConnector {
    public let tail: BezierPath
    public let body: BezierPath
    public let head: BezierPath
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
public struct Connector {
    public let objectID: ObjectID?
    public let tag: Int?
    
    /// ID of the origin object if the origin represents a design object.
    ///
    /// It is recommended to set the ID for connectors that are used in interactive
    /// user interfaces.
    ///
    public let originID: ObjectID?
    
    /// ID of the target object if the target represents a design object.
    ///
    /// It is recommended to set the ID for connectors that are used in interactive
    /// user interfaces.
    ///
    public let targetID: ObjectID?
    
    /// Reasonable offset from the connector line that is used for testing the touch point.
    ///
    static let TouchOutlineOffset: Double = 10.0
    
    /// The starting point of the connector.
    ///
    public let originPoint: Vector2D
    public let targetPoint: Vector2D
    //    public var originPoint: Vector2D
    
    /// The ending point of the connector.
    //    public var targetPoint: Vector2D
    
    /// Optional intermediate waypoints the connector routes through.
    public let midpoints: [Vector2D]
    
    /// The connector style (thin or fat) with associated configuration.
    public let glyph: ConnectorGlyph
    
    /// Visual styling properties for colours and line width.
    public let shapeStyle: ShapeStyle
    
    /// Points of a poly-line that roughly passes through the connector center. Used for touch
    /// detection
    ///
    var tessellatedWirePoints: [Vector2D] {
        let wire = Geometry.wirePath(from: originPoint,
                                     to: targetPoint,
                                     through: midpoints,
                                     lineType: glyph.lineType)
        // Tessellate the path to convert curves into line segments for distance testing
        // Use a reasonable tolerance for touch detection - doesn't need to be pixel-perfect
        return wire.tessellate(tolerance: 1.0)
    }
    
    public init(objectID: ObjectID? = nil,
                tag: Int? = nil,
                originPoint: Vector2D,
                targetPoint: Vector2D,
                midpoints: [Vector2D] = [],
                glyph: ConnectorGlyph = .defaultThin,
                shapeStyle: ShapeStyle = ShapeStyle()) {
        self.objectID = objectID
        self.tag = tag
        self.originPoint = originPoint
        self.targetPoint = targetPoint
        self.midpoints = midpoints
        self.glyph = glyph
        self.shapeStyle = shapeStyle
    }
#if false
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
#endif
}
