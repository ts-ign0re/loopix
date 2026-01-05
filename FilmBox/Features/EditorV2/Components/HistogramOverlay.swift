import SwiftUI
import CoreImage

/// Semi-transparent RGB histogram overlay in Loopix style
struct HistogramOverlay: View {
    @Bindable var viewModel: EditorV2ViewModel
    @State private var histogramData: HistogramDataV2?

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                guard let data = histogramData else { return }

                let width = size.width
                let height = size.height

                // Draw each channel
                drawChannel(context: context, data: data.green, color: .green, width: width, height: height)
                drawChannel(context: context, data: data.blue, color: .blue, width: width, height: height)
                drawChannel(context: context, data: data.red, color: .red, width: width, height: height)
            }
        }
        .opacity(0.65)
        .task(id: viewModel.editor.currentImage) {
            await calculateHistogram()
        }
    }

    private func drawChannel(
        context: GraphicsContext,
        data: [Float],
        color: Color,
        width: CGFloat,
        height: CGFloat
    ) {
        guard !data.isEmpty else { return }

        let binCount = data.count
        let binWidth = width / CGFloat(binCount)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))

        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * binWidth
            let y = height - (CGFloat(value) * height)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        // Fill with gradient
        context.fill(
            path,
            with: .color(color.opacity(0.4))
        )

        // Stroke the line
        var strokePath = Path()
        strokePath.move(to: CGPoint(x: 0, y: height))
        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * binWidth
            let y = height - (CGFloat(value) * height)
            strokePath.addLine(to: CGPoint(x: x, y: y))
        }

        context.stroke(
            strokePath,
            with: .color(color.opacity(0.8)),
            lineWidth: 1
        )
    }

    private func calculateHistogram() async {
        guard let image = viewModel.editor.currentImage else {
            histogramData = nil
            return
        }

        // Calculate histogram in background
        let data = await Task.detached(priority: .userInitiated) {
            HistogramDataV2.calculate(from: image)
        }.value

        await MainActor.run {
            histogramData = data
        }
    }
}

// MARK: - Histogram Data

struct HistogramDataV2: Sendable {
    let red: [Float]
    let green: [Float]
    let blue: [Float]
    let luminance: [Float]

    static let binCount = 256

    static func calculate(from image: CIImage) -> HistogramDataV2 {
        // Scale down for faster processing
        let maxDimension: CGFloat = 256
        let scale = min(maxDimension / image.extent.width, maxDimension / image.extent.height, 1.0)
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Create context for rendering
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let extent = scaledImage.extent

        // Render to bitmap
        let width = Int(extent.width)
        let height = Int(extent.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: height * bytesPerRow)

        context.render(
            scaledImage,
            toBitmap: &pixelData,
            rowBytes: bytesPerRow,
            bounds: extent,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        // Calculate histogram bins
        var redBins = [Float](repeating: 0, count: binCount)
        var greenBins = [Float](repeating: 0, count: binCount)
        var blueBins = [Float](repeating: 0, count: binCount)
        var lumBins = [Float](repeating: 0, count: binCount)

        _ = width * height // totalPixels - reserved for future normalization

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = Int(pixelData[offset])
                let g = Int(pixelData[offset + 1])
                let b = Int(pixelData[offset + 2])

                redBins[r] += 1
                greenBins[g] += 1
                blueBins[b] += 1

                // Luminance calculation
                let lum = Int(0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))
                lumBins[min(lum, 255)] += 1
            }
        }

        // Normalize bins
        let maxRed = redBins.max() ?? 1
        let maxGreen = greenBins.max() ?? 1
        let maxBlue = blueBins.max() ?? 1
        let maxLum = lumBins.max() ?? 1

        redBins = redBins.map { $0 / maxRed }
        greenBins = greenBins.map { $0 / maxGreen }
        blueBins = blueBins.map { $0 / maxBlue }
        lumBins = lumBins.map { $0 / maxLum }

        return HistogramDataV2(
            red: redBins,
            green: greenBins,
            blue: blueBins,
            luminance: lumBins
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
        HistogramOverlay(viewModel: EditorV2ViewModel())
            .frame(height: 80)
            .padding()
    }
}
