//
//  BlockSystems.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/11/2025.
//

import PoieticCore

/// System that associates diagram block and connector components.
///
/// - Design objects with trait `DiagramBlock` will get ``DiagramBlock`` component.
/// - Design objects with trait `DiagramConnector` will get ``DiagramConnector`` component,
///
/// - **Input:**
///     - Design objects with trait `DiagramBlock` or `DiagramConnector`.
///     - ``Notation`` singleton component, default notation is used if not found.
///     - ``NotationRules`` singleton, empty rules are used if not found.
/// - **Output:** ``DiagramBlock`` and ``DiagramConnector`` components for their respective entities.
/// - **Forgiveness:**
///     - Non-edge objects are ignored.
///     - Midpoints default to empty list.
/// - **Issues collected:** No issues generated.
///
public struct TraitsToDiagramObjectsSystem: System {
    public static let dependencies: [SystemDependency] = [
        .after(VisualMetadataSystem.self),
    ]
    public static func update(_ world: World) throws (InternalSystemError) {
        guard let frame = world.plane else { return }
        let notation: Notation = world.singleton() ?? Notation.DefaultNotation

        for object in frame.filter(trait: DiagramDomain.Traits.DiagramBlock) {
            updateBlock(object: object, notation: notation, in: world)
        }
        
        for object in frame.filter(trait: DiagramDomain.Traits.DiagramConnector) {
            guard let edge = DesignObjectEdge(object, in: frame) else { continue }
            updateConnector(edge: edge, notation: notation, in: world)
        }
    }
    
    public static func updateBlock(object: ObjectSnapshot,
                            notation: Notation,
                            in world: World)
    {
        guard let plane = world.plane,
              let entity = world.entity(object.objectID)
        else { return }
       
        let accentColor: AdaptableColorKey?
        if let colorComponent: AdaptableColor = entity.component() {
            accentColor = colorComponent.key
        }
        else {
            accentColor = nil
        }

        let pictogram = notation.pictogram(for: object, in: plane)
        let block = DiagramBlock(
            position: object.position ?? .zero,
            pictogram: pictogram,
            label: object.label,
            secondaryLabel: object.secondaryLabel,
            accentColor: accentColor,
            visualTypeName: object.type.name
        )
        
        entity.setComponent(block)
        entity.setComponent(DiagramObject())
        entity.setComponent(DirtyContent.all)
    }
    
    public static func updateConnector(edge: DesignObjectEdge,
                                notation: Notation,
                                in world: World)
    {
        guard let plane = world.plane,
              let entity = world.entity(edge.id),
              let originEntity = world.entity(edge.origin),
              let targetEntity = world.entity(edge.target),
              let origin = originEntity.designObject,
              let target = targetEntity.designObject
        else { return }
        
        let midpoints: [Vector2D] = edge.object["midpoints", default: []]

        let glyph = notation.connectorGlyph(for: edge.object,
                                            origin: origin,
                                            target: target,
                                            in: plane)

        let connector = DiagramConnector(
            originID: originEntity.runtimeID,
            targetID: targetEntity.runtimeID,
            glyph: glyph,
            midpoints: midpoints
        )
        entity.setComponent(connector)
        entity.setComponent(DiagramObject())
        entity.setComponent(DirtyContent.all)
    }
}
