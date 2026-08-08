//
//  Presenter.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/04/2026.
//

import PoieticCore

public struct ViewportState: Component {
    public let offset: Vector2D
    public let zoom: Double
    
    public lazy var transform = AffineTransform(a: zoom,      b: 0,
                                                c: 0,         d:zoom,
                                                tx: offset.x, ty: offset.y)
    
    public init(offset: Vector2D = .zero, zoom: Double = 1.0) {
        self.offset = offset
        self.zoom = zoom
    }
}

