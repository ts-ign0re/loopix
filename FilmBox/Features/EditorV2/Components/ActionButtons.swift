import SwiftUI

/// Cancel and confirm action buttons for detail views
struct ActionButtons: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Confirm button
            Button(action: onConfirm) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
    }
}

/// Compact action buttons row with filter/tool name in center
struct ActionButtonsWithTitle: View {
    let title: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Title in center
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(.white)

            Spacer()

            // Confirm button
            Button(action: onConfirm) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ActionButtons(
            onCancel: {},
            onConfirm: {}
        )

        ActionButtonsWithTitle(
            title: "A6 PRO / Analog",
            onCancel: {},
            onConfirm: {}
        )
    }
    .padding()
    .background(Color.black)
}
