//
//  DiagramPresenter.swift
//  poietic-godot
//
//  Created by Stefan Urbanek on 19/08/2025.
//
// FIXME: Change order so that head/tail props are together
import PoieticCore

public class DiagramStyle {
    static let DefaultPictogramName = "default"
    static let DefaultConnectorStyleName = "default"

    public let pictograms: PictogramCollection
    public let defaultPictogram: Pictogram
    
    public let connectorStyles: [String:ConnectorStyle]
    public let defaultConnectorStyle: ConnectorStyle

    public init(pictograms: PictogramCollection? = nil,
                defaultPictogram: Pictogram? = nil,
                connectorStyles: [String:ConnectorStyle] = [:],
                defaultConnectorStyle: ConnectorStyle? = nil) {
        self.pictograms = pictograms ?? PictogramCollection()
        self.defaultPictogram = defaultPictogram
                ?? self.pictograms.pictogram(Self.DefaultPictogramName)
                ?? Pictogram(Self.DefaultPictogramName, circleWithRadius: 10.0)
        self.connectorStyles = connectorStyles
        self.defaultConnectorStyle = defaultConnectorStyle
                ?? self.connectorStyles[Self.DefaultConnectorStyleName]
                ?? .defaultThin
    }
    
    /// Get a pictogram by name. If there is no pictogram with given name, then returns default
    /// pictogram.
    ///
    public func pictogram(_ name: String) -> Pictogram {
        return pictograms.pictogram(name) ?? defaultPictogram
    }

    /// Get connector style by name. If there is no connector style with given name, returns
    /// default connector style.
    ///
    public func connectorStyle(_ name: String) -> ConnectorStyle {
        return connectorStyles[name] ?? defaultConnectorStyle
    }
}

public let StockFlowConnectorStyles: [String:ConnectorStyle] = [
    "_default": .thin(ThinConnectorStyle(
        headType: .none,
        tailType: .none,
        headSize: 0.0,
        tailSize: 0.0,
        lineType: .straight
    )),

    "Parameter": .thin(ThinConnectorStyle(
        headType: .stick,
        tailType: .ball,
        headSize: 10.0,
        tailSize: 5.0,
        lineType: .curved
    )),

    "Flow": .fat(FatConnectorStyle(
        headType: .regular,
        tailType: .none,
        headSize: 20.0,
        tailSize: 0.0,
        width: 10.0,
        joinType: .round
    ))
]

extension Connector {
    /// Compute touch points to origin and target blocks.
    ///
    /// The touch point is computed as a an intersection of block's collision shape and a
    /// ray originating from the first adjacent point to the endpoint. If no intersection is found,
    /// then the endpoint block position is returned for given endpoint.
    ///
    public static func touchPoints(origin: Block,
                                   target: Block,
                                   midpoints: [Vector2D]) -> (origin: Vector2D, target: Vector2D){
        let originShapePosition = origin.position + origin.collisionShape.position
        let originTouch = touchPoint(shape: origin.collisionShape.shape,
                                     position: originShapePosition,
                                     from: midpoints.first ?? target.position,
                                     towards: origin.position)
        let targetShapePosition = target.position + target.collisionShape.position
        let targetTouch = touchPoint(shape: target.collisionShape.shape,
                                     position: targetShapePosition,
                                     from: midpoints.last ?? origin.position,
                                     towards: target.position)
        return (origin: originTouch, target:targetTouch)
    }
    // FIXME: Change to (from:touching:at:)
    public static func touchPoint(shape: ShapeType,
                                  position: Vector2D,
                                  from startPoint: Vector2D,
                                  towards endPoint: Vector2D) -> Vector2D {
        let direction = (endPoint - startPoint).normalized
        let touch = Geometry.rayIntersection(shape: shape,
                                             position: position,
                                             from: startPoint,
                                             direction: direction)
        return touch ?? endPoint
    }
}

// Makes Design -> Diagram -> Canvas
public class DiagramComposer {
    let style: DiagramStyle
    let pictogramAliases: [String:String]
    
    public init(style: DiagramStyle, pictogramAliases: [String:String] = [:]) {
        self.style = style
        self.pictogramAliases = pictogramAliases
    }
    
    /// Gets a pictogram based on object type from the associated pictogram collection.
    ///
    /// First, a map ``typePictogramMap`` is used to get a pictogram. If there is no type name
    /// mapping or if no such pictogram exists, then pictogram with name as the object's type name
    /// is tried. When there is no such pictogram, then default pictogram for unknown object is
    /// used.
    ///
    /// - SeeAlso: ``pictograms``, ``unknownPictogram``
    ///
    func pictogram(for object: ObjectSnapshot) -> Pictogram {
        if let name = pictogramAliases[object.type.name],
           let picto = style.pictograms.pictogram(name) {
            return picto
        }
        else if let picto = style.pictograms.pictogram(object.type.name) {
            return picto
        }
        else {
            return style.defaultPictogram
        }
    }
    
    public func connectorStyle(for object: ObjectSnapshot) -> ConnectorStyle {
        if let style = style.connectorStyles[object.type.name] {
            return style
        }
        else {
            return style.defaultConnectorStyle
        }
    }

    public func connectorStyle(forType typeName: String) -> ConnectorStyle {
        if let style = style.connectorStyles[typeName] {
            return style
        }
        else {
            return style.defaultConnectorStyle
        }
    }

