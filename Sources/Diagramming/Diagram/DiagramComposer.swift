//
//  DiagramPresenter.swift
//  poietic-godot
//
//  Created by Stefan Urbanek on 19/08/2025.
//
// FIXME: Change order so that head/tail props are together

nonisolated(unsafe) public let DefaultStockFlowConnectorGlyphs: [ConnectorGlyph] = [
    ConnectorGlyph(
        name: "default",
        kind: .thin(ConnectorGlyph.Thin(
            headType: .none,
            tailType: .none)),
        headSize: 0.0,
        tailSize: 0.0,
        lineType: .straight
    ),

    ConnectorGlyph(
        name: "Parameter",
        kind: .thin(ConnectorGlyph.Thin(
                headType: .stick,
                tailType: .ball)),
        headSize: 10.0,
        tailSize: 5.0,
        lineType: .straight
    ),
    ConnectorGlyph(
        name: "Flow",
        kind: .fat(ConnectorGlyph.Fat(
                headType: .regular,
                tailType: .none,
                width: 10.0,
                joinType: .round)),
        headSize: 20.0,
        tailSize: 0.0,
        lineType: .straight
    ),
]

#if false
// Makes Design -> Diagram -> Canvas
public class DiagramComposer {
    let style: Notation
    let pictogramAliases: [String:String]
    
    public init(style: Notation, pictogramAliases: [String:String] = [:]) {
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
            secondaryLabel: node.secondaryLabel,
            colorName: node["color"]
        )
        
        return block
    }
    public func updateBlock(block: Block, node: ObjectSnapshot) {
        block.objectID = node.objectID
        block.position = node.position ?? .zero
        block.pictogram = pictogram(for: node)
        block.label = node.label
        block.secondaryLabel = node.secondaryLabel
        block.colorName = node["color"]
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
#endif
