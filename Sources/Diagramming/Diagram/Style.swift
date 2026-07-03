//
//  Style.swift
//  Diagramming
//
//  Created by Stefan Urbanek on 19/05/2026.
//

import PoieticCore

/// Style how canvas node should be presented.
///
/// When determining concrete style, the presentation backend should consider style in the
/// following order:
///
/// 1. Find style by style class or use default style.
/// 2. Override colour of the element using adaptable colour, if provided.
/// 3. Apply style of modifiers.
///
public struct CanvasNodeStyle: Component {
    /// Style class of the diagram scene node.
    let `class`: StyleClass
    let modifiers: StyleModifierSet
    let adaptableColor: AdaptableColorKey?
}

// TODO: Probably remove, as it should be backend-specific
// public enum StyleProperty {
//    case strokeColor
//    case fillColor
//    case strokeWidth
//    case fontName
//    case fontSize
//    case fontWeight
//    case fontStyle
//}

/// - Note: This is different data type from node type, as this is an information about
///   presentation, not behaviour.
public struct StyleModifierSet: OptionSet, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    public static let selected      = StyleModifierSet(rawValue: 1 << 0)
    public static let hovered       = StyleModifierSet(rawValue: 1 << 1)
    /// Elements highlighted by search or other means. Different from `selected`.
    public static let highlighted   = StyleModifierSet(rawValue: 1 << 2)
    public static let disabled      = StyleModifierSet(rawValue: 1 << 3)
    public static let error         = StyleModifierSet(rawValue: 1 << 4)
    public static let warning       = StyleModifierSet(rawValue: 1 << 5)
    // public static let locked       = StyleModifierSet(rawValue: 1 << 6)

    // Interaction
    public static let allowed       = StyleModifierSet(rawValue: 1 << 7)
    public static let notAllowed    = StyleModifierSet(rawValue: 1 << 8)

    // Indicated Value
    public static let overflow      = StyleModifierSet(rawValue: 1 << 9)
    public static let underflow     = StyleModifierSet(rawValue: 1 << 10)
    public static let positive      = StyleModifierSet(rawValue: 1 << 11)
    public static let negative      = StyleModifierSet(rawValue: 1 << 12)

    public func asStrings() -> [String] {
        var result: [String] = []
        if self.contains(.selected) { result.append("selected") }
        if self.contains(.hovered) { result.append("hovered") }
        if self.contains(.highlighted) { result.append("highlighted") }
        if self.contains(.disabled) { result.append("disabled") }
        if self.contains(.error) { result.append("error") }
        if self.contains(.warning) { result.append("warning") }

        if self.contains(.overflow) { result.append("overflow") }
        if self.contains(.underflow) { result.append("underflow") }
        if self.contains(.negative) { result.append("negative") }
        if self.contains(.positive) { result.append("positive") }

        if self.contains(.allowed) { result.append("allowed") }
        if self.contains(.notAllowed) { result.append("not-allowed") }
        return result
    }
    
    public var description: String {
        return asStrings().joined(separator: " ")
    }
}


/// Role of the diagram element in the visual vocabulary.
public enum StyleClass: String, Sendable {
    // NOTE: If extending this list, make sure the cases do not conflict with AdaptableColorKey
    
    /// Color for strokes if not specified otherwise.
    case normal
    /// Color for labels and other text if not specified otherwise.
    case label
    case primaryLabel
    case secondaryLabel
    
    case canvas
    case grid
    
    case pictogram

    /// Thin wire connector.
    case thinConnector
    /// Fat outlined connector.
    case fatConnector
    
    /// Colour of selection mask fill.
    case selection
    
    /// Colour of interactive intent such as new object to be placed.
    case intentShadow
    
    /// Colour of mid-point or other handle.
    case handle
    
    /// Foreground colour of error indicator.
    case errorIndicator

    /// Colour of colour swatch border.
    case colorSwatch
    
    case valueLabel
    case valueIndicator
    case valueIndicatorLine

    public var stringValue: String { return self.rawValue }
}


public enum DiagramColorKey: String {
    // NOTE: If extending this list, make sure the cases do not conflict with AdaptableColorKey
    
    /// Color for strokes if not specified otherwise.
    case defaultStroke
    /// Color for labels and other text if not specified otherwise.
    case defaultText
    
    /// Canvas background colour.
    case background

    /// Canvas grid colour.
    case grid
    
    /// Color for pictogram stroke.
    case pictogram
    case pictogramMask

    /// Default colour for connector.
    case connector
    /// Default colour for fill of outlined connectors.
    case connectorFill
    
    /// Colour of selection mask fill.
    case selection
    /// Colour of selection mask outline.
    case selectionOutline
    
    /// Colour of interactive intent such as new object to be placed.
    case intentShadow
    
    /// Colour of object outline mask for interactive target that accepts interaction.
    case allowedTarget
    /// Colour of object outline mask for interactive target that does not accept an interaction.
    /// For example: invalid connection target;
    case notAllowedTarget
    
    /// Colour of mid-point or other handle.
    case handle
    
    /// Foreground colour of error indicator.
    case errorIndicator
    /// Background colour of error indicator.
    case errorIndicatorBackground

    /// Colour of value indicator line.
    case indicatorLine
    
    /// Colour of colour swatch border.
    case swatchBorder
    
    case valueIndicatorBorder
    case valueIndicatorBackground
    case valueIndicatorLine
    
    case valueDefault
    /// Colour of value indicator indicating negative value.
    case valueNegative
    /// Colour of value indicator indicating value overflow.
    case valueOverflow
    /// Colour of value indicator indicating value underflow.
    case valueUnderflow
    /// Colour of value indicator indicating that no value is present for given object.
    case valueEmpty
    
    public var stringValue: String { return self.rawValue }
}


/// Diagram layout geometry.
///
public struct DiagramLayoutStyle {
    public enum MetricKey: CaseIterable {
        // Sizes, paddings and magrins
        case primaryLabelPadding
        case secondaryLabelPadding
        case colorSwatchSize
        case valueIndicatorPadding
        case errorIndicatorPadding
        
        case handleSize

        // Line widths
        case pictogramLineWidth
        case connectorLineWidth
    }
    
    public enum FontKey: CaseIterable {
        /// Default label font.
        case label
        
        /// Font key for primary block label - usually a block name. If not defined, then ``label``
        /// font is used.
        case primaryBlockLabel
        /// Font key for secondary block label - usually a block formula or custom value.
        /// If not defined, then ``label`` font is used.
        case secondaryBlockLabel

        /// Font key for value indicator value.
        /// If not defined, then ``label`` font is used.
        case indicatorValueLabel

        // case comment
    }

    public struct Font: Sendable {
        public let name: String
        public let size: Double
        
        public init(name: String, size: Double) {
            self.name = name
            self.size = size
        }
    }
    
    public let metrics: [MetricKey:Double]
    public let fonts: [FontKey:Font]
    public let defaultFont: Font
    
    public static let DefaultFont = Font(name: "Helvetica", size: 8.0)
    
    /// Create a new diagram layout style.
    ///
    ///
    public init(metrics: [MetricKey:Double] = [:],
                fonts: [FontKey:Font] = [:],
                defaultFont: Font? = nil)
    {
        self.metrics = metrics
        self.fonts = fonts
        self.defaultFont = defaultFont ?? DiagramLayoutStyle.DefaultFont
    }
    
    public func metric(_ key: MetricKey, default defaultValue: Double=0.0) -> Double {
        return metrics[key, default: defaultValue]
    }
    public func font(_ key: FontKey, default defaultValue: Font) -> Font {
        return fonts[key, default: defaultValue]
    }
}
