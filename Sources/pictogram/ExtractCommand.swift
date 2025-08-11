//
//  ExtractCommand.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/08/2025.
//
@preconcurrency import ArgumentParser
import Foundation
import Diagramming

enum SVGPictogramError: Error {
    /// Path element was not found in the image.
    case noPictogramPathFound
    
    /// Path element has no path components.
    case emptyPictogramPath

    /// No shape element found in the image.
    case noShapeFound
    
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
    
}

extension PictogramTool {
    struct Extract: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "Extract pictogram")
       
        @Option(name: [.customLong("name")], help: "Pictogram name. Default is base filename.")
        var name: String?

        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Argument(help: "SVG file with Pictogram structure")
        var inputFile: String

        mutating func run() throws {
            // 1. Read the SVG file -> SVGImage
            let inputURL = URL(fileURLWithPath: inputFile)
            let svgImage = try readSVGImage(fromURL: inputURL)
            
            // 2. Extract Pictogram from the SVGImage
            let pictogramName = name ?? inputURL.deletingPathExtension().lastPathComponent
            let pictogram = try extractPictogram(image: svgImage, name: pictogramName)
            
            // 3. Write Pictogram as JSON to outputPath or print to stdout
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(pictogram)
            
            if outputPath == "-" {
                // Print to stdout
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            } else {
                // Write to file
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

func extractPictogramPath(image: SVGImage, id: String = "pictogram") throws -> BezierPath {
    guard let first = image.first(where: { $0.id == id }) else {
        throw SVGPictogramError.noPictogramPathFound
    }
    
    guard let element = first as? SVGGraphicElement else {
        throw SVGPictogramError.elementTypeMismatch(id: id, expected: "graphic element")
    }

    var result = element.renderBezierPath()
    
    if let parent = element.parent as? SVGGraphicElement{
        let trans = parent.cumulativeTransform().asAffineTransform()
        result = result.transform(trans)
    }
    
    if result.isEmpty {
        throw SVGPictogramError.emptyPictogramPath
    }
    
    return result
}

func extractPictogramPathOld(image: SVGImage, id: String = "pictogram") throws -> BezierPath {
    var result = BezierPath()

    guard let element = image.first(where: { $0.id == id }) else {
        throw SVGPictogramError.noPictogramPathFound
    }
    
    guard let group = element as? SVGGroup else {
        throw SVGPictogramError.elementTypeMismatch(id: id, expected: "group")
    }
    
    // 3. Make sure the element contains one child which is a path element, otherwise throw error.
    let children = group.children()

    for child in children {
        guard let pathElement = child as? SVGGeometryElement else {
            throw SVGPictogramError.invalidStructure(id: id, details: "Geometry element expected, got: \(type(of: child))")
        }
        let path = convertSVGPath(pathElement)
        result.addPath(path)
    }
    if result.isEmpty {
        throw SVGPictogramError.emptyPictogramPath
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
func extractPictogramShape(image: SVGImage, id: String = "shape") throws -> (shape: CollisionShape, center: Vector2D) {
    // 1. Find an element with given ID
    guard let element = image.first(where: { $0.id == id }) else {
        throw SVGPictogramError.noShapeFound
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
            throw SVGPictogramError.invalidShape // Invalid polygon with no points
        }
        return (shape: .polygon(points), center: center)
        
    case let polyline as SVGPolyline:
        let points = polyline.points.map { transform.apply(to: $0) }
        guard let center = Geometry.centroid(points: points) else {
            throw SVGPictogramError.invalidShape // Invalid polyline with no points
        }
        return (shape: .polygon(points), center: center) // Treat polyline as polygon
        
    case let path as SVGPath:
        // Convert SVG path to BezierPath and check if it's a strict polygon
        let bezierPath = convertSVGPath(path)
        guard let points = bezierPath.asStrictPolygon() else {
            throw SVGPictogramError.invalidShape // Path contains curves
        }
        guard let center = Geometry.centroid(points: points) else {
            throw SVGPictogramError.invalidShape // Invalid path with no points
        }
        return (shape: .polygon(points), center: center) // Points are already transformed by convertSVGPath
        
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
    let path = try extractPictogramPath(image: image)
    
    // 2. Extract pictogram shape and its center - required.
    let shapeResult = try extractPictogramShape(image: image)
    let collisionShape = shapeResult.shape
    let shapeCenter = shapeResult.center
    
    // 3. Optionally extract origin. If origin is not present, then use shape center as origin.
    let origin = extractOrigin(image: image) ?? shapeCenter
    
    // 4. Compute bounding box of the path.
    let boundingBox = path.boundingBox! // Force unwrap - guaranteed to work after successful path extraction
    
    // 5. Create a pictogram object, make the collision and mask shapes the same.
    let pictogram = Pictogram(name,
                              path: path,
                              maskShape: collisionShape,
                              origin: origin,
                              boundingBox: boundingBox,
                              collisionShape: collisionShape)
    
    return pictogram
}

