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
/// - **Set by:**
///     - Custom diagram creation methods.
///     - ``DiagramSceneComposer`` on ``DiagramSceneComposer/createDiagramFromAll()``.
/// - **Read by:** ``DiagramSceneComposer/createScene(diagram:viewport:)``
///
///
/// ## Entity Situation
///
/// ```
/// +-----------------+      +-------------------+
/// | (Design Object) |      | (Design Object)   |
/// +-----------------+      +-------------------+
/// | Diagram Block   |      | Diagram Connector |
/// +-----------------+      +-------------------+
/// | ...             |      | ...               |
/// +-----------------+      +-------------------+
///     ^                         ^        ^
///     | Depicts                 |        |
///     +-------------------------+        |
///     |                                  |
/// +---------+                            |
/// | Diagram |                            |
/// +---------+                            |
///     ^                                  |
///     | Representation Of                |
///     |                                  |
/// +--------------+                       |
/// | DiagramScene |                       |
/// +--------------+                       |
///     ^                                  |
///     | ChildOf                          |
///     | *                                |
/// +------------------+ RepresentationOf  |
/// | DiagramSceneNode |-------------------+
/// +------------------+
/// ```
///
public struct Diagram: Component {
    // Empty tag component
    public init() { /* Empty */ }
}

/// Which content of a diagram entity is dirty.
///
/// - **Set by:** Custom: application, interactive tools (canvas tools).
/// - **Read by:** ``SceneCompositionSystem``
/// - **Removed by:** Custom clean-up systems.
///
/// Set this entity together with ``IsDirty`` component. When a diagram is
/// dirty and there is no ``DirtyContent`` component set, then it is assumed
/// that everything is dirty.
///
/// - Note: (Developer's reasoning) The dirty content structure is here not to pollute the
///   top-level namespace.
public struct DirtyContent: Component, OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    public static let data        = DirtyContent(rawValue: 1 << 0)
    public static let geometry    = DirtyContent(rawValue: 1 << 2)
    public static let all         = DirtyContent([data, geometry])

    public func asStrings() -> [String] {
        var result: [String] = []
        if self.contains(.data) { result.append("data") }
        if self.contains(.geometry) { result.append("geometry") }
        return result
    }
    
    public var description: String {
        return asStrings().joined(separator: " ")
    }
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

/// Tag for any diagram object.
///
/// - SeeAlso: ``DiagramConnector``, ``DiagramBlock``.
///
/// - Important: Entities with``DiagramConnector`` and ``DiagramBlock`` are expected to have
///   ``DiagramObject`` component tag set as well.
///
public struct DiagramObject: Component {
    public init() { /* Empty */ }
}
