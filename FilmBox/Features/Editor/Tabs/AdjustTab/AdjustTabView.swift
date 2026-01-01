import SwiftUI

/// Adjustment tab view for manual photo adjustments
/// Contains Light and Color sections with individual parameter sliders
struct AdjustTabView: View {

    // MARK: - Properties

    /// Current filter parameters being edited
    @Binding var parameters: FilterParameters

    /// Whether the HSL editor modal is presented
    @State private var showingHSLEditor: Bool = false

    /// Whether the Split Tone editor modal is presented
    @State private var showingSplitToneEditor: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Light Section
                lightSection

                // Color Section
                colorSection

                // Advanced Editors
                advancedSection
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingHSLEditor) {
            HSLEditorSheet(hsl: $parameters.hsl)
        }
        .sheet(isPresented: $showingSplitToneEditor) {
            SplitToneEditorSheet(splitTone: $parameters.splitTone)
        }
    }

    // MARK: - Light Section

    private var lightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Light", icon: "sun.max")

            VStack(spacing: 8) {
                AdjustmentSlider(
                    title: "Exposure",
                    value: $parameters.exposure,
                    range: -2...2,
                    format: .exposure
                )

                AdjustmentSlider(
                    title: "Contrast",
                    value: $parameters.contrast,
                    range: -100...100,
                    format: .percentage
                )

                AdjustmentSlider(
                    title: "Highlights",
                    value: $parameters.highlights,
                    range: -100...100,
                    format: .percentage
                )

                AdjustmentSlider(
                    title: "Shadows",
                    value: $parameters.shadows,
                    range: -100...100,
                    format: .percentage
                )

                AdjustmentSlider(
                    title: "Whites",
                    value: $parameters.whites,
                    range: -100...100,
                    format: .percentage
                )

                AdjustmentSlider(
                    title: "Blacks",
                    value: $parameters.blacks,
                    range: -100...100,
                    format: .percentage
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Color", icon: "drop.fill")

            VStack(spacing: 8) {
                AdjustmentSlider(
                    title: "Temperature",
                    value: $parameters.temperature,
                    range: -100...100,
                    format: .temperature
                )

                AdjustmentSlider(
                    title: "Tint",
                    value: $parameters.tint,
                    range: -100...100,
                    format: .tint
                )

                AdjustmentSlider(
                    title: "Saturation",
                    value: $parameters.saturation,
                    range: -100...100,
                    format: .percentage
                )

                AdjustmentSlider(
                    title: "Vibrance",
                    value: $parameters.vibrance,
                    range: -100...100,
                    format: .percentage
                )
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Advanced", icon: "slider.horizontal.3")

            VStack(spacing: 0) {
                AdvancedEditorButton(
                    title: "HSL / Color",
                    subtitle: "Adjust individual color channels",
                    icon: "paintpalette"
                ) {
                    showingHSLEditor = true
                }

                Divider()
                    .padding(.leading, 56)

                AdvancedEditorButton(
                    title: "Split Tone",
                    subtitle: "Color highlights and shadows",
                    icon: "circle.lefthalf.filled"
                ) {
                    showingSplitToneEditor = true
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Adjustment Slider

private struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let format: ValueFormat

    enum ValueFormat {
        case exposure
        case percentage
        case temperature
        case tint

        func format(_ value: Float) -> String {
            switch self {
            case .exposure:
                let sign = value >= 0 ? "+" : ""
                return "\(sign)\(String(format: "%.2f", value))"
            case .percentage:
                let sign = value >= 0 ? "+" : ""
                return "\(sign)\(Int(value))"
            case .temperature:
                // Convert -100...100 to Kelvin (2500K to 10000K, with 6500K at center)
                let kelvin = Int(6500 + value * 35)
                return "\(kelvin)K"
            case .tint:
                let sign = value >= 0 ? "+" : ""
                return "\(sign)\(Int(value))"
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                Text(format.format(value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if format == .temperature {
                TemperatureSlider(value: $value, range: range)
            } else if format == .tint {
                TintSlider(value: $value, range: range)
            } else {
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { value = Float($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound)
                )
                .tint(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Temperature Slider (Cool Blue to Warm Orange)

private struct TemperatureSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gradient track
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.6, blue: 1.0),  // Cool blue
                        Color(red: 0.6, green: 0.8, blue: 1.0),  // Light blue
                        Color.white,                              // Neutral
                        Color(red: 1.0, green: 0.9, blue: 0.7),  // Light warm
                        Color(red: 1.0, green: 0.6, blue: 0.2)   // Warm orange
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 6)
                .clipShape(Capsule())

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .offset(x: thumbOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                updateValue(from: gesture.location.x, in: geometry.size.width)
                            }
                    )
            }
        }
        .frame(height: 24)
        .contentShape(Rectangle())
        .onTapGesture { location in
            // Handle tap to set value
        }
    }

    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let normalized = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return normalized * (width - 24)
    }

    private func updateValue(from x: CGFloat, in width: CGFloat) {
        let normalized = max(0, min(1, x / width))
        let newValue = range.lowerBound + Float(normalized) * (range.upperBound - range.lowerBound)
        value = newValue
    }
}

// MARK: - Tint Slider (Green to Magenta)

private struct TintSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Gradient track
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.9, blue: 0.4),  // Green
                        Color(red: 0.7, green: 0.95, blue: 0.7), // Light green
                        Color.white,                              // Neutral
                        Color(red: 1.0, green: 0.7, blue: 0.9),  // Light magenta
                        Color(red: 0.9, green: 0.3, blue: 0.7)   // Magenta
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 6)
                .clipShape(Capsule())

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .offset(x: thumbOffset(in: geometry.size.width))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                updateValue(from: gesture.location.x, in: geometry.size.width)
                            }
                    )
            }
        }
        .frame(height: 24)
        .contentShape(Rectangle())
    }

    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let normalized = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return normalized * (width - 24)
    }

    private func updateValue(from x: CGFloat, in width: CGFloat) {
        let normalized = max(0, min(1, x / width))
        let newValue = range.lowerBound + Float(normalized) * (range.upperBound - range.lowerBound)
        value = newValue
    }
}

