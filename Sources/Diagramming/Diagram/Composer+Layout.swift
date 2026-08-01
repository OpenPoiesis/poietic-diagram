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
        guard let pictogramNode: RuntimeEntity = entity.target(CanvasNode.Pictogram.self),
              let pictComp: PictogramCanvasNode = pictogramNode.component()
        else { return }
        
        let pictogram = pictComp.pictogram
        
        let bbox = pictogram.pathBoundingBox
        var labelCenter = Vector2D(0, bbox.topLeft.y)
        var swatchCenter: Vector2D = labelCenter

        // 1. Primary label
        if let labelEntity: RuntimeEntity = entity.target(CanvasNode.PrimaryLabel.self),
           let label: LabelCanvasNode = labelEntity.component()
        {
            labelCenter.y += layout.metric(.primaryLabelPadding, default: 0.0)
            let extents = layout.textExtents(label.text, class: .primaryLabel)
            let position = labelPosition(center: labelCenter, anchor: label.anchor, extents: extents)

            labelCenter.y += layout.metric(.secondaryLabelPadding, default: 0.0)
            swatchCenter = Vector2D(position.x - layout.metric(.colorSwatchSize, default: 0.0),
                                    position.y - extents.height/2)

            labelEntity.setComponent(PositionComponent(position: position))
            
            let shape = CollisionShape(rectangle: extents)
            labelEntity.setComponent(shape)
        }
        // 2. Secondary label
        if let labelEntity: RuntimeEntity = entity.target(CanvasNode.SecondaryLabel.self),
           let label: LabelCanvasNode = labelEntity.component()
        {
            let extents = layout.textExtents(label.text, class: .secondaryLabel)
            let position = labelPosition(center: labelCenter, anchor: label.anchor, extents: extents)

            labelEntity.setComponent(PositionComponent(position: position))

            let shape = CollisionShape(rectangle: extents)
            labelEntity.setComponent(shape)
        }
        // 3. Color swatch
        if let swatchEntity: RuntimeEntity = entity.target(CanvasNode.ColorSwatch.self) {
            swatchEntity.setComponent(PositionComponent(position: swatchCenter))
            // Swatch is not yet touchable, no touch region here.
        }

    }
    
    @inlinable
    func labelPosition(center: Vector2D, anchor: Vector2D, extents: Rect2D) -> Vector2D {
        return center - extents.origin - extents.size * anchor
    }

}
