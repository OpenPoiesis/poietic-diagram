//
//  ExtractCommand.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/08/2025.
//
@preconcurrency import ArgumentParser
import Foundation
import Diagramming

enum SVGPictogramError: Error, CustomStringConvertible {
    /// Path element was not found in the image.
    case noPictogramElementFound
    
    /// Path element has no path components.
    case emptyPictogramPath

    /// No shape element found in the image.
    case noCollisionShapeFound
    
    /// Element is of different type than expected.
    ///
    /// For example a collision shape element is expected to be a group element.
    case elementTypeMismatch(id: String, expected: String)
    
    /// Structure of an element is not as expected.
    ///
    /// For example: group element for a path must contain only one item and it must be a path.
    case invalidStructure(id: String, details: String)
    
    /// Shape element is of unsupported type or a shape path contains curves.
    case invalidShape
    
    var description: String {
        switch self {
        case .elementTypeMismatch(let id, let expected):
            "Element with id '\(id)' is expected to be of type '\(expected)'"
        case .noPictogramElementFound:
            "No graphic element for pictogram found"
        case .noCollisionShapeFound:
            "No element for the pictogram collision shape found"
        case .emptyPictogramPath:
            "Pictogram path is empty or there is no pictogram graphic element"
        case .invalidShape:
            "Invalid shape type, expected: circle, rect, polyline, polygon, path (polyline only)"
        case .invalidStructure(let id, let details):
            "Invalid element structure in id '\(id)', details: \(details)"
        }
    }

}

extension PictogramTool {
    struct Extract: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "Extract pictogram")
       
        @Option(name: [.customLong("name")], help: "Pictogram name. Default is base filename.")
        var name: String?

        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Flag(name: [.customLong("pretty")], help: "Pretty format output")
        var pretty: Bool = false

        @Argument(help: "SVG file with Pictogram structure")
        var inputFile: String

        mutating func run() throws {
            let inputURL = URL(fileURLWithPath: inputFile)
            let svgImage = try readSVGImage(fromURL: inputURL)
            
            let pictogramName = name ?? inputURL.deletingPathExtension().lastPathComponent
            let pictogram = try extractPictogram(image: svgImage, name: pictogramName)
            
            let encoder = JSONEncoder()
            if pretty {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            }
            let jsonData = try encoder.encode(pictogram)
            
            if outputPath == "-" {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            } else {
                let outputURL = URL(fileURLWithPath: outputPath)
                try jsonData.write(to: outputURL)
            }
        }
    }
}

/// Converts SVGPath into a BezierPath while applying all transforms of the svgPath element
func convertSVGPath(_ element: SVGGeometryElement) -> BezierPath {
    let cumulativeTransform = element.cumulativeTransform()
    let transform = cumulativeTransform.asAffineTransform()
    let result = element.toBezierPath().transform(transform)
    return result
}

func extractPictogramPath(image: SVGImage, id: String = "pictogram") throws (SVGPictogramError) -> BezierPath {
    guard let first = image.first(where: { $0.id == id }) else {
        throw .noPictogramElementFound
    }
    
    guard let element = first as? SVGGraphicElement else {
        throw .elementTypeMismatch(id: id, expected: "graphic element")
    }

    var result = element.renderBezierPath()
    
    if let parent = element.parent as? SVGGraphicElement{
        let trans = parent.cumulativeTransform().asAffineTransform()
        result = result.transform(trans)
    }
    
    if result.isEmpty {
        throw .emptyPictogramPath
    }
    
    return result
}

func extractPictogramMask(image: SVGImage, id: String = "mask") -> BezierPath? {
    guard let first = image.first(where: { $0.id == id }) else {
        return nil
    }
    
    guard let element = first as? SVGGraphicElement else {
        return nil
    }

    var result = element.renderBezierPath()
    
    if let parent = element.parent as? SVGGraphicElement{
        let trans = parent.cumulativeTransform().asAffineTransform()
        result = result.transform(trans)
    }
    
    if result.isEmpty {
        return nil
    }
    
    return result
}

