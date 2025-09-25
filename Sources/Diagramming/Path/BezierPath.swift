//
//  BezierPath.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/06/2025.
//

public struct BezierPath: Sendable, Codable {
    public var elements: [PathElement]
    public private(set) var currentPoint: Vector2D?
    private var startPoint: Vector2D?
    
    public enum PathElement: CustomStringConvertible, Sendable, Codable {
        case moveTo(Vector2D)
        case lineTo(Vector2D)
        case curveTo(end: Vector2D, control1: Vector2D, control2: Vector2D)
        // TODO: Swap the arguments
        case quadCurveTo(control: Vector2D, end: Vector2D)
        case closePath
        
        private enum CodingKeys: String, CodingKey {
            case command
            case parameters
        }
        
        public var commandCharacter: Character {
            switch self {
            case .moveTo: "M"
            case .lineTo: "L"
            case .curveTo: "C"
            case .quadCurveTo: "Q"
            case .closePath: "Z"
            }
        }
        
        public var parameters: [Double] {
            switch self {
            case .moveTo(let point): [point.x, point.y]
            case .lineTo(let point): [point.x, point.y]
            case .curveTo(let end, let control1, let control2): [end.x, end.y, control1.x, control1.y, control2.x, control2.y]
            case .quadCurveTo(let control, let end): [control.x, control.y, end.x, end.y]
            case .closePath: []
            }

        }
        
