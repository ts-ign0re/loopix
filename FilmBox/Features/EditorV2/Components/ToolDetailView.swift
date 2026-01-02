import SwiftUI

/// Full-screen tool detail view for adjusting a single tool parameter
struct ToolDetailView: View {
    @Bindable var viewModel: EditorV2ViewModel
    let tool: ToolDefinition
    let geometry: GeometryProxy

    var body: some View {
        VStack(spacing: 0) {
            // Image preview with histogram
            VSCOImagePreview(
                viewModel: viewModel,
                showHistogram: true,
                showIntensitySlider: false
            )
            .frame(height: geometry.size.height * 0.55)

            Spacer()

            // Tool-specific content
            if isComplexTool {
                complexToolSliders
            } else {
                simpleToolSlider
            }

            Spacer()

            // Bottom controls: X - Tool name - ✓
            HStack {
                // Cancel button
                Button {
                    viewModel.cancelChanges()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Tool name
                Text(tool.name.lowercased())
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                // Confirm button
                Button {
                    viewModel.confirmChanges()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Computed Properties

    /// Whether this tool has multiple sub-parameters (like Grain)
    private var isComplexTool: Bool {
        switch tool.parameterType {
        case .grain, .vignette, .bloom, .halation:
            return true
        default:
            return false
        }
    }

    // MARK: - Subviews

    /// Slider style based on tool type
    private var sliderStyle: FullScreenSliderStyle {
        switch tool.parameterType {
        case .temperature:
            return .temperature
        case .tint:
            return .tint
        default:
            return .default
        }
    }

    /// Simple single slider for most tools
    @ViewBuilder
    private var simpleToolSlider: some View {
        VStack(spacing: 8) {
            // Value display
            Text(formattedValue)
                .font(.system(size: 17, weight: .medium, design: .monospaced))
                .foregroundColor(.white)

            // Slider with appropriate style
            FullScreenSlider(
                value: Binding(
                    get: { viewModel.getValue(for: tool) },
                    set: { viewModel.setValue($0, for: tool) }
                ),
                range: tool.range,
                defaultValue: tool.defaultValue,
                style: sliderStyle
            )
        }
        .padding(.vertical, 16)
    }

    /// Multiple sliders for complex tools (Grain, Vignette, etc.)
    @ViewBuilder
    private var complexToolSliders: some View {
        VStack(spacing: 24) {
            switch tool.parameterType {
            case .grain:
                grainSliders
            case .vignette:
                vignetteSliders
            case .bloom:
                bloomSliders
            case .halation:
                halationSliders
            default:
                simpleToolSlider
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Complex Tool Sliders

    @ViewBuilder
    private var grainSliders: some View {
        LabeledSlider(
            label: "strength",
            value: Binding(
                get: { viewModel.editor.currentParameters.grain.amount },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.grain.amount = value
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )

        LabeledSlider(
            label: "size",
            value: Binding(
                get: { viewModel.editor.currentParameters.grain.size * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.grain.size = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )

        LabeledSlider(
            label: "roughness",
            value: Binding(
                get: { viewModel.editor.currentParameters.grain.roughness * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.grain.roughness = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )
    }

    @ViewBuilder
    private var vignetteSliders: some View {
        LabeledSlider(
            label: "amount",
            value: Binding(
                get: { viewModel.editor.currentParameters.vignette.amount },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.vignette.amount = value
                    viewModel.editor.currentParameters = params
                }
            ),
            range: -100...100
        )

        LabeledSlider(
            label: "midpoint",
            value: Binding(
                get: { viewModel.editor.currentParameters.vignette.midpoint * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.vignette.midpoint = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )

        LabeledSlider(
            label: "feather",
            value: Binding(
                get: { viewModel.editor.currentParameters.vignette.feather * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.vignette.feather = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )
    }

    @ViewBuilder
    private var bloomSliders: some View {
        LabeledSlider(
            label: "intensity",
            value: Binding(
                get: { viewModel.editor.currentParameters.bloom.intensity },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.bloom.intensity = value
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )

        LabeledSlider(
            label: "radius",
            value: Binding(
                get: { viewModel.editor.currentParameters.bloom.radius * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.bloom.radius = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )

        LabeledSlider(
            label: "threshold",
            value: Binding(
                get: { viewModel.editor.currentParameters.bloom.threshold * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.bloom.threshold = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )
    }

    @ViewBuilder
    private var halationSliders: some View {
        LabeledSlider(
            label: "intensity",
            value: Binding(
                get: { viewModel.editor.currentParameters.halation.intensity },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.halation.intensity = value
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )

        LabeledSlider(
            label: "hue",
            value: Binding(
                get: { viewModel.editor.currentParameters.halation.hue },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.halation.hue = value
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...360
        )

        LabeledSlider(
            label: "spread",
            value: Binding(
                get: { viewModel.editor.currentParameters.halation.spread * 100 },
                set: { value in
                    var params = viewModel.editor.currentParameters
                    params.halation.spread = value / 100
                    viewModel.editor.currentParameters = params
                }
            ),
            range: 0...100
        )
    }

    // MARK: - Helpers

    private var formattedValue: String {
        let value = viewModel.getValue(for: tool)
        let sign = value >= 0 && tool.defaultValue == 0 ? "+" : ""
        if tool.range.upperBound - tool.range.lowerBound <= 10 {
            return String(format: "%@%.2f", sign, value)
        } else {
            return String(format: "%@%.0f", sign, value)
        }
    }
}

// MARK: - Labeled Slider Component

/// Compact labeled slider for complex tools
struct LabeledSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 80, alignment: .leading)

            FullScreenSlider(
                value: $value,
                range: range,
                defaultValue: range.lowerBound
            )

            Text(String(format: "%.0f", value))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geometry in
        ToolDetailView(
            viewModel: EditorV2ViewModel(),
            tool: .grain,
            geometry: geometry
        )
    }
    .background(Color.black)
}
