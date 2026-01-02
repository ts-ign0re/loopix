import SwiftUI

/// Horizontal bar with filter sub-parameters (Strength, Contrast, Color, Tone)
struct FilterParameterBar: View {
    @Bindable var viewModel: EditorV2ViewModel
    @Binding var selectedParameter: EditorV2ViewModel.FilterSubParameter

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorV2ViewModel.FilterSubParameter.allCases) { param in
                parameterButton(for: param)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func parameterButton(for param: EditorV2ViewModel.FilterSubParameter) -> some View {
        let isSelected = selectedParameter == param
        let value = viewModel.getFilterSubValue(for: param)
        let hasValue = param == .strength ? value != 75 : value != 0

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedParameter = param
            }
        } label: {
            VStack(spacing: 6) {
                // Icon
                Image(systemName: param.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .gray)

                // Label
                Text(param.rawValue.lowercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .gray)

                // Value indicator dot
                Circle()
                    .fill(hasValue ? Color.yellow : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    FilterParameterBar(
        viewModel: EditorV2ViewModel(),
        selectedParameter: .constant(.strength)
    )
    .background(Color.black)
}
