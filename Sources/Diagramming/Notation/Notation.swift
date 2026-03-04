//
//  Notation.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 15/11/2025.
//

import PoieticCore

/// Collection of pictograms and connector glyphs.
///
/// The notation defines a domain specific visual language.
///
/// - SeeAlso: ``NotationRules``
///
public final class Notation: Component {
#if false
    /// Name of the notation.
    ///
    /// Typically the same as the metamodel name.
    ///
    public let name: String
    public let variantName: String? = nil
#endif
    public static let ReplacementPictogramName = "__REPLACEMENT"

    /// Pictogram used when the default connector glyph was not found.
    ///
    /// Replacement pictogram is a circle with radius 10.0.
    ///
    public static let ReplacementPictogram = Pictogram(ReplacementPictogramName, circleWithRadius: 10.0)
    public static let ReplacementConnectorGlyphName = "__REPLACEMENT"
    // TODO: Add simple error pictogram

    /// Connector glyph used when the default connector glyph was not found.
    ///
    /// Replacement connector glyph is a thin connector with head as stick arrow: `--->`.
    ///
    public static let ReplacementConnectorGlyph = ConnectorGlyph(
        name: ReplacementConnectorGlyphName,
        kind: .thin(ConnectorGlyph.Thin(headType: .stick, tailType: .none)),
        headSize: 10.0,
        tailSize: 0.0,
        lineType: .straight
    )

    internal let _pictogramLookup: [String:Pictogram]
    public let pictograms: [Pictogram]
    public let defaultPictogram: Pictogram
    
    internal let _connectorGlyphLookup: [String:ConnectorGlyph]
    public let connectorGlyphs: [ConnectorGlyph]
    public let defaultConnectorGlyph: ConnectorGlyph
    
    
    /// Very basic notation with a circle for any kind of block and a stick arrow for any kind
    /// of connector.
    ///
    /// - SeeAlso: ``ReplacementPictogram``, ``ReplacementConnectorGlyph``
    ///
    nonisolated(unsafe) public static let DefaultNotation = Notation(
        pictograms: [Notation.ReplacementPictogram],
        defaultPictogram: Notation.ReplacementPictogram,
        connectorGlyphs: [Notation.ReplacementConnectorGlyph],
        defaultConnectorGlyph:Notation.ReplacementConnectorGlyph
    )
    
    public init(pictograms: [Pictogram] = [],
                defaultPictogram: Pictogram,
                connectorGlyphs: [ConnectorGlyph] = [],
                defaultConnectorGlyph: ConnectorGlyph)
    {
        self._pictogramLookup = Dictionary(uniqueKeysWithValues: pictograms.map { ($0.name, $0) })
        self._connectorGlyphLookup = Dictionary(uniqueKeysWithValues: connectorGlyphs.map { ($0.name, $0) })

        self.pictograms = pictograms
        self.defaultPictogram = defaultPictogram
        
        self.connectorGlyphs = connectorGlyphs
        self.defaultConnectorGlyph = defaultConnectorGlyph
    }

    public init(pictograms: [Pictogram] = [],
                defaultPictogramName: String,
                connectorGlyphs: [ConnectorGlyph] = [],
                defaultConnectorGlyphName: String)
    {
        self._pictogramLookup = Dictionary(uniqueKeysWithValues: pictograms.map { ($0.name, $0) })
        self._connectorGlyphLookup = Dictionary(uniqueKeysWithValues: connectorGlyphs.map { ($0.name, $0) })

        self.pictograms = pictograms
        self.defaultPictogram = _pictogramLookup[defaultPictogramName]
                                ?? pictograms.first
                                ?? Notation.ReplacementPictogram

        self.connectorGlyphs = connectorGlyphs
        self.defaultConnectorGlyph = _connectorGlyphLookup[defaultConnectorGlyphName]
                                    ?? connectorGlyphs.first
                                    ?? Notation.ReplacementConnectorGlyph
    }

    /// Get a pictogram by name. If there is no pictogram with given name, then returns default
    /// pictogram.
    ///
    /// - SeeAlso: ``defaultPictogram``, ``NotationRules/pictogramName(for:)``
    ///
    public func pictogram(_ name: String) -> Pictogram {
        _pictogramLookup[name] ?? defaultPictogram
    }

    /// Get connector style by name. If there is no connector style with given name, returns
    /// default connector style.
    ///
    /// - SeeAlso: ``defaultConnectorGlyph``, ``NotationRules/connectorGlyphName(for:)``
    ///
    public func connectorGlyph(_ name: String) -> ConnectorGlyph {
        _connectorGlyphLookup[name] ?? defaultConnectorGlyph
    }
}

/// Rules for mapping between object types and notation elements.
///
/// - SeeAlso: ``Notation``, ``Pictogram``, ``ConnectorGlyph``
///
public struct NotationRules: Component {
    // TODO: Extend with Trait rules when needed

    /// Mapping between object type name and pictogram name.
    ///
    /// - SeeAlso: ``Notation``, ``Pictogram``
    ///
    public let typeToPictogram: [String:String]

    /// Mapping between object type name and connector glyph name.
    ///
    /// - SeeAlso: ``Notation``, ``ConnectorGlyph``
    ///
    public let typeToConnectorGlyph: [String:String]
    
    public init(typeToPictogram: [String : String] = [:],
                typeToConnectorGlyph: [String : String] = [:])
    {
        self.typeToPictogram = typeToPictogram
        self.typeToConnectorGlyph = typeToConnectorGlyph
    }

    /// Look-up a pictogram name for given object type. If there is no specific name for the object
    /// type, then use the object type name itself.
    ///
    /// - SeeAlso: ``Notation/pictogram(_:)``, ``Notation/defaultPictogram``
    ///
    public func pictogramName(for objectType: ObjectType) -> String {
        return typeToPictogram[objectType.name] ?? objectType.name
    }
    
    /// Look-up a connector glyph name for given object type. If there is no specific name for the
    /// object type, then use the object type name itself.
    ///
    /// - SeeAlso: ``Notation/connectorGlyph(_:)``, ``Notation/defaultConnectorGlyph``
    ///
    public func connectorGlyphName(for objectType: ObjectType) -> String {
        return typeToConnectorGlyph[objectType.name] ?? objectType.name
    }

}
