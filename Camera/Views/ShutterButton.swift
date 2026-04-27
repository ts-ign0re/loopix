import SwiftUI

struct ShutterButton: View {
    let isCapturing: Bool
    let captureMode: CaptureMode
    let isRecording: Bool
    @Binding var shutterAnimating: Bool
    let action: () -> Void

    @State private var isPressed = false
    private let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticRigid = UIImpactFeedbackGenerator(style: .rigid)

    var body: some View {
        Button(
            action: {
                hapticHeavy.impactOccurred(intensity: 1.0)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    hapticRigid.impactOccurred(intensity: 0.6)
                }

                action()
            },
            label: {
                ZStack {
                    if captureMode == .photo {
                        // Border
                        Capsule()
                            .stroke(CameraTheme.controlActive, lineWidth: 3)

                        // Fill
                        Capsule()
                            .fill(CameraTheme.controlActive)
                            .padding(7)
                    } else {
                        // Video mode
                        Capsule()
                            .stroke(isRecording ? Color.red : CameraTheme.controlActive, lineWidth: 3)

                        if isRecording {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.red)
                                .padding(18)
                        } else {
                            Capsule()
                                .fill(Color.red)
                                .padding(7)
                        }
                    }
                }
                .frame(height: 64)
                .scaleEffect(shutterAnimating ? 0.8 : (isPressed ? 0.92 : 1.0))
                .opacity(shutterAnimating ? 0.7 : 1.0)
                .animation(.easeOut(duration: shutterAnimating ? 0.1 : 0.2), value: shutterAnimating)
                .animation(.easeInOut(duration: 0.08), value: isPressed)
            }
        )
        .buttonStyle(ShutterButtonStyle(isPressed: $isPressed))
        .disabled(captureMode == .photo && isCapturing)
        .onAppear {
            hapticHeavy.prepare()
            hapticRigid.prepare()
        }
    }
}

private struct ShutterButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}
