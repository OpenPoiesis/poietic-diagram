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
/// - **Output:** ``DiagramConnector``.
/// - **Forgiveness:**
///     - Non-edge objects are ignored.
///     - Midpoints default to empty list.
/// - **Issues collected:** No issues generated.
///
public struct TraitConnectorCreationSystem: System {
    // TODO: Name is too long.
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

        let connector = DiagramConnector(
            representedObjectID: edge.key,
            originID: .object(edge.origin),
            targetID: .object(edge.target),
            glyph: connectorGlyph,
            midpoints: midpoints
        )
        frame.setComponent(connector, for: .object(edge.key))
    }
}

/// System that computes connector geometry from ``DiagramConnector`` and ``DiagramBlock``.
///
///
/// - **Input:** Any runtime object with ``DiagramConnector`` component. Uses ``DiagramStyle``
///   component set on `Frame` runtime object.
/// - **Output:** ``DiagramConnectorGeometry``.
/// - **Forgiveness:**
///     - Ignores objects where origin or target entities do not exist or if they do not have
///       ``DiagramBlock``.
///     - If no ``DiagramStyle`` is found on `Frame` runtime object, then default diagram style
///       is used.
///
/// When you create your own ``DiagramConnector`` system, make sure that it includes
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
        for (runtimeID, connector) in frame.runtimeFilter(DiagramConnector.self) {
            try update(frame, runtimeID: runtimeID, connector: connector)
        }
    }

    public func update(_ frame: AugmentedFrame,
                       runtimeID: RuntimeEntityID,
                       connector: DiagramConnector)
    throws (InternalSystemError) {
        // Get origin/target blocks
        guard let originBlock: DiagramBlock = frame.component(for: connector.originID),
              let targetBlock: DiagramBlock = frame.component(for: connector.targetID)
        else { return }
        
        let originPreview: BlockPreview? = frame.component(for: connector.originID)
        let targetPreview: BlockPreview? = frame.component(for: connector.targetID)
        let preview: ConnectorPreview? = frame.component(for: runtimeID)
        let midpoints = preview?.midpoints ?? connector.midpoints

        let (originTouch, targetTouch) = Geometry.touchPoints(
            originPosition: originPreview?.position ?? originBlock.position,
            originShape: originBlock.collisionShape,
            targetPosition: targetPreview?.position ?? targetBlock.position,
            targetShape: targetBlock.collisionShape,
            midpoints: midpoints
        )

        let geometry = DiagramConnectorGeometry(originTouch: originTouch,
                                                targetTouch: targetTouch,
                                                midpoints: midpoints,
                                                glyph: connector.glyph)

        frame.setComponent(geometry, for: runtimeID)
    }
}

extension DiagramConnectorGeometry {
    public init(originTouch: Vector2D,
                targetTouch: Vector2D,
                midpoints: [Vector2D] = [],
                glyph: ConnectorGlyph)
    {
        let wirePath = Geometry.wirePath(from: originTouch,
                                         to: targetTouch,
                                         through: midpoints,
                                         lineType: glyph.lineType)
        
        switch glyph.kind {
        case .fat(let kind):
            let outline = Geometry.fatConnectorPath(
                originPoint: originTouch,
                targetPoint: targetTouch,
                midpoints: midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                kind: kind
            )
            
            self.originPoint = originTouch
            self.targetPoint = targetTouch
            self.wire = wirePath
            self.linePath = outline
            self.fillPath = outline
            self.tailArrowhead = nil
            self.headArrowhead = nil
            
        case .thin(let kind):
            let paths = Geometry.thinConnectorPaths(
                originPoint: originTouch,
                targetPoint: targetTouch,
                midpoints: midpoints,
                headSize: glyph.headSize,
                tailSize: glyph.tailSize,
                lineType: glyph.lineType,
                kind: kind
            )
            
            self.originPoint = originTouch
            self.targetPoint = targetTouch
            self.wire = wirePath
            self.linePath = paths.body
            self.fillPath = nil
            self.tailArrowhead = paths.tail
            self.headArrowhead = paths.head
        }
    }
}