        public var description: String {
            switch self {
            case .moveTo(let point): "M\(point.x),\(point.y)"
            case .lineTo(let point): "L\(point.x),\(point.y)"
            case .curveTo(let end, let control1, let control2): "C\(end.x),\(end.y) \(control1.x),\(control1.y) \(control2.x),\(control2.y)"
            case .quadCurveTo(let control, let end): "Q\(control.x),\(control.y),\(end.x),\(end.y)"
            case .closePath: "Z"
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let command = try container.decode(String.self, forKey: .command)
            let params = try container.decodeIfPresent([Double].self, forKey: .parameters) ?? []

            switch command {
            case "M":
                guard params.count == 2 else {
                    throw DecodingError.typeMismatch(
                        [Double].self,
                        DecodingError.Context(codingPath: decoder.codingPath,
                                              debugDescription: "Move-to expects exactly 2 parameters")
                    )
                }
                self = .moveTo(Vector2D(params[0], params[1]))
            case "L":
                guard params.count == 2 else {
                    throw DecodingError.typeMismatch(
                        [Double].self,
                        DecodingError.Context(codingPath: decoder.codingPath,
                                              debugDescription: "Line-to expects exactly 2 parameters")
                    )
                }
                self = .lineTo(Vector2D(params[0], params[1]))
            case "C":
                guard params.count == 6 else {
                    throw DecodingError.typeMismatch(
                        [Double].self,
                        DecodingError.Context(codingPath: decoder.codingPath,
                                              debugDescription: "Curve-to expects exactly 6 parameters")
                    )
                }
                self = .curveTo(end: Vector2D(params[0], params[1]),
                                control1: Vector2D(params[2], params[3]),
                                control2: Vector2D(params[4], params[5]))
            case "Q":
                guard params.count == 4 else {
                    throw DecodingError.typeMismatch(
                        [Double].self,
                        DecodingError.Context(codingPath: decoder.codingPath,
                                              debugDescription: "Quad-curve expects exactly 4 parameters")
                    )
                }
                self = .quadCurveTo(control: Vector2D(params[0], params[1]),
                                    end: Vector2D(params[2], params[3]))
            case "Z":
                guard params.count == 0 else {
                    throw DecodingError.typeMismatch(
                        [Double].self,
                        DecodingError.Context(codingPath: decoder.codingPath,
                                              debugDescription: "Close path expects no parameters")
                    )
                }
                self = .closePath
            default:
                throw DecodingError.typeMismatch(
                    String.self,
                    DecodingError.Context(codingPath: decoder.codingPath,
                                          debugDescription: "Invalid path command '\(command)'")
                )
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(String(self.commandCharacter), forKey: .command)
            if !self.parameters.isEmpty {
                try container.encode(self.parameters, forKey: .parameters)
            }
        }

        
    }
    
    /// Create an empty path.
    public init(_ elements: [PathElement] = []) {
        self.elements = elements
    }
        
    /// Create a line between two points
    public init(line start: Vector2D, to end: Vector2D) {
        self.init()
        move(to: start)
        addLine(to: end)
    }
    
    /// Create a quadratic curve between two points with a control point
    public init(quadCurve start: Vector2D, to end: Vector2D, control: Vector2D) {
        self.init()
        move(to: start)
        addQuadCurve(to: end, control: control)
    }
    
    /// Create a circle
    public init(circle center: Vector2D, radius: Double) {
        self.init()
        addCircle(center: center, radius: radius)
    }
    
    public init(ellipse center: Vector2D, radiusX: Double, radiusY: Double) {
        self.init()
        addEllipse(center: center, radiusX: radiusX, radiusY: radiusY)
    }

    /// Create a rectangle
    public init(rect: Rect2D) {
        self.init()
        addRect(rect)
    }
    
    /// Create a path from a string.
    ///
    /// The string is a sequence of path operations followed by operation parameters.
    /// Operation is specified as a single character, parameters are comma separated numbers.
    ///
    /// Operations:
    ///
    /// - `M` – move to _x, y_. See ``move(to:)``.
    /// - `L` – line to _x, y_. See ``addLine(to:)``.
    /// - `Q` – quadratic curve with control point _cx, cy_ to endpoint _x, y_. See ``addQuadCurve(to:control:)``.
    /// - `C` – cubic curve with control point _x1, y1_, _x2, y2_ to endpoint _x, y_. See ``addCurve(to:control1:control2:)``.
    /// - `Z` – close path. See ``closeSubpath()``.
    ///
    /// Example: `M 10, 10 L 20, 20`
    ///
    public init?(string: String) {
        var scanner = StringScanner(string)
        guard let elements = scanner.scanBezierPathElements() else {
            return nil
        }
        self.elements = []
        self.addElements(elements)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let elements = try container.decode([PathElement].self)
        self.elements = []
        self.addElements(elements)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }

    public var isEmpty: Bool {
        return elements.isEmpty
    }
    
    /// A box that encapsulates the whole path.
    ///
    /// - Note: The bounding box is computed by tessellation of the path.
    ///
    public var boundingBox: Rect2D? {
        let points = tessellate()
        guard !points.isEmpty else { return nil }
        
        let minX = points.map { $0.x }.min()!
        let maxX = points.map { $0.x }.max()!
        let minY = points.map { $0.y }.min()!
        let maxY = points.map { $0.y }.max()!
        
        return Rect2D(
            origin: Vector2D(minX, minY),
            size: Vector2D(maxX - minX, maxY - minY)
        )
    }
    
    /// Check if path is closed – ends where it started.
    ///
    public var isClosed: Bool {
        return elements.contains { element in
            if case .closePath = element {
                return true
            }
            return false
        }
    }
    
    /// Check if path contains only straight lines (no curves).
    ///
    /// A polygon path can only contain moveTo, lineTo, and closePath elements.
    /// Any curveTo or quadCurveTo elements make it a non-polygon path.
    ///
    /// - Returns: true if the path contains only straight line segments, false if it contains any curves
    ///
    /// - SeeAlso: ``asStrictPolygon()``
    ///
    public func isPolygon() -> Bool {
        return elements.allSatisfy { element in
            switch element {
            case .moveTo, .lineTo, .closePath:
                return true
            case .curveTo, .quadCurveTo:
                return false
            }
        }
    }
    
    /// Extract polygon points from path that contains only lines.
    ///
    /// Returns polygon vertices if the path contains only moveTo, lineTo, and closePath elements.
    /// MoveTo interruptions are treated as lineTo connections (continuous polygon).
    /// Returns nil if path contains any curves - use tessellate() to approximate curves.
    ///
    /// - Returns: Array of polygon vertices, or nil if path contains curves
    ///
    /// - SeeAlso: ``isPolygon()``
    ///
    public func asStrictPolygon() -> [Vector2D]? {
        // First check if path is linear-only
        guard isPolygon() else {
            return nil
        }
        
        guard !elements.isEmpty else {
            return []
        }
        
        var points: [Vector2D] = []
        
        for element in elements {
            switch element {
            case .moveTo(let point):
                // First moveTo establishes starting point, subsequent ones are treated as lineTo
                if points.isEmpty {
                    points.append(point)
                } else {
                    // Treat moveTo interruption as lineTo (continuous polygon)
                    points.append(point)
                }
                
            case .lineTo(let point):
                points.append(point)
                
            case .closePath:
                // closePath is implicit in polygon - don't add duplicate point
                break
                
            case .curveTo, .quadCurveTo:
                // This should not happen due to isPolygon() check above, but be safe
                return nil
            }
        }
        
        return points
    }
    
    public func asString() -> String {
        elements.map { $0.description }.joined(separator: " ")
    }
    
    // MARK: - Path Construction
    
    /// Move to a point without drawing
    public mutating func move(to point: Vector2D) {
        elements.append(.moveTo(point))
        currentPoint = point
        startPoint = point
    }
    
    /// Add a line to the specified point
    public mutating func addLine(to point: Vector2D) {
        if currentPoint == nil {
            move(to: Vector2D(0, 0))
        }
        elements.append(.lineTo(point))
        currentPoint = point
    }
    
    /// Add lines between consecutive points
    public mutating func addLines(between points: [Vector2D]) {
        guard !points.isEmpty else { return }
        
        if currentPoint == nil {
            move(to: points[0])
            for point in points.dropFirst() {
                addLine(to: point)
            }
        } else {
            for point in points {
                addLine(to: point)
            }
        }
    }
    
    /// Add a rectangle
    public mutating func addRect(_ rect: Rect2D) {
        move(to: rect.bottomLeft)
        addLine(to: rect.bottomRight)
        addLine(to: rect.topRight)
        addLine(to: rect.topLeft)
        closeSubpath()
    }
    
    /// Add a quadratic Bezier curve
    public mutating func addQuadCurve(to endPoint: Vector2D, control: Vector2D) {
        if currentPoint == nil {
            move(to: Vector2D(0, 0))
        }
        elements.append(.quadCurveTo(control: control, end: endPoint))
        currentPoint = endPoint
    }
    
    /// Add a cubic Bezier curve (converted from quadratic)
    public mutating func addCurve(to endPoint: Vector2D, control1: Vector2D, control2: Vector2D) {
        if currentPoint == nil {
            move(to: Vector2D(0, 0))
        }
        elements.append(.curveTo(end: endPoint, control1: control1, control2: control2))
        currentPoint = endPoint
    }
    
    /// Add a circle.
    ///
    /// The circle is approximated using cubic bezier curves.
    ///
    public mutating func addCircle(center: Vector2D, radius: Double) {
        // https://spencermortensen.com/articles/bezier-BALL/
        // P0=(0,a), P1=(b,c), P2=(c,b), P3=(a,0)
        let a = 1.00005519
        let b = 0.55342686
        let p1 = Vector2D(b, 0) * radius
        let p2 = Vector2D(0, b) * radius
        
        let bottom = center + (Vector2D(0, a) * radius)
        let right = center + (Vector2D(a, 0) * radius)
        let top = center + (Vector2D(0, -a) * radius)
        let left = center + (Vector2D(-a, 0) * radius)
        move(to: bottom)
        addCurve(to: right, control1: bottom + p1, control2: right + p2)
        addCurve(to: top, control1: right - p2, control2: top + p1)
        addCurve(to: left, control1: top - p1, control2: left - p2)
        addCurve(to: bottom, control1: left + p2, control2: bottom - p1)
        closeSubpath()
    }
    
    /// Add an ellipse.
    ///
    /// The ellispe is approximated using cubic bezier curves.
    ///
    public mutating func addEllipse(center: Vector2D, radiusX: Double, radiusY: Double) {
        let a = 1.00005519
        let b = 0.55342686
        let p1 = Vector2D(b, 0) * radiusX
        let p2 = Vector2D(0, b) * radiusY
        
        let bottom = center + (Vector2D(0, a) * radiusY)
        let right = center + (Vector2D(a, 0) * radiusX)
        let top = center + (Vector2D(0, -a) * radiusY)
        let left = center + (Vector2D(-a, 0) * radiusX)
        move(to: bottom)
        addCurve(to: right, control1: bottom + p1, control2: right + p2)
        addCurve(to: top, control1: right - p2, control2: top + p1)
        addCurve(to: left, control1: top - p1, control2: left - p2)
        addCurve(to: bottom, control1: left + p2, control2: bottom - p1)
        closeSubpath()
    }
    
    
    public mutating func addElements(_ elements: [PathElement]) {
        for element in elements {
            switch element {
            case .moveTo(let point):
                move(to: point)
            case .lineTo(let point):
                addLine(to: point)
            case .curveTo(let end, let control1, let control2):
                addCurve(to: end, control1: control1, control2: control2)
            case .quadCurveTo(let control, let end):
                addQuadCurve(to: end, control: control)
            case .closePath:
                closeSubpath()
            }
        }
    }

    /// Add another bezier path to this one
    public mutating func addPath(_ other: BezierPath) {
        self.addElements(other.elements)
    }
    
    public func addingPath(_ other: BezierPath) -> BezierPath {
        var result = self
        result.addPath(other)
        return result
    }

    public static func +(left: BezierPath, right: BezierPath) -> BezierPath {
        return left.addingPath(right)
    }

    public static func +=(left: inout BezierPath, right: BezierPath) {
        left.addPath(right)
    }

    /// Close the current subpath
    public mutating func closeSubpath() {
        elements.append(.closePath)
        if let start = startPoint {
            currentPoint = start
        }
    }
    
    // MARK: - Path Analysis
    
    /// Split the path into individual subpaths.
    ///
    /// A subpath is a continuous sequence of drawing operations that ends with either
    /// a closePath command or the end of the path. Multiple moveTo commands within
    /// the same subpath create disconnected segments but remain part of the same subpath.
    ///
    /// This follows the standard SVG/PostScript behavior where only closePath
    /// explicitly ends a subpath.
    ///
    /// - Returns: Array of BezierPath objects, each representing one subpath
    ///
    /// ## Example
    /// ```swift
    /// var path = BezierPath()
    /// path.move(to: Vector2D(0, 0))
    /// path.addLine(to: Vector2D(5, 5))
    /// path.closeSubpath()                    // End first subpath
    /// path.move(to: Vector2D(10, 10))
    /// path.addLine(to: Vector2D(15, 15))     // Second subpath (unclosed)
    ///
    /// let subpaths = path.subpaths()         // Returns 2 subpaths
    /// ```
    public func subpaths() -> [BezierPath] {
        var result: [BezierPath] = []
        var current = BezierPath()
        var hasElements = false
        
        for element in elements {
            switch element {
            case .closePath:
                current.elements.append(element)
                if hasElements {
                    result.append(current)
                    current = BezierPath() // Start fresh subpath
                    hasElements = false
                }
                
            default:
                // All other elements (moveTo, lineTo, curveTo, quadCurveTo) 
                // get added to current subpath
                current.elements.append(element)
                hasElements = true
            }
        }
        
        // Add final subpath if it has elements (wasn't closed)
        if hasElements {
            result.append(current)
        }
        
        return result
    }
    
    
    /// Get a copy of the bezier path transformed using the given affine transform.
    ///
    public func transform(_ transform: AffineTransform) -> BezierPath {
        var result = BezierPath()
        
        for element in self.elements {
            switch element {
            case .moveTo(let point):
                result.move(to: transform.apply(to: point))
                
            case .lineTo(let point):
                result.addLine(to: transform.apply(to: point))
                
            case .curveTo(let end, let control1, let control2):
                result.addCurve(to: transform.apply(to: end),
                                control1: transform.apply(to: control1),
                                control2: transform.apply(to: control2))
                
            case .quadCurveTo(let control, let end):
                result.addQuadCurve(to: transform.apply(to: end),
                                    control: transform.apply(to: control))
                
            case .closePath:
                result.closeSubpath()
            }
        }
        
        return result
    }
    
}

extension StringScanner {
    public mutating func scanBezierPathElements() -> [BezierPath.PathElement]? {
        let savedIndex = self.currentIndex
        var elements: [BezierPath.PathElement] = []
        
        while !atEnd {
            skipWhitespace()
            
            guard let command = scanCharacter() else { break }
            
            skipWhitespace()
            
            // Parse elements for this command
            switch command {
            case "M": // moveTo
                guard let point = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                elements.append(.moveTo(point))
                
            case "L": // lineTo
                guard let point = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                elements.append(.lineTo(point))
                
            case "Q": // quadraticCurveTo
                guard let controlPoint = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipWhitespace()
                accept(",")
                skipWhitespace()
                guard let endPoint = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                elements.append(.quadCurveTo(control: controlPoint, end: endPoint))
                
            case "C": // curveTo (cubic bezier)
                guard let control1Point = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipWhitespace()
                accept(",")
                skipWhitespace()
                guard let control2Point = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                skipWhitespace()
                accept(",")
                skipWhitespace()
                guard let endPoint = scanPoint() else {
                    self.currentIndex = savedIndex
                    return nil
                }
                elements.append(.curveTo(end: endPoint, control1: control1Point, control2: control2Point))

            case "Z": // closePath
                elements.append(.closePath)
                
            default:
                self.currentIndex = savedIndex
                return nil
            }
            
            skipWhitespace()
        }
        
        return elements
    }

}
