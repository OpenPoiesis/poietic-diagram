//
//  Connector.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/07/2025.
//


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
    public func paths() -> [BezierPath] {
        switch style {
        case .thin(let style):
            let paths = ShapeGeometry.createThinArrow(
                origin: originPoint,
                target: targetPoint,
                midpoints: midpoints,
                headType: style.headType,
                tailType: style.tailType,
                lineType: style.lineType,
                size: size
            )
            return paths
        case .fat(let style):
            fatalError("Fat connector paths not implemented")
        }
    }
    
    /// Get the selection outline polygons
    public func getSelectionOutline(width: Double = 4.0) -> [[Vector2D]] {
        // To be overridden by subclasses
        return []
    }
}


public enum ConnectorStyle {
    case thin(ThinConnectorStyle)
    case fat(FatConnectorStyle)
}

public struct ThinConnectorStyle {
    public var headType: ThinArrowheadType
    public var tailType: ThinArrowheadType
    public var lineType: LineType
    
    public init(headType: ThinArrowheadType = .stick,
                tailType: ThinArrowheadType = .none,
                lineType: LineType = .straight) {
        self.headType = headType
        self.tailType = tailType
        self.lineType = lineType
    }
}
/// Connector drawn as filled polygons
public struct FatConnectorStyle {
    public var headType: FatArrowheadType
    public var tailType: FatArrowheadType
    public var width: Double
    
    public init(headType: FatArrowheadType = .regular,
                tailType: FatArrowheadType = .none,
                width: Double = 7.0) {
        self.headType = headType
        self.tailType = tailType
        self.width = width
    }
}
