//
//  Composer+Layout.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/06/2026.
//
import PoieticCore

extension DiagramSceneComposer {
    public func layoutDiagram(scene: RuntimeEntity, layout: some LayoutProvider) {
        print("=== Layout diagram scene \(scene) with \(scene.children.count) children")
        for child in scene.children {
            guard child.contains(BlockCanvasNode.self)
            else { continue }
            
            layoutBlock(child, layout: layout)
        }
    }
    /// Lays out block children nodes such as labels and indicators.
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
        guard let pictComp: PictogramCanvasNode = entity.component()
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
            let position = labelCenter + extents.center

            labelCenter.y = position.y + layout.metric(.secondaryLabelPadding, default: 0.0)
            swatchCenter = Vector2D(position.x - layout.metric(.colorSwatchSize, default: 0.0),
                                    position.y - extents.height/2)

            let positionComp = PositionComponent(position: position)
            labelEntity.setComponent(positionComp)
        }
        // 2. Secondary label
        if let labelEntity: RuntimeEntity = entity.target(CanvasNode.SecondaryLabel.self),
           let label: LabelCanvasNode = labelEntity.component()
        {
            let extents = layout.textExtents(label.text, class: .secondaryLabel)
            let position = labelCenter + extents.center
            let positionComp = PositionComponent(position: position)
            labelEntity.setComponent(positionComp)
        }
        // 3. Color swatch
        if let swatchEntity: RuntimeEntity = entity.target(CanvasNode.ColorSwatch.self) {
            swatchEntity.setComponent(PositionComponent(position: swatchCenter))
        }

    }

}
