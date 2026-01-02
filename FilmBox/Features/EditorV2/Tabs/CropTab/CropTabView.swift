import SwiftUI

/// Available crop aspect ratios for EditorV2
enum V2CropAspectRatio: String, CaseIterable, Identifiable {
    case free = "free"
    case square = "1:1"
    case fourThree = "4:3"
    case threeTwo = "3:2"
    case twoThree = "2:3"
    case sixteenNine = "16:9"
    case nineSixteen = "9:16"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .free: return "crop"
        case .square: return "square"
        case .fourThree: return "rectangle"
        case .threeTwo: return "rectangle"
        case .twoThree: return "rectangle.portrait"
        case .sixteenNine: return "rectangle"
        case .nineSixteen: return "rectangle.portrait"
        }
    }

    /// Returns the aspect ratio value, or nil for free
    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .fourThree: return 4.0 / 3.0
        case .threeTwo: return 3.0 / 2.0
        case .twoThree: return 2.0 / 3.0
        case .sixteenNine: return 16.0 / 9.0
        case .nineSixteen: return 9.0 / 16.0
        }
    }
}

/// Main crop tab view with interactive crop overlay
struct CropTabView: View {
    @Bindable var viewModel: EditorV2ViewModel
    let geometry: GeometryProxy

    @State private var selectedRatio: V2CropAspectRatio = .free
    @State private var cropRect: CGRect = .zero
    @State private var imageRect: CGRect = .zero
    @State private var isDragging = false
    @State private var dragHandle: CropHandle = .none