// MARK: - Advanced Editor Button

private struct AdvancedEditorButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.accentColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - HSL Editor Sheet

private struct HSLEditorSheet: View {
    @Binding var hsl: HSLAdjustments
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<8, id: \.self) { index in
                        HSLChannelEditor(
                            channelName: HSLAdjustments.channelNames[index],
                            channel: channelBinding(for: index)
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("HSL / Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func channelBinding(for index: Int) -> Binding<HSLAdjustments.HSLChannel> {
        Binding(
            get: { hsl[index] },
            set: { hsl[index] = $0 }
        )
    }
}

private struct HSLChannelEditor: View {
    let channelName: String
    @Binding var channel: HSLAdjustments.HSLChannel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(channelName)
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Hue")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(channel.hue))")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(channel.hue) },
                        set: { channel.hue = Float($0) }
                    ),
                    in: -180...180
                )

                HStack {
                    Text("Saturation")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(channel.saturation))")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(channel.saturation) },
                        set: { channel.saturation = Float($0) }
                    ),
                    in: -100...100
                )

                HStack {
                    Text("Luminance")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(channel.luminance))")
                        .font(.subheadline)
                        .monospacedDigit()
                }
                Slider(
                    value: Binding(
                        get: { Double(channel.luminance) },
                        set: { channel.luminance = Float($0) }
                    ),
                    in: -100...100
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Split Tone Editor Sheet

private struct SplitToneEditorSheet: View {
    @Binding var splitTone: SplitToneData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Highlights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Highlights")
                            .font(.headline)

                        VStack(spacing: 8) {
                            HStack {
                                Text("Hue")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(splitTone.highlightHue))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(splitTone.highlightHue) },
                                    set: { splitTone.highlightHue = Float($0) }
                                ),
                                in: 0...360
                            )
                            .tint(Color(hue: Double(splitTone.highlightHue) / 360, saturation: 0.8, brightness: 0.9))

                            HStack {
                                Text("Saturation")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(splitTone.highlightSaturation))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(splitTone.highlightSaturation) },
                                    set: { splitTone.highlightSaturation = Float($0) }
                                ),
                                in: 0...100
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Shadows
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shadows")
                            .font(.headline)

                        VStack(spacing: 8) {
                            HStack {
                                Text("Hue")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(splitTone.shadowHue))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(splitTone.shadowHue) },
                                    set: { splitTone.shadowHue = Float($0) }
                                ),
                                in: 0...360
                            )
                            .tint(Color(hue: Double(splitTone.shadowHue) / 360, saturation: 0.8, brightness: 0.9))

                            HStack {
                                Text("Saturation")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(splitTone.shadowSaturation))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(splitTone.shadowSaturation) },
                                    set: { splitTone.shadowSaturation = Float($0) }
                                ),
                                in: 0...100
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Balance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Balance")
                            .font(.headline)

                        HStack {
                            Text("Shadows")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Highlights")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(splitTone.balance) },
                                set: { splitTone.balance = Float($0) }
                            ),
                            in: -100...100
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Split Tone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var parameters = FilterParameters()

        var body: some View {
            AdjustTabView(parameters: $parameters)
        }
    }

    return PreviewWrapper()
}
