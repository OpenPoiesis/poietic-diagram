//
//  DiagramComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 21/04/2026.
//

import PoieticCore

/// Component representing a diagram entity.
///
/// Diagram parts are referenced rom the diagram through the ``Depicts`` relationship.
///
public struct Diagram: Component {
    // Empty component
}

/// Relationship for parts of a diagram.
///
/// - SeeAlso: ``Diagram``.
///
public struct Depicts: Relationship {
    public static let targetRemovalPolicy: RelationshipRemovalPolicy = .remove
    public static var outgoingCardinality: Cardinality { .many }
    public init() { /* Empty */ }
}

