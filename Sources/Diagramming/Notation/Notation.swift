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
public final class Notation: Component, Sendable {
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
   
    /// Mapping between object type name and connector glyph name.
    ///
    /// - SeeAlso: ``Notation``, ``ConnectorGlyph``
    ///
    public let connectorRules: [ConnectorGlyphRule]
    public let pictogramRules: [PictogramRule]

    
    /// Very basic notation with a circle for any kind of block and a stick arrow for any kind
    /// of connector.
    ///
    /// - SeeAlso: ``ReplacementPictogram``, ``ReplacementConnectorGlyph``
    ///
    public static let DefaultNotation = Notation(
        pictograms: [Notation.ReplacementPictogram],
        connectorGlyphs: [Notation.ReplacementConnectorGlyph]
    )
    
    public init(pictograms: [Pictogram] = [],
                defaultPictogramName: String? = nil,
                connectorGlyphs: [ConnectorGlyph] = [],
                defaultConnectorGlyphName: String? = nil,
                pictogramRules: [PictogramRule] = [],
                connectorRules: [ConnectorGlyphRule] = [])
    {
        self._pictogramLookup = Dictionary(uniqueKeysWithValues: pictograms.map { ($0.name, $0) })
        self._connectorGlyphLookup = Dictionary(uniqueKeysWithValues: connectorGlyphs.map { ($0.name, $0) })

        self.pictograms = pictograms
        let pictogram: Pictogram?
        if let defaultPictogramName {
            pictogram = _pictogramLookup[defaultPictogramName]
        }
        else {
            pictogram = nil
        }
        
        self.defaultPictogram = pictogram
                                ?? pictograms.first
                                ?? Notation.ReplacementPictogram

        self.connectorGlyphs = connectorGlyphs
        let glyph: ConnectorGlyph?
        if let defaultConnectorGlyphName {
            glyph = _connectorGlyphLookup[defaultConnectorGlyphName]
        }
        else {
            glyph = nil
        }
        self.defaultConnectorGlyph = glyph
                                    ?? connectorGlyphs.first
                                    ?? Notation.ReplacementConnectorGlyph

        self.pictogramRules = pictogramRules
        self.connectorRules = connectorRules
    }

    /// Get a pictogram by name. If there is no pictogram with given name, then returns default
    /// pictogram.
    ///
    /// - SeeAlso: ``defaultPictogram``, ``NotationRules/pictogramName(for:)``
    ///
    public func pictogram(_ name: String) -> Pictogram {
        _pictogramLookup[name] ?? defaultPictogram
    }

    public func pictogram(for object: ObjectSnapshot, in plane: DesignPlane) -> Pictogram {
        let first = pictogramRules.first {
            $0.match(object, in: plane)
        }
        let name = first?.pictogramName ?? object.type.name
        return pictogram(name)
    }

    /// Get connector style by name. If there is no connector style with given name, returns
    /// default connector style.
    ///
    /// - SeeAlso: ``defaultConnectorGlyph``, ``NotationRules/connectorGlyphName(for:)``
    ///
    public func connectorGlyph(_ name: String) -> ConnectorGlyph {
        _connectorGlyphLookup[name] ?? defaultConnectorGlyph
    }

    public func connectorGlyph(for object: ObjectSnapshot, origin: ObjectSnapshot, target: ObjectSnapshot, in plane: DesignPlane) -> ConnectorGlyph {
        let first = connectorRules.first {
            $0.match(object.type, origin: origin, target: target, in: plane)
        }
        let name = first?.glyphName ?? object.type.name
        return connectorGlyph(name)
    }
}
