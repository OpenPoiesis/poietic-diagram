//
//  main.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//

@preconcurrency import ArgumentParser
import Foundation
import Diagramming

enum ToolError: Error {
    case unableToReadFile(String)
    case unableToReadPictogram(String, String?)
    case pictogramError(String)
    
    var description: String {
        switch self {
        case .unableToReadFile(let file):
            return "Unable to read file '\(file)'"
        case .unableToReadPictogram(let location, let details):
            if let details {
                return "Unable to read pictogram '\(location)': \(details)"
            }
            else {
                return "Unable to read file '\(location)'"
            }
        case .pictogramError(let message):
            return "Pictogram error: \(message)"
        }
    }
}

@main
struct PictogramTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pictogram",
        abstract: "Tool to manipulate pictograms for Diagramming and Poietic tools",
        subcommands: [
            Extract.self,
            Collect.self,
            Preview.self,
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
