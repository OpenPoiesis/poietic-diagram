//
//  CatalogCommand.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 07/08/2025.
//

@preconcurrency import ArgumentParser
import Foundation
import Diagramming

extension PictogramTool {
    struct Catalog: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "Create a catalog preview of pictograms")
       
        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Argument(help: "Pictogram files")
        var inputFiles: [String]

        mutating func run() throws {
            guard inputFiles.count > 0 else {
                throw CleanExit.message("No input files given")
            }
            
            var pictograms: [Pictogram]  = []

            for filename in inputFiles {
                let url = URL(fileURLWithPath: filename)
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let pictogram = try decoder.decode(Pictogram.self, from: data)
                pictograms.append(pictogram)
            }
            
            let image = createCatalog(pictograms)
            
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

func createCatalog(_ pictograms: [Pictogram], columns: Int = 3, padding: Double = 10.0) -> SVGImage{
    let image = SVGImage()
    
    var tileSize = Vector2D()
    
    for picto in pictograms {
        let size = picto.maskBoundingBox.size
        tileSize = Vector2D(max(tileSize.x, size.x), max(tileSize.y, size.y))
    }
    
    var column: Int = 0
    var row: Int = 0

    for picto in pictograms {
        let origin = Vector2D(x: (tileSize.x + padding) * Double(column),
                              y: (tileSize.y + padding) * Double(row))
        let element = picto.toSVGElement()
        (element as? SVGGeometryElement)?.strokeWidth = 2.0
        let debug = picto.toDebugSVGElement()

        let center = (tileSize / 2)
        
        let bbox = picto.path.boundingBox!
        let offset = center - bbox.center
        
        element.id = "pictogram-\(picto.name)"

        let transform = SVGTransformList([
            .translate(tx: origin.x + offset.x, ty: origin.y + offset.y),
        ])
        
        element.transform = transform
        debug.transform = transform
        image.addChild(debug)
        image.addChild(element)
        
        let tbox = SVGRectangle()
        tbox.x = origin.x
        tbox.y = origin.y
        tbox.width = tileSize.x
        tbox.height = tileSize.y
        tbox.fill = "none"
        tbox.stroke = "blue"
        image.addChild(tbox)

        column += 1
        if column >= columns {
            column = 0
            row += 1
        }
    }
    
    image.width = (tileSize.x + padding) * Double(column + 1)
    image.height = (tileSize.y + padding) * Double(row + 1)

    return image
}
