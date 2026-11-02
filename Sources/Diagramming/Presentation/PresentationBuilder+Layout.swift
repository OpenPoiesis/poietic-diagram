//
//  PresentationBuilder+Layout.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/06/2026.
//
import PoieticCore

extension PresentationBuilder {
    public func layout(presentation: RuntimeEntity, layout: any LayoutProvider) {
        for child in presentation.children {
            layoutBlock(child, layout: layout)
            // Other canvas node types that need layout go here... (nothing else yet)
        }
        presentation.removeComponent(LayoutDirty.self)
    }
    
    /// Lays out block children nodes such as labels and indicators.
    ///
    /// The function positions labels and indicators based on their content and style.
    ///
    /// Usually called when:
    /// - A new block is created.
    /// - Label did change.
    /// - Style did change.
    ///
    /// No need to call when:
    /// - Block did move.
    ///
    /// - SeeAlso: ``DiagramLayoutStyle``.
    ///
    public func layoutBlock(_ entity: RuntimeEntity, layout: some LayoutProvider) {
        // NOTE: Do not change block position here, only position of block's children.
        guard let pictogramNode: RuntimeEntity = entity.target(PresentationNode.Pictogram.self),
              let pictComp: PictogramNode = pictogramNode.component()
        else { return }
        
        let pictogram = pictComp.pictogram
        
        let bbox = pictogram.pathBoundingBox
        var labelTopCenter = Vector2D(0, bbox.bottomLeft.y)
        var swatchCenter: Vector2D = labelTopCenter

        // 1. Primary label
        if let labelEntity: RuntimeEntity = entity.target(PresentationNode.PrimaryLabel.self),
           let label: LabelNode = labelEntity.component()
        {
            let extents = layout.textExtents(label.text, class: .primaryLabel)

            labelTopCenter.y += layout.metric(.primaryLabelPadding, default: 0.0)

            let position = labelTopCenter + Vector2D(0.0, extents.height / 2) - extents.origin
            
            let swatchSize = layout.metric(.colorSwatchSize, default: 0.0)
            swatchCenter = Vector2D(position.x - extents.center.x - swatchSize ,
                                    position.y + extents.height/2)
            

            labelTopCenter.y += extents.height + layout.metric(.secondaryLabelPadding, default: 0.0)
            let offset = layout.labelRenderingOffset(extents: extents, anchor: label.anchor)
            
            labelEntity.setComponent(LocalPosition(position: position))
            if offset != .zero {
                labelEntity.setComponent(RenderingOffset(position: offset))
            }

            let labelBox = Rect2D(origin: -extents.center, size: extents.size)
            let shape = CollisionShape(rectangle: labelBox)
            
            labelEntity.setComponent(shape)
        }
        // 2. Secondary label
        if let labelEntity: RuntimeEntity = entity.target(PresentationNode.SecondaryLabel.self),
           let label: LabelNode = labelEntity.component()
        {
            let extents = layout.textExtents(label.text, class: .secondaryLabel)

            labelTopCenter.y += layout.metric(.primaryLabelPadding, default: 0.0)

            let position = labelTopCenter + Vector2D(0.0, extents.height / 2) - extents.origin
            
            let offset = layout.labelRenderingOffset(extents: extents, anchor: label.anchor)

            labelEntity.setComponent(LocalPosition(position: position))
            if offset != .zero {
                labelEntity.setComponent(RenderingOffset(position: offset))
            }

            let labelBox = Rect2D(origin: -extents.center, size: extents.size)
            let shape = CollisionShape(rectangle: labelBox)
            
            labelEntity.setComponent(shape)
        }
        // 3. Color swatch
        if let swatchEntity: RuntimeEntity = entity.target(PresentationNode.ColorSwatch.self) {
            swatchEntity.setComponent(LocalPosition(position: swatchCenter))
            // Swatch is not yet touchable, no touch region here.
        }
        
        // 3. Color swatch
        if let indicatorEntity: RuntimeEntity = entity.target(PresentationNode.ValueIndicator.self),
           let indicator: ValueIndicatorNode = indicatorEntity.component()
        {
            let offset = layout.metric(.valueIndicatorPadding, default: 0.0)
            let position: Vector2D = Vector2D(
                bbox.center.x,
                bbox.minY - indicator.size.y / 2 - offset
            )
            indicatorEntity.setComponent(LocalPosition(position: position))
            // Swatch is not yet touchable, no touch region here.
        }
        
        entity.removeComponent(LayoutDirty.self)
    }
}
