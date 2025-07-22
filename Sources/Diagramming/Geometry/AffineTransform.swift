//
//  AffineTransform.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 16/06/2025.
//

/// A 2D affine transformation represented as a 3x2 matrix
/// 
/// Matrix representation:
///
/// ```
/// [a  c  tx]   [x]   [a*x + c*y + tx]
/// [b  d  ty] × [y] = [b*x + d*y + ty]
/// [0  0  1 ]   [1]   [1             ]
/// ```
///
public struct AffineTransform: Equatable, Sendable {
    
    public let a: Double
    public let b: Double
    public let c: Double
    public let d: Double
    public let tx: Double
    public let ty: Double
    
    /// The identity transform
    ///
    public static let identity = AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
    
    /// Creates an identity transform
    ///
    public init() {
        self = .identity
    }
    
    /// Creates a transform with the specified matrix components
    ///
    public init(a: Double, b: Double, c: Double, d: Double, tx: Double, ty: Double) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.tx = tx
        self.ty = ty
    }
    
    /// Creates a translation transform
    ///
    public init(translation: Vector2D) {
        self.a = 1
        self.b = 0
        self.c = 0
        self.d = 1
        self.tx = translation.x
        self.ty = translation.y
    }
    
    /// Creates a scaling transform
    ///
    public init(scale: Vector2D) {
        self.a = scale.x
        self.b = 0
        self.c = 0
        self.d = scale.y
        self.tx = 0
        self.ty = 0
    }
    
    /// Creates a rotation transform
    ///
    /// - Parameter angle: Rotation angle in radians
    public init(angle: Double) {
        let cosA = _cos(angle)
        let sinA = _sin(angle)
        self.a = cosA
        self.b = sinA
        self.c = -sinA
        self.d = cosA
        self.tx = 0
        self.ty = 0
    }
    
    // MARK: - Matrix Operations
    
    /// Returns a transform by concatenating this transform with another transform
    /// The result applies `other` first, then `self` (following CGAffineTransform convention)
    /// Mathematically: result = self × other
    public func concatenating(_ other: AffineTransform) -> AffineTransform {
        return AffineTransform(
            a: a * other.a + c * other.b,
            b: b * other.a + d * other.b,
            c: a * other.c + c * other.d,
            d: b * other.c + d * other.d,
            tx: a * other.tx + c * other.ty + tx,
            ty: b * other.tx + d * other.ty + ty
        )
    }
    
    /// Returns the inverse transform, or nil if the transform is not invertible
    /// Uses simple 2x2 matrix inversion algorithm
    ///
    public func inverted() -> AffineTransform? {
        let determinant = a * d - b * c
        
        guard !determinant.isZero else { return nil }
        
        let invDet = 1.0 / determinant
        
        return AffineTransform(
            a: d * invDet,
            b: -b * invDet,
            c: -c * invDet,
            d: a * invDet,
            tx: (c * ty - d * tx) * invDet,
            ty: (b * tx - a * ty) * invDet
        )
    }
    
    /// Applies the transform to a point
    ///
    public func apply(to point: Vector2D) -> Vector2D {
        return Vector2D(
            a * point.x + c * point.y + tx,
            b * point.x + d * point.y + ty
        )
    }
    
    /// Translation component as a vector
    ///
    public var origin: Vector2D { Vector2D(tx, ty) }
    
    /// Scale factors extracted from the matrix
    ///
    /// - Note: This is a simple algorithm. For complex transforms with skew,
    ///   consider using "Polar Decomposition" or "QR Decomposition" for more accurate results
    public var scale: Vector2D {
        get {
            let scaleX = (a * a + b * b).squareRoot()
            let scaleY = (c * c + d * d).squareRoot()
            return Vector2D(scaleX, scaleY)
        }
    }
    
    // MARK: - Transform Creation
    
    /// Returns a new transform that applies a translation after this transform
    /// 
    public func translated(_ offset: Vector2D) -> AffineTransform {
        return concatenating(AffineTransform(translation: offset))
    }
    
    /// Returns a new transform that applies a scale after this transform
    ///
    public func scaled(_ scale: Vector2D) -> AffineTransform {
        return concatenating(AffineTransform(scale: scale))
    }
    
    /// Returns a new transform that applies a rotation after this transform
    ///
    /// - Parameter angle: Rotation angle in radians
    ///
    public func rotated(_ angle: Double) -> AffineTransform {
        return concatenating(AffineTransform(angle: angle))
    }
    
    @inlinable
    public static func *(transform: AffineTransform, vector: Vector2D) -> Vector2D {
        return transform.apply(to: vector)
    }
}

