import SwiftUI
import CoreImage

/// Image preview with VSCO-style histogram overlay
struct VSCOImagePreview: View {
    @Bindable var viewModel: EditorV2ViewModel

    /// Whether to show the histogram overlay
    var showHistogram: Bool = true

    /// Whether to show the vertical intensity slider (for filter detail mode)
    var showIntensitySlider: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black

                // Image preview - centered
                if let image = viewModel.editor.currentImage {
                    MetalImageViewWrapper(image: image)
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .cacheIntermediates: false,
            .priorityRequestLow: false
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
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
              let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let ciContext = ciContext else { return }

        let drawableSize = metalLayer.drawableSize
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

        // Render to drawable
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
    VSCOImagePreview(viewModel: EditorV2ViewModel())
        .frame(height: 400)
        .background(Color.black)
}
