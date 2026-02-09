//
//  BlockSystems.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/11/2025.
//

import PoieticCore

/// System that block components for objects with trait `DiagramBlock`.
///
/// - **Input:**
///     - Design objects with trait `DiagramBlock`.
///     - ``Notation`` singleton component, default notation is used if not found.
///     - ``NotationRules`` singleton, empty rules are used if not found.
/// - **Output:** ``DiagramBlock``.
/// - **Forgiveness:** Nothing needed.
/// - **Issues collected:** No issues generated.
///
public struct BlockCreationSystem: System {
    public init(_ world: World) {}

    public func update(_ world: World) throws (InternalSystemError) {
        guard let frame = world.frame else { return }
        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        for object in frame.filter(trait: .DiagramBlock) {
            try update(object: object, in: world, notation: notation, rules: rules)
        }
    }
    
    public func update(object: ObjectSnapshot,
                       in world: World,
                       notation: Notation,
                       rules: NotationRules)
    throws (InternalSystemError) {
        let accentColorName: String? = object["color"]
        let pictogramName = rules.pictogramName(for: object.type)
        let pictogram = notation.pictogram(pictogramName)
        let block = DiagramBlock(
            representedObjectID: object.objectID,
            position: object.position ?? .zero,
            pictogram: pictogram,
            label: object.label,
            secondaryLabel: object.secondaryLabel,
            accentColorName: accentColorName,
            visualTypeName: object.type.name
        )
        
        world.setComponent(block, for: object.objectID)
    }
}
