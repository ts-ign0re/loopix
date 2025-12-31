import SwiftUI

// MARK: - Slider Style

/// Slider visual style
enum FBSliderStyle {
    case `default`
    case temperature
    case tint
    case exposure
    case bipolar  // -100 to +100 with center

    var trackGradient: LinearGradient? {
        switch self {
        case .temperature:
            return LinearGradient(
                colors: [.fbSliderTemperatureCool, .fbSliderTemperatureWarm],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .tint:
            return LinearGradient(
                colors: [.fbSliderTintGreen, .fbSliderTintMagenta],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return nil
        }
    }
}

// MARK: - FBSlider

/// Custom slider component for photo editing adjustments
struct FBSlider: View {

    // MARK: - Properties

    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float?
    let style: FBSliderStyle
    let showValue: Bool
    let valueFormatter: ((Float) -> String)?
    let onEditingChanged: ((Bool) -> Void)?

    // MARK: - State

    @State private var isDragging = false

    // MARK: - Initialization

    init(
        _ title: String,
        value: Binding<Float>,
        in range: ClosedRange<Float> = 0...100,
        step: Float? = nil,
        style: FBSliderStyle = .default,
        showValue: Bool = true,
        valueFormatter: ((Float) -> String)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.style = style
        self.showValue = showValue
        self.valueFormatter = valueFormatter
        self.onEditingChanged = onEditingChanged
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.xs) {
            // Header
            HStack {
                Text(title)
                    .font(.fbToolLabel)
                    .foregroundStyle(.fbLabel)

                Spacer()

                if showValue {
                    Text(formattedValue)
                        .font(.fbValueDisplay)
                        .foregroundStyle(.fbLabelSecondary)
                }
            }

            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    trackBackground
                        .frame(height: 4)
                        .clipShape(Capsule())

                    // Active track
                    activeTrack(width: geometry.size.width)
                        .frame(height: 4)
                        .clipShape(Capsule())

                    // Center indicator for bipolar
                    if style == .bipolar {
                        centerIndicator(width: geometry.size.width)
                    }

                    // Thumb
                    thumb
                        .offset(x: thumbOffset(width: geometry.size.width))
                        .gesture(dragGesture(width: geometry.size.width))
                }
                .frame(height: Spacing.touchTarget)
            }
            .frame(height: Spacing.touchTarget)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(formattedValue)
        .accessibilityHint("Swipe up or down to adjust")
        .accessibilityAdjustableAction { direction in
            adjustValue(direction: direction)
        }
    }

    // MARK: - Track Background

    @ViewBuilder
    private var trackBackground: some View {
        if let gradient = style.trackGradient {
            gradient
        } else {
            Color.fbSliderTrack
        }
    }

    // MARK: - Active Track

    @ViewBuilder
    private func activeTrack(width: CGFloat) -> some View {
        if style == .bipolar {
            // Bipolar: fill from center
            let center = width / 2
            let current = thumbOffset(width: width) + thumbSize / 2
            let fillWidth = abs(current - center)
            let fillOffset = min(current, center)

            Rectangle()
                .fill(Color.fbSliderActive)
                .frame(width: fillWidth)
                .offset(x: fillOffset)
        } else if style.trackGradient != nil {
            // Gradient track - no active fill needed
            EmptyView()
        } else {
            // Default: fill from leading
            Rectangle()
                .fill(Color.fbSliderActive)
                .frame(width: thumbOffset(width: width) + thumbSize / 2)
        }
    }

    // MARK: - Center Indicator

    private func centerIndicator(width: CGFloat) -> some View {
        Rectangle()
            .fill(Color.fbSeparator)
            .frame(width: 2, height: 12)
            .offset(x: width / 2 - 1)
    }

    // MARK: - Thumb

    private var thumb: some View {
        Circle()
            .fill(Color.fbSliderThumb)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .scaleEffect(isDragging ? 1.1 : 1)
            .animation(AnimationCurve.spring, value: isDragging)
    }

