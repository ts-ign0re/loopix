import SwiftUI
import CoreImage

// MARK: - Histogram Display Mode

/// Display modes for the histogram
enum HistogramDisplayMode: String, CaseIterable, Identifiable {
    case rgb = "RGB"
    case luminance = "Luminance"
    case channels = "Channels"

    var id: String { rawValue }
}

// MARK: - Histogram View

/// RGB histogram display showing luminance and individual R, G, B channels
/// Updates automatically with image changes
struct HistogramView: View {

    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    /// Display mode for the histogram
    @State private var displayMode: HistogramDisplayMode = .rgb

    /// Cached histogram data
    @State private var histogramData: HistogramData?

    /// Whether histogram is currently calculating
    @State private var isCalculating: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            // Mode selector (optional, can be hidden)
            // modeSelector

            // Histogram display
            histogramCanvas
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .task(id: viewModel.currentImage) {
            await updateHistogram()
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(HistogramDisplayMode.allCases) { mode in
                Button {
                    displayMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(displayMode == mode ? .white : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if isCalculating {
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Histogram Canvas

    private var histogramCanvas: some View {
        Canvas { context, size in
            var ctx = context
            guard let data = histogramData else {
                drawPlaceholder(context: ctx, size: size)
                return
            }

            switch displayMode {
            case .rgb:
                drawRGBHistogram(context: ctx, size: size, data: data)
            case .luminance:
                drawLuminanceHistogram(context: ctx, size: size, data: data)
            case .channels:
                drawSeparateChannels(context: &ctx, size: size, data: data)
            }
        }
    }

    // MARK: - Drawing Functions

    /// Draw placeholder when no data available
    private func drawPlaceholder(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(rect),
            with: .color(.white.opacity(0.05))
        )
    }

    /// Draw RGB histogram with overlapping channels
    private func drawRGBHistogram(context: GraphicsContext, size: CGSize, data: HistogramData) {
        let binCount = data.red.count
        let binWidth = size.width / CGFloat(binCount)

        // Draw each channel with blend mode
        // Red channel
        drawChannelPath(
            context: context,
            size: size,
            values: data.red,
            color: .red.opacity(0.5),
            binWidth: binWidth
        )

        // Green channel
        drawChannelPath(
            context: context,
            size: size,
            values: data.green,
            color: .green.opacity(0.5),
            binWidth: binWidth
        )

        // Blue channel
        drawChannelPath(
            context: context,
            size: size,
            values: data.blue,
            color: .blue.opacity(0.5),
            binWidth: binWidth
        )
    }

    /// Draw luminance-only histogram
    private func drawLuminanceHistogram(context: GraphicsContext, size: CGSize, data: HistogramData) {
        let binCount = data.luminance.count
        let binWidth = size.width / CGFloat(binCount)

        drawChannelPath(
            context: context,
            size: size,
            values: data.luminance,
            color: .white.opacity(0.7),
            binWidth: binWidth
        )
    }

    /// Draw separate R, G, B channel histograms stacked
    private func drawSeparateChannels(context: inout GraphicsContext, size: CGSize, data: HistogramData) {
        let channelHeight = size.height / 3
        let binCount = data.red.count
        let binWidth = size.width / CGFloat(binCount)

        // Red (top)
        context.translateBy(x: 0, y: 0)
        drawChannelPath(
            context: context,
            size: CGSize(width: size.width, height: channelHeight),
            values: data.red,
            color: .red.opacity(0.7),
            binWidth: binWidth
        )

        // Green (middle)
        context.translateBy(x: 0, y: channelHeight)
        drawChannelPath(
            context: context,
            size: CGSize(width: size.width, height: channelHeight),
            values: data.green,
            color: .green.opacity(0.7),
            binWidth: binWidth
        )

        // Blue (bottom)
        context.translateBy(x: 0, y: channelHeight)
        drawChannelPath(
            context: context,
            size: CGSize(width: size.width, height: channelHeight),
            values: data.blue,
            color: .blue.opacity(0.7),
            binWidth: binWidth
        )
    }

    /// Draw a single channel histogram path
    private func drawChannelPath(
        context: GraphicsContext,
        size: CGSize,
        values: [Float],
        color: Color,
        binWidth: CGFloat
    ) {
        var path = Path()

        // Start at bottom-left
        path.move(to: CGPoint(x: 0, y: size.height))

        // Add points for each bin
        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * binWidth + binWidth / 2
            let y = size.height * (1 - CGFloat(value))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close path at bottom-right
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()

        // Fill with gradient
        let gradient = Gradient(colors: [color, color.opacity(0.3)])
        context.fill(
            path,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: size.height)
            )
        )
    }

    // MARK: - Update

    private func updateHistogram() async {
        isCalculating = true
        defer { isCalculating = false }

        histogramData = await viewModel.calculateHistogram()
    }
}

// MARK: - Standalone Histogram View

/// Standalone histogram view that takes CIImage directly
struct StandaloneHistogramView: View {

    let image: CIImage?
    let displayMode: HistogramDisplayMode

    @State private var histogramData: HistogramData?
    @State private var isCalculating: Bool = false

    private let ciContext: CIContext = {
        if let device = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: device)
        }
        return CIContext()
    }()

