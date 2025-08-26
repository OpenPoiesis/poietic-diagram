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
        let originTouch = touchPoint(touching: origin.collisionShape,
                                     from: midpoints.first ?? target.position,
                                     towards: origin.position)
        let targetTouch = touchPoint(touching: target.collisionShape,
                                     from: midpoints.last ?? origin.position,
                                     towards: target.position)
        return (origin: originTouch, target:targetTouch)
    }

    static func touchPoint(touching shape: CollisionShape,
                           from startPoint: Vector2D,
                           towards endPoint: Vector2D) -> Vector2D {
        
        let direction = (endPoint - startPoint).normalized
        let touch = Geometry.rayIntersection(shape: shape, from: startPoint, direction: direction)
        return touch ?? endPoint
    }
}

// Makes Design -> Diagram -> Canvas
// FIXME: Rename to "DiagramComposer"
public class DiagramPresenter {
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
    
    func connectorStyle(for object: ObjectSnapshot) -> ConnectorStyle {
        if let style = style.connectorStyles[object.type.name] {
            return style
        }
        else {
            return style.defaultConnectorStyle
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
    public func createDiagram(from frame: StableFrame) -> Diagram {
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
    
    func createBlock(_ node: ObjectSnapshot) -> Block {
        let block = Block(
            objectID: node.objectID,
            position: node.position ?? .zero,
            pictogram: pictogram(for: node),
            label: node.label,
            secondaryLabel: node.secondaryLabel
        )

        return block
    }

    func createConnector(_ edge: EdgeObject, origin: Block, target: Block) -> Connector {
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
}