    /// Returns the center wire path of a connector regardless of visual style.
    ///
    /// This method returns the logical connection path that represents the center line
    /// of the connector, without visual styling elements like arrowheads, stroke width,
    /// or fill polygons. The path follows the connector's line type (straight, curved,
    /// or orthogonal) and routes through all midpoints.
    ///
    /// This is useful for:
    /// - Touch detection and hit testing
    /// - Logical path analysis
    /// - Computing connector geometry independent of visual presentation
    ///
    /// - Returns: A `BezierPath` representing the center wire of the connector
    ///
    public static func wire(connectorStyle: ConnectorStyle,
                            from originPoint: Vector2D,
                            to targetPoint: Vector2D,
                            midpoints: [Vector2D]) -> BezierPath
    {
        let allPoints = [originPoint] + midpoints + [targetPoint]
        
        let lineType: LineType
        switch connectorStyle {
        case .thin(let thinStyle):
            lineType = thinStyle.lineType
        case .fat(_):
            // Fat connectors currently only support straight lines
            // This can be extended in the future to support other line types
            lineType = .straight
        }
        
        switch lineType {
        case .straight:
            return BezierPath(polyline: allPoints)
        case .curved:
            return BezierPath(curveThrough: allPoints)
        case .orthogonal:
            return BezierPath(orthogonalPolylineThrough: allPoints)
        }
    }
    
    
    /// Creates a diagram from objects in the frame.
    ///
    /// The objects with the trait `DiagramBlock` will be used to create ``Block``
    /// and the objects with the trait `DiagramConnector` will be used to create ``Connector``.
    ///
    /// - Precondition: Edges representing diagram connectors must connects nodes that are
    ///   represented by diagram blocks.
    ///
    @available(*, deprecated, message: "Do not use")
    public func createDiagram(from frame: DesignFrame) -> Diagram {
        // TODO: Add incremental diagram update (only changed)
        let diagram = Diagram()
        
        var blocks: [ObjectID:Block] = [:]
        
        let nodes = frame.nodes(withTrait: .DiagramBlock)
        for node in nodes {
            let block = createBlock(node)
            diagram.insertBlock(block)
            blocks[node.objectID] = block
        }
        
        let edges = frame.edges(withTrait: .DiagramConnector)
        for edge in edges {
            guard let origin = blocks[edge.origin], let target = blocks[edge.target] else {
                // FIXME: [IMPORTANT] Handle with grace
                preconditionFailure("Connector has no origin or target as diagram node")
            }
            let connector = createConnector(edge, origin: origin, target: target)
            diagram.insertConnector(connector)
        }
        
        return diagram
    }
    
    /// Create a block from object snapshot.
    ///
    /// - SeeAlso: ``createConnector(_:origin:target:)``
    public func createBlock(_ node: ObjectSnapshot) -> Block {
        let block = Block(
            objectID: node.objectID,
            position: node.position ?? .zero,
            pictogram: pictogram(for: node),
            label: node.label,
            secondaryLabel: node.secondaryLabel
        )
        
        return block
    }
    public func updateBlock(block: Block, node: ObjectSnapshot) {
        block.objectID = node.objectID
        block.position = node.position ?? .zero
        block.pictogram = pictogram(for: node)
        block.label = node.label
        block.secondaryLabel = node.secondaryLabel
    }

    /// Create a connector from an edge object between two blocks.
    ///
    /// The connector touch points are computed using block's collision shape and edge's endpoints.
    ///
    /// - SeeAlso: ``createBlock(_:)``, ``updateConnector(connector:edge:origin:target:)``
    /// - SeeAlso: ``Connector/touchPoints(origin:target:midpoints:)``
    ///
    public func createConnector(_ edge: EdgeObject, origin: Block, target: Block) -> Connector {
        let midpoints: [Point] = (try? edge.object["midpoints"]?.pointArray()) ?? []
        
        let style: ConnectorStyle = connectorStyle(for: edge.object)
        
        let (originTouch, targetTouch) = Connector.touchPoints(origin: origin,
                                                               target: target,
                                                               midpoints: midpoints)
        
        let connector = Connector(
            objectID: edge.key,
            originPoint: originTouch,
            targetPoint: targetTouch,
            midpoints: midpoints,
            style: style
        )
        
        return connector
    }
    
    /// Update existing connector from an edge and blocks it connects.
    ///
    /// Use this function when one of the blocks has moved to recompute touch points.
    ///
    /// - SeeAlso: ``createConnector(_:origin:target:)``
    ///
    public func updateConnector(connector: Connector, edge: EdgeObject, origin: Block, target: Block) {
        let midpoints: [Point] = (try? edge.object["midpoints"]?.pointArray()) ?? []
        let style: ConnectorStyle = connectorStyle(for: edge.object)
        let (originTouch, targetTouch) = Connector.touchPoints(origin: origin,
                                                               target: target,
                                                               midpoints: midpoints)
        connector.objectID = edge.key
        connector.originPoint = originTouch
        connector.targetPoint = targetTouch
        connector.midpoints = midpoints
        connector.style = style
    }
    public func updateConnector(connector: Connector, origin: Block, target: Block) {
        let (originTouch, targetTouch) = Connector.touchPoints(origin: origin,
                                                               target: target,
                                                               midpoints: connector.midpoints)
        connector.originPoint = originTouch
        connector.targetPoint = targetTouch
    }

}
