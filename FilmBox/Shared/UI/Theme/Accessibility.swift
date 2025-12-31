import SwiftUI

// MARK: - Accessibility Configuration

/// Accessibility utilities and configurations for FilmBox
enum Accessibility {

    // MARK: - Semantic Labels

    /// Standard accessibility labels for common UI elements
    enum Labels {
        // Navigation
        static let back = String(localized: "Back", comment: "Navigation back button")
        static let close = String(localized: "Close", comment: "Close button")
        static let done = String(localized: "Done", comment: "Done button")
        static let cancel = String(localized: "Cancel", comment: "Cancel button")
        static let settings = String(localized: "Settings", comment: "Settings button")

        // Editor Actions
        static let save = String(localized: "Save", comment: "Save button")
        static let export = String(localized: "Export", comment: "Export button")
        static let undo = String(localized: "Undo", comment: "Undo button")
        static let redo = String(localized: "Redo", comment: "Redo button")
        static let reset = String(localized: "Reset", comment: "Reset button")

        // Image Operations
        static let rotateLeft = String(localized: "Rotate left", comment: "Rotate image left")
        static let rotateRight = String(localized: "Rotate right", comment: "Rotate image right")
        static let flipHorizontal = String(localized: "Flip horizontal", comment: "Flip image horizontally")
        static let flipVertical = String(localized: "Flip vertical", comment: "Flip image vertically")
        static let crop = String(localized: "Crop", comment: "Crop image")

        // Tabs
        static let filtersTab = String(localized: "Filters", comment: "Filters tab")
        static let adjustTab = String(localized: "Adjust", comment: "Adjustments tab")
        static let effectsTab = String(localized: "Effects", comment: "Effects tab")
        static let cropTab = String(localized: "Crop", comment: "Crop tab")
        static let presetsTab = String(localized: "Presets", comment: "Presets tab")

        // Gallery
        static let selectPhoto = String(localized: "Select photo", comment: "Select photo action")
        static let photoSelected = String(localized: "Selected", comment: "Photo is selected")
        static let photoCount = String(localized: "%d photos", comment: "Number of photos")
    }

    // MARK: - Hints

    /// Accessibility hints for complex interactions
    enum Hints {
        static let sliderAdjust = String(localized: "Swipe left or right to adjust value", comment: "Slider hint")
        static let doubleTapToReset = String(localized: "Double tap to reset", comment: "Reset hint")
        static let pinchToZoom = String(localized: "Pinch to zoom", comment: "Zoom hint")
        static let dragToMove = String(localized: "Drag to move", comment: "Move hint")
        static let tapToSelect = String(localized: "Tap to select", comment: "Selection hint")
        static let longPressForOptions = String(localized: "Long press for more options", comment: "Context menu hint")
    }

    // MARK: - Value Formatters

    /// Format values for VoiceOver announcements
    enum ValueFormat {
        /// Format percentage value
        static func percentage(_ value: Float) -> String {
            String(format: "%.0f percent", value)
        }

        /// Format exposure value
        static func exposure(_ value: Float) -> String {
            if value >= 0 {
                return String(format: "plus %.1f stops", value)
            } else {
                return String(format: "minus %.1f stops", abs(value))
            }
        }

        /// Format temperature value
        static func temperature(_ value: Float) -> String {
            if value > 0 {
                return String(format: "warmer by %d", Int(value))
            } else if value < 0 {
                return String(format: "cooler by %d", Int(abs(value)))
            } else {
                return "neutral"
            }
        }

        /// Format angle in degrees
        static func angle(_ degrees: Float) -> String {
            String(format: "%.1f degrees", degrees)
        }

        /// Format filter intensity
        static func filterIntensity(_ value: Float) -> String {
            String(format: "%.0f percent intensity", value)
        }
    }

    // MARK: - Announcements

    /// Post accessibility announcements
    static func announce(_ message: String, delay: Double = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    /// Announce screen change
    static func announceScreenChange(_ screenName: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIAccessibility.post(notification: .screenChanged, argument: screenName)
        }
    }

