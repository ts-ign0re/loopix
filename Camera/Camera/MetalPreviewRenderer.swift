import MetalKit
import CoreImage

/// MTKViewDelegate that renders CIImage frames with live filter + grain overlay
final class MetalPreviewRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    /// Current source frame from camera
    var currentCIImage: CIImage?

    /// Current filter to apply
    var currentFilter: CameraFilter = .clean

    /// Filter intensity (0.0 = original, 1.0 = full filter)
    var filterIntensity: Float = 1.0

    /// Grain settings
    var grainData: GrainData = .defaultCamera
    var grainEnabled: Bool = true
    var isDeviceStationary: Bool = false

    /// Reference time for grain animation — keeps Float precision high
    /// by using seconds-since-start instead of seconds-since-boot
    private let referenceTime: Double = CACurrentMediaTime()
    private var frameCount: UInt32 = 0

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
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.preferredFramesPerSecond = 30
        mtkView.colorPixelFormat = .bgra8Unorm

        super.init()
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    // swiftlint:disable:next function_body_length
    func draw(in view: MTKView) {
        guard let image = currentCIImage,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        // Apply filter
        var processed = LiveFilterPipeline.apply(currentFilter, to: image, intensity: filterIntensity)
        let profiledGrain = currentFilter.profiledGrainData(from: grainData)

        // Apply animated grain
        if grainEnabled && profiledGrain.isActive {
            frameCount &+= 1
            let elapsed = CACurrentMediaTime() - referenceTime
            let time: Float
            if isDeviceStationary {
                // When camera is still, slow grain refresh so texture is readable.
                time = Float(floor(elapsed * 2.0) / 2.0)
            } else {
                time = Float(elapsed)
            }
            if let grained = try? MetalFilterLoader.shared.applyGrain(
                to: processed,
                grainData: profiledGrain,
                time: time,
                clumpStrength: currentFilter.grainClumpBoost
            ) {
                processed = grained
            }
        }

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
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
