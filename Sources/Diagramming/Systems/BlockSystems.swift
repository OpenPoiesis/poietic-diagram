//
//  BlockSystems.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/11/2025.
//
/// - **Input:**
///     - Design objects with trait `DiagramBlock` or `DiagramConnector`.
///     - ``Notation`` singleton component, default notation is used if not found.
///     - ``NotationRules`` singleton, empty rules are used if not found.
/// - **Output:**
///     - ``DiagramBlock`` component for `DiagramBlock` trait.
///     - ``DiagramConnector`` component for `DiagramConnector` trait.
/// - **Forgiveness:**

import PoieticCore

/// System that associates diagram block and connector components.
///
/// - Design objects with trait `DiagramBlock` will get ``DiagramBlock`` component.
/// - Design objects with trait `DiagramConnector` will get ``DiagramConnector`` component,
///
/// - **Input:**
///     - Design objects with trait `DiagramBlock`.
///     - ``Notation`` singleton component, default notation is used if not found.
///     - ``NotationRules`` singleton, empty rules are used if not found.
/// - **Output:** ``DiagramBlock``.
/// - **Forgiveness:** Nothing needed.
/// - **Issues collected:** No issues generated.
///
public struct DiagramBlockFromTraitSystem: System {
    public init(_ world: World) {}

    public func update(_ world: World) throws (InternalSystemError) {
        guard let frame = world.frame else { return }
        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        for object in frame.filter(trait: .DiagramBlock) {
            try createBlock(object: object, notation: notation, rules: rules, in: world)
        }
    }
    
    public func createBlock(object: ObjectSnapshot,
                            notation: Notation,
                            rules: NotationRules,
                            in world: World)
    {
        guard let entity = world.entity(object.objectID) else { return }
        
        let accentColorName: String? = object["color"]
        let accentColor = accentColorName.map { AdaptableColorKey(rawValue: $0) } ?? nil
        let pictogramName = rules.pictogramName(for: object.type)
        let pictogram = notation.pictogram(pictogramName)
        let block = DiagramBlock(
            position: object.position ?? .zero,
            pictogram: pictogram,
            label: object.label,
            secondaryLabel: object.secondaryLabel,
            accentColor: accentColor,
            visualTypeName: object.type.name
        )
        
        entity.setComponent(block)
    }
}

/// System that creates connector components for edges with trait ``DiagramConnector``.
///
/// - **Input:**
///     - Design objects with trait `DiagramConnector`.
///     - ``Notation`` component associated with the frame, default notation is used if not found.
///     - ``NotationRules`` associated with the frame, empty rules are used if not found.
/// - **Output:** ``DiagramConnector``.
/// - **Forgiveness:**
///     - Non-edge objects are ignored.
///     - Midpoints default to empty list.
/// - **Issues collected:** No issues generated.
///
public struct DiagramConnectorFromTraitSystem: System {
    // TODO: Name is too long.
    public init(_ world: World) {}

    public func update(_ world: World) throws (InternalSystemError) {
        guard let frame = world.frame else { return }
        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        for object in frame.filter(trait: .DiagramConnector) {
            guard let edge = DesignObjectEdge(object, in: frame) else { continue }
            createConnector(edge: edge, notation: notation, rules: rules, in: world)
        }
    }
    
    public func createConnector(edge: DesignObjectEdge,
                                notation: Notation,
                                rules: NotationRules,
                                in world: World)
    {
        guard let entity = world.entity(edge.id),
              let originEntity = world.entity(edge.origin)?.runtimeID,
              let targetEntity = world.entity(edge.target)?.runtimeID else
        {
            return
        }
        let midpoints: [Vector2D] = edge.object["midpoints", default: []]

        let glyphName = rules.connectorGlyphName(for: edge.object.type)
        let connectorGlyph = notation.connectorGlyph(glyphName)

        let connector = DiagramConnector(
            originID: originEntity,
            targetID: targetEntity,
            glyph: connectorGlyph,
            midpoints: midpoints
        )
        entity.setComponent(connector)
    }
}

