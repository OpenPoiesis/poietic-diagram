//
//  SVGGraphicElement+BezierPath.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 08/08/2025.
//

extension SVGGraphicElement {
    /// Renders a graphic element into a bezier path applying element's transform.
    ///
    /// - Note: Not supported features: text, clipping, `<use>` elements.
    ///
    public func renderBezierPath() -> BezierPath {
        var path: BezierPath
        switch self {
        case let element as SVGPath:
            path = element.toBezierPath()
        case let element as SVGCircle:
            path = BezierPath(circle: Vector2D(element.cx, element.cy), radius: element.r)
        case let element as SVGEllipse:
            path = BezierPath(ellipse: Vector2D(element.cx, element.cy), radiusX: element.rx, radiusY: element.ry)
        case let element as SVGLine:
            path = BezierPath(line: Vector2D(element.x1, element.y1),
                              to: Vector2D(element.x2, element.y2))
        case let element as SVGPolygon:
            path = BezierPath()
            path.addLines(between: element.points)
            path.closeSubpath()
        case let element as SVGPolyline:
            path = BezierPath()
            path.addLines(between: element.points)
        case let element as SVGRectangle:
            path = BezierPath(rect: Rect2D(x: element.x, y:element.y,
                                           width: element.width, height: element.height))
        case let element as SVGGroup:
            path = BezierPath()
            for child in element.children() {
                guard let child = child as? SVGGraphicElement else {
                    continue
                }
                path += child.renderBezierPath()
            }
        default:
            fatalError("Rendering of \(type(of: self)) to bezier path is not implemented")
        }

        if let trans = self.transform?.asAffineTransform() {
            return path.transform(trans)
        }
        else {
            return path
        }
    }
}