    private var thumbSize: CGFloat { 28 }

    // MARK: - Calculations

    private func thumbOffset(width: CGFloat) -> CGFloat {
        let availableWidth = width - thumbSize
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(normalizedValue) * availableWidth
    }

    private func valueFromOffset(_ offset: CGFloat, width: CGFloat) -> Float {
        let availableWidth = width - thumbSize
        let clampedOffset = max(0, min(offset, availableWidth))
        let normalizedValue = Float(clampedOffset / availableWidth)
        var newValue = range.lowerBound + normalizedValue * (range.upperBound - range.lowerBound)

        // Apply step if specified
        if let step = step {
            newValue = (newValue / step).rounded() * step
        }

        return max(range.lowerBound, min(range.upperBound, newValue))
    }

    // MARK: - Drag Gesture

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    isDragging = true
                    onEditingChanged?(true)
                    Haptics.shared.light()
                }

                let newValue = valueFromOffset(gesture.location.x - thumbSize / 2, width: width)
                if newValue != value {
                    value = newValue

                    // Haptic at boundaries or center
                    if newValue == range.lowerBound || newValue == range.upperBound {
                        Haptics.shared.light()
                    } else if style == .bipolar && abs(newValue) < 1 {
                        Haptics.shared.selection()
                    }
                }
            }
            .onEnded { _ in
                isDragging = false
                onEditingChanged?(false)
            }
    }

    // MARK: - Accessibility

    private func adjustValue(direction: AccessibilityAdjustmentDirection) {
        let stepValue = step ?? ((range.upperBound - range.lowerBound) / 20)
        switch direction {
        case .increment:
            value = min(value + stepValue, range.upperBound)
        case .decrement:
            value = max(value - stepValue, range.lowerBound)
        @unknown default:
            break
        }
        Haptics.shared.selection()
    }

    // MARK: - Formatting

    private var formattedValue: String {
        if let formatter = valueFormatter {
            return formatter(value)
        }

        switch style {
        case .exposure:
            let sign = value >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.2f", value))"
        case .bipolar:
            let sign = value > 0 ? "+" : ""
            return "\(sign)\(Int(value))"
        default:
            return "\(Int(value))"
        }
    }
}

// MARK: - Tool Slider (Editor Specific)

/// Slider with reset button for editor tools
struct FBToolSlider: View {

    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let defaultValue: Float
    let style: FBSliderStyle

    init(
        _ title: String,
        value: Binding<Float>,
        in range: ClosedRange<Float> = -100...100,
        defaultValue: Float = 0,
        style: FBSliderStyle = .bipolar
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.defaultValue = defaultValue
        self.style = style
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            FBSlider(title, value: $value, in: range, style: style)

            // Reset button
            if value != defaultValue {
                Button {
                    withAnimation(AnimationCurve.spring) {
                        value = defaultValue
                    }
                    Haptics.shared.light()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.fbLabelSecondary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Reset \(title)")
                .accessibilityHint("Double tap to reset to default value")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(AnimationCurve.spring, value: value != defaultValue)
    }
}

// MARK: - Preview

#Preview("Sliders") {
    struct SliderPreview: View {
        @State private var value1: Float = 50
        @State private var value2: Float = 0
        @State private var value3: Float = 6500
        @State private var value4: Float = 0
        @State private var exposure: Float = 0.5

        var body: some View {
            VStack(spacing: Spacing.lg) {
                FBSlider("Default", value: $value1, in: 0...100)

                FBSlider("Bipolar", value: $value2, in: -100...100, style: .bipolar)

                FBSlider("Temperature", value: $value3, in: 2000...10000, style: .temperature) { value in
                    "\(Int(value))K"
                }

                FBSlider("Tint", value: $value4, in: -100...100, style: .tint)

                FBSlider("Exposure", value: $exposure, in: -2...2, step: 0.1, style: .exposure)

                Divider()

                FBToolSlider("Contrast", value: $value2, in: -100...100)
            }
            .padding()
        }
    }

    return SliderPreview()
}
