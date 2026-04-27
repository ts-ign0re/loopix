import SwiftUI

struct CameraControlsOverlay: View {
    let state: CameraState
    let cameraManager: CameraManager

    var body: some View {
        Button {
            let newLock = !(state.isFocusLocked && state.isExposureLocked)
            state.isFocusLocked = newLock
            state.isExposureLocked = newLock
            cameraManager.setFocusLock(newLock)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: state.isFocusLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 16))
                Text("AE/AF")
                    .font(CameraTheme.captionFont)
            }
            .foregroundColor(state.isFocusLocked ? CameraTheme.controlActive : CameraTheme.textSecondary)
        }
    }
}
