//
//  StatusComponents.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 01/06/2026.
//

import PoieticCore

public struct PositionComponent: Component {
    public init(position: Vector2D) {
        self.position = position
    }
    
    public let position: Vector2D
    
}

