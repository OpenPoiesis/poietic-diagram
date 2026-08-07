//
//  Composer+Layout.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/06/2026.
//
import PoieticCore

extension DiagramSceneComposer {
    public func layout(scene: RuntimeEntity, layout: any LayoutProvider) {
        for child in scene.children {
            layoutBlock(child, layout: layout)
            // Other canvas node types that need layout go here... (nothing else yet)
        }
        scene.removeComponent(LayoutDirty.self)
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
        guard let pictogramNode: RuntimeEntity = entity.target(SceneNode.Pictogram.self),
              let pictComp: PictogramSceneNode = pictogramNode.component()
        else { return }
        
        let pictogram = pictComp.pictogram
        
        let bbox = pictogram.pathBoundingBox
        var labelTopCenter = Vector2D(0, bbox.topLeft.y)
        var swatchCenter: Vector2D = labelTopCenter

        // 1. Primary label
        if let labelEntity: RuntimeEntity = entity.target(SceneNode.PrimaryLabel.self),
           let label: LabelSceneNode = labelEntity.component()
        {
            let extents = layout.textExtents(label.text, class: .primaryLabel)

            labelTopCenter.y += layout.metric(.primaryLabelPadding, default: 0.0)

            let position = labelTopCenter + Vector2D(0.0, extents.height / 2) - extents.origin
            
            let swatchSize = layout.metric(.colorSwatchSize, default: 0.0)
            swatchCenter = Vector2D(position.x - extents.center.x - swatchSize ,
                                    position.y + extents.height/2)
            

            labelTopCenter.y += extents.height + layout.metric(.secondaryLabelPadding, default: 0.0)
            let offset = layout.labelRenderingOffset(extents: extents, anchor: label.anchor)
            
            labelEntity.setComponent(PositionComponent(position: position))
            if offset != .zero {
                labelEntity.setComponent(RenderingOffset(position: offset))
            }

            let labelBox = Rect2D(origin: -extents.center, size: extents.size)
            let shape = CollisionShape(rectangle: labelBox)
            
            labelEntity.setComponent(shape)
        }
        // 2. Secondary label
        if let labelEntity: RuntimeEntity = entity.target(SceneNode.SecondaryLabel.self),
           let label: LabelSceneNode = labelEntity.component()
        {
            let extents = layout.textExtents(label.text, class: .secondaryLabel)

            labelTopCenter.y += layout.metric(.primaryLabelPadding, default: 0.0)

            let position = labelTopCenter + Vector2D(0.0, extents.height / 2) - extents.origin
            
            let offset = layout.labelRenderingOffset(extents: extents, anchor: label.anchor)

            labelEntity.setComponent(PositionComponent(position: position))
            if offset != .zero {
                labelEntity.setComponent(RenderingOffset(position: offset))
            }

            let labelBox = Rect2D(origin: -extents.center, size: extents.size)
            let shape = CollisionShape(rectangle: labelBox)
            
            labelEntity.setComponent(shape)
        }
        // 3. Color swatch
        if let swatchEntity: RuntimeEntity = entity.target(SceneNode.ColorSwatch.self) {
            swatchEntity.setComponent(PositionComponent(position: swatchCenter))
            // Swatch is not yet touchable, no touch region here.
        }
        
        // 3. Color swatch
        if let indicatorEntity: RuntimeEntity = entity.target(SceneNode.ValueIndicator.self),
           let indicator: ValueIndicatorSceneNode = indicatorEntity.component()
        {
            let offset = layout.metric(.valueIndicatorPadding, default: 0.0)
            let position: Vector2D = Vector2D(
                bbox.center.x,
                bbox.minY - indicator.size.y / 2 - offset
            )
            indicatorEntity.setComponent(PositionComponent(position: position))
            // Swatch is not yet touchable, no touch region here.
        }
        
        entity.removeComponent(LayoutDirty.self)
    }
}
