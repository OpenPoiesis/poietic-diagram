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
    
    /// Which content of a diagram entity is dirty.
    ///
    /// Can be set on ``Diagram`` entity or on a diagram object entity.
    ///
    /// Set this entity together with ``IsDirty`` component. When a diagram is
    /// dirty and there is no ``DirtyContent`` component set, then it is assumed
    /// that everything is dirty.
    ///
    public struct DirtyContent: Component, OptionSet, Sendable, Hashable {
        public let rawValue: UInt64
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
        public static let data        = DirtyContent(rawValue: 1 << 0)
        public static let layout      = DirtyContent(rawValue: 1 << 1)
        public static let geometry    = DirtyContent(rawValue: 1 << 2)
        public static let all         = DirtyContent([data, layout, geometry])

        public func asStrings() -> [String] {
            var result: [String] = []
            if self.contains(.data) { result.append("data") }
            if self.contains(.layout) { result.append("layout") }
            if self.contains(.geometry) { result.append("geometry") }
            return result
        }
        
        public var description: String {
            return asStrings().joined(separator: " ")
        }
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

