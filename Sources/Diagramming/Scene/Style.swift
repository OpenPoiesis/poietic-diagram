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
    public var `class`: StyleClass
    public var modifiers: StyleModifierSet

    /// Adaptable colour of the node, if the node or any of its parts have to be rendered in
    /// specific colour.
    ///
    /// Note that the actual rendering might depend on the class and style modifiers, which might
    /// make the colour brighter, darer, or might just not display the colour at all (for example
    /// grey for disabled nodes).
    ///
    public var adaptableColor: AdaptableColorKey?
    
    public init(class styleClass: StyleClass, modifiers: StyleModifierSet = .none, adaptableColor: AdaptableColorKey? = nil) {
        self.class = styleClass
        self.modifiers = modifiers
        self.adaptableColor = adaptableColor
    }
}

/// - Note: This is different data type from node type, as this is an information about
///   presentation, not behaviour.
public struct StyleModifierSet: OptionSet, Sendable, Hashable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
    public static let none: StyleModifierSet = []
    public static let selected      = StyleModifierSet(rawValue: 1 << 0)
    public static let hovered       = StyleModifierSet(rawValue: 1 << 1)
    /// Elements highlighted by search or other means. Different from `selected`.
    public static let highlighted   = StyleModifierSet(rawValue: 1 << 2)
    public static let disabled      = StyleModifierSet(rawValue: 1 << 3)
    public static let error         = StyleModifierSet(rawValue: 1 << 4)
    public static let warning       = StyleModifierSet(rawValue: 1 << 5)
    // public static let locked       = StyleModifierSet(rawValue: 1 << 6)

    // Interaction
    /// The node is just an intent to be previewed.
    ///
    /// Typical style should be light, shadow-like.
    public static let preview       = StyleModifierSet(rawValue: 1 << 7)
    
    /// Highlight of a node that is an allowed target of an interaction. For example
    /// a block node representing flow rate of an intended flow connector.
    public static let allowed       = StyleModifierSet(rawValue: 1 << 8)
    /// Highlight of a node that is not allowed target of an interaction. For example
    /// a block node of an auxiliary computation as a target intended flow connector.
    public static let notAllowed    = StyleModifierSet(rawValue: 1 << 9)

    /// Mask for both `allowed` and `notAllowed` modifiers used to remove them both. Used in
    /// clean-up:
    ///
    /// ```swift
    /// var modifiers: StyleModifierSet
    /// modifiers.subtract(.allowedMask)
    /// ```
    public static let allowedMask   = StyleModifierSet([.allowed, .notAllowed])
    
    // Indicated Value
    public static let overflow      = StyleModifierSet(rawValue: 1 << 10)
    public static let underflow     = StyleModifierSet(rawValue: 1 << 11)
    public static let positive      = StyleModifierSet(rawValue: 1 << 12)
    public static let negative      = StyleModifierSet(rawValue: 1 << 13)
    public static let empty         = StyleModifierSet(rawValue: 1 << 14)

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
    
    /// Non-specific block
    case block
    case pictogram

    /// Non-specific connector
    case connector
    /// Thin wire connector.
    case thinConnector
    /// Fat outlined connector.
    case fatConnector
    
    /// Colour of highlight, such as selection. Concrete highlight is to be specified with
    /// ``StyleModifierSet``.
    case highlight
    
    /// Colour of interactive intent such as new object to be placed.
    case intentShadow
    
    /// Colour of mid-point or other handle.
    case handle
    
    /// Foreground colour of error indicator.
    case issueIndicator

    /// Colour of colour swatch border.
    case colorSwatch
    
    case valueLabel
    case valueIndicator
    case valueIndicatorLine
    
    public var stringValue: String { return self.rawValue }
}


public enum DiagramLayoutMetric: CaseIterable, Sendable {
    // Sizes, paddings and magrins
    case primaryLabelPadding
    case secondaryLabelPadding
    case colorSwatchSize
    case valueIndicatorPadding
    case errorIndicatorPadding
    
    case handleSize
}

/// Provider of a diagram layout geometry.
///
/// Part of diagram rendering backend, related to ``DiagramSceneRenderer`` and its rendering context.
///
/// - Note: It is assumed that the metric do not change between layout and render.
///
public protocol LayoutProvider {
    func metric(_ metric: DiagramLayoutMetric, default defaultValue: Double) -> Double
    /// Compute text extents for a text with given style class (semantic role).
    ///
    /// Used to compute label bounding box and for ``TouchRegion``.
    func textExtents(_ text: String, class styleClass: StyleClass) -> Rect2D
    /// Offset for label rendering position relative to label node position.
    ///
    /// Different backends might use different positions for label rendering. Typically
    /// backends use lower left point. SVG can use centre point (using `"middle"` positioning
    /// attribute). This method give opportunity to the rendering backend to compute correct offset
    /// without affecting the actual node position.
    ///
    /// Default implementation returns nil – default backend behaviour.
    ///
    /// The return value is used by the ``DiagramSceneComposer`` during layout phase to create
    /// ``RenderingOffset`` component on ``LabelSceneNode``.
    ///
    func labelRenderingOffset(extents: Rect2D, anchor: Vector2D) -> Vector2D
}

public extension LayoutProvider {
    func labelRenderingOffset(extents: Rect2D, anchor: Vector2D) -> Vector2D {
        return .zero
    }

}


/// Component set on diagram scene.
///
/// Required by ``SceneCompositionSystem`` to preform scene layout.
///
public struct SceneLayoutProvider: Component {
    public let provider: any LayoutProvider
    public init(provider: any LayoutProvider) {
        self.provider = provider
    }
}
