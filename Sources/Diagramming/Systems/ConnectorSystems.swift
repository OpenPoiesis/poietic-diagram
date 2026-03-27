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
    public init(_ world: World) {}

    public func update(_ world: World) throws (InternalSystemError) {
        guard let frame = world.frame else { return }
        let notation: Notation = world.singleton() ?? Notation.DefaultNotation
        let rules: NotationRules = world.singleton() ?? NotationRules()

        for object in frame.filter(trait: .DiagramConnector) {
            guard let edge = DesignObjectEdge(object, in: frame) else { continue }
            try create(edge: edge, in: world, notation: notation, rules: rules)
        }
    }
    
    public func create(edge: DesignObjectEdge, in world: World, notation: Notation, rules: NotationRules) throws (InternalSystemError){
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

/// System that computes connector geometry from ``DiagramConnector`` and ``DiagramBlock``.
///
///
/// - **Input:**
///     - World objects with the ``DiagramConnector`` component.
///     - Optional ``ConnectorPreview`` for the same objects.
///     - Optional ``Notation`` singleton. If not provided, default empty notation is used.
/// - **Output:** ``DiagramConnectorGeometry``.
/// - **Forgiveness:**
///     - Ignores objects where origin or target entities do not exist or if they do not have
///       ``DiagramBlock``.
///     - If no ``Notation`` singleton is found, then default empty notation is used.
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

    public init(_ world: World) {}

    public func update(_ world: World) throws (InternalSystemError) {
        for (entity, connector) in world.query(DiagramConnector.self) {
            try update(entity, connector: connector, world: world)
        }
    }

    public func update(_ entity: RuntimeEntity,
                       connector: DiagramConnector,
                       world: World)
    throws (InternalSystemError) {
        // Get origin/target blocks
        guard let origin = world.entity(connector.originID),
              let originBlock: DiagramBlock = origin.component(),
              let target = world.entity(connector.targetID),
              let targetBlock: DiagramBlock = target.component()
        else { return }
        
        let originPreview: BlockPreview? = origin.component()
        let targetPreview: BlockPreview? = target.component()
        let preview: ConnectorPreview? = entity.component()
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

        entity.setComponent(geometry)
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
