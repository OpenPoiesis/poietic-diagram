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
///     - ``Notation`` component associated with the frame, default notation is used if not found.
///     - ``NotationRules`` associated with the frame, empty rules are used if not found.
/// - **Output:** ``BlockComponent``.
/// - **Forgiveness:** Nothing needed.
/// - **Issues collected:** No issues generated.
///
public struct BlockCreationSystem: System {
    // TODO: We do not have a way how to change this once the pipeline is set-up.
    // NOTE: Current system of Systems has no explicit system state management.
    // TODO: Should this be stored in a component/ephemeral entity?
    public init() {}

    public func update(_ frame: AugmentedFrame) throws (InternalSystemError) {
        let notation: Notation = frame.component(for: .Frame) ?? Notation.DefaultNotation
        let rules: NotationRules = frame.component(for: .Frame) ?? NotationRules()

        for object in frame.filter(trait: .DiagramBlock) {
            try update(object: object, in: frame, notation: notation, rules: rules)
        }
    }
    
    public func update(object: ObjectSnapshot,
                       in frame: AugmentedFrame,
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
        
        frame.setComponent(block, for: object.objectID)
    }
}
