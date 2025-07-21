//
//  BezierPath.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 12/06/2025.
//

public struct BezierPath {
    public var elements: [PathElement]
    public private(set) var currentPoint: Vector2D?
    private var startPoint: Vector2D?

    public enum PathElement: CustomStringConvertible {
        case moveTo(Vector2D)
        case lineTo(Vector2D)
        case curveTo(end: Vector2D, control1: Vector2D, control2: Vector2D)
        // TODO: Swap the arguments
        case quadCurveTo(control: Vector2D, end: Vector2D)
        case closePath
        
        public var commandCharacter: Character {
            switch self {
            case .moveTo: "M"
            case .lineTo: "L"
            case .curveTo: "C"
            case .quadCurveTo: "Q"
            case .closePath: "Z"
            }
        }
        public var description: String {
            switch self {
            case .moveTo(let point): "M\(point.x),\(point.y)"
            case .lineTo(let point): "L\(point.x),\(point.y)"
            case .curveTo(let end, let control1, let control2): "Q\(end.x),\(end.y) \(control1.x),\(control1.y) \(control2.x),\(control2.y)"
            case .quadCurveTo(let control, let end): "Q\(control.x),\(control.y),\(end.x),\(end.y)"
            case .closePath: "Z"
            }
        }
    }

    /// Create an empty path.
    public init() {
        self.elements = []
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
    
    /// Create a rectangle
    public init(rect: Rect2D) {
        self.init()
        addRect(rect)
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

    /// Add another bezier path to this one
    public mutating func addPath(_ other: BezierPath) {
        for element in other.elements {
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
    
    /// Close the current subpath
    public mutating func closeSubpath() {
        elements.append(.closePath)
        if let start = startPoint {
            currentPoint = start
        }
    }
    
    // MARK: - Tessellation
    
    /// Tessellate the path into line segments with adaptive point density
    public func tessellate(maxStages: Int = 5, toleranceDegrees: Double = 1.0) -> [Vector2D] {
        var points: [Vector2D] = []
        var currentPos: Vector2D?
        var subpathStart: Vector2D?
        
        for element in elements {
            switch element {
            case .moveTo(let point):
                currentPos = point
                subpathStart = point
                points.append(point)
                
            case .lineTo(let point):
                if currentPos != nil {
                    points.append(point)
                    currentPos = point
                }
                
            case .curveTo(_, _, _):
                // FIXME: Implement this
                fatalError("Tessellation of curve-to not implemented")
                
            case .quadCurveTo(let control, let end):
                if let current = currentPos {
                    let curvePoints = tessellateQuadraticCurve(
                        start: current,
                        control: control,
                        end: end,
                        maxStages: maxStages,
                        toleranceDegrees: toleranceDegrees
                    )
                    // Skip the first point as it's the current position
                    if curvePoints.count > 1 {
                        points.append(contentsOf: curvePoints.dropFirst())
                    }
                    currentPos = end
                }
                
            case .closePath:
                // Connect back to start if needed
                if let current = currentPos, let start = subpathStart {
                    if current.distance(to: start) > 1e-6 {
                        points.append(start)
                    }
                    currentPos = start
                }
            }
        }
        
        return points
    }
    
    // MARK: - Private Tessellation Implementation
    
    private func tessellateQuadraticCurve(start: Vector2D,
                                          control: Vector2D,
                                          end: Vector2D,
                                          maxStages: Int,
                                          toleranceDegrees: Double) -> [Vector2D] {
        
        var segments = [(start: Vector2D, control: Vector2D, end: Vector2D)]()
        segments.append((start, control, end))
        
        let toleranceRadians = toleranceDegrees * .pi / 180.0
        
        for _ in 0..<maxStages {
            var newSegments: [(start: Vector2D, control: Vector2D, end: Vector2D)] = []
            var needsSubdivision = false
            
            for segment in segments {
                if shouldSubdivideQuadratic(segment, toleranceRadians: toleranceRadians) {
                    let (left, right) = subdivideQuadraticCurve(segment)
                    newSegments.append(left)
                    newSegments.append(right)
                    needsSubdivision = true
                } else {
                    newSegments.append(segment)
                }
            }
            
            segments = newSegments
            if !needsSubdivision {
                break
            }
        }
        
        // Collect all points: start of first segment, then all end points
        var points = [start]
        for segment in segments {
            points.append(segment.end)
        }
        
        return points
    }
    
    private func shouldSubdivideQuadratic(
        _ segment: (start: Vector2D, control: Vector2D, end: Vector2D),
        toleranceRadians: Double
    ) -> Bool {
        // Calculate midpoint of curve
        let t = 0.5
        let curveMidpoint = evaluateQuadraticCurve(
            start: segment.start,
            control: segment.control,
            end: segment.end,
            t: t
        )
        
        // Calculate midpoint of line segment
        let lineMidpoint = segment.start.lerp(to: segment.end, t: 0.5)
        
        // Calculate distance
        let distance = curveMidpoint.distance(to: lineMidpoint)
        
        // Simple flatness test: if curve deviates from line by more than 0.5 units, subdivide
        return distance > 0.5
    }
    
    private func subdivideQuadraticCurve(
        _ segment: (start: Vector2D, control: Vector2D, end: Vector2D)
    ) -> (left: (start: Vector2D, control: Vector2D, end: Vector2D),
          right: (start: Vector2D, control: Vector2D, end: Vector2D)) {
        
        // De Casteljau's algorithm for quadratic subdivision at t=0.5
        let p0 = segment.start
        let p1 = segment.control
        let p2 = segment.end
        
        let q0 = p0.lerp(to: p1, t: 0.5)
        let q1 = p1.lerp(to: p2, t: 0.5)
        
        let r = q0.lerp(to: q1, t: 0.5)
        
        let left = (start: p0, control: q0, end: r)
        let right = (start: r, control: q1, end: p2)
        
        return (left, right)
    }
    
    private func evaluateQuadraticCurve(start: Vector2D,
                                        control: Vector2D,
                                        end: Vector2D,
                                        t: Double) -> Vector2D
    {
        let t2 = t * t
        let mt = 1.0 - t
        let mt2 = mt * mt
        
        return start * mt2 +
               control * (2.0 * mt * t) +
               end * t2
    }
    
    
    /// Get a copy of the bezier path transformed using the given affine transform.
    ///
    func transform(_ transform: AffineTransform) -> BezierPath {
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

    /// Convert bezier path to a collection of bezier curves as used by Godot game engine.
    ///
    /// Godot curve is specified by position, in-control point and out-control point where the
    /// control points are relative to the curve point position.
    ///
    /// Move-to path elements break the path into multiple curves.
    ///
    func godotCurves() -> [[GodotCurvePoint]] {
        fatalError("Not implemented")
    }
}

struct GodotCurvePoint {
    let position: Vector2D
    let inControl: Vector2D
    let outControl: Vector2D
}
