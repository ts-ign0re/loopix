import SwiftUI

/// Effects tab view for applying special effects to photos
/// Contains controls for Clarity, Sharpen, Grain, Vignette, Fade, Bloom, and Halation
struct EffectsTabView: View {

    // MARK: - Properties

    /// Current filter parameters being edited
    @Binding var parameters: FilterParameters

    /// Expanded sections tracking
    @State private var expandedSections: Set<EffectSection> = []

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Simple Effects
                simpleEffectsSection

                // Multi-parameter Effects
                grainSection
                vignetteSection
                bloomSection
                halationSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Simple Effects Section

    private var simpleEffectsSection: some View {
        VStack(spacing: 0) {
            EffectSliderRow(
                title: "Clarity",
                icon: "sparkle",
                value: $parameters.clarity,
                range: -100...100,
                showSign: true
            )

            Divider()
                .padding(.leading, 56)

            EffectSliderRow(
                title: "Sharpen",
                icon: "triangle",
                value: $parameters.sharpness,
                range: 0...100,
                showSign: false
            )

            Divider()
                .padding(.leading, 56)

            EffectSliderRow(
                title: "Fade",
                icon: "square.stack",
                value: $parameters.fade,
                range: 0...100,
                showSign: false
            )
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Grain Section

    private var grainSection: some View {
        ExpandableEffectSection(
            title: "Grain",
            icon: "circle.dotted",
            isExpanded: expandedSections.contains(.grain),
            isActive: parameters.grain.isActive,
            onToggle: { toggleSection(.grain) }
        ) {
            VStack(spacing: 12) {
                EffectParameterSlider(
                    title: "Amount",
                    value: $parameters.grain.amount,
                    range: 0...100
                )

                EffectParameterSlider(
                    title: "Size",
                    value: $parameters.grain.size,
                    range: 0...1,
                    displayMultiplier: 100
                )

                EffectParameterSlider(
                    title: "Roughness",
                    value: $parameters.grain.roughness,
                    range: 0...1,
                    displayMultiplier: 100
                )

                Toggle("Monochromatic", isOn: $parameters.grain.monochromatic)
                    .font(.subheadline)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Vignette Section

    private var vignetteSection: some View {
        ExpandableEffectSection(
            title: "Vignette",
            icon: "circle.inset.filled",
            isExpanded: expandedSections.contains(.vignette),
            isActive: parameters.vignette.isActive,
            onToggle: { toggleSection(.vignette) }
        ) {
            VStack(spacing: 12) {
                EffectParameterSlider(
                    title: "Amount",
                    value: $parameters.vignette.amount,
                    range: -100...100,
                    showSign: true
                )

                EffectParameterSlider(
                    title: "Midpoint",
                    value: $parameters.vignette.midpoint,
                    range: 0...1,
                    displayMultiplier: 100
                )

                EffectParameterSlider(
                    title: "Roundness",
                    value: $parameters.vignette.roundness,
                    range: -100...100,
                    showSign: true
                )

                EffectParameterSlider(
                    title: "Feather",
                    value: $parameters.vignette.feather,
                    range: 0...1,
                    displayMultiplier: 100
                )
            }
        }
    }

    // MARK: - Bloom Section

    private var bloomSection: some View {
        ExpandableEffectSection(
            title: "Bloom",
            icon: "sun.max.fill",
            isExpanded: expandedSections.contains(.bloom),
            isActive: parameters.bloom.isActive,
            onToggle: { toggleSection(.bloom) }
        ) {
            VStack(spacing: 12) {
                EffectParameterSlider(
                    title: "Intensity",
                    value: $parameters.bloom.intensity,
                    range: 0...100
                )

                EffectParameterSlider(
                    title: "Radius",
                    value: $parameters.bloom.radius,
                    range: 0...1,
                    displayMultiplier: 100
                )

                EffectParameterSlider(
                    title: "Threshold",
                    value: $parameters.bloom.threshold,
                    range: 0...1,
                    displayMultiplier: 100
                )
            }
        }
    }

    // MARK: - Halation Section

    private var halationSection: some View {
        ExpandableEffectSection(
            title: "Halation",
            icon: "light.max",
            isExpanded: expandedSections.contains(.halation),
            isActive: parameters.halation.isActive,
            onToggle: { toggleSection(.halation) }
        ) {
            VStack(spacing: 12) {
                EffectParameterSlider(
                    title: "Intensity",
                    value: $parameters.halation.intensity,
                    range: 0...100
                )

                EffectParameterSlider(
                    title: "Hue",
                    value: $parameters.halation.hue,
                    range: 0...360,
                    suffix: "°"
                )

                EffectParameterSlider(
                    title: "Spread",
                    value: $parameters.halation.spread,
                    range: 0...1,
                    displayMultiplier: 100
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func toggleSection(_ section: EffectSection) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

// MARK: - Effect Section Enum

private enum EffectSection: Hashable {
    case grain
    case vignette
    case bloom
    case halation
}

// MARK: - Effect Slider Row

private struct EffectSliderRow: View {
    let title: String
    let icon: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let showSign: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32)

            VStack(spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)

                    Spacer()

                    Text(formattedValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Float($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound)
                )
                .tint(.accentColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var formattedValue: String {
        if showSign && value >= 0 {
            return "+\(Int(value))"
        }
        return "\(Int(value))"
    }
}

// MARK: - Expandable Effect Section

private struct ExpandableEffectSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let isActive: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isActive ? .accentColor : .secondary)
                        .frame(width: 32)

                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Spacer()

                    if isActive {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    }

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded Content
            if isExpanded {
                Divider()
                    .padding(.leading, 56)

                content()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

// MARK: - Effect Parameter Slider

private struct EffectParameterSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var showSign: Bool = false
    var displayMultiplier: Float = 1
    var suffix: String = ""

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formattedValue)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound)
            )
            .tint(.accentColor)
        }
    }

    private var formattedValue: String {
        let displayValue = Int(value * displayMultiplier)
        var result: String
        if showSign && displayValue >= 0 {
            result = "+\(displayValue)"
        } else {
            result = "\(displayValue)"
        }
        return result + suffix
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var parameters = FilterParameters()

        var body: some View {
            EffectsTabView(parameters: $parameters)
        }
    }

    return PreviewWrapper()
}
