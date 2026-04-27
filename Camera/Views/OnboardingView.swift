import SwiftUI

struct OnboardingView: View {
    let onComplete: (Bool) -> Void  // true = right-handed

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                VStack(spacing: 12) {
                    Text("Which hand do you shoot with?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Shutter button will be under your thumb")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                // Two shutter buttons — in thumb zone
                HStack(spacing: 48) {
                    // Left-handed
                    onboardingButton(label: "Left", isRightHanded: false)

                    // Right-handed
                    onboardingButton(label: "Right", isRightHanded: true)
                }
                .padding(.bottom, 80)
            }
        }
        .statusBarHidden()
    }

    private func onboardingButton(label: String, isRightHanded: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
            }
            onComplete(isRightHanded)
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    // Outer border
                    Capsule()
                        .stroke(CameraTheme.controlActive.opacity(0.4), lineWidth: 2.5)
                        .frame(width: 110, height: 80)

                    // Inner border
                    Capsule()
                        .stroke(CameraTheme.controlActive, lineWidth: 3)
                        .frame(width: 96, height: 66)

                    // Fill
                    Capsule()
                        .fill(CameraTheme.controlActive)
                        .frame(width: 84, height: 54)
                }

                Text(label)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(CameraTheme.controlActive)
            }
        }
    }
}
