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
            Image.self,
            Catalog.self,
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
