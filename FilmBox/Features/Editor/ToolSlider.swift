import SwiftUI

// MARK: - Tool Slider

/// A custom slider control for photo editing parameters
struct ToolSlider: View {

    // MARK: - Properties

    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let defaultValue: Float

    @State private var isEditing: Bool = false

    // MARK: - Computed Properties

    private var displayValue: String {
        String(format: "%.0f", value)
    }

    private var normalizedValue: Double {
        get {
            Double((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        }
        set {
            value = Float(newValue) * (range.upperBound - range.lowerBound) + range.lowerBound
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            // Label and value display
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                HStack(spacing: 8) {
                    Text(displayValue)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(isEditing ? .yellow : .white.opacity(0.7))
                        .frame(minWidth: 40, alignment: .trailing)

                    // Reset button (shown when value differs from default)
                    if abs(value - defaultValue) > 0.001 {
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                value = defaultValue
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Slider
            Slider(value: $value, in: range) { editing in
                isEditing = editing
            }
            .tint(.yellow)
        }
    }
}

// MARK: - Preview

#Preview("Tool Slider") {
    @Previewable @State var exposureValue: Float = 0

    VStack(spacing: 24) {
        ToolSlider(
            label: "Exposure",
            value: $exposureValue,
            range: -2...2,
            defaultValue: 0
        )

        ToolSlider(
            label: "Contrast",
            value: .constant(25),
            range: -100...100,
            defaultValue: 0
        )

        ToolSlider(
            label: "Saturation",
            value: .constant(-50),
            range: -100...100,
            defaultValue: 0
        )
    }
    .padding()
    .background(Color.black)
}
