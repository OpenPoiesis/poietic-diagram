//
//  ConnectorGeometrySystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/11/2025.
//

import PoieticCore

/// System that creates connector components for edges with trait ``DiagramConnector``.
///
/// - **Input:**
///     - Design objects with trait `DiagramConnector`.
///     - ``Notation`` component associated with the frame, default notation is used if not found.
///     - ``NotationRules`` associated with the frame, empty rules are used if not found.
/// - **Output:** ``ConnectorComponent``.
/// - **Forgiveness:**
///     - Non-edge objects are ignored.
///     - Midpoints default to empty list.
/// - **Issues collected:** No issues generated.
///
public struct TraitConnectorCreationSystem: System {
    public init() { }

    public func update(_ frame: AugmentedFrame) throws (InternalSystemError) {
        let notation: Notation = frame.component(for: .Frame) ?? Notation.DefaultNotation
        let rules: NotationRules = frame.component(for: .Frame) ?? NotationRules()

        for object in frame.filter(trait: .DiagramConnector) {
            guard let edge = EdgeObject(object, in: frame) else { continue }
            try update(edge: edge, in: frame, notation: notation, rules: rules)
        }
    }
    
    public func update(edge: EdgeObject, in frame: AugmentedFrame, notation: Notation, rules: NotationRules) throws (InternalSystemError){
        let midpoints: [Vector2D] = edge.object["midpoints", default: []]

        let glyphName = rules.connectorGlyphName(for: edge.object.type)
        let connectorGlyph = notation.connectorGlyph(glyphName)

        let connector = ConnectorComponent(
            representedObjectID: edge.key,
            originID: .object(edge.origin),
            targetID: .object(edge.target),
            glyph: connectorGlyph,
            midpoints: midpoints
        )
        frame.setComponent(connector, for: .object(edge.key))
    }
}

/// System that computes connector geometry from ``ConnectorComponent`` and ``BlockComponent``.
///
///
/// - **Input:** Any runtime object with ``ConnectorComponent`` component. Uses ``DiagramStyle``
///   component set on `Frame` runtime object.
/// - **Output:** ``ConnectorGeometryComponent``.
/// - **Forgiveness:**
///     - Ignores objects where origin or target entities do not exist or if they do not have
///       ``BlockComponent``.
///     - If no ``DiagramStyle`` is found on `Frame` runtime object, then default diagram style
///       is used.
///
/// When you create your own ``ConnectorComponent`` system, make sure that it includes
/// ``ConnectorGeometrySystem`` in its dependency list:
///
/// ```swift
/// public struct MyConnectorCreationSystem: System {
///     public static let dependencies: [SystemDependency] = [
///         .before(ConnectorGeometrySystem.self),
///     ]
///     // ... body of the system goes here
/// }
/// ```
///

public struct ConnectorGeometrySystem: System {
    nonisolated(unsafe) public static let dependencies: [SystemDependency] = [
        .after(TraitConnectorCreationSystem.self),
        .after(BlockCreationSystem.self)
    ]
    public init() {}
    public func update(_ frame: AugmentedFrame) throws (InternalSystemError) {
        // For all entities with ConnectorComponent:
        for (runtimeID, connector) in frame.runtimeFilter(ConnectorComponent.self) {
            try update(frame, runtimeID: runtimeID, connector: connector)
        }
    }
    public func update(_ frame: AugmentedFrame,
                       runtimeID: RuntimeEntityID,
                       connector: ConnectorComponent)
    throws (InternalSystemError) {
        // Get origin/target blocks
        guard let originBlock: BlockComponent = frame.component(for: connector.originID),
              let targetBlock: BlockComponent = frame.component(for: connector.targetID)
        else { return }
        
        // TODO: Add PreviewPosition component
        
        // Compute touch points
        let (originTouch, targetTouch) = Geometry.touchPoints(
            originPosition: originBlock.position,
            originShape: originBlock.collisionShape,
            targetPosition: targetBlock.position,
            targetShape: targetBlock.collisionShape,
            midpoints: connector.midpoints
        )
        let glyph = connector.glyph

        let wirePath = Geometry.wirePath(from: originTouch,
                                         to: targetTouch,
                                         through: connector.midpoints,
                                         lineType: glyph.lineType)
        let tessellatedWire = wirePath.tessellate()
        
        let geometry: ConnectorGeometryComponent

        switch glyph.kind {
        case .fat(let kind):
            let outline = Geometry.fatConnectorPath(
                originPoint: originTouch,
                targetPoint: targetTouch,
                midpoints: connector.midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                kind: kind
            )
            
            geometry = ConnectorGeometryComponent(
                wirePoints: tessellatedWire,
                linePath: outline,
                fillPath: outline,
                tailArrowhead: nil,
                headArrowhead: nil
            )
            
        case .thin(let kind):
            let paths = Geometry.thinConnectorPaths(
                originPoint: originTouch,
                targetPoint: targetTouch,
                midpoints: connector.midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                lineType: glyph.lineType,
                kind: kind
            )

            geometry = ConnectorGeometryComponent(
                wirePoints: tessellatedWire,
                linePath: paths.body,
                fillPath: nil,
                tailArrowhead: paths.tail,
                headArrowhead: paths.head
            )
        }
        
        frame.setComponent(geometry, for: runtimeID)
    }
}

