//
//  ImageCommand.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 05/08/2025.
//
@preconcurrency import ArgumentParser
import Foundation
import Diagramming

// TODO: Accept pictogram collection

extension PictogramTool {
    struct Preview: ParsableCommand {
        static let configuration
        = CommandConfiguration(commandName: "preview",
                               abstract: "Create an image from a pictogram")
       
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
    path.setStyle(fill: "none", stroke: "black")
    
    let group = SVGGroup()
    group.id = "pictogram" + idSuffix
    group.addChild(path)
    
    image.addChild(group)
    
    // Origin
    let origin = SVGCircle(id: "origin" + idSuffix, center: pictogram.origin, radius: 2.0)
    origin.setStyle(fill: "salmon", stroke: "red")
    image.addChild(origin)

    // Debug
    
    let debug = SVGGroup()
    debug.id = "debug" + idSuffix
    
    let bbox = SVGRectangle(rect: box)
    bbox.setStyle(fill: "none", stroke: "yellow")
    debug.addChild(bbox)
    image.addChild(debug)
    
    return image
}
