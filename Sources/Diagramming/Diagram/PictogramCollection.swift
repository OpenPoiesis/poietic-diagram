//
//  PictogramCollection.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 11/08/2025.
//


public class PictogramCollection: Codable {
    public var pictograms: [Pictogram]
    
    public init(_ pictograms: [Pictogram] = []) {
        self.pictograms = pictograms
    }
    
    public func pictogram(_ name: String) -> Pictogram? {
        return pictograms.first { $0.name == name }
    }
}