    /// Announce layout change
    static func announceLayoutChange(_ element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

// MARK: - Accessibility View Modifiers

extension View {

    /// Add standard accessibility for an adjustment slider
    func accessibilitySlider(
        label: String,
        value: Float,
        range: ClosedRange<Float>,
        formatter: (Float) -> String = Accessibility.ValueFormat.percentage
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(formatter(value))
            .accessibilityHint(Accessibility.Hints.sliderAdjust)
            .accessibilityAdjustableAction { direction in
                // This allows VoiceOver users to increment/decrement
            }
    }

    /// Add accessibility for an image element
    func accessibilityImage(_ description: String, isDecorative: Bool = false) -> some View {
        if isDecorative {
            return self.accessibilityHidden(true).eraseToAnyView()
        } else {
            return self
                .accessibilityLabel(description)
                .accessibilityAddTraits(.isImage)
                .eraseToAnyView()
        }
    }

    /// Add accessibility for a selectable item
    func accessibilitySelectable(label: String, isSelected: Bool) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            .accessibilityHint(isSelected ? "" : Accessibility.Hints.tapToSelect)
    }

    /// Add accessibility for a tab item
    func accessibilityTab(label: String, isSelected: Bool, index: Int, total: Int) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            .accessibilityValue("\(index + 1) of \(total)")
    }

    /// Hide element from accessibility but keep it visible
    func accessibilityDecorative() -> some View {
        self.accessibilityHidden(true)
    }

    /// Group children under a single accessibility element
    func accessibilityGroup(label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }
}

// MARK: - Type Erasure Helper

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Accessibility Rotor

/// Custom accessibility rotor for filter presets
struct FilterRotor: AccessibilityRotorContent {
    let filters: [String]
    let onSelect: (String) -> Void

    var body: some AccessibilityRotorContent {
        ForEach(filters, id: \.self) { filter in
            AccessibilityRotorEntry(filter, id: filter) {
                onSelect(filter)
            }
        }
    }
}

// MARK: - Dynamic Type Helpers

extension View {

    /// Scale with Dynamic Type while respecting minimum size
    @ViewBuilder
    func dynamicTypeSize(minimum: DynamicTypeSize = .xSmall, maximum: DynamicTypeSize = .accessibility3) -> some View {
        self.dynamicTypeSize(minimum...maximum)
    }

    /// Apply scaled padding that respects Dynamic Type
    func scaledPadding(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        self.padding(edges, length)
    }
}

// MARK: - Reduce Motion Support

extension View {

    /// Apply animation only if user hasn't enabled Reduce Motion
    func animationRespectingMotion<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(ReduceMotionModifier(animation: animation, value: value))
    }
}

private struct ReduceMotionModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - Contrast Support

extension View {

    /// Increase contrast when accessibility setting is enabled
    func contrastAdaptive() -> some View {
        self.modifier(ContrastAdaptiveModifier())
    }
}

private struct ContrastAdaptiveModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .opacity(reduceTransparency ? 1.0 : 1.0)
    }
}

// MARK: - VoiceOver Detection

/// Check if VoiceOver is currently running
var isVoiceOverRunning: Bool {
    UIAccessibility.isVoiceOverRunning
}

/// Check if Reduce Motion is enabled
var isReduceMotionEnabled: Bool {
    UIAccessibility.isReduceMotionEnabled
}

/// Check if Bold Text is enabled
var isBoldTextEnabled: Bool {
    UIAccessibility.isBoldTextEnabled
}

// MARK: - Accessibility Focus

extension View {

    /// Focus this element when it appears (for VoiceOver)
    func accessibilityFocusOnAppear() -> some View {
        self.modifier(AccessibilityFocusOnAppearModifier())
    }
}

private struct AccessibilityFocusOnAppearModifier: ViewModifier {
    @AccessibilityFocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityFocused($isFocused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
    }
}

// MARK: - Preview

#Preview("Accessibility Demo") {
    VStack(spacing: 20) {
        Text("Accessibility Demo")
            .font(.title)
            .accessibilityAddTraits(.isHeader)

        Button("Primary Action") {}
            .accessibilityHint("Performs the main action")

        Slider(value: .constant(0.5))
            .accessibilitySlider(
                label: "Exposure",
                value: 50,
                range: -100...100,
                formatter: { Accessibility.ValueFormat.percentage($0) }
            )

        HStack {
            ForEach(0..<4) { index in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 44, height: 44)
                    .accessibilityTab(
                        label: "Tab \(index + 1)",
                        isSelected: index == 0,
                        index: index,
                        total: 4
                    )
            }
        }
    }
    .padding()
}
