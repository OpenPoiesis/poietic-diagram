//
//  Camera.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/04/2026.
//

import PoieticCore

public struct Camera: Component {
    public let offset: Vector2D
    public let zoom: Double
    
    public init(offset: Vector2D = .zero, zoom: Double = 1.0) {
        self.offset = offset
        self.zoom = zoom
    }
}

