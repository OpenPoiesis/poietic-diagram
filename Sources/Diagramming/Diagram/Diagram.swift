//
//  Diagram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/08/2025.
//

import PoieticCore
#if false
public protocol DiagramObject {
    /// ID of an object that the diagram object represents.
    ///
    /// Use `nil` to represent temporary diagram objects.
    ///
    var objectID: ObjectID? { get }
    
    /// Custom tag that can be used to distinguish multiple diagram objects that
    /// have the same represented object.
    var tag: Int? { get }
}

// FIXME: Reconsider necessity of this
public struct Diagram: Component {
    public let connectors: [Connector]
    public let blocks: [Block]
    
    public init() {
        connectors = []
        blocks = []
    }
    
    /// Inserts a connector into the diagram.
    ///
    /// - Precondition: The diagram must contain the origin and target blocks of the connector.
    ///
    public func insertConnector(_ connector: Connector) {
        connectors.append(connector)
    }

    public func insertBlock(_ block: Block, tag: Int? = nil) {
        blocks.append(block)
    }
}
#endif
