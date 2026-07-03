//
//  Composer+Layout.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/06/2026.
//
import PoieticCore

public protocol LayoutContextProtocol {
    var layoutStyle: DiagramLayoutStyle { get }
    /// Save layout state on a stack. State is restored with ``restoreState()``
    func saveState()
    /// Restore saved state from a stack. State is saved with ``saveState()``.
    ///
    /// When no state is saved, nothing happens.
    func restoreState()
    
    /// Set current affine transform of the layout.
    ///
    /// - SeeAlso: ``saveState()``, ``restoreState()``
    ///
    func setTransform(_ transform: AffineTransform)
    
    /// Compute text label extents.
    ///
    func textExtents(text: String, font: DiagramLayoutStyle.FontKey) -> Rect2D
}

extension DiagramSceneComposer {
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
    public func layoutBlock(_ entity: RuntimeEntity, context: some LayoutContextProtocol) {
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
            let extents = context.textExtents(text: label.text, font: .primaryBlockLabel)
            let position = labelCenter + extents.center

            labelCenter.y = position.y + context.layoutStyle.metric(.secondaryLabelPadding)
            swatchCenter = Vector2D(position.x - context.layoutStyle.metric(.colorSwatchSize),
                                    position.y - extents.height/2)

            let positionComp = PositionComponent(position: position)
            labelEntity.setComponent(positionComp)
        }
        // 2. Secondary label
        if let labelEntity: RuntimeEntity = entity.target(CanvasNode.SecondaryLabel.self),
           let label: LabelCanvasNode = labelEntity.component()
        {
            let extents = context.textExtents(text: label.text, font: .secondaryBlockLabel)
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
