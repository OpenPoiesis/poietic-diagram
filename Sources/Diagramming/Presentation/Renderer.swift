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


/// Protocol for renderers of diagram presentation.
///
public protocol DiagramRenderer {
    associatedtype Context: RenderingContextProtocol
    
    /// Renders a diagram entity and its children.
    ///
    func render(_ entity: RuntimeEntity, context: Context)
    /// Render a diagram presentation node.
    ///
    /// The `entity` is guaranteed to have the ``BlockNode`` component.
    func renderBlock(_ entity: RuntimeEntity, context: Context)
    /// Render a diagram connector node.
    ///
    /// The `entity` is guaranteed to have the ``ConnectorNodeNode`` component.
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

extension DiagramRenderer {
    public func render(_ entity: RuntimeEntity, context: Context) {
        context.save()
        if let localPosition: LocalPosition = entity.component() {
            let transform = context.transform.translated(localPosition.position)
            context.setTransform(transform)
        }
        
        if entity.contains(BlockNode.self) { renderBlock(entity, context: context) }
        else if entity.contains(ConnectorNode.self) {
            renderConnector(entity, context: context)
        }
        else if entity.contains(PictogramNode.self) {
            renderPictogram(entity, context: context)
        }
        else if entity.contains(LabelNode.self) {
            renderLabel(entity, context: context)
        }
        else if entity.contains(ValueIndicatorNode.self) {
            renderValueIndicator(entity, context: context)
        }
        else if entity.contains(IssueIndicatorNode.self) {
            renderIssueIndicator(entity, context: context)
        }
        else if entity.contains(ColorSwatchNode.self) {
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