    var body: some View {
        Canvas { context, size in
            guard let data = histogramData else {
                return
            }

            let binCount = data.luminance.count
            let binWidth = size.width / CGFloat(binCount)

            switch displayMode {
            case .rgb:
                drawRGBOverlay(context: context, size: size, data: data, binWidth: binWidth)
            case .luminance:
                drawLuminance(context: context, size: size, data: data, binWidth: binWidth)
            case .channels:
                drawRGBOverlay(context: context, size: size, data: data, binWidth: binWidth)
            }
        }
        .task(id: image) {
            await calculateHistogram()
        }
    }

    private func drawRGBOverlay(context: GraphicsContext, size: CGSize, data: HistogramData, binWidth: CGFloat) {
        // Draw channels
        for (values, color) in [(data.red, Color.red), (data.green, Color.green), (data.blue, Color.blue)] {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))

            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * binWidth
                let y = size.height * (1 - CGFloat(value))
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()

            context.fill(path, with: .color(color.opacity(0.4)))
        }
    }

    private func drawLuminance(context: GraphicsContext, size: CGSize, data: HistogramData, binWidth: CGFloat) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))

        for (index, value) in data.luminance.enumerated() {
            let x = CGFloat(index) * binWidth
            let y = size.height * (1 - CGFloat(value))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()

        let gradient = Gradient(colors: [.white.opacity(0.6), .white.opacity(0.2)])
        context.fill(
            path,
            with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )
    }

    private func calculateHistogram() async {
        guard let image = image else {
            histogramData = nil
            return
        }

        isCalculating = true
        defer { isCalculating = false }

        histogramData = await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) { [ciContext] in
                let data = HistogramData.calculate(from: image, context: ciContext)
                continuation.resume(returning: data)
            }
        }
    }
}

// MARK: - Mini Histogram

/// Compact histogram for inline display
struct MiniHistogramView: View {

    let data: HistogramData?
    let showRGB: Bool

    init(data: HistogramData?, showRGB: Bool = true) {
        self.data = data
        self.showRGB = showRGB
    }

    var body: some View {
        Canvas { context, size in
            guard let data = data else { return }

            let binCount = data.luminance.count
            let binWidth = size.width / CGFloat(binCount)

            if showRGB {
                // Draw RGB overlay
                for (values, color) in [
                    (data.red, Color.red.opacity(0.4)),
                    (data.green, Color.green.opacity(0.4)),
                    (data.blue, Color.blue.opacity(0.4))
                ] {
                    drawChannel(context: context, size: size, values: values, color: color, binWidth: binWidth)
                }
            } else {
                // Draw luminance only
                drawChannel(
                    context: context,
                    size: size,
                    values: data.luminance,
                    color: .white.opacity(0.5),
                    binWidth: binWidth
                )
            }
        }
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private func drawChannel(
        context: GraphicsContext,
        size: CGSize,
        values: [Float],
        color: Color,
        binWidth: CGFloat
    ) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))

        for (index, value) in values.enumerated() {
            let x = CGFloat(index) * binWidth
            let y = size.height * (1 - CGFloat(value))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()

        context.fill(path, with: .color(color))
    }
}

// MARK: - Previews

#Preview("Histogram View") {
    struct PreviewWrapper: View {
        // Create mock histogram data
        let mockData = HistogramData(
            red: (0..<256).map { Float.random(in: 0...1) * sin(Float($0) / 256 * .pi) },
            green: (0..<256).map { Float.random(in: 0...1) * sin(Float($0) / 256 * .pi + 0.5) },
            blue: (0..<256).map { Float.random(in: 0...1) * sin(Float($0) / 256 * .pi + 1.0) },
            luminance: (0..<256).map { Float.random(in: 0...1) * sin(Float($0) / 256 * .pi) }
        )

        var body: some View {
            VStack(spacing: 16) {
                MiniHistogramView(data: mockData, showRGB: true)
                    .frame(height: 60)

                MiniHistogramView(data: mockData, showRGB: false)
                    .frame(height: 60)
            }
            .padding()
            .background(Color.black)
        }
    }

    return PreviewWrapper()
}
