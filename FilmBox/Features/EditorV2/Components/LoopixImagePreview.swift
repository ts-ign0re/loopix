import SwiftUI
import CoreImage
import Metal

/// Image preview with Loopix-style histogram overlay
struct LoopixImagePreview: View {
    @Bindable var viewModel: EditorV2ViewModel

    /// Whether to show the histogram overlay
    var showHistogram: Bool = true

    /// Whether to show the vertical intensity slider (for filter detail mode)
    var showIntensitySlider: Bool = false

    /// Whether radial blur tool is active
    private var isRadialBlurActive: Bool {
        viewModel.activeTool?.parameterType == .radialBlur
    }

    /// Whether linear blur tool is active
    private var isLinearBlurActive: Bool {
        viewModel.activeTool?.parameterType == .linearBlur
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black

                // Image preview - fills available space, Metal handles aspect-fit internally
                if let image = viewModel.editor.currentImage {
                    MetalImageViewWrapper(image: image)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Radial blur focus point overlay
                    if isRadialBlurActive {
                        radialBlurOverlay(in: geometry.size, imageExtent: image.extent)
                    }

                    // Linear blur position line overlay
                    if isLinearBlurActive {
                        linearBlurOverlay(in: geometry.size, imageExtent: image.extent)
                    }
                } else if viewModel.editor.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    // Placeholder
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.3))
                }

                // Histogram overlay at bottom of preview area
                if showHistogram {
                    VStack {
                        Spacer()
                        HistogramOverlay(viewModel: viewModel)
                            .frame(height: 80)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .background(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .padding(.top, -40)
                            )
                    }
                }

                // Vertical intensity slider on right edge (for filter detail)
                if showIntensitySlider {
                    HStack {
                        Spacer()
                        VerticalIntensitySlider(
                            value: Binding(
                                get: { viewModel.editor.filterIntensity },
                                set: { viewModel.setFilterIntensity($0) }
                            ),
                            range: 0...100
                        )
                        .frame(width: 44)
                        .padding(.trailing, 8)
                    }
                }
            }
        }
    }

    // MARK: - Radial Blur Overlay

    @ViewBuilder
    private func radialBlurOverlay(in viewSize: CGSize, imageExtent: CGRect) -> some View {
        let imageRect = calculateImageRect(viewSize: viewSize, imageExtent: imageExtent)
        let centerX = imageRect.origin.x + imageRect.width * CGFloat(viewModel.editor.currentParameters.radialBlur.centerX)
        let centerY = imageRect.origin.y + imageRect.height * (1 - CGFloat(viewModel.editor.currentParameters.radialBlur.centerY)) // Flip Y for SwiftUI
        let radius = min(imageRect.width, imageRect.height) * CGFloat(viewModel.editor.currentParameters.radialBlur.radius)

        ZStack {
            // Focus circle outline
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
                .position(x: centerX, y: centerY)

            // Center crosshair/dot
            Circle()
                .fill(Color.yellow)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .position(x: centerX, y: centerY)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.editor.isDraggingBlur = true
                    let normalizedX = Float((value.location.x - imageRect.origin.x) / imageRect.width)
                    let normalizedY = Float(1 - (value.location.y - imageRect.origin.y) / imageRect.height)
                    var params = viewModel.editor.currentParameters
                    params.radialBlur.centerX = max(0, min(1, normalizedX))
                    params.radialBlur.centerY = max(0, min(1, normalizedY))
                    viewModel.editor.currentParameters = params
                }
                .onEnded { _ in
                    viewModel.editor.isDraggingBlur = false
                    viewModel.editor.schedulePreviewUpdatePublic()
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    viewModel.editor.isDraggingBlur = true
                    let currentRadius = viewModel.editor.currentParameters.radialBlur.radius
                    let newRadius = currentRadius * Float(scale)
                    var params = viewModel.editor.currentParameters
                    params.radialBlur.radius = max(0.05, min(0.8, newRadius))
                    viewModel.editor.currentParameters = params
                }
                .onEnded { _ in
                    viewModel.editor.isDraggingBlur = false
                    viewModel.editor.schedulePreviewUpdatePublic()
                }
        )
    }

    // MARK: - Linear Blur Overlay

    @ViewBuilder
    private func linearBlurOverlay(in viewSize: CGSize, imageExtent: CGRect) -> some View {
        let imageRect = calculateImageRect(viewSize: viewSize, imageExtent: imageExtent)
        let positionY = imageRect.origin.y + imageRect.height * (1 - CGFloat(viewModel.editor.currentParameters.linearBlur.position))
        let focusHeight = imageRect.height * CGFloat(viewModel.editor.currentParameters.linearBlur.focusWidth)

        ZStack {
            // Top blur zone indicator
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: imageRect.width, height: max(0, positionY - focusHeight / 2 - imageRect.origin.y))
                .position(x: imageRect.midX, y: imageRect.origin.y + (positionY - focusHeight / 2 - imageRect.origin.y) / 2)

            // Bottom blur zone indicator
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: imageRect.width, height: max(0, imageRect.maxY - (positionY + focusHeight / 2)))
                .position(x: imageRect.midX, y: positionY + focusHeight / 2 + (imageRect.maxY - positionY - focusHeight / 2) / 2)

            // Focus band lines
            Rectangle()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: imageRect.width, height: 2)
                .position(x: imageRect.midX, y: positionY - focusHeight / 2)

            Rectangle()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: imageRect.width, height: 2)
                .position(x: imageRect.midX, y: positionY + focusHeight / 2)

            // Draggable handle in center
            Capsule()
                .fill(Color.yellow)
                .frame(width: 60, height: 24)
                .overlay(
                    Capsule()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .position(x: imageRect.midX, y: positionY)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.editor.isDraggingBlur = true
                    let normalizedY = Float(1 - (value.location.y - imageRect.origin.y) / imageRect.height)
                    var params = viewModel.editor.currentParameters
                    params.linearBlur.position = max(0.1, min(0.9, normalizedY))
                    viewModel.editor.currentParameters = params
                }
                .onEnded { _ in
                    viewModel.editor.isDraggingBlur = false
                    viewModel.editor.schedulePreviewUpdatePublic()
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    viewModel.editor.isDraggingBlur = true
                    let currentWidth = viewModel.editor.currentParameters.linearBlur.focusWidth
                    // Scale relative to 1.0 (no change)
                    let newWidth = currentWidth * Float(scale)
                    var params = viewModel.editor.currentParameters
                    params.linearBlur.focusWidth = max(0.05, min(0.8, newWidth))
                    viewModel.editor.currentParameters = params
                }
                .onEnded { _ in
                    viewModel.editor.isDraggingBlur = false
                    viewModel.editor.schedulePreviewUpdatePublic()
                }
        )
    }

    // MARK: - Helper

    /// Calculate the actual image rect within the view (aspect-fit)
    private func calculateImageRect(viewSize: CGSize, imageExtent: CGRect) -> CGRect {
        let scale = min(viewSize.width / imageExtent.width, viewSize.height / imageExtent.height)
        let scaledWidth = imageExtent.width * scale
        let scaledHeight = imageExtent.height * scale
        let xOffset = (viewSize.width - scaledWidth) / 2
        let yOffset = (viewSize.height - scaledHeight) / 2
        return CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)
    }
}