    var body: some View {
        VStack(spacing: 0) {
            // Image preview with crop overlay
            ZStack {
                Color.black

                // Image preview - use ORIGINAL image for crop, not currentImage (which has crop already applied)
                if let image = viewModel.editor.originalImage {
                    GeometryReader { previewGeometry in
                        CropImagePreview(
                            image: image,
                            cropRect: $cropRect,
                            imageRect: $imageRect,
                            selectedRatio: selectedRatio,
                            isDragging: $isDragging,
                            dragHandle: $dragHandle,
                            previewSize: previewGeometry.size,
                            existingCropRect: viewModel.editor.currentParameters.cropRect
                        )
                    }
                }
            }
            .frame(height: geometry.size.height * 0.55)

            Spacer()

            // Aspect ratio buttons
            HStack(spacing: 24) {
                ForEach(V2CropAspectRatio.allCases) { ratio in
                    ratioButton(ratio)
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Bottom controls: X - crop - ✓
            HStack {
                // Cancel button
                Button {
                    cancelCrop()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Crop label
                Text("crop")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                // Confirm button
                Button {
                    applyCrop()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func ratioButton(_ ratio: V2CropAspectRatio) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedRatio = ratio
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: ratio.icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedRatio == ratio ? .white : .gray)
                    .frame(width: 44, height: 44)

                Text(ratio.rawValue.lowercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(selectedRatio == ratio ? .white : .gray.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
    }

    private func cancelCrop() {
        // Just go back without changing anything - keep existing crop if any
        viewModel.selectedTab = .filters
    }

    private func applyCrop() {
        // Validate rects have positive dimensions
        guard cropRect.width > 0, cropRect.height > 0,
              imageRect.width > 0, imageRect.height > 0 else {
            return
        }

        // Convert crop rect from view coordinates to image coordinates
        guard let image = viewModel.editor.originalImage else { return }

        let imageExtent = image.extent
        guard imageExtent.width > 0, imageExtent.height > 0 else { return }

        let scaleX = imageExtent.width / imageRect.width
        let scaleY = imageExtent.height / imageRect.height

        // Calculate image crop rect
        let x = (cropRect.minX - imageRect.minX) * scaleX + imageExtent.minX
        let y = (imageRect.maxY - cropRect.maxY) * scaleY + imageExtent.minY // Flip Y
        let width = cropRect.width * scaleX
        let height = cropRect.height * scaleY

        // Validate no NaN or infinite values
        guard x.isFinite, y.isFinite, width.isFinite, height.isFinite,
              width > 0, height > 0 else {
            print("⚠️ Invalid crop rect calculated: x=\(x), y=\(y), w=\(width), h=\(height)")
            return
        }

        let imageCropRect = CGRect(x: x, y: y, width: width, height: height)

        // Ensure crop rect is within image bounds
        let clampedCropRect = imageCropRect.intersection(imageExtent)
        guard !clampedCropRect.isEmpty, clampedCropRect.width > 0, clampedCropRect.height > 0 else {
            print("⚠️ Crop rect outside image bounds")
            return
        }

        // Apply crop to parameters
        var params = viewModel.editor.currentParameters
        params.cropRect = clampedCropRect
        viewModel.editor.currentParameters = params

        // Go to filters tab to show result
        viewModel.selectedTab = .filters
    }
}

// MARK: - Crop Handle Enum

enum CropHandle {
    case none
    case topLeft, topRight, bottomLeft, bottomRight
    case top, bottom, left, right
    case center
}

// MARK: - Crop Image Preview

struct CropImagePreview: View {
    let image: CIImage
    @Binding var cropRect: CGRect
    @Binding var imageRect: CGRect
    let selectedRatio: V2CropAspectRatio
    @Binding var isDragging: Bool
    @Binding var dragHandle: CropHandle
    let previewSize: CGSize
    /// Existing crop rect from parameters (in image coordinates)
    var existingCropRect: CGRect?

    @State private var initialCropRect: CGRect = .zero
    @State private var hasInitialized: Bool = false

    /// Safe aspect ratio calculation
    private var imageAspectRatio: CGFloat {
        let extent = image.extent
        guard extent.height > 0, extent.width > 0,
              extent.width.isFinite, extent.height.isFinite else {
            return 1.0
        }
        return extent.width / extent.height
    }

    /// Calculate image rect based on container size and aspect ratio (aspect-fit)
    private func calculateImageRect(in containerSize: CGSize) -> CGRect {
        guard containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let containerRatio = containerSize.width / containerSize.height
        var imageWidth: CGFloat
        var imageHeight: CGFloat

        if imageAspectRatio > containerRatio {
            // Image is wider - fit to width
            imageWidth = containerSize.width
            imageHeight = containerSize.width / imageAspectRatio
        } else {
            // Image is taller - fit to height
            imageHeight = containerSize.height
            imageWidth = containerSize.height * imageAspectRatio
        }

        let x = (containerSize.width - imageWidth) / 2
        let y = (containerSize.height - imageHeight) / 2

        return CGRect(x: x, y: y, width: imageWidth, height: imageHeight)
    }

    var body: some View {
        GeometryReader { geometry in
            let calculatedImageRect = calculateImageRect(in: geometry.size)

            ZStack {
                // Image
                MetalImageViewWrapper(image: image)
                    .aspectRatio(imageAspectRatio, contentMode: .fit)

                // Crop overlay
                CropOverlayView(
                    cropRect: $cropRect,
                    imageRect: calculatedImageRect,
                    isDragging: $isDragging,
                    dragHandle: $dragHandle,
                    selectedRatio: selectedRatio
                )
            }
            .onAppear {
                imageRect = calculatedImageRect
                initializeCropRect(imageRect: calculatedImageRect)
            }
            .onChange(of: geometry.size) { _, newSize in
                let newRect = calculateImageRect(in: newSize)
                imageRect = newRect
                if !hasInitialized {
                    initializeCropRect(imageRect: newRect)
                }
            }
        }
        .onChange(of: selectedRatio) { _, newRatio in
            adjustCropToRatio(newRatio)
        }
    }

    /// Initialize crop rect from existing crop or full image
    private func initializeCropRect(imageRect: CGRect) {
        guard !hasInitialized else { return }
        hasInitialized = true

        if let existing = existingCropRect, !existing.isEmpty {
            // Convert from image coordinates to view coordinates
            let imageExtent = image.extent
            guard imageExtent.width > 0, imageExtent.height > 0 else {
                cropRect = imageRect
                return
            }

            let scaleX = imageRect.width / imageExtent.width
            let scaleY = imageRect.height / imageExtent.height

            // Convert coordinates (note: CIImage Y is flipped)
            let viewX = imageRect.minX + (existing.minX - imageExtent.minX) * scaleX
            let viewY = imageRect.minY + (imageExtent.maxY - existing.maxY) * scaleY
            let viewWidth = existing.width * scaleX
            let viewHeight = existing.height * scaleY

            cropRect = CGRect(x: viewX, y: viewY, width: viewWidth, height: viewHeight)
        } else {
            cropRect = imageRect
        }
    }

    private func adjustCropToRatio(_ ratio: V2CropAspectRatio) {
        guard !imageRect.isEmpty else { return }

        // For free ratio, reset to full image
        guard let targetRatio = ratio.ratio else {
            withAnimation(.easeInOut(duration: 0.2)) {
                cropRect = imageRect
            }
            return
        }

        // Calculate maximum crop size that fits imageRect with target ratio
        let imageRatio = imageRect.width / imageRect.height
        var newWidth: CGFloat
        var newHeight: CGFloat

        if targetRatio > imageRatio {
            // Target is wider - fit to image width
            newWidth = imageRect.width
            newHeight = newWidth / targetRatio
        } else {
            // Target is taller - fit to image height
            newHeight = imageRect.height
            newWidth = newHeight * targetRatio
        }

        // Center in image
        let x = imageRect.midX - newWidth / 2
        let y = imageRect.midY - newHeight / 2

        withAnimation(.easeInOut(duration: 0.2)) {
            cropRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        }
    }
}

// MARK: - Crop Overlay View

struct CropOverlayView: View {
    @Binding var cropRect: CGRect
    let imageRect: CGRect
    @Binding var isDragging: Bool
    @Binding var dragHandle: CropHandle
    let selectedRatio: V2CropAspectRatio

    private let handleSize: CGFloat = 20
    private let cornerIndicatorSize: CGFloat = 24
    private let edgeWidth: CGFloat = 3

    /// Initial crop rect at drag start (for proper translation calculation)
    @State private var dragStartCropRect: CGRect = .zero

    /// Whether cropRect is valid for rendering
    private var isValidCropRect: Bool {
        cropRect.width > 0 && cropRect.height > 0 &&
        cropRect.width.isFinite && cropRect.height.isFinite
    }

    var body: some View {
        ZStack {
            // Dimming overlay (outside crop area)
            dimmingOverlay

            // Only render crop UI elements if cropRect is valid
            if isValidCropRect {
                // Crop border
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)

                // Grid lines (rule of thirds)
                gridLines

                // Corner handles (visual)
                cornerHandles

                // Corner drag handles (invisible, for gestures)
                cornerDragHandles

                // Drag gesture for moving the entire crop area
                movementHandle
            }
        }
    }

    private var dimmingOverlay: some View {
        GeometryReader { geometry in
            Path { path in
                // Full overlay using actual geometry
                let fullRect = CGRect(origin: .zero, size: geometry.size)
                path.addRect(fullRect)
                // Cut out crop area (only if valid)
                if cropRect.width > 0, cropRect.height > 0 {
                    path.addRect(cropRect)
                }
            }
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
        }
    }

    private var gridLines: some View {
        Path { path in
            let thirdWidth = cropRect.width / 3
            let thirdHeight = cropRect.height / 3

            // Vertical lines
            path.move(to: CGPoint(x: cropRect.minX + thirdWidth, y: cropRect.minY))
            path.addLine(to: CGPoint(x: cropRect.minX + thirdWidth, y: cropRect.maxY))
            path.move(to: CGPoint(x: cropRect.minX + thirdWidth * 2, y: cropRect.minY))
            path.addLine(to: CGPoint(x: cropRect.minX + thirdWidth * 2, y: cropRect.maxY))

            // Horizontal lines
            path.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + thirdHeight))
            path.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + thirdHeight))
            path.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + thirdHeight * 2))
            path.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + thirdHeight * 2))
        }
        .stroke(Color.white.opacity(0.4), lineWidth: 1)
    }

    private var cornerHandles: some View {
        let length: CGFloat = 20
        let width: CGFloat = 3

        return Canvas { context, _ in
            // Top-left
            context.fill(
                Path(CGRect(x: cropRect.minX, y: cropRect.minY, width: length, height: width)),
                with: .color(.white)
            )
            context.fill(
                Path(CGRect(x: cropRect.minX, y: cropRect.minY, width: width, height: length)),
                with: .color(.white)
            )

            // Top-right
            context.fill(
                Path(CGRect(x: cropRect.maxX - length, y: cropRect.minY, width: length, height: width)),
                with: .color(.white)
            )
            context.fill(
                Path(CGRect(x: cropRect.maxX - width, y: cropRect.minY, width: width, height: length)),
                with: .color(.white)
            )

            // Bottom-left
            context.fill(
                Path(CGRect(x: cropRect.minX, y: cropRect.maxY - width, width: length, height: width)),
                with: .color(.white)
            )
            context.fill(
                Path(CGRect(x: cropRect.minX, y: cropRect.maxY - length, width: width, height: length)),
                with: .color(.white)
            )

            // Bottom-right
            context.fill(
                Path(CGRect(x: cropRect.maxX - length, y: cropRect.maxY - width, width: length, height: width)),
                with: .color(.white)
            )
            context.fill(
                Path(CGRect(x: cropRect.maxX - width, y: cropRect.maxY - length, width: width, height: length)),
                with: .color(.white)
            )
        }
        .allowsHitTesting(false)
    }

    /// Invisible drag handles at corners
    private var cornerDragHandles: some View {
        Group {
            cornerDragHandle(at: CGPoint(x: cropRect.minX, y: cropRect.minY), handle: .topLeft)
            cornerDragHandle(at: CGPoint(x: cropRect.maxX, y: cropRect.minY), handle: .topRight)
            cornerDragHandle(at: CGPoint(x: cropRect.minX, y: cropRect.maxY), handle: .bottomLeft)
            cornerDragHandle(at: CGPoint(x: cropRect.maxX, y: cropRect.maxY), handle: .bottomRight)
        }
    }

    private func cornerDragHandle(at position: CGPoint, handle: CropHandle) -> some View {
        Color.clear
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .position(position)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            // Save initial rect at drag start
                            dragStartCropRect = cropRect
                        }
                        isDragging = true
                        dragHandle = handle
                        updateCropRect(for: handle, translation: value.translation)
                    }
                    .onEnded { _ in
                        isDragging = false
                        dragHandle = .none
                    }
            )
    }

    private var movementHandle: some View {
        Color.clear
            .frame(width: max(10, cropRect.width - 60), height: max(10, cropRect.height - 60))
            .contentShape(Rectangle())
            .position(x: cropRect.midX, y: cropRect.midY)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            dragStartCropRect = cropRect
                        }
                        isDragging = true
                        dragHandle = .center
                        moveCropRect(by: value.translation)
                    }
                    .onEnded { _ in
                        isDragging = false
                        dragHandle = .none
                    }
            )
    }

    private func updateCropRect(for handle: CropHandle, translation: CGSize) {
        var newRect = dragStartCropRect
        let minSize: CGFloat = 50

        switch handle {
        case .topLeft:
            newRect.origin.x += translation.width
            newRect.origin.y += translation.height
            newRect.size.width -= translation.width
            newRect.size.height -= translation.height
        case .topRight:
            newRect.origin.y += translation.height
            newRect.size.width += translation.width
            newRect.size.height -= translation.height
        case .bottomLeft:
            newRect.origin.x += translation.width
            newRect.size.width -= translation.width
            newRect.size.height += translation.height
        case .bottomRight:
            newRect.size.width += translation.width
            newRect.size.height += translation.height
        default:
            break
        }

        // Enforce minimum size
        if newRect.width < minSize {
            if handle == .topLeft || handle == .bottomLeft {
                newRect.origin.x = dragStartCropRect.maxX - minSize
            }
            newRect.size.width = minSize
        }
        if newRect.height < minSize {
            if handle == .topLeft || handle == .topRight {
                newRect.origin.y = dragStartCropRect.maxY - minSize
            }
            newRect.size.height = minSize
        }

        // Apply aspect ratio constraint
        if let ratio = selectedRatio.ratio {
            let currentRatio = newRect.width / newRect.height
            if currentRatio > ratio {
                newRect.size.width = newRect.height * ratio
            } else {
                newRect.size.height = newRect.width / ratio
            }
        }

        // Constrain to image bounds
        cropRect = newRect.constrainedTo(imageRect)
    }

    private func moveCropRect(by translation: CGSize) {
        var newRect = dragStartCropRect
        newRect.origin.x += translation.width
        newRect.origin.y += translation.height

        // Constrain to image bounds
        cropRect = newRect.constrainedTo(imageRect)
    }
}

// MARK: - Preference Key

struct ImageRectPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - CGRect Extension

extension CGRect {
    func constrainedTo(_ bounds: CGRect) -> CGRect {
        var rect = self

        // Ensure rect doesn't exceed bounds
        if rect.width > bounds.width { rect.size.width = bounds.width }
        if rect.height > bounds.height { rect.size.height = bounds.height }

        // Constrain position
        if rect.minX < bounds.minX { rect.origin.x = bounds.minX }
        if rect.minY < bounds.minY { rect.origin.y = bounds.minY }
        if rect.maxX > bounds.maxX { rect.origin.x = bounds.maxX - rect.width }
        if rect.maxY > bounds.maxY { rect.origin.y = bounds.maxY - rect.height }

        return rect
    }
}

// MARK: - Preview

#Preview {
    GeometryReader { geometry in
        CropTabView(viewModel: EditorV2ViewModel(), geometry: geometry)
    }
    .background(Color.black)
}
