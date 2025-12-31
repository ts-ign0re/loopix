import SwiftUI
import CoreImage
import MetalKit

// MARK: - Image Preview

/// SwiftUI view for displaying and interacting with the edited image
/// Supports pinch to zoom, pan gestures, and uses Metal for GPU-accelerated rendering
struct ImagePreview: View {

    // MARK: - Properties

    let image: CIImage

    @Binding var zoomScale: CGFloat
    @Binding var panOffset: CGSize

    /// Minimum zoom scale
    private let minZoom: CGFloat = 1.0

    /// Maximum zoom scale
    private let maxZoom: CGFloat = 5.0

    /// State for tracking gesture
    @GestureState private var gestureZoom: CGFloat = 1.0
    @GestureState private var gesturePan: CGSize = .zero

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            MetalImageView(image: image)
                .scaleEffect(zoomScale * gestureZoom)
                .offset(x: panOffset.width + gesturePan.width,
                        y: panOffset.height + gesturePan.height)
                .gesture(zoomGesture)
                .gesture(panGesture)
                .gesture(doubleTapGesture(in: geometry))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .contentShape(Rectangle())
        }
    }

    // MARK: - Gestures

    /// Pinch to zoom gesture
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newZoom = zoomScale * value
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    zoomScale = min(max(newZoom, minZoom), maxZoom)

                    // Reset pan if zoomed out to minimum
                    if zoomScale <= minZoom {
                        panOffset = .zero
                    }
                }
            }
    }

    /// Pan gesture for dragging the image
    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { value, state, _ in
                guard zoomScale > minZoom else { return }
                state = value.translation
            }
            .onEnded { value in
                guard zoomScale > minZoom else { return }
                panOffset = CGSize(
                    width: panOffset.width + value.translation.width,
                    height: panOffset.height + value.translation.height
                )
            }
    }

    /// Double tap to toggle between fit and 100% zoom
    private func doubleTapGesture(in geometry: GeometryProxy) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if zoomScale > minZoom {
                        zoomScale = minZoom
                        panOffset = .zero
                    } else {
                        zoomScale = 2.0
                    }
                }
            }
    }
}

// MARK: - Metal Image View

/// UIViewRepresentable wrapper for MTKView to render CIImage using Metal
struct MetalImageView: UIViewRepresentable {

    let image: CIImage

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        mtkView.framebufferOnly = false
        mtkView.backgroundColor = .clear
        mtkView.contentMode = .scaleAspectFit

        // Set up Metal device
        if let device = MTLCreateSystemDefaultDevice() {
            mtkView.device = device
            mtkView.colorPixelFormat = .bgra8Unorm
            context.coordinator.setup(device: device)
        }

        return mtkView
    }

    func updateUIView(_ mtkView: MTKView, context: Context) {
        context.coordinator.image = image
        mtkView.setNeedsDisplay()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MTKViewDelegate {

        var image: CIImage?
        private var ciContext: CIContext?
        private var commandQueue: MTLCommandQueue?
        private var device: MTLDevice?

        func setup(device: MTLDevice) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()
            self.ciContext = CIContext(mtlDevice: device, options: [
                .cacheIntermediates: false,
                .priorityRequestLow: false,
                .highQualityDownsample: true
            ])
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size changes if needed
        }

        func draw(in view: MTKView) {
            guard let image = image,
                  let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let ciContext = ciContext else {
                return
            }

            let drawableSize = view.drawableSize
            let imageSize = image.extent.size

            // Calculate scale to fit image in view while maintaining aspect ratio
            let scaleX = drawableSize.width / imageSize.width
            let scaleY = drawableSize.height / imageSize.height
            let scale = min(scaleX, scaleY)

            // Calculate centered position
            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            let offsetX = (drawableSize.width - scaledWidth) / 2
            let offsetY = (drawableSize.height - scaledHeight) / 2

            // Transform image to fit in view
            var transformedImage = image
                .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

            // Create destination bounds
            let bounds = CGRect(origin: .zero, size: drawableSize)

            // Create background color
            let backgroundColor = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
            let backgroundImage = CIImage(color: backgroundColor).cropped(to: bounds)

            // Composite image over background
            transformedImage = transformedImage.composited(over: backgroundImage)

            // Render to drawable
            ciContext.render(
                transformedImage,
                to: drawable.texture,
                commandBuffer: commandBuffer,
                bounds: bounds,
                colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            )

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

// MARK: - Image Preview with CALayer (Alternative)

/// Alternative implementation using CALayer for simpler rendering
/// Use this if Metal is not required or for compatibility
struct CALayerImagePreview: UIViewRepresentable {

    let image: CIImage

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit

        let imageLayer = CALayer()
        imageLayer.contentsGravity = .resizeAspect
        imageLayer.backgroundColor = UIColor.clear.cgColor
        view.layer.addSublayer(imageLayer)

        context.coordinator.imageLayer = imageLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let imageLayer = context.coordinator.imageLayer else { return }

        // Update layer frame
        imageLayer.frame = uiView.bounds

        // Render CIImage to CGImage
        if let cgImage = ciContext.createCGImage(image, from: image.extent) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            imageLayer.contents = cgImage
            CATransaction.commit()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var imageLayer: CALayer?
    }
}

// MARK: - Before/After Comparison View

/// View for showing before/after comparison with slider
struct BeforeAfterComparisonView: View {

    let originalImage: CIImage
    let editedImage: CIImage

    @State private var sliderPosition: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Edited image (full)
                MetalImageView(image: editedImage)

                // Original image (clipped)
                MetalImageView(image: originalImage)
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                            Spacer(minLength: 0)
                        }
                    )

                // Slider line and handle
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: geometry.size.width * sliderPosition - 2)

                    Rectangle()
                        .fill(.white)
                        .frame(width: 4)
                        .overlay {
                            Circle()
                                .fill(.white)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "arrow.left.and.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                        }

                    Spacer(minLength: 0)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPosition = value.location.x / geometry.size.width
                            sliderPosition = min(max(newPosition, 0.05), 0.95)
                        }
                )

                // Labels
                VStack {
                    Spacer()
                    HStack {
                        Text("BEFORE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.leading, 16)

                        Spacer()

                        Text("AFTER")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.6))
                            .clipShape(Capsule())
                            .padding(.trailing, 16)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Zoom Info Overlay

/// Overlay showing current zoom level
struct ZoomInfoOverlay: View {

    let zoomScale: CGFloat
    @State private var isVisible: Bool = false

    var body: some View {
        Group {
            if isVisible {
                Text("\(Int(zoomScale * 100))%")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .transition(.opacity)
            }
        }
        .onChange(of: zoomScale) { _, _ in
            withAnimation(.easeIn(duration: 0.1)) {
                isVisible = true
            }

            // Hide after delay
            Task {
                try? await Task.sleep(for: .seconds(1))
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Image Preview") {
    if let uiImage = UIImage(systemName: "photo.fill"),
       let ciImage = CIImage(image: uiImage) {
        ImagePreview(
            image: ciImage,
            zoomScale: .constant(1.0),
            panOffset: .constant(.zero)
        )
        .frame(height: 400)
        .background(Color.black)
    }
}
