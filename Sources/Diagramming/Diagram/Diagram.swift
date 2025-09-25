//
//  Diagram.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 03/08/2025.
//

import PoieticCore

public protocol DiagramObject {
    /// ID of an object that the diagram object represents.
    ///
    /// Use `nil` to represent temporary diagram objects.
    ///
    var objectID: ObjectID? { get }
    
    /// Custom tag that can be used to distinguish multiple diagram objects that
    /// have the same represented object.
    var tag: Int? { get }
    
    /// Test whether the object collides with a circle with centre at `point` with
    /// given radius.
    /// 
    func containsTouch(at point: Vector2D, radius: Double) -> Bool
}

// FIXME: Reconsider necessity of this
public class Diagram {
    public var connectors: [Connector]
    public var blocks: [Block]
    
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
