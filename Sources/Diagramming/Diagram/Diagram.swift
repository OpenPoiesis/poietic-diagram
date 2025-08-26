//
//  Diagram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/08/2025.
//

import PoieticCore

public class Diagram {
    var _connectors: [ObjectID:Connector]
    public var connectors: [Connector] { Array(_connectors.values) }
    public var connectorKeys: [ObjectID] { Array(_connectors.keys) }
    var _blocks: [ObjectID:Block]
    public var blocks: [Block] { Array(_blocks.values) }
    public var blockKeys: [ObjectID] { Array(_blocks.keys) }
    // var annotations: [Annotation]
    
    public init() {
        _connectors = [:]
        _blocks = [:]
    }
    
    public func block(forObject id: ObjectID) -> Block? {
        _blocks[id]
    }

    public func connector(forObject id: ObjectID) -> Connector? {
        _connectors[id]
    }

    /// Inserts a connector into the diagram.
    ///
    /// - Precondition: The diagram must contain the origin and target blocks of the connector.
    ///
    public func insertConnector(_ connector: Connector) {
        _connectors[connector.objectID] = connector
    }

    @discardableResult
    public func removeConnector(forObject id: ObjectID) -> Connector? {
        return _connectors.removeValue(forKey: id)
    }

    public func insertBlock(_ block: Block) {
        _blocks[block.objectID] = block
    }
    @discardableResult
    public func removeBlock(forObject id: ObjectID) -> Block? {
        return _blocks.removeValue(forKey: id)
    }
}