// MARK: - Metal Image View Wrapper

/// UIViewRepresentable wrapper for MetalImageView
struct MetalImageViewWrapper: UIViewRepresentable {
    let image: CIImage

    func makeUIView(context: Context) -> MetalImageUIView {
        let view = MetalImageUIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: MetalImageUIView, context: Context) {
        uiView.image = image
    }
}

/// Simple UIView that renders CIImage using Metal
class MetalImageUIView: UIView {
    private var metalLayer: CAMetalLayer?
    private var ciContext: CIContext?
    private var commandQueue: MTLCommandQueue?

    var image: CIImage? {
        didSet {
            setNeedsDisplay()
            renderImage()
        }
    }

    override class var layerClass: AnyClass {
        CAMetalLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMetal()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetal()
    }

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        metalLayer = layer as? CAMetalLayer
        metalLayer?.device = device
        metalLayer?.pixelFormat = .bgra8Unorm
        metalLayer?.framebufferOnly = false
        metalLayer?.contentsScale = traitCollection.displayScale

        commandQueue = device.makeCommandQueue()
        ciContext = CIContext(mtlDevice: device, options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .cacheIntermediates: false,
            .priorityRequestLow: false
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }

        metalLayer?.drawableSize = CGSize(
            width: bounds.width * contentScaleFactor,
            height: bounds.height * contentScaleFactor
        )
        renderImage()
    }

    override func display(_ layer: CALayer) {
        renderImage()
    }

    private func renderImage() {
        guard let image = image,
              let metalLayer = metalLayer,
              let ciContext = ciContext,
              let commandQueue = commandQueue else { return }

        let drawableSize = metalLayer.drawableSize
        guard drawableSize.width > 0, drawableSize.height > 0 else { return }

        guard let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        // Clear to black
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.endEncoding()
        }

        let bounds = CGRect(origin: .zero, size: drawableSize)

        // Calculate aspect-fit transform
        let imageExtent = image.extent
        let scale = min(
            drawableSize.width / imageExtent.width,
            drawableSize.height / imageExtent.height
        )

        let scaledWidth = imageExtent.width * scale
        let scaledHeight = imageExtent.height * scale
        let xOffset = (drawableSize.width - scaledWidth) / 2
        let yOffset = (drawableSize.height - scaledHeight) / 2

        let transform = CGAffineTransform(translationX: xOffset, y: yOffset)
            .scaledBy(x: scale, y: scale)

        let transformedImage = image.transformed(by: transform)

        ciContext.render(
            transformedImage,
            to: drawable.texture,
            commandBuffer: commandBuffer,
            bounds: bounds,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Preview

#Preview {
    LoopixImagePreview(viewModel: EditorV2ViewModel())
        .frame(height: 400)
        .background(Color.black)
}
