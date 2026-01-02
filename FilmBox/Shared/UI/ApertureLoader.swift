import SwiftUI

/// Rotating aperture loader inspired by the app logo
struct ApertureLoader: View {
    @State private var rotation: Double = 0

    let size: CGFloat
    let color: Color
    let lineWidth: CGFloat

    init(size: CGFloat = 40, color: Color = .white, lineWidth: CGFloat = 2) {
        self.size = size
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(color, lineWidth: lineWidth)

            // Aperture blades
            ApertureShape()
                .stroke(color, lineWidth: lineWidth)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

/// Shape that draws 6 aperture blades
struct ApertureShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.85
        let innerRadius = radius * 0.35
        let bladeCount = 6

        for i in 0..<bladeCount {
            let startAngle = Double(i) * (360.0 / Double(bladeCount)) - 90
            let endAngle = startAngle + 40

            // Start point on inner circle
            let startRad = startAngle * .pi / 180
            let endRad = endAngle * .pi / 180

            let innerStart = CGPoint(
                x: center.x + innerRadius * cos(startRad),
                y: center.y + innerRadius * sin(startRad)
            )

            let outerEnd = CGPoint(
                x: center.x + radius * cos(endRad),
                y: center.y + radius * sin(endRad)
            )

            // Draw blade line
            path.move(to: innerStart)
            path.addLine(to: outerEnd)
        }

        return path
    }
}

/// Full-screen processing overlay with aperture loader
struct ProcessingOverlay: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ApertureLoader(size: 48, color: .white, lineWidth: 2.5)

                if let message {
                    Text(message)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}

#Preview("Aperture Loader") {
    ZStack {
        Color.black
        ApertureLoader(size: 60, color: .yellow)
    }
}

#Preview("Processing Overlay") {
    ProcessingOverlay(message: "processing...")
}
