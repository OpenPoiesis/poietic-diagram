//
//  StringScanner+SVG.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//


extension StringScanner {
    public mutating func scanSVGLength(dpi: Double = DefaultSVGLengthDPI) -> Double? {
        let savedIndex = self.currentIndex
        guard let length = self.scanDouble() else {
            return nil
        }
        
        self.skipWhitespace()
        
        guard let units = self.scanIdentifier() else {
            return length
        }
        
        switch units {
        case "px": return length
        case "in": return length * dpi
        case "pt": return (length / 72.0) * dpi
        case "cm": return (length * 0.393701) * dpi
        case "mm": return (length * 0.0393701) * dpi
        case "pc": return (length * 12.0 / 72.0) * dpi
        default:
            self.currentIndex = savedIndex
            return nil
        }
    }
    public mutating func scanSVGCommaSeparatedLengths(dpi: Double=DefaultSVGLengthDPI) -> [Double]? {
        var numbers: [Double] = []
        
        while !atEnd {
            self.skipWhitespace()
            guard let number = self.scanDouble() else {
                break
            }
            numbers.append(number)
            self.skipWhitespace()
            self.accept(",")
        }
        return numbers
    }
    public mutating func scanSVGPoint(dpi: Double=DefaultSVGLengthDPI) -> Vector2D? {
        let savedIndex = self.currentIndex

        self.skipWhitespace()
        guard let x = scanDouble() else {
            self.currentIndex = savedIndex
            return nil
        }

        self.skipWhitespace()
        self.accept(",")
        self.skipWhitespace()

        guard let y = scanDouble() else {
            self.currentIndex = savedIndex
            return nil
        }
        return Vector2D(x, y)
    }
    
    public mutating func scanSVGPathComponents(dpi: Double=DefaultSVGLengthDPI) -> [SVGPath.Component]? {
        let savedIndex = self.currentIndex
        // TODO: Implement this.
        fatalError("Not implemented")
    }
}

