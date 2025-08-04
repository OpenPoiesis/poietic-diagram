//
//  Diagram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/08/2025.
//


public class Diagram {
    public typealias ElementID = UInt64
    
    public var connectors: [Connector]
    public var blocks: [Block]
    // var annotations: [Annotation]
    
    public init() {
        connectors = []
        blocks = []
    }
    
    public func insertConnector(_ connector: Connector) {
        self.connectors.append(connector)
    }

    public func insertBlock(_ block: Block) {
        self.blocks.append(block)
    }
}
