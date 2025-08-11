//
//  SVGTransform.swift
//  poietic-asset
//
//  Created by Stefan Urbanek on 10/03/2025.
//

public struct SVGLength {
    enum Unit: String {
        case pixels = "px"
        case centimeters = "cm"
        case inches = "in"
        case millimeters = "mm"
        case picas = "pc"
    }
    let length: Double
    let unit: Unit
}

public extension Vector2D {
    var rawSVGValue: String { "\(x),\(y)" }
}


public struct SVGViewBox {
    var minX: Double
    var minY: Double
    var width: Double
    var height: Double

    public init(_ rect: Rect2D) {
        self.minX = rect.minX
        self.minY = rect.minY
        self.width = rect.width
        self.height = rect.height
    }
    init?(string: String) {
        var scanner = StringScanner(string)
        
        scanner.skipWhitespace()
        guard let minX = scanner.scanDouble() else { return nil }
        scanner.skipWhitespace()
        scanner.accept(",")
        scanner.skipWhitespace()
        guard let minY = scanner.scanDouble() else { return nil }
        scanner.skipWhitespace()
        scanner.accept(",")
        scanner.skipWhitespace()
        guard let width = scanner.scanDouble() else { return nil }
        scanner.skipWhitespace()
        scanner.accept(",")
        scanner.skipWhitespace()
        guard let height = scanner.scanDouble() else { return nil }
        
        self.minX = minX
        self.minY = minY
        self.width = width
        self.height = height
    }
    
    var rawValue: String { "\(minX) \(minY) \(width) \(height)" }
}
