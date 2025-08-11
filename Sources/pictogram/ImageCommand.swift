//
//  ImageCommand.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/08/2025.
//
@preconcurrency import ArgumentParser
import Foundation
import Diagramming

extension PictogramTool {
    struct Image: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "Create an image from a pictogram")
       
        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Argument(help: "Pictogram file")
        var inputFile: String

        mutating func run() throws {
            // 1. Read the SVG file -> SVGImage
            let inputURL = URL(fileURLWithPath: inputFile)
            let data = try Data(contentsOf: inputURL)
            let decoder = JSONDecoder()
            let pictogram = try decoder.decode(Pictogram.self, from: data)
            
            print("Pictogram: \(pictogram)")
            
            let image = pictogramToSVG(pictogram)
            
            let writer = SVGWriter()
            let text = writer.write(image)
            if outputPath == "-" {
                print(text)
            } else {
                let data: Data = text.data(using: .utf8)!
                try data.write(to: URL(fileURLWithPath: outputPath))
            }
        }
    }
}

func pictogramToSVG(_ pictogram: Pictogram) -> SVGImage {
    let image = SVGImage()
    let box = pictogram.path.boundingBox!
    image.width = box.width
    image.height = box.height

    let group = pictogramToSVGGroup(pictogram)

    image.addChild(group)
    
    image.viewBox = SVGViewBox(box)
    return image
}
func pictogramToSVGGroup(_ pictogram: Pictogram, includeNameInID: Bool = false) -> SVGGroup {
    let idSuffix: String
    if includeNameInID {
        idSuffix = "-" + pictogram.name
    }
    else {
        idSuffix = ""
    }
    
    let image = SVGGroup()
    
    let path = SVGPath(pictogram.path)
    let box = pictogram.path.boundingBox!
    path.fill = "none"
    path.stroke = "black"
    
    let group = SVGGroup()
    group.id = "pictogram" + idSuffix
    group.addChild(path)
    
    image.addChild(group)
    
    // Origin
    let origin = SVGCircle()
    origin.id = "origin" + idSuffix
    origin.cx = pictogram.origin.x
    origin.cy = pictogram.origin.y
    origin.fill = "salmon"
    origin.stroke = "red"
    origin.r = 2
    image.addChild(origin)

    // Debug
    
    let debug = SVGGroup()
    debug.id = "debug" + idSuffix
    
    let bbox = SVGRectangle()
    bbox.x = box.origin.x
    bbox.y = box.origin.y
    bbox.width = box.width
    bbox.height = box.height
    bbox.fill = "none"
    bbox.stroke = "yellow"
    debug.addChild(bbox)
    image.addChild(debug)
    
    return image
}

func shapeToSVG(_ shape: CollisionShape) -> SVGGraphicElement {
    switch shape {
    case let .circle(radius):
        let element = SVGCircle()
        element.r = radius
        return element
    case let .ellipse(cx, cy):
        let element = SVGEllipse()
        element.cx = cx
        element.cy = cy
        return element
    case let .rectangle(size):
        let element = SVGRectangle()
        element.x = -(size.x) / 2.0
        element.y = -(size.y) / 2.0
        element.width = size.x
        element.height = size.y
        return element
    case let .polygon(points):
        let element = SVGPolygon()
        element.points = points
        return element
    }
}

