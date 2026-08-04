//
//  Renderer.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 08/06/2026.
//

import PoieticCore

public protocol RenderingContextProtocol {
    /// Save context state onto a state stack.
    func save()
    /// Restore previously saved context state stack. If there is no saved state in the stack,
    /// nothing happens.
    func restore()
    
    /// Current affine transform of the rendering context
    var transform: AffineTransform { get }
    func setTransform(_ transform: AffineTransform)
}


/// Protocol for renderers of diagram scene.
///
public protocol DiagramSceneRenderer {
    associatedtype Context: RenderingContextProtocol
    
    /// Renders a diagram entity and its children.
    ///
    func render(_ entity: RuntimeEntity, context: Context)
    /// Render a diagram canvas node.
    ///
    /// The `entity` is guaranteed to have the ``BlockCanvasNode`` component.
    func renderBlock(_ entity: RuntimeEntity, context: Context)
    /// Render a diagram connector node.
    ///
    /// The `entity` is guaranteed to have the ``ConnectorCanvasNodeNode`` component.
    func renderConnector(_ entity: RuntimeEntity, context: Context)
    func renderPictogram(_ entity: RuntimeEntity, context: Context)
    func renderLabel(_ entity: RuntimeEntity, context: Context)
    func renderValueIndicator(_ entity: RuntimeEntity, context: Context)
    func renderIssueIndicator(_ entity: RuntimeEntity, context: Context)
    func renderColorSwatch(_ entity: RuntimeEntity, context: Context)

    /// Render entity that is not known to the diagramming library – an entity that was
    /// not handled in any other rendering methods by the renderer.
    ///
    /// Use this method to render directly or for further dispatch.
    func renderUnknown(_ entity: RuntimeEntity, context: Context)

    /// Function to render additional content regardless of node type. For example debugging
    /// annotations.
    ///
    /// Called from default ``render(_:context:)`` after the type dispatch and before descending
    /// into children.
    func renderNodeExtras(_ entity: RuntimeEntity, context: Context)
}

extension DiagramSceneRenderer {
    public func render(_ entity: RuntimeEntity, context: Context) {
        // TODO: [REFACTORING] Is the preview position still needed here? It should be set on the original (represented object, as source of truth)
        context.save()
        if let positionComp: PositionComponent = entity.component() {
            let previewPositionComp: PreviewPositionComponent? = entity.component()
            let position = previewPositionComp?.position ?? positionComp.position
            let transform = context.transform.translated(position)
            context.setTransform(transform)
        }
        
        if entity.contains(BlockCanvasNode.self) { renderBlock(entity, context: context) }
        else if entity.contains(ConnectorCanvasNode.self) {
            renderConnector(entity, context: context)
        }
        else if entity.contains(PictogramCanvasNode.self) {
            renderPictogram(entity, context: context)
        }
        else if entity.contains(LabelCanvasNode.self) {
            renderLabel(entity, context: context)
        }
        else if entity.contains(ValueIndicatorCanvasNode.self) {
            renderValueIndicator(entity, context: context)
        }
        else if entity.contains(IssueIndicatorCanvasNode.self) {
            renderIssueIndicator(entity, context: context)
        }
        else if entity.contains(ColorSwatchCanvasNode.self) {
            renderColorSwatch(entity, context: context)
        }
        else {
            renderUnknown(entity, context: context)
        }

        renderNodeExtras(entity, context: context)
        
        for child in entity.children {
            render(child, context: context)
        }
        context.restore()
    }
    public func renderUnknown(_ entity: RuntimeEntity, context: Context) {
        /* Default implementation does nothing */
    }

    public func renderNodeExtras(_ entity: RuntimeEntity, context: Context) {
        /* Default implementation does nothing */
    }
}
