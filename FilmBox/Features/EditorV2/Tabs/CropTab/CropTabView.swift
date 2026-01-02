import SwiftUI

/// Available crop aspect ratios for EditorV2
enum V2CropAspectRatio: String, CaseIterable, Identifiable {
    case free = "free"
    case square = "1:1"
    case fourThree = "4:3"
    case threeTwo = "3:2"
    case sixteenNine = "16:9"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .free: return "crop"
        case .square: return "square"
        case .fourThree: return "rectangle"
        case .threeTwo: return "rectangle.portrait"
        case .sixteenNine: return "rectangle.ratio.16.to.9"
        }
    }

    /// Returns the aspect ratio value, or nil for free
    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .square: return 1.0
        case .fourThree: return 4.0 / 3.0
        case .threeTwo: return 3.0 / 2.0
        case .sixteenNine: return 16.0 / 9.0
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

                // Image preview
                if let image = viewModel.editor.currentImage {
                    GeometryReader { previewGeometry in
                        CropImagePreview(
                            image: image,
                            cropRect: $cropRect,
                            imageRect: $imageRect,
                            selectedRatio: selectedRatio,
                            isDragging: $isDragging,
                            dragHandle: $dragHandle,
                            previewSize: previewGeometry.size
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
        // Reset crop rect
        var params = viewModel.editor.currentParameters
        params.cropRect = nil
        viewModel.editor.currentParameters = params
        viewModel.selectedTab = .filters
    }

    private func applyCrop() {
        guard !cropRect.isEmpty, !imageRect.isEmpty else { return }

        // Convert crop rect from view coordinates to image coordinates
        guard let image = viewModel.editor.originalImage else { return }

        let imageExtent = image.extent
        let scaleX = imageExtent.width / imageRect.width
        let scaleY = imageExtent.height / imageRect.height

        // Calculate image crop rect
        let imageCropRect = CGRect(
            x: (cropRect.minX - imageRect.minX) * scaleX + imageExtent.minX,
            y: (imageRect.maxY - cropRect.maxY) * scaleY + imageExtent.minY, // Flip Y
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        )

        // Apply crop to parameters
        var params = viewModel.editor.currentParameters
        params.cropRect = imageCropRect
        viewModel.editor.currentParameters = params

        // Go back to filters tab
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

    @State private var initialCropRect: CGRect = .zero

    var body: some View {
        ZStack {
            // Image
            MetalImageViewWrapper(image: image)
                .aspectRatio(contentMode: .fit)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ImageRectPreferenceKey.self,
                            value: geo.frame(in: .named("cropContainer"))
                        )
                    }
                )

            // Crop overlay
            CropOverlayView(
                cropRect: $cropRect,
                imageRect: imageRect,
                isDragging: $isDragging,
                dragHandle: $dragHandle,
                selectedRatio: selectedRatio
            )
        }
        .coordinateSpace(name: "cropContainer")
        .onPreferenceChange(ImageRectPreferenceKey.self) { rect in
            imageRect = rect
            if cropRect.isEmpty {
                cropRect = rect
            }
        }
        .onChange(of: selectedRatio) { _, newRatio in
            adjustCropToRatio(newRatio)
        }
    }

    private func adjustCropToRatio(_ ratio: V2CropAspectRatio) {
        guard !imageRect.isEmpty else { return }

        if let targetRatio = ratio.ratio {
            // Calculate new crop rect with the target ratio
            let currentCenter = CGPoint(
                x: cropRect.midX,
                y: cropRect.midY
            )

            var newWidth = cropRect.width
            var newHeight = cropRect.height

            if newWidth / newHeight > targetRatio {
                // Too wide, constrain width
                newWidth = newHeight * targetRatio
            } else {
                // Too tall, constrain height
                newHeight = newWidth / targetRatio
            }

            // Ensure it fits within image bounds
            newWidth = min(newWidth, imageRect.width)
            newHeight = min(newHeight, imageRect.height)

            // Re-constrain to ratio after fitting
            if newWidth / newHeight > targetRatio {
                newWidth = newHeight * targetRatio
            } else {
                newHeight = newWidth / targetRatio
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                cropRect = CGRect(
                    x: currentCenter.x - newWidth / 2,
                    y: currentCenter.y - newHeight / 2,
                    width: newWidth,
                    height: newHeight
                ).constrainedTo(imageRect)
            }
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

    var body: some View {
        ZStack {
            // Dimming overlay (outside crop area)
            dimmingOverlay

            // Crop border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)

            // Grid lines (rule of thirds)
            gridLines

            // Corner handles
            cornerHandles

            // Drag gesture for moving the entire crop area
            movementHandle
        }
    }

    private var dimmingOverlay: some View {
        GeometryReader { _ in
            Path { path in
                // Full overlay
                path.addRect(CGRect(origin: .zero, size: CGSize(width: 10000, height: 10000)))
                // Cut out crop area
                path.addRect(cropRect)
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
        Group {
            // Top-left corner
            cornerIndicator(position: CGPoint(x: cropRect.minX, y: cropRect.minY), handle: .topLeft)

            // Top-right corner
            cornerIndicator(position: CGPoint(x: cropRect.maxX, y: cropRect.minY), handle: .topRight)

            // Bottom-left corner
            cornerIndicator(position: CGPoint(x: cropRect.minX, y: cropRect.maxY), handle: .bottomLeft)

            // Bottom-right corner
            cornerIndicator(position: CGPoint(x: cropRect.maxX, y: cropRect.maxY), handle: .bottomRight)
        }
    }

    @ViewBuilder
    private func cornerIndicator(position: CGPoint, handle: CropHandle) -> some View {
        let isTopLeft = handle == .topLeft
        let isTopRight = handle == .topRight
        let isBottomLeft = handle == .bottomLeft

        ZStack {
            // L-shaped corner indicator
            Path { path in
                let length: CGFloat = 20
                let width: CGFloat = 3

                if isTopLeft {
                    path.addRect(CGRect(x: 0, y: 0, width: length, height: width))
                    path.addRect(CGRect(x: 0, y: 0, width: width, height: length))
                } else if isTopRight {
                    path.addRect(CGRect(x: -length, y: 0, width: length, height: width))
                    path.addRect(CGRect(x: -width, y: 0, width: width, height: length))
                } else if isBottomLeft {
                    path.addRect(CGRect(x: 0, y: -width, width: length, height: width))
                    path.addRect(CGRect(x: 0, y: -length, width: width, height: length))
                } else {
                    // Bottom-right
                    path.addRect(CGRect(x: -length, y: -width, width: length, height: width))
                    path.addRect(CGRect(x: -width, y: -length, width: width, height: length))
                }
            }
            .fill(Color.white)
        }
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragHandle = handle
                    updateCropRect(for: handle, translation: value.translation)
                }
                .onEnded { _ in
                    isDragging = false
                    dragHandle = .none
                }
        )
        .contentShape(Rectangle().size(CGSize(width: 44, height: 44)))
    }

    private var movementHandle: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: cropRect.width - handleSize * 2, height: cropRect.height - handleSize * 2)
            .position(x: cropRect.midX, y: cropRect.midY)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
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
        var newRect = cropRect
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
                newRect.origin.x = cropRect.maxX - minSize
            }
            newRect.size.width = minSize
        }
        if newRect.height < minSize {
            if handle == .topLeft || handle == .topRight {
                newRect.origin.y = cropRect.maxY - minSize
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
        var newRect = cropRect
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
