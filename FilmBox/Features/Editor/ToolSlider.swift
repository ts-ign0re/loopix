import SwiftUI

// MARK: - Tool Slider

/// Reusable horizontal slider component for parameter adjustment
/// Features: parameter name, current value display, range, haptic feedback at zero, reset button
struct ToolSlider: View {

    // MARK: - Properties

    /// Label displayed above the slider
    let label: String

    /// The current value binding
    @Binding var value: Float

    /// The allowed range for the slider
    let range: ClosedRange<Float>

    /// The default/reset value (typically 0 or center of range)
    let defaultValue: Float

    /// Optional format string for displaying the value
    var valueFormat: String = "%.0f"

    /// Whether to show the value as a percentage
    var showAsPercentage: Bool = false

    /// Whether to use stepped values
    var step: Float? = nil

    /// Custom value display formatter (overrides valueFormat if provided)
    var customValueDisplay: ((Float) -> String)? = nil

    /// Callback when sliding begins
    var onEditingChanged: ((Bool) -> Void)? = nil

    // MARK: - Private State

    @State private var isDragging: Bool = false
    @State private var hasTriggeredZeroHaptic: Bool = false

    // MARK: - Computed Properties

    /// Whether the value is at the default/zero point
    private var isAtDefault: Bool {
        abs(value - defaultValue) < 0.01
    }

    /// Display string for the current value
    private var displayValue: String {
        // Use custom formatter if provided
        if let customDisplay = customValueDisplay {
            return customDisplay(value)
        }

        if showAsPercentage {
            return "\(Int(value))%"
        }

        if abs(value) < 0.01 {
            return "0"
        }

        let formatted = String(format: valueFormat, value)
        if value > 0 && !formatted.hasPrefix("+") {
            return "+\(formatted)"
        }
        return formatted
    }

    /// Normalized position for the zero/default point on the track
    private var defaultPosition: CGFloat {
        let rangeSpan = range.upperBound - range.lowerBound
        guard rangeSpan > 0 else { return 0.5 }
        return CGFloat((defaultValue - range.lowerBound) / rangeSpan)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Header row
            headerRow

            // Slider track
            sliderTrack
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            // Parameter label
            Text(label.lowercased())
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            // Current value display
            Text(displayValue)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(isAtDefault ? .white.opacity(0.5) : .yellow)
                .frame(minWidth: 44, alignment: .trailing)

            // Reset button
            if !isAtDefault {
                Button {
                    resetToDefault()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAtDefault)
    }

    // MARK: - Slider Track

    private var sliderTrack: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let trackHeight: CGFloat = 44
            let thumbSize: CGFloat = 24

            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 4)

                // Active fill
                activeFill(trackWidth: trackWidth)

                // Zero/default indicator line
                if defaultPosition > 0.01 && defaultPosition < 0.99 {
                    Rectangle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 2, height: 12)
                        .offset(x: trackWidth * defaultPosition - 1)
                }

                // Thumb with larger hit area
                Circle()
                    .fill(isDragging ? .yellow : .white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .overlay(
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                    )
                    .offset(x: thumbPosition(trackWidth: trackWidth, thumbSize: thumbSize))
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
            }
            .frame(height: trackHeight)
            .contentShape(Rectangle())
            .gesture(sliderGesture(trackWidth: trackWidth, thumbSize: thumbSize))
        }
        .frame(height: 44)
    }

    // MARK: - Active Fill

    @ViewBuilder
    private func activeFill(trackWidth: CGFloat) -> some View {
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        let defaultPos = defaultPosition

        if normalizedValue >= defaultPos {
            // Fill from default to current (right side)
            Capsule()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: max(0, (normalizedValue - defaultPos) * trackWidth), height: 4)
                .offset(x: defaultPos * trackWidth)
        } else {
            // Fill from current to default (left side)
            Capsule()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: max(0, (defaultPos - normalizedValue) * trackWidth), height: 4)
                .offset(x: normalizedValue * trackWidth)
        }
    }

    // MARK: - Thumb Position

    private func thumbPosition(trackWidth: CGFloat, thumbSize: CGFloat) -> CGFloat {
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return normalizedValue * (trackWidth - thumbSize)
    }

    // MARK: - Gesture

    private func sliderGesture(trackWidth: CGFloat, thumbSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    isDragging = true
                    hasTriggeredZeroHaptic = false
                    onEditingChanged?(true)
                }

                // Calculate new value from position
                let usableWidth = trackWidth - thumbSize
                let position = gesture.location.x - thumbSize / 2
                let normalizedPosition = max(0, min(1, position / usableWidth))

                var newValue = Float(normalizedPosition) * (range.upperBound - range.lowerBound) + range.lowerBound

                // Apply step if specified
                if let step = step {
                    newValue = round(newValue / step) * step
                }

                // Clamp to range
                newValue = max(range.lowerBound, min(range.upperBound, newValue))

                // Check for zero crossing haptic
                let wasAtDefault = abs(value - defaultValue) < 0.01
                let isNowAtDefault = abs(newValue - defaultValue) < 0.01

                if !wasAtDefault && isNowAtDefault && !hasTriggeredZeroHaptic {
                    triggerHaptic()
                    hasTriggeredZeroHaptic = true
                } else if !isNowAtDefault {
                    hasTriggeredZeroHaptic = false
                }

                value = newValue
            }
            .onEnded { _ in
                isDragging = false
                onEditingChanged?(false)
            }
    }

    // MARK: - Actions

    private func resetToDefault() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            value = defaultValue
        }
        triggerHaptic()
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Vertical Tool Slider

