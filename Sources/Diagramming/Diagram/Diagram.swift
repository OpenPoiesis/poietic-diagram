//
//  Diagram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/08/2025.
//


public enum DiagramError: Error {
    /// Block is not present in the diagram.
    ///
    case blockNotFound
}

public class Diagram {
    public typealias ElementKey = UInt64
    
    public var connectors: [Connector]
    public var blocks: [Block]
    // var annotations: [Annotation]
    
    public init() {
        connectors = []
        blocks = []
    }
    
    /// Inserts a connector into the diagram.
    ///
    /// - Precondition: The diagram must contain the origin and target blocks of the connector.
    ///
    public func insertConnector(_ connector: Connector) {
        precondition(blocks.contains(where: { connector.origin === $0}), "Connector origin not found")
        precondition(blocks.contains(where: { connector.target === $0}), "Connector target not found")
        self.connectors.append(connector)
    }

    public func insertBlock(_ block: Block) {
        self.blocks.append(block)
    }
    
    public func block(_ key: ElementKey) -> Block? {
        return blocks.first { $0.id == key }
    }
}
