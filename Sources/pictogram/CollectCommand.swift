//
//  CollectCommand.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 11/08/2025.
//


@preconcurrency import ArgumentParser
import Foundation
import Diagramming

extension PictogramTool {
    struct Collect: ParsableCommand {
        static let configuration
        = CommandConfiguration(abstract: "Create a pictogram collection")
       
        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Flag(name: [.customLong("pretty")], help: "Pretty format output")
        var pretty: Bool = false

        @Argument(help: "Pictogram files")
        var inputFiles: [String]

        mutating func run() throws {
            guard inputFiles.count > 0 else {
                throw CleanExit.message("No input files given")
            }
            
            var pictograms: [Pictogram]  = []
            var names: Set<String> = Set()
            
            for filename in inputFiles {
                let url = URL(fileURLWithPath: filename)
                let data: Data
                let pictogram: Pictogram
                
                do {
                    data = try Data(contentsOf: url)
                }
                catch {
                    throw ToolError.unableToReadFile(filename)
                }
                
                let decoder = JSONDecoder()
                do {
                    pictogram = try decoder.decode(Pictogram.self, from: data)
                }
                catch let error as DecodingError {
                    throw ToolError.unableToReadPictogram(filename, error.localizedDescription)
                }
                catch {
                    throw ToolError.unableToReadPictogram(filename, "unknown parsing error")
                }
                
                guard !names.contains(pictogram.name) else {
                    throw ToolError.pictogramError("Duplicate pictogram name '\(pictogram.name)' in: \(filename)")
                }
                names.insert(pictogram.name)
                pictograms.append(pictogram)
            }
            
            let collection = PictogramCollection(pictograms)

            let encoder = JSONEncoder()
            if pretty {
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            }
            let jsonData = try encoder.encode(collection)
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

