import SwiftUI

// MARK: - Histogram Channel

/// Histogram display channels
enum HistogramChannel: String, CaseIterable, Identifiable {
    case rgb = "RGB"
    case red = "R"
    case green = "G"
    case blue = "B"
    case luminance = "L"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .rgb: return .white
        case .red: return .fbHistogramRed
        case .green: return .fbHistogramGreen
        case .blue: return .fbHistogramBlue
        case .luminance: return .fbHistogramLuminance
        }
    }
}

// MARK: - Histogram View

/// RGB histogram view for photo analysis
struct FBHistogram: View {

    // MARK: - Properties

    /// Histogram data (256 values per channel, normalized 0-1)
    let data: HistogramDisplayData?

    /// Which channels to display
    var channels: Set<HistogramChannel> = [.red, .green, .blue]

    /// Whether to show channel selector
    var showChannelSelector: Bool = false

    /// Height of the histogram
    var height: CGFloat = 80

    // MARK: - State

    @State private var selectedChannels: Set<HistogramChannel> = [.red, .green, .blue]

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if showChannelSelector {
                channelSelector
            }

            histogramContent
                .frame(height: height)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
        }
    }

    // MARK: - Channel Selector

    private var channelSelector: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(HistogramChannel.allCases) { channel in
                channelButton(channel)
            }
            Spacer()
        }
    }

    private func channelButton(_ channel: HistogramChannel) -> some View {
        Button {
            Haptics.shared.selection()
            if selectedChannels.contains(channel) {
                selectedChannels.remove(channel)
            } else {
                selectedChannels.insert(channel)
            }
        } label: {
            Text(channel.rawValue)
                .font(.fbCaption2.weight(.medium))
                .foregroundStyle(selectedChannels.contains(channel) ? channel.color : .fbLabelTertiary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(selectedChannels.contains(channel) ? channel.color.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Histogram Content

    @ViewBuilder
    private var histogramContent: some View {
        if let data = data {
            GeometryReader { geometry in
                ZStack {
                    // Draw each selected channel
                    if selectedChannels.contains(.red) || selectedChannels.contains(.rgb) {
                        histogramPath(data: data.red, color: .fbHistogramRed, size: geometry.size)
                    }

                    if selectedChannels.contains(.green) || selectedChannels.contains(.rgb) {
                        histogramPath(data: data.green, color: .fbHistogramGreen, size: geometry.size)
                    }

                    if selectedChannels.contains(.blue) || selectedChannels.contains(.rgb) {
                        histogramPath(data: data.blue, color: .fbHistogramBlue, size: geometry.size)
                    }

                    if selectedChannels.contains(.luminance) {
                        histogramPath(data: data.luminance, color: .fbHistogramLuminance, size: geometry.size)
                    }
                }
            }
        } else {
            // Loading state
            ZStack {
                Color.clear

                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Path Drawing

    private func histogramPath(data: [Float], color: Color, size: CGSize) -> some View {
        Path { path in
            guard !data.isEmpty else { return }

            let binCount = data.count
            let binWidth = size.width / CGFloat(binCount)

            path.move(to: CGPoint(x: 0, y: size.height))

            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * binWidth
                let y = size.height * (1 - CGFloat(value))
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
        }
        .fill(color.opacity(0.5))
        .blendMode(.screen)
    }
}

// MARK: - Histogram Display Data

/// Data structure for histogram display
struct HistogramDisplayData {
    let red: [Float]
    let green: [Float]
    let blue: [Float]
    let luminance: [Float]

    static let empty = HistogramDisplayData(
        red: Array(repeating: 0, count: 256),
        green: Array(repeating: 0, count: 256),
        blue: Array(repeating: 0, count: 256),
        luminance: Array(repeating: 0, count: 256)
    )

    /// Generate sample data for preview
    static var sample: HistogramDisplayData {
        func generateCurve(peak: Float, spread: Float) -> [Float] {
            (0..<256).map { i in
                let x = Float(i) / 255.0
                let diff = x - peak
                return exp(-diff * diff / (2 * spread * spread))
            }
        }

        return HistogramDisplayData(
            red: generateCurve(peak: 0.4, spread: 0.15),
            green: generateCurve(peak: 0.5, spread: 0.18),
            blue: generateCurve(peak: 0.6, spread: 0.12),
            luminance: generateCurve(peak: 0.5, spread: 0.2)
        )
    }
}

// MARK: - Compact Histogram

/// Compact histogram for toolbar display
struct FBCompactHistogram: View {

    let data: HistogramDisplayData?
    var width: CGFloat = 60
    var height: CGFloat = 24

    var body: some View {
        FBHistogram(data: data, channels: [.luminance], height: height)
            .frame(width: width, height: height)
    }
}

// MARK: - Preview

#Preview("Histogram") {
    VStack(spacing: Spacing.lg) {
        Text("Full Histogram")
            .font(.headline)

        FBHistogram(data: .sample, showChannelSelector: true)
            .frame(height: 100)

        Divider()

        Text("Compact Histogram")
            .font(.headline)

        FBCompactHistogram(data: .sample)

        Divider()

        Text("Loading State")
            .font(.headline)

        FBHistogram(data: nil)
            .frame(height: 80)
    }
    .padding()
    .background(Color.fbBackground)
}
