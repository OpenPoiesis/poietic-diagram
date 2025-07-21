//
//  StringScanner+SVG.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/07/2025.
//


extension StringScanner {
    /// Skip whitespace, optional comma, and whitespace again - common pattern in SVG parsing
    public mutating func skipSVGListSeparator() {
        skipWhitespace()
        accept(",")
        skipWhitespace()
    }
    
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
            self.skipSVGListSeparator()
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

        self.skipSVGListSeparator()

        guard let y = scanDouble() else {
            self.currentIndex = savedIndex
            return nil
        }
        return Vector2D(x, y)
    }
    
    public mutating func scanSVGPathComponents(dpi: Double=DefaultSVGLengthDPI) -> [SVGPath.Component]? {
        let savedIndex = self.currentIndex
        var components: [SVGPath.Component] = []
        
        while !atEnd {
            skipWhitespace()
            
            guard let command = peek() else { break }
            
            // Check if it's a valid command character
            guard "MmLlHhVvCcSsQqTtAaZz".contains(command) else {
                // Invalid command, restore and return failure
                self.currentIndex = savedIndex
                return nil
            }
            
            advance() // consume command character
            
            // Parse components for this command
            switch command {
            case "M": // moveTo
                guard let point = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.moveTo(x: point.x, y: point.y))
                
            case "m": // moveToRelative
                guard let point = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.moveToRelative(dx: point.x, dy: point.y))
                
            case "L": // lineTo
                guard let point = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.lineTo(x: point.x, y: point.y))
                
            case "l": // lineToRelative
                guard let point = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.lineToRelative(dx: point.x, dy: point.y))
                
            case "H": // horizontalLineTo
                skipWhitespace()
                guard let x = scanDouble() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.horizontalLineTo(x: x))
                
            case "h": // horizontalLineToRelative
                skipWhitespace()
                guard let dx = scanDouble() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.horizontalLineToRelative(dx: dx))
                
            case "V": // verticalLineTo
                skipWhitespace()
                guard let y = scanDouble() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.verticalLineTo(y: y))
                
            case "v": // verticalLineToRelative
                skipWhitespace()
                guard let dy = scanDouble() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.verticalLineToRelative(dy: dy))
                
            case "C": // curveTo
                guard let point1 = scanSVGPoint(dpi: dpi),
                      let point2 = scanSVGPoint(dpi: dpi),
                      let point3 = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.curveTo(x1: point1.x, y1: point1.y, x2: point2.x, y2: point2.y, x: point3.x, y: point3.y))
                
            case "c": // curveToRelative
                guard let point1 = scanSVGPoint(dpi: dpi),
                      let point2 = scanSVGPoint(dpi: dpi),
                      let point3 = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.curveToRelative(dx1: point1.x, dy1: point1.y, dx2: point2.x, dy2: point2.y, dx: point3.x, dy: point3.y))
                
            case "S": // smoothCurveTo
                guard let point1 = scanSVGPoint(dpi: dpi),
                      let point2 = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.smoothCurveTo(x2: point1.x, y2: point1.y, x: point2.x, y: point2.y))
                
            case "s": // smoothCurveToRelative
                guard let point1 = scanSVGPoint(dpi: dpi),
                      let point2 = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.smoothCurveToRelative(dx2: point1.x, dy2: point1.y, dx: point2.x, dy: point2.y))
                
            case "Q": // quadraticCurveTo
                guard let controlPoint = scanSVGPoint(dpi: dpi),
                      let endPoint = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.quadraticCurveTo(x1: controlPoint.x, y1: controlPoint.y, x: endPoint.x, y: endPoint.y))
                
            case "q": // quadraticCurveToRelative
                guard let controlPoint = scanSVGPoint(dpi: dpi),
                      let endPoint = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.quadraticCurveToRelative(dx1: controlPoint.x, dy1: controlPoint.y, dx: endPoint.x, dy: endPoint.y))
                
            case "T": // smoothQuadraticCurveTo
                guard let point = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.smoothQuadraticCurveTo(x: point.x, y: point.y))
                
            case "t": // smoothQuadraticCurveToRelative
                guard let point = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.smoothQuadraticCurveToRelative(dx: point.x, dy: point.y))
                
            case "A": // arcTo
                guard let radius = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipSVGListSeparator()
                guard let xAxisRotation = scanDouble() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipSVGListSeparator()
                guard let largeArcFlagInt = scanInteger() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipSVGListSeparator()
                guard let sweepFlagInt = scanInteger() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                guard let endPoint = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.arcTo(rx: radius.x, ry: radius.y, xAxisRotation: xAxisRotation, 
                                        largeArcFlag: largeArcFlagInt != 0, 
                                        sweepFlag: sweepFlagInt != 0, 
                                        x: endPoint.x, y: endPoint.y))
                
            case "a": // arcToRelative
                guard let radius = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipSVGListSeparator()
                guard let xAxisRotation = scanDouble() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipSVGListSeparator()
                guard let largeArcFlagInt = scanInteger() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipSVGListSeparator()
                guard let sweepFlagInt = scanInteger() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                guard let endPoint = scanSVGPoint(dpi: dpi) else {
                    self.currentIndex = savedIndex
                    return nil
                }
                components.append(.arcToRelative(rx: radius.x, ry: radius.y, xAxisRotation: xAxisRotation, 
                                                largeArcFlag: largeArcFlagInt != 0, 
                                                sweepFlag: sweepFlagInt != 0, 
                                                dx: endPoint.x, dy: endPoint.y))
                
            case "Z", "z": // closePath
                components.append(.closePath)
                
            default:
                // Should not reach here as we already checked valid commands
                self.currentIndex = savedIndex
                return nil
            }
            
            skipWhitespace()
        }
        
        return components
    }
}

