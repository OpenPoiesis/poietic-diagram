//
//  main.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//

@preconcurrency import ArgumentParser
import Foundation
import Diagramming

@main
struct PictogramTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pictogram",
        abstract: "Tool to manipulate pictograms for Diagramming and Poietic tools",
        subcommands: [
            Extract.self,
        ]
    )
}

func readSVGImage(fromURL: URL) throws -> SVGImage {
    let data = try Data(contentsOf: fromURL)
    let reader = SVGReader()
    let element = try reader.read(data: data)
    
    guard let image = element as? SVGImage else {
        throw SVGReaderError.parsingError("Root element is not an SVG image")
    }
    
    return image
}

/// Converts SVGPath into a BezierPath while applying all transforms of the svgPath element
func convertSVGPath(_ svgPath: SVGPath) -> BezierPath {
    // 1. Get a consolidated transform of the svg path parameter
    let cumulativeTransform = svgPath.cumulativeTransform()
    
    // 2. Convert the transform into AffineTransform
    let affineTransform = cumulativeTransform.asAffineTransform()
    
    // 3. Convert the SVG path to BezierPath
    let bezierPath = svgPath.toBezierPath()
    
    // 4. Get a new BezierPath by applying the affine transform.
    let transformedPath = bezierPath.transform(affineTransform)
    
    // return the new bezier path.
    return transformedPath
}

func extractPictogramPath(image: SVGImage, id: String = "path") -> BezierPath? {
    // 1. Find an element with given ID
    guard let element = image.first(where: { $0.id == id }) else {
        return nil
    }
    
    // 2. Make sure the element is a group element, otherwise return nil.
    guard let group = element as? SVGGroup else {
        return nil
    }
    
    // 3. Make sure the element contains one child which is a path element, otherwise return nil.
    let children = group.children()
    guard children.count == 1,
          let pathElement = children.first as? SVGPath else {
        return nil
    }
    
    // 4. Convert the child, which is the path element, using convertSVGPath()
    let bezierPath = convertSVGPath(pathElement)
    
    // 5. Return the path.
    return bezierPath
}

/// Extract collision shape from SVG group containing a single shape element.
///
/// Transforms are applied using scale factors only - rotation and skew are ignored.
/// For positioning, collision shapes are assumed to be centered at origin.
///
/// - Parameter image: The SVG image to search
/// - Parameter id: The ID of the group element to find
/// - Returns: Tuple containing CollisionShape and its center point with transforms applied, or nil if extraction fails
///
func extractPictogramShape(image: SVGImage, id: String = "shape") -> (shape: CollisionShape, center: Vector2D)? {
    // 1. Find an element with given ID
    guard let element = image.first(where: { $0.id == id }) else {
        return nil
    }
    
    // 2. Make sure the element is a group element, otherwise return nil.
    guard let group = element as? SVGGroup else {
        return nil
    }
    
    // 3. Make sure the element contains one child which is one of the valid collision shape types:
    //    circle, rectangle, ellipse, polygon, or path which is a strict polygon (no curves)
    let children = group.children()
    guard children.count == 1,
          let child = children.first else {
        return nil
    }
    
    // Get cumulative transform for the child
    guard let graphicChild = child as? SVGGraphicElement else {
        return nil
    }

    let transform = graphicChild.cumulativeTransform().asAffineTransform()
    let scale = transform.scale
    
    // 4. Convert the child, which represents the collision shape, into CollisionShape, if possible,
    //    otherwise return nil. Make sure cumulative transform is applied to the final shape.
    switch child {
    case let circle as SVGCircle:
        let r = circle.r * scale.x // Use scale.x for uniform scaling
        let center = transform.apply(to: Vector2D(circle.cx, circle.cy))
        return (shape: .circle(r), center: center)
        
    case let ellipse as SVGEllipse:
        let rx = ellipse.rx * scale.x
        let ry = ellipse.ry * scale.y
        let center = transform.apply(to: Vector2D(ellipse.cx, ellipse.cy))
        return (shape: .ellipse(rx, ry), center: center)
        
    case let rectangle as SVGRectangle:
        let width = rectangle.width * scale.x
        let height = rectangle.height * scale.y
        let center = transform.apply(to: Vector2D(rectangle.x + rectangle.width/2, rectangle.y + rectangle.height/2))
        return (shape: .rectangle(Vector2D(width, height)), center: center)
        
    case let polygon as SVGPolygon:
        let points = polygon.points.map { transform.apply(to: $0) }
        guard let center = Geometry.centroid(points: points) else {
            return nil // Invalid polygon with no points
        }
        return (shape: .polygon(points), center: center)
        
    case let polyline as SVGPolyline:
        let points = polyline.points.map { transform.apply(to: $0) }
        guard let center = Geometry.centroid(points: points) else {
            return nil // Invalid polyline with no points
        }
        return (shape: .polygon(points), center: center) // Treat polyline as polygon
        
    case let path as SVGPath:
        // Convert SVG path to BezierPath and check if it's a strict polygon
        let bezierPath = convertSVGPath(path)
        guard let points = bezierPath.asStrictPolygon() else {
            return nil // Path contains curves
        }
        guard let center = Geometry.centroid(points: points) else {
            return nil // Invalid path with no points
        }
        return (shape: .polygon(points), center: center) // Points are already transformed by convertSVGPath
        
    default:
        return nil // Unsupported shape type
    }
}

/// Extract origin point from SVG element containing a circle.
///
/// Searches for an element that is either a circle directly or a group containing exactly one circle.
/// Returns the transformed center point of the circle with cumulative transforms applied.
///
/// - Parameter image: The SVG image to search
/// - Parameter id: The ID of the element to find
/// - Returns: Center point of the circle with transforms applied, or nil if not found or invalid
///
func extractOrigin(image: SVGImage, id: String = "origin") -> Vector2D? {
    // 1. Find an element with given ID
    guard let element = image.first(where: { $0.id == id }) else {
        return nil
    }
    
    // 2. Check if element is directly a circle
    if let circle = element as? SVGCircle {
        // Get cumulative transform and apply to circle center
        let transform = circle.cumulativeTransform().asAffineTransform()
        let center = Vector2D(circle.cx, circle.cy)
        return transform.apply(to: center)
    }
    
    // 3. Check if element is a group containing exactly one circle
    if let group = element as? SVGGroup {
        let children = group.children()
        guard children.count == 1,
              let circle = children.first as? SVGCircle else {
            return nil
        }
        
        // Get cumulative transform and apply to circle center
        let transform = circle.cumulativeTransform().asAffineTransform()
        let center = Vector2D(circle.cx, circle.cy)
        return transform.apply(to: center)
    }
    
    // 4. Element is neither a circle nor a valid group
    return nil
}

extension PictogramTool {
    struct Extract: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "Extract pictogram")
        
        mutating func run() throws {
            print("Hello!")
        }
    }
}
