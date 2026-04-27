import SwiftUI

struct FocusIndicatorView: View {
    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(CameraTheme.accent, lineWidth: 1.5)
            .frame(width: CameraTheme.focusSquareSize, height: CameraTheme.focusSquareSize)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.0
                }
                withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
                    opacity = 0
                }
            }
    }
}
