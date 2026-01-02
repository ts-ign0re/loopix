import SwiftUI

/// Vertical slider for filter intensity (shown on right edge in filter detail mode)
struct VerticalIntensitySlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>

    @State private var isDragging: Bool = false

    /// Track height
    private let trackHeight: CGFloat = 200

    /// Thumb size
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .trailing) {
                // Value label
                HStack {
                    Spacer()
                    Text(String(format: "+%.1f", value))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                }
                .frame(width: 60)
                .offset(y: -trackHeight / 2 - 20)

                // Vertical track
                VStack(spacing: 0) {
                    // Track background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4, height: trackHeight)
                        .overlay(alignment: .bottom) {
                            // Filled portion
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 4, height: trackHeight * CGFloat(normalizedValue))
                        }

                    // Thumb
                    Circle()
                        .fill(isDragging ? Color.yellow : Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .offset(y: -thumbOffset)
                }
                .gesture(dragGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 44, height: trackHeight + 60)
    }

    // MARK: - Computed Properties

    private var normalizedValue: Float {
        let rangeSize = range.upperBound - range.lowerBound
        guard rangeSize > 0 else { return 0 }
        return (value - range.lowerBound) / rangeSize
    }

    private var thumbOffset: CGFloat {
        CGFloat(normalizedValue) * trackHeight
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                isDragging = true

                // Convert drag location to value
                let yOffset = trackHeight - gesture.location.y
                let normalized = max(0, min(1, yOffset / trackHeight))
                let rangeSize = range.upperBound - range.lowerBound
                value = range.lowerBound + Float(normalized) * rangeSize
            }
            .onEnded { _ in
                isDragging = false
            }
    }
}

// MARK: - Slider Style

/// Visual style for full screen slider
enum FullScreenSliderStyle {
    case `default`
    case temperature
    case tint

    var trackGradient: LinearGradient? {
        switch self {
        case .temperature:
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.5, blue: 1.0),   // Cool blue
                    Color(red: 0.5, green: 0.7, blue: 1.0),   // Light blue
                    Color.white,                              // Neutral
                    Color(red: 1.0, green: 0.85, blue: 0.5),  // Warm yellow
                    Color(red: 1.0, green: 0.6, blue: 0.3)    // Warm orange
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .tint:
            return LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.8, blue: 0.4),   // Green
                    Color.white,                              // Neutral
                    Color(red: 0.9, green: 0.4, blue: 0.7)    // Magenta
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .default:
            return nil
        }
    }
}

// MARK: - Horizontal Variant (for tool detail)

/// Full-width horizontal slider for tool adjustment
struct FullScreenSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let defaultValue: Float
    var style: FullScreenSliderStyle = .default

    @State private var isDragging: Bool = false
    @State private var hasTriggeredZeroHaptic: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - 32 // Padding

            ZStack(alignment: .leading) {
                // Track background - use gradient if style has one
                if let gradient = style.trackGradient {
                    Capsule()
                        .fill(gradient)
                        .frame(height: 6)
                } else {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                }

                // Active fill from default to current (only for default style)
                if style == .default {
                    let defaultNorm = CGFloat((defaultValue - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let currentNorm = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))

                    let fillStart = min(defaultNorm, currentNorm)
                    let fillEnd = max(defaultNorm, currentNorm)
                    let fillWidth = (fillEnd - fillStart) * trackWidth

                    Capsule()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: fillWidth, height: 4)
                        .offset(x: fillStart * trackWidth)
                }

                // Center line indicator (at default value)
                let defaultNorm = CGFloat((defaultValue - range.lowerBound) / (range.upperBound - range.lowerBound))
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2, height: 14)
                    .offset(x: defaultNorm * trackWidth - 1)

                // Thumb
                let currentNorm = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                Circle()
                    .fill(isDragging ? Color.yellow : Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                    .offset(x: currentNorm * trackWidth - 11)
            }
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true

                        let normalizedX = (gesture.location.x - 16) / trackWidth
                        let clamped = max(0, min(1, normalizedX))
                        let rangeSize = range.upperBound - range.lowerBound
                        let newValue = range.lowerBound + Float(clamped) * rangeSize

                        // Haptic when crossing default
                        if !hasTriggeredZeroHaptic &&
                           ((value < defaultValue && newValue >= defaultValue) ||
                            (value > defaultValue && newValue <= defaultValue)) {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            hasTriggeredZeroHaptic = true
                        } else if abs(newValue - defaultValue) > rangeSize * 0.05 {
                            hasTriggeredZeroHaptic = false
                        }

                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 44)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Vertical slider
        HStack {
            Spacer()
            VerticalIntensitySlider(
                value: .constant(75),
                range: 0...100
            )
        }
        .frame(height: 280)

        // Full screen slider
        FullScreenSlider(
            value: .constant(25),
            range: -100...100,
            defaultValue: 0
        )
    }
    .padding()
    .background(Color.black)
}
