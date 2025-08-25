//
//  Diagram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/08/2025.
//


public class Diagram {
    public typealias ElementKey = UInt64
    
    var _connectors: [ElementKey:Connector]
    public var connectors: [Connector] { Array(_connectors.values) }
    public var connectorKeys: [ElementKey] { Array(_connectors.keys) }
    var _blocks: [ElementKey:Block]
    public var blocks: [Block] { Array(_blocks.values) }
    public var blockKeys: [ElementKey] { Array(_blocks.keys) }
    // var annotations: [Annotation]
    
    public init() {
        _connectors = [:]
        _blocks = [:]
    }
    
    public func block(forKey key: ElementKey) -> Block? {
        _blocks[key]
    }

    public func connector(forKey key: ElementKey) -> Connector? {
        _connectors[key]
    }

    /// Inserts a connector into the diagram.
    ///
    /// - Precondition: The diagram must contain the origin and target blocks of the connector.
    ///
    public func insertConnector(_ connector: Connector) {
        _connectors[connector.key] = connector
    }

    @discardableResult
    public func removeConnector(forKey key: ElementKey) -> Connector? {
        return _connectors.removeValue(forKey: key)
    }

    public func insertBlock(_ block: Block) {
        _blocks[block.key] = block
    }
    @discardableResult
    public func removeBlock(forKey key: ElementKey) -> Block? {
        return _blocks.removeValue(forKey: key)
    }
}
