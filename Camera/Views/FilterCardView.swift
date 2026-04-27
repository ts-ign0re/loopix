import SwiftUI

struct FilterCardView: View {
    let filter: CameraFilter
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Grain texture overlay
                    if filter.id != "clean" {
                        GrainOverlay(seed: abs(filter.id.hashValue))
                            .blendMode(.overlay)
                            .opacity(0.35)
                    }

                    // Bottom scrim for text readability
                    VStack(spacing: 0) {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 44)
                    }

                    // Text content
                    VStack(alignment: .leading, spacing: 0) {
                        Text(filter.tagline)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)

                        Spacer()

                        Text(filter.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                    // Color bar at very bottom
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(Array(paletteBarColors.enumerated()), id: \.offset) { _, color in
                                color.frame(height: 8)
                            }
                        }
                    }
                }

                // Lock icon
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                        .padding(8)
                }
            }
            .frame(width: 160, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.white : Color(white: 0.2),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .opacity(isLocked ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card gradient from filter color parameters

    private var gradientColors: [Color] {
        if filter.id == "clean" {
            return [Color(white: 0.1), Color(white: 0.14), Color(white: 0.16)]
        }

        if filter.isMonochrome {
            let hue = filter.shadowTintStrength > 0
                ? Double(filter.shadowHue) / 360
                : 0.08
            let sat = filter.shadowTintStrength > 0 ? 0.15 : 0.05
            return [
                Color(hue: hue, saturation: sat, brightness: 0.15),
                Color(hue: hue, saturation: sat * 0.7, brightness: 0.25),
                Color(hue: hue, saturation: sat * 0.4, brightness: 0.32)
            ]
        }

        let sHue = Double(filter.shadowHue) / 360
        let hHue = Double(filter.highlightHue) / 360
        let satBoost = Double(max(0, filter.saturation)) / 100 * 0.2
        let baseSat = 0.5 + satBoost

        return [
            Color(hue: sHue, saturation: min(0.85, baseSat + 0.15), brightness: 0.28),
            Color(hue: hueMiddle(sHue, hHue), saturation: baseSat, brightness: 0.38),
            Color(hue: hHue, saturation: min(0.8, baseSat + 0.05), brightness: 0.48)
        ]
    }

    /// Shortest-path midpoint between two hues on the color wheel
    private func hueMiddle(_ h1: Double, _ h2: Double) -> Double {
        var diff = h2 - h1
        if diff > 0.5 { diff -= 1 }
        if diff < -0.5 { diff += 1 }
        var mid = h1 + diff / 2
        if mid < 0 { mid += 1 }
        if mid >= 1 { mid -= 1 }
        return mid
    }

    // MARK: - Color bar at bottom edge

    private var paletteBarColors: [Color] {
        if filter.id == "clean" {
            return [Color(white: 0.4), Color(white: 0.55)]
        }

        if filter.isMonochrome && filter.contrast > 20 {
            return [Color(white: 0.15), Color(white: 0.85)]
        }

        if filter.isMonochrome {
            let hue = filter.shadowTintStrength > 0
                ? Double(filter.shadowHue) / 360 : 0.08
            return [
                Color(hue: hue, saturation: 0.3, brightness: 0.3),
                Color(hue: hue, saturation: 0.15, brightness: 0.6)
            ]
        }

        let sHue = Double(filter.shadowHue) / 360
        let hHue = Double(filter.highlightHue) / 360
        let sSat = min(Double(filter.shadowTintStrength) * 14 + 0.25, 0.85)
        let hSat = min(Double(filter.highlightTintStrength) * 14 + 0.25, 0.85)

        return [
            Color(hue: sHue, saturation: sSat, brightness: 0.5),
            Color(hue: hueMiddle(sHue, hHue), saturation: (sSat + hSat) / 2, brightness: 0.55),
            Color(hue: hHue, saturation: hSat, brightness: 0.65)
        ]
    }
}

// MARK: - Grain Texture Overlay

private struct GrainOverlay: View {
    let seed: Int

    var body: some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }
            var rng = UInt64(bitPattern: Int64(seed) &+ 12345)
            let w = UInt64(max(1, size.width))
            let h = UInt64(max(1, size.height))

            for _ in 0..<400 {
                rng = rng &* 6364136223846793005 &+ 1442695040888963407
                let x = CGFloat((rng >> 16) % w)
                rng = rng &* 6364136223846793005 &+ 1442695040888963407
                let y = CGFloat((rng >> 16) % h)
                rng = rng &* 6364136223846793005 &+ 1442695040888963407
                let val = Double((rng >> 16) % 100) / 100
                let color: Color = val > 0.5 ? .white : .black
                let opacity = abs(val - 0.5) * 0.7
                let dotSize: CGFloat = val > 0.75 ? 2.0 : 1.0

                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: dotSize, height: dotSize)),
                    with: .color(color.opacity(opacity))
                )
            }
        }
        .drawingGroup()
    }
}
