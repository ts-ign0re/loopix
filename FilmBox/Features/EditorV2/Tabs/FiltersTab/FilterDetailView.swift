import SwiftUI

/// Full-screen filter detail view for adjusting filter parameters
struct FilterDetailView: View {
    @Bindable var viewModel: EditorV2ViewModel
    let geometry: GeometryProxy

    @State private var selectedParameter: EditorV2ViewModel.FilterSubParameter = .strength

    var body: some View {
        VStack(spacing: 0) {
            // Image preview with histogram
            LoopixImagePreview(
                viewModel: viewModel,
                showHistogram: true,
                showIntensitySlider: false
            )
            .frame(height: geometry.size.height * 0.55)

            Spacer()

            // Parameter bar
            FilterParameterBar(
                viewModel: viewModel,
                selectedParameter: $selectedParameter
            )

            // Slider for selected parameter
            VStack(spacing: 8) {
                // Value display
                Text(formattedValue(for: selectedParameter))
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                // Slider
                FullScreenSlider(
                    value: Binding(
                        get: { viewModel.getFilterSubValue(for: selectedParameter) },
                        set: { viewModel.setFilterSubValue($0, for: selectedParameter) }
                    ),
                    range: viewModel.getFilterSubRange(for: selectedParameter),
                    defaultValue: selectedParameter == .strength ? 75 : 0
                )
            }
            .padding(.vertical, 16)

            // Bottom controls: X - Filter name - ✓
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

                // Filter name
                Text(viewModel.filterDisplayName.lowercased())
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

    private func formattedValue(for param: EditorV2ViewModel.FilterSubParameter) -> String {
        let value = viewModel.getFilterSubValue(for: param)
        switch param {
        case .strength:
            return String(format: "%.0f%%", value)
        default:
            let sign = value >= 0 ? "+" : ""
            return String(format: "%@%.0f", sign, value)
        }
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geometry in
        FilterDetailView(
            viewModel: EditorV2ViewModel(),
            geometry: geometry
        )
    }
    .background(Color.black)
}
