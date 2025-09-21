//
//  Pictogram+SVG.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/08/2025.
//


extension Pictogram {
    public func toSVGElement() -> SVGGraphicElement {
        let path = SVGPath(self.path)
        path.setStyle(fill: "none", stroke: "black")
        path.transform = SVGTransformList([
            .translate(tx: -self.origin.x, ty: -self.origin.y),
        ])
        return path
    }
        
    public func toDebugSVGElement() -> SVGGraphicElement {
        let result = SVGGroup()
        result.id = "debug-\(name)"
        let bbox = SVGRectangle(id: "debug-bbox-\(name)",
                                rect: self.boundingBox)
        bbox.setStyle(fill: "none", stroke: "LimeGreen")
        result.addChild(bbox)
        
        let mask = SVGPath(self.mask)
        mask.id = "debug-mask-\(name)"
        mask.setStyle(fill: "yellow", stroke: "orange")
        mask.transform = SVGTransformList([
//            .translate(tx: -self.origin.x, ty: -self.origin.y),
        ])
        result.addChild(mask)

        let collision = self.collisionShape.toSVGElement()
        collision.id = "debug-collision-\(name)"
        if let collision = collision as? SVGGeometryElement {
            collision.setStyle(fill: "lightsalmon", stroke: "red")
        }
        collision.transform = SVGTransformList([
//            .translate(tx: origin.x, ty: origin.y),
        ])

        result.addChild(collision)

        // Origin
        let origin = SVGCircle(id: "debug-origin-\(name)",
                               center: self.origin,
                               radius: 4.0)
        origin.setStyle(fill: "yellow", stroke: "red")
        result.addChild(origin)

        return result

    }
}

extension ShapeType {
    public func toSVGElement() -> SVGGeometryElement {
        switch self {
        case let .circle(radius):
            let element = SVGCircle()
            element.cx = 0.0
            element.cy = 0.0
            element.r = radius
            return element
        case let .rectangle(size):
            let element = SVGRectangle()
            element.x = -size.x / 2.0
            element.y = -size.y / 2.0
            element.width = size.x
            element.height = size.y
            return element
        case let .convexPolygon(points), let .concavePolygon(points):
            let element = SVGPolygon()
            element.points = points
            return element
        }
    }
}

extension CollisionShape {
    public func toSVGElement() -> SVGGeometryElement {
        switch shape {
        case let .circle(radius):
            let element = SVGCircle()
            element.cx = position.x
            element.cy = position.y
            element.r = radius
            return element
        case let .rectangle(size):
            let element = SVGRectangle()
            element.x = position.x - (size.x) / 2.0
            element.y = position.y - (size.y) / 2.0
            element.width = size.x
            element.height = size.y
            return element
        case let .convexPolygon(points), let .concavePolygon(points):
            let element = SVGPolygon()
            element.points = points.map { $0 + position }
            return element
        }
    }
}