/// Extract collision shape from SVG group containing a single shape element.
///
/// Transforms are applied using scale factors only - rotation and skew are ignored.
/// For positioning, collision shapes are assumed to be centered at origin.
///
/// - Parameter image: The SVG image to search
/// - Parameter id: The ID of the group element to find
/// - Returns: Tuple containing CollisionShape and its center point with transforms applied
/// - Throws: SVGPictogramError if extraction fails
///
func extractPictogramCollision(image: SVGImage, id: String = "collision") throws -> CollisionShape {
    // 1. Find an element with given ID
    guard let element = image.first(where: { $0.id == id }) else {
        throw SVGPictogramError.noCollisionShapeFound
    }
    
    // 2. Make sure the element is a group element, otherwise throw error.
    guard let group = element as? SVGGroup else {
        throw SVGPictogramError.elementTypeMismatch(id: id, expected: "group")
    }
    
    // 3. Make sure the element contains one child which is one of the valid collision shape types:
    //    circle, rectangle, ellipse, polygon, or path which is a strict polygon (no curves)
    let children = group.children()
    guard children.count == 1 else {
        throw SVGPictogramError.invalidStructure(id: id, details: "Group must contain exactly one element")
    }
    
    guard let child = children.first else {
        throw SVGPictogramError.invalidStructure(id: id, details: "Group must contain exactly one shape element")
    }
    
    // Get cumulative transform for the child
    guard let graphicChild = child as? SVGGraphicElement else {
        throw SVGPictogramError.invalidShape
    }

    let transform = graphicChild.cumulativeTransform().asAffineTransform()
    let scale = transform.scale
    
    // 4. Convert the child, which represents the collision shape, into CollisionShape, if possible,
    //    otherwise return nil. Make sure cumulative transform is applied to the final shape.
    switch child {
    case let circle as SVGCircle:
        let r = circle.r * scale.x
        let center = transform.apply(to: Vector2D(circle.cx, circle.cy))
        return CollisionShape(position: center, shape: .circle(r))
        
    case let ellipse as SVGEllipse:
        let rx = ellipse.rx * scale.x
        let ry = ellipse.ry * scale.y
        let center = transform.apply(to: Vector2D(ellipse.cx, ellipse.cy))
        return CollisionShape(position: center, shape: .rectangle(Vector2D(rx, ry) * 2))
        
    case let rectangle as SVGRectangle:
        let width = rectangle.width * scale.x
        let height = rectangle.height * scale.y
        let center = transform.apply(to: Vector2D(rectangle.x + rectangle.width/2, rectangle.y + rectangle.height/2))
        return CollisionShape(position: center, shape: .rectangle(Vector2D(width, height)))
        
    case let polygon as SVGPolygon:
        let points = polygon.points.map { transform.apply(to: $0) }
        // Points already contain a position, relative to the coordinate system of the original pictogram
        let shapeType: ShapeType = Geometry.isConvex(polygon: points) ? .convexPolygon(points) : .concavePolygon(points)
        return CollisionShape(position: .zero, shape: shapeType)
        
    case let polyline as SVGPolyline:
        let points = polyline.points.map { transform.apply(to: $0) }
        let shapeType: ShapeType = Geometry.isConvex(polygon: points) ? .convexPolygon(points) : .concavePolygon(points)
        return CollisionShape(position: .zero, shape: shapeType)

    case let path as SVGPath:
        let bezierPath = convertSVGPath(path)
        guard let points = bezierPath.asStrictPolygon() else {
            throw SVGPictogramError.invalidShape // Path contains curves
        }
        let shapeType: ShapeType = Geometry.isConvex(polygon: points) ? .convexPolygon(points) : .concavePolygon(points)
        return CollisionShape(position: .zero, shape: shapeType)
    default:
        throw SVGPictogramError.invalidShape // Unsupported shape type
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

    let originElement: SVGGraphicElement
    
    if let group = element as? SVGGroup {
        guard group.children().count == 1 else {
            return nil
        }
        guard let first = group.children().first as? SVGGraphicElement else {
            return nil
        }
        originElement = first
    }
    else {
        guard let element = element as? SVGGraphicElement else {
            return nil
        }
        originElement = element
    }
    
    let transform = originElement.cumulativeTransform().asAffineTransform()
    var center: Vector2D

    switch originElement {
    case let circle as SVGCircle:
        center = Vector2D(circle.cx, circle.cy)
    case let ellipse as SVGEllipse:
        center = Vector2D(ellipse.cx, ellipse.cy)
    default:
        return nil
    }
    
    return transform.apply(to: center)
}


func extractPictogram(image: SVGImage, name: String) throws -> Pictogram {
    // Extract pictogram from a SVG image
    // 1. Extract pictogram path - required.
    let extractedPath = try extractPictogramPath(image: image)
    
    // 2. Extract pictogram shape and its center - required.
    let extractedCollision = try extractPictogramCollision(image: image)

    // 2. Extract pictogram shape and its center - required.
    let extractedMask = extractPictogramMask(image: image)

    // 3. Optionally extract origin. If origin is not present, then use shape center as origin.
    let origin = extractOrigin(image: image) ?? extractedCollision.center
    let transform = AffineTransform(translation: -origin)

    let path = extractedPath.transform(transform)
    let collision = CollisionShape(position: extractedCollision.position - origin,
                                   shape: extractedCollision.shape)
    let mask: BezierPath?
    if let extractedMask {
        mask = extractedMask.transform(transform)
    }
    else {
        mask = nil
    }
    
    // 5. Create a pictogram object, make the collision and mask shapes the same.
    let pictogram = Pictogram(name,
                              path: path,
                              collisionShape: collision,
                              mask: mask)
                              
    
    return pictogram
}

