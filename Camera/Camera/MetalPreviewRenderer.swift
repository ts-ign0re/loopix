import MetalKit
import CoreImage

/// Temporary freeze instrumentation: counts every preview pipeline stage and
/// prints a summary to stderr once per second (driven by the capture callback).
/// Remove once the freeze investigation closes.
enum PreviewDiag {
    nonisolated(unsafe) static var captured = 0
    nonisolated(unsafe) static var deliveryDropped = 0
    nonisolated(unsafe) static var delivered = 0
    nonisolated(unsafe) static var drawCalls = 0
    nonisolated(unsafe) static var gateDropped = 0
    nonisolated(unsafe) static var earlyExit = 0
    nonisolated(unsafe) static var submitted = 0
    nonisolated(unsafe) static var completed = 0
    nonisolated(unsafe) private static var lastReport: Double = 0

    static func reportIfDue() {
        let now = CACurrentMediaTime()
        guard now - lastReport >= 1.0 else { return }
        lastReport = now
        let line = "PreviewDiag cap=\(captured) delDrop=\(deliveryDropped) del=\(delivered) " +
            "draw=\(drawCalls) gateDrop=\(gateDropped) early=\(earlyExit) " +
            "sub=\(submitted) done=\(completed)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}

/// MTKViewDelegate that renders CIImage frames with the live filter applied
final class MetalPreviewRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    private let inFlightGate = DispatchSemaphore(value: 2)

    /// Current source frame from camera
    var currentCIImage: CIImage?

    /// Current filter to apply
    var currentFilter: CameraFilter = .clean

    /// Filter intensity (0.0 = original, 1.0 = full filter)
    var filterIntensity: Float = 1.0

    init?(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.ciContext = CIContext(mtlDevice: device, options: [
            .cacheIntermediates: false,
            .priorityRequestLow: false
        ])

        mtkView.device = device
        mtkView.framebufferOnly = false
        // ponytail: event-driven — one camera frame triggers one redraw, so the view
        // never re-renders a stale frame and GPU work can't outpace the capture rate.
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.colorPixelFormat = .bgra8Unorm

        super.init()
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        autoreleasepool {
            drawFrame(in: view)
        }
    }

    private func drawFrame(in view: MTKView) {
        PreviewDiag.drawCalls += 1
        let gate = inFlightGate
        guard gate.wait(timeout: .now()) == .success else {
            PreviewDiag.gateDropped += 1
            return
        }
        var submitted = false
        defer {
            if !submitted {
                gate.signal()
            }
        }

        guard let image = currentCIImage,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            PreviewDiag.earlyExit += 1
            return
        }

        // Apply filter. Grain is photo-only: the Metal grain path renders black
        // frames in the live preview on current iOS, so preview skips it.
        let processed = LiveFilterPipeline.apply(currentFilter, to: image, intensity: filterIntensity)

        // Scale to fill the drawable (crops edges, no black bars)
        let drawableSize = view.drawableSize
        let imageExtent = processed.extent

        let scaleX = drawableSize.width / imageExtent.width
        let scaleY = drawableSize.height / imageExtent.height
        let scale = max(scaleX, scaleY)

        let scaledWidth = imageExtent.width * scale
        let scaledHeight = imageExtent.height * scale
        let offsetX = (drawableSize.width - scaledWidth) / 2
        let offsetY = (drawableSize.height - scaledHeight) / 2

        let scaledImage = processed
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

        let destination = CIRenderDestination(
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            pixelFormat: view.colorPixelFormat,
            commandBuffer: commandBuffer,
            mtlTextureProvider: { drawable.texture }
        )

        do {
            try self.ciContext.startTask(toRender: scaledImage, to: destination)
        } catch {
            print("MetalPreviewRenderer: render error: \(error)")
            return
        }

        commandBuffer.addCompletedHandler { _ in
            PreviewDiag.completed += 1
            gate.signal()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        submitted = true
        PreviewDiag.submitted += 1
    }
}
