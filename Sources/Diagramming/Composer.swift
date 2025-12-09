//
//  SVGDiagramComposer.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 14/07/2025.
//

public class SVGDiagramComposer {
    let pictogramColor = "black"
    
    var elements: [SVGElement]
    var pictograms: [String:Pictogram]
    var symbols: [String:SVGSymbol]
    
    public init(pictograms: [Pictogram]) {
        self.elements = []
        self.pictograms = [:]
        for pictogram in pictograms {
            self.pictograms[pictogram.name] = pictogram
        }
        self.symbols = [:]
    }
    
    public func symbolForPictogram(_ name: String) -> SVGSymbol {
        if let symbol = symbols[name] {
            return symbol
        }

        guard let pictogram = pictograms[name] else {
            fatalError("Unknown pictogram '\(name)'")
        }

        let path = SVGPath(pictogram.path)
        path.fill = "none"
        path.stroke = pictogramColor

        let group = SVGGroup()
        group.addChild(path)

        let symbol = SVGSymbol()
        symbol.addChild(group)
        
        symbol.id = "pictogram-\(name)"
        
        symbols[name] = symbol
        return symbol
    }
    
    public func compose() -> SVGImage {
        let image = SVGImage()
        for symbol in symbols.values {
            image.addChild(symbol)
        }
        for element in elements {
            image.addChild(element)
        }
        return image
    }
}
