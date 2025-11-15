//
//  ConnectorGlyph.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/11/2025.
//


/// Visual semantic definition of a connector.
///
/// Defines whether a connector should be drawn as thin stroked paths or fat filled polygons.
///
public final class ConnectorGlyph: Sendable {
    public enum Kind: Sendable {
        /// Thin connector drawn as stroked paths with separate arrowhead elements.
        case thin(Thin)
        
        /// Fat connector drawn as a single filled polygon with integrated arrowheads.
        case fat(Fat)
    }

    /// Style configuration for thin (stroke-based) connectors.
    ///
    /// Defines the visual properties for connectors drawn as stroked paths with separate arrowhead elements.
    /// Supports different arrowhead types at both ends and various line drawing styles.
    ///
    public struct Thin: Sendable {
        /// The arrowhead type at the target endpoint.
        public let headType: ThinArrowheadType
        
        /// The arrowhead type at the origin endpoint.
        public let tailType: ThinArrowheadType
        
        public init(headType: ThinArrowheadType = .stick,
                    tailType: ThinArrowheadType = .none) {
            self.headType = headType
            self.tailType = tailType
        }
    }

    /// Style configuration for fat (filled polygon) connectors.
    ///
    /// Defines the visual properties for connectors drawn as single filled polygon shapes
    /// with integrated arrowheads. The entire connector including arrowheads is rendered
    /// as one continuous filled path.
    ///
    public struct Fat: Sendable {
        /// The arrowhead type at the target endpoint.
        public let headType: FatArrowheadType
        
        /// The arrowhead type at the origin endpoint.
        public let tailType: FatArrowheadType
        
        /// The width of the connector body in points.
        public let width: Double
        
        /// How line segments are joined at corners in the polygon.
        public let joinType: JoinType
        
        public init(headType: FatArrowheadType = .regular,
                    tailType: FatArrowheadType = .none,
                    width: Double = 7.0,
                    joinType: JoinType = .miter) {
            self.headType = headType
            self.tailType = tailType
            self.width = width
            self.joinType = joinType
        }
    }

    /// Name of the glyph.
    ///
    /// Used to lookup glyph in ``Notation``.
    ///
    public let name: String
    
    public let kind: Kind
    /// The size of the arrowhead at the target endpoint in points.
    public let headSize: Double
    
    /// The size of the arrowhead at the origin endpoint in points.
    public let tailSize: Double
    
    /// The line drawing style for the connector body.
    public let lineType: LineType

    // TODO: Dash pattern
    
    public init(name: String,
                kind: Kind,
                headSize: Double = 10.0,
                tailSize: Double? = nil,
                lineType: LineType = .straight)
    {
        self.name = name
        self.kind = kind
        self.headSize = headSize
        self.tailSize = tailSize ?? headSize
        self.lineType = lineType
    }
    
    public static let defaultThin = ConnectorGlyph(name: "default_thin",
                                                   kind: .thin(ConnectorGlyph.Thin()))
    public static let defaultFat = ConnectorGlyph(name: "default_fat",
                                                  kind: .fat(ConnectorGlyph.Fat()))

}

