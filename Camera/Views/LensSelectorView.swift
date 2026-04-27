import SwiftUI

struct LensSelectorView: View {
    let lenses: [LensInfo]
    @Binding var selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: CameraTheme.paddingLarge) {
            ForEach(Array(lenses.enumerated()), id: \.element.id) { index, lens in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedIndex = index
                    }
                    onSelect(index)
                } label: {
                    Text(lens.displayName)
                        .font(CameraTheme.captionFont)
                        .foregroundColor(index == selectedIndex ? CameraTheme.background : CameraTheme.text)
                        .frame(width: CameraTheme.lensButtonSize, height: CameraTheme.lensButtonSize)
                        .background(
                            Circle()
                                .fill(index == selectedIndex ? CameraTheme.pillSelected : CameraTheme.pillBackground)
                        )
                }
            }
        }
        .frame(height: CameraTheme.lensButtonSize + CameraTheme.paddingSmall)
    }
}
