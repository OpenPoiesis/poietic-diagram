//
//  SVGTransform.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 04/07/2025.
//

// FIXME: for tan()
import Foundation

public enum SVGTransform {
    case translate(tx: Double, ty: Double)
    case rotate(angle: Double, cx: Double?, cy: Double?)
    case scale(sx: Double, sy: Double)
    case matrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
    case skewX(angle: Double)
    case skewY(angle: Double)

    init?(type: String, parameters: [Double]) {
        guard parameters.count >= 1 else { return nil }
        
        switch type.lowercased() {
        case "translate":
            if parameters.count >= 2 {
                self = .translate(tx: parameters[0], ty: parameters[1])
            }
            else {
                self = .translate(tx: parameters[0], ty: 0.0)
            }
            
        case "rotate":
            if parameters.count >= 3 {
                self = .rotate(angle: parameters[0], cx: parameters[1], cy: parameters[2])
            }
            else {
                self = .rotate(angle: parameters[0], cx: nil, cy: nil)
            }
            
        case "scale":
            if parameters.count >= 2 {
                self = .scale(sx: parameters[0], sy: parameters[1])
            }
            else {
                self = .scale(sx: parameters[0], sy: parameters[0])
            }
            
        case "matrix":
            guard parameters.count == 6 else { return nil }
            self = .matrix(a: parameters[0], b: parameters[1], c: parameters[2],
                           d: parameters[3], e: parameters[4], f: parameters[5])
            
        case "skewx":
            guard parameters.count == 1 else { return nil }
            self = .skewX(angle: parameters[0])
            
        case "skewy":
            guard parameters.count == 1 else { return nil }
            self = .skewY(angle: parameters[0])
            
        default:
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .translate(let tx, let ty):
            "translate(\(tx) \(ty))"
        case .rotate(let angle, let cx, let cy):
            if let cx = cx, let cy = cy {
                "rotate(\(angle) \(cx) \(cy))"
            }
            else {
                "rotate(\(angle))"
            }
        case .scale(let sx, let sy):
            "scale(\(sx) \(sy))"
        case .matrix(let a, let b, let c, let d, let e, let f):
            "matrix(\(a) \(b) \(c) \(d) \(e) \(f))"
        case .skewX(let angle):
            "skewX(\(angle))"
        case .skewY(let angle):
            "skewY(\(angle))"
        }
    }

    public func asAffineTransform() -> AffineTransform {
        switch self {
        case .translate(let tx, let ty):
            return AffineTransform(translation: Vector2D(tx, ty))
            
        case .scale(let sx, let sy):
            return AffineTransform(scale: Vector2D(sx, sy))
            
        case .rotate(let angle, let cx, let cy):
            let angleRad = angle * .pi / 180.0 // Convert degrees to radians
            
            if let cx = cx, let cy = cy {
                // Rotate around specific center: translate(-cx,-cy) * rotate * translate(cx,cy)
                let t1 = AffineTransform(translation: Vector2D(-cx, -cy))
                let r = AffineTransform(angle: angleRad)
                let t2 = AffineTransform(translation: Vector2D(cx, cy))
                return t2.concatenating(r.concatenating(t1))
            } else {
                // Rotate around origin
                return AffineTransform(angle: angleRad)
            }
            
        case .skewX(let angle):
            let angleRad = angle * .pi / 180.0
            let tanA = tan(angleRad)
            return AffineTransform(a: 1, b: 0, c: tanA, d: 1, tx: 0, ty: 0)
            
        case .skewY(let angle):
            let angleRad = angle * .pi / 180.0
            let tanA = tan(angleRad)
            return AffineTransform(a: 1, b: tanA, c: 0, d: 1, tx: 0, ty: 0)
            
        case .matrix(let a, let b, let c, let d, let e, let f):
            return AffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
        }
    }
}

public struct SVGTransformList {
    var items: [SVGTransform] = []

    public init(_ items: [SVGTransform] = []) {
        self.items = items
    }
    /// Create a transform from a SVG transform string.
    ///
    public init(_ string: String) {
        guard !string.isEmpty else {
            self.items = []
            return
        }
       
        var scanner = StringScanner(string)
        var components: [SVGTransform] = []
        
        while !scanner.atEnd {
            scanner.skipWhitespace()
            
            guard let type = scanner.scanIdentifier() else { break }
            
            scanner.skipWhitespace()
            guard scanner.accept("(") else {
                break
            }
            
            // Parse parameters
            let parameters = parseParameters(&scanner)
            
            guard scanner.accept(")") else { break }
            
            // Create transform based on function name and parameters
            if let transform = SVGTransform(type: type, parameters: parameters) {
                components.append(transform)
            }
            
            scanner.skipWhitespace()
        }
        
        self.items = components
    }
    
    public mutating func append(_ item: SVGTransform) {
        self.items.append(item)
    }

    public mutating func append(contentsOf items: [SVGTransform]) {
        self.items += items
    }

    public mutating func append(contentsOf list: SVGTransformList) {
        self.items += list.items
    }

    private func parseParameters(_ scanner: inout StringScanner) -> [Double] {
        var parameters: [Double] = []
        
        scanner.skipWhitespace()
        
        while !scanner.atEnd && scanner.peek() != ")" {
            if let value = scanner.scanDouble() {
                parameters.append(value)
            }
            else {
                break
            }
            
            scanner.skipWhitespace()
            scanner.accept(",")
            scanner.skipWhitespace()
        }
        
        return parameters
    }
    
    var rawValue: String {
        return items.map { $0.rawValue }.joined(separator: " ")
    }
    
    public func asAffineTransform() -> AffineTransform {
        var result = AffineTransform.identity
        
        for transform in self.items {
            result = result.concatenating(transform.asAffineTransform())
        }
        return result
    }

}
