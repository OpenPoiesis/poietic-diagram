//
//  PresentationUpdateSystem.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 20/07/2026.
//

import PoieticCore

/// System that builds and updates diagram presentations.
///
/// The system performs the following:
///
/// 1. Update data on all presentations and their nodes.
/// 2. Update layout for presentations which have ``LayoutEnvironment`` component set
/// 3. Update geometry of all presentations.
/// 4. Cleans-up diagram dirty content flags.
///
/// This system is intended to be run on each application update cycle.
///
/// - **Input:**
///     - ``DiagramPresentation`` entities and their children.
///         - Considers ``Diagram.DirtyContent`` flag if present.
///     - ``NotationRules`` singleton, empty rules are used if not found.
/// - **Updates:** Presentation nodes and their children ``PresentationNode``.
/// - **Output:** Nothing new created.
/// - **Defaults:**
///     - ``LayoutProvider`` must be present if layout is requested, otherwise layout phase is
///       omitted.
///     - If ``Diagram/DirtyContent`` component is not set, then empty set (all clean) is
///     assumed.
/// - **Issues collected:** No issues generated.
///
public struct PresentationUpdateSystem: System {
    public static let dependencies: [SystemDependency] = [
        .after(TraitsToDiagramObjectsSystem.self),
    ]
    
    public static func update(_ world: World) throws(InternalSystemError) {
        let builder = PresentationBuilder(world: world)
        flagTouchedObjects(world)
        updateData(world, builder: builder)
        updateHighlights(world)
        updateLayout(world, builder: builder)
        updateGeometry(world, builder: builder)

    }
    /// Transform ``ObjectTouched`` flag into dirty content.
    static func flagTouchedObjects(_ world: World) {
        for entity: RuntimeEntity in world.query(ObjectTouched.self) {
            // TODO: Filter only diagram object entities. Enable once we know for sure the component is set.
            // guard entity.contains(DiagramObject.self) else { continue }
            entity.setComponent(DirtyContent.all)
        }
    }
    
    static func updateData(_ world: World, builder: PresentationBuilder) {
        for node: RuntimeEntity in world.query(BlockNode.self) {
            guard let represented: RuntimeEntity = node.target(RepresentationOf.self),
                  let flags: DirtyContent = represented.component(),
                  flags.contains(.data)
            else { continue }
            builder.updateBlockData(node, from: represented)
        }
        // No connector data to be updated here yet.
    }

    static func updateHighlights(_ world: World) {
        // TODO: Use something like SelectionDirty world singleton
        for node: RuntimeEntity in world.query(PresentationNode.self) {
            guard let represented: RuntimeEntity = node.target(RepresentationOf.self)
            else { continue }
            
            if represented.contains(IsSelected.self) {
                node.modify(NodeStyle.self) { $0.modifiers.insert(.selected) }
            } else {
                node.modify(NodeStyle.self) { $0.modifiers.remove(.selected) }
            }
        }
    }
    
    /// Update geometry of presentation nodes.
    ///
    /// - Block Nodes:
    ///     - when represented entity is dirty
    ///     - when presentation has ``ProjectionDirty``
    /// - Connector Nodes:
    ///     - when represented entity is dirty
    ///     - when presentation has ``ProjectionDirty``
    ///     - when either origin or target
    static func updateGeometry(_ world: World, builder: PresentationBuilder) {
        var dirtyBlocks: Set<RuntimeID> = Set()
        
        // TODO: Update WHEN: original is geometry dirty OR presentation is geometry dirty
        for node: RuntimeEntity in world.query(BlockNode.self) {
            guard let represented: RuntimeEntity = node.target(RepresentationOf.self)
            else { continue }

            var isDirty: Bool = false

            if let flags: DirtyContent = represented.component() {
                isDirty = flags.contains(.geometry)
            }
            if let presentation: RuntimeEntity = node.target(MemberOf.self) {
                isDirty = isDirty || presentation.contains(ProjectionDirty.self)
            }
                  
            guard isDirty else { continue }
            
            dirtyBlocks.insert(represented.runtimeID)
            builder.updateBlockGeometry(node, from: represented)
        }
        
        for node: RuntimeEntity in world.query(ConnectorNode.self) {
            var isDirty: Bool = false
            let original: RuntimeEntity?
            
            if let represented: RuntimeEntity = node.target(RepresentationOf.self) {
                if let flags: DirtyContent = represented.component() {
                    isDirty = flags.contains(.geometry)
                }
                if let presentation: RuntimeEntity = node.target(MemberOf.self) {
                    isDirty = isDirty || presentation.contains(ProjectionDirty.self)
                }
                if let connector: DiagramConnector = represented.component() {
                    isDirty = isDirty || dirtyBlocks.contains(connector.originID) ||
                    dirtyBlocks.contains(connector.targetID)
                    
                }
                guard isDirty else { continue }
                original = represented
            }
            else {
                // For connectors without representation check dirty directly on the connector
                if let flags: DirtyContent = node.component() {
                    isDirty = flags.contains(.geometry)
                }
                guard isDirty else { continue }
                original = nil
            }

            builder.updateConnectorGeometry(node, from: original)
        }
    }

    static func updateLayout(_ world: World, builder: PresentationBuilder) {
        for (presentation, _, provider) in world.query(DiagramPresentation.self, LayoutEnvironment.self) {
            guard presentation.contains(LayoutDirty.self)
            else { continue }

            builder.layout(presentation: presentation, layout: provider.provider)
        }
    }
}