/// Vertical version of the tool slider for specific use cases
struct VerticalToolSlider: View {

    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let defaultValue: Float

    @State private var isDragging: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            // Value display
            Text(String(format: "%.0f", value))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))

            // Vertical track
            GeometryReader { geometry in
                let trackHeight = geometry.size.height
                let thumbSize: CGFloat = 20

                ZStack(alignment: .bottom) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 4)

                    // Thumb
                    Circle()
                        .fill(isDragging ? .yellow : .white)
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(y: -thumbPosition(trackHeight: trackHeight, thumbSize: thumbSize))
                }
                .frame(maxWidth: .infinity)
                .gesture(verticalSliderGesture(trackHeight: trackHeight, thumbSize: thumbSize))
            }

            // Label
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func thumbPosition(trackHeight: CGFloat, thumbSize: CGFloat) -> CGFloat {
        let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return normalizedValue * (trackHeight - thumbSize)
    }

    private func verticalSliderGesture(trackHeight: CGFloat, thumbSize: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                isDragging = true

                let usableHeight = trackHeight - thumbSize
                let position = trackHeight - gesture.location.y - thumbSize / 2
                let normalizedPosition = max(0, min(1, position / usableHeight))

                let newValue = Float(normalizedPosition) * (range.upperBound - range.lowerBound) + range.lowerBound
                value = max(range.lowerBound, min(range.upperBound, newValue))
            }
            .onEnded { _ in
                isDragging = false
            }
    }
}

// MARK: - Compact Tool Slider

/// Compact version with inline label for tight spaces
struct CompactToolSlider: View {

    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let defaultValue: Float

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 60, alignment: .leading)

            ToolSlider(
                label: "",
                value: $value,
                range: range,
                defaultValue: defaultValue
            )
        }
    }
}

// MARK: - Previews

#Preview("Tool Slider") {
    struct PreviewWrapper: View {
        @State private var exposure: Float = 0
        @State private var contrast: Float = 25
        @State private var saturation: Float = -50

        var body: some View {
            VStack(spacing: 24) {
                ToolSlider(
                    label: "Exposure",
                    value: $exposure,
                    range: -2...2,
                    defaultValue: 0,
                    valueFormat: "%.1f"
                )

                ToolSlider(
                    label: "Contrast",
                    value: $contrast,
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Saturation",
                    value: $saturation,
                    range: -100...100,
                    defaultValue: 0
                )
            }
            .padding(24)
            .background(Color.black)
        }
    }

    return PreviewWrapper()
}

#Preview("Compact Slider") {
    struct PreviewWrapper: View {
        @State private var value: Float = 50

        var body: some View {
            CompactToolSlider(
                label: "Grain",
                value: $value,
                range: 0...100,
                defaultValue: 0
            )
            .padding(24)
            .background(Color.black)
        }
    }

    return PreviewWrapper()
}
