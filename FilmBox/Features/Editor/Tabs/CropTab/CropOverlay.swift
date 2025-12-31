import SwiftUI

// MARK: - Crop Overlay

/// Interactive crop overlay that allows users to adjust crop region
struct CropOverlay: View {

    // MARK: - Properties

    /// The current crop rectangle (normalized 0-1)
    @Binding var cropRect: CGRect

    /// Aspect ratio constraint (nil for free crop)
    let aspectRatio: CGFloat?

    /// Size of the image being cropped
    let imageSize: CGSize

    /// Size of the view
    let viewSize: CGSize

    /// Minimum crop size (in points)
    let minimumSize: CGFloat = 50

    /// Currently dragged handle
    @State private var activeHandle: CropHandle?

    /// Initial rect when drag started
    @State private var initialRect: CGRect = .zero

    /// Initial drag location
    @State private var dragStart: CGPoint = .zero

    // MARK: - Crop Handles

    enum CropHandle: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case center

        var cursor: NSCursor {
            switch self {
            case .topLeft, .bottomRight: return .crosshair
            case .topRight, .bottomLeft: return .crosshair
            case .top, .bottom: return .resizeUpDown
            case .left, .right: return .resizeLeftRight
            case .center: return .openHand
            }
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let scale = calculateScale(viewSize: geometry.size)
            let offset = calculateOffset(viewSize: geometry.size, scale: scale)
            let displayRect = cropRectInViewCoordinates(scale: scale, offset: offset)

            ZStack {
                // Darkened area outside crop
                darkenedOverlay(displayRect: displayRect, viewSize: geometry.size)

                // Crop frame
                cropFrame(displayRect: displayRect)

                // Grid lines
                gridLines(displayRect: displayRect)

                // Corner handles
                cornerHandles(displayRect: displayRect, scale: scale, offset: offset)

                // Edge handles
                edgeHandles(displayRect: displayRect, scale: scale, offset: offset)
            }
        }
    }

    // MARK: - Darkened Overlay

    private func darkenedOverlay(displayRect: CGRect, viewSize: CGSize) -> some View {
        Path { path in
            // Outer rectangle (full view)
            path.addRect(CGRect(origin: .zero, size: viewSize))
            // Inner rectangle (crop area) - creates a hole
            path.addRect(displayRect)
        }
        .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))
        .allowsHitTesting(false)
    }

    // MARK: - Crop Frame

    private func cropFrame(displayRect: CGRect) -> some View {
        Rectangle()
            .strokeBorder(Color.white, lineWidth: 1)
            .frame(width: displayRect.width, height: displayRect.height)
            .position(x: displayRect.midX, y: displayRect.midY)
            .allowsHitTesting(false)
    }

    // MARK: - Grid Lines (Rule of Thirds)

    private func gridLines(displayRect: CGRect) -> some View {
        ZStack {
            // Vertical lines
            ForEach([1, 2], id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 0.5)
                    .frame(height: displayRect.height)
                    .position(
                        x: displayRect.minX + displayRect.width * CGFloat(i) / 3,
                        y: displayRect.midY
                    )
            }

            // Horizontal lines
            ForEach([1, 2], id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(height: 0.5)
                    .frame(width: displayRect.width)
                    .position(
                        x: displayRect.midX,
                        y: displayRect.minY + displayRect.height * CGFloat(i) / 3
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Corner Handles

    private func cornerHandles(displayRect: CGRect, scale: CGFloat, offset: CGPoint) -> some View {
        let handleSize: CGFloat = 20
        let cornerLength: CGFloat = 24

        return ZStack {
            // Top Left
            cornerHandle(
                position: CGPoint(x: displayRect.minX, y: displayRect.minY),
                handle: .topLeft,
                cornerLength: cornerLength,
                scale: scale,
                offset: offset
            )

            // Top Right
            cornerHandle(
                position: CGPoint(x: displayRect.maxX, y: displayRect.minY),
                handle: .topRight,
                cornerLength: cornerLength,
                scale: scale,
                offset: offset
            )

            // Bottom Left
            cornerHandle(
                position: CGPoint(x: displayRect.minX, y: displayRect.maxY),
                handle: .bottomLeft,
                cornerLength: cornerLength,
                scale: scale,
                offset: offset
            )

            // Bottom Right
            cornerHandle(
                position: CGPoint(x: displayRect.maxX, y: displayRect.maxY),
                handle: .bottomRight,
                cornerLength: cornerLength,
                scale: scale,
                offset: offset
            )
        }
    }

    private func cornerHandle(position: CGPoint, handle: CropHandle, cornerLength: CGFloat, scale: CGFloat, offset: CGPoint) -> some View {
        let lineWidth: CGFloat = 3

        return ZStack {
            // L-shaped corner
            Path { path in
                switch handle {
                case .topLeft:
                    path.move(to: CGPoint(x: 0, y: cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                case .topRight:
                    path.move(to: CGPoint(x: -cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: cornerLength))
                case .bottomLeft:
                    path.move(to: CGPoint(x: 0, y: -cornerLength))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                case .bottomRight:
                    path.move(to: CGPoint(x: -cornerLength, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: -cornerLength))
                default:
                    break
                }
            }
            .stroke(Color.white, lineWidth: lineWidth)
            .position(position)

            // Invisible hit area
            Circle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .position(position)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if activeHandle == nil {
                                activeHandle = handle
                                initialRect = cropRect
                                dragStart = value.startLocation
                            }
                            handleDrag(value: value, handle: handle, scale: scale, offset: offset)
                        }
                        .onEnded { _ in
                            activeHandle = nil
                        }
                )
        }
    }

    // MARK: - Edge Handles

    private func edgeHandles(displayRect: CGRect, scale: CGFloat, offset: CGPoint) -> some View {
        ZStack {
            // Top edge
            edgeHandle(
                rect: CGRect(
                    x: displayRect.midX - 20,
                    y: displayRect.minY - 15,
                    width: 40,
                    height: 30
                ),
                handle: .top,
                scale: scale,
                offset: offset
            )

            // Bottom edge
            edgeHandle(
                rect: CGRect(
                    x: displayRect.midX - 20,
                    y: displayRect.maxY - 15,
                    width: 40,
                    height: 30
                ),
                handle: .bottom,
                scale: scale,
                offset: offset
            )

            // Left edge
            edgeHandle(
                rect: CGRect(
                    x: displayRect.minX - 15,
                    y: displayRect.midY - 20,
                    width: 30,
                    height: 40
                ),
                handle: .left,
                scale: scale,
                offset: offset
            )

            // Right edge
            edgeHandle(
                rect: CGRect(
                    x: displayRect.maxX - 15,
                    y: displayRect.midY - 20,
                    width: 30,
                    height: 40
                ),
                handle: .right,
                scale: scale,
                offset: offset
            )

            // Center (drag to move)
            Rectangle()
                .fill(Color.clear)
                .frame(width: displayRect.width - 60, height: displayRect.height - 60)
                .contentShape(Rectangle())
                .position(x: displayRect.midX, y: displayRect.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if activeHandle == nil {
                                activeHandle = .center
                                initialRect = cropRect
                                dragStart = value.startLocation
                            }
                            handleDrag(value: value, handle: .center, scale: scale, offset: offset)
                        }
                        .onEnded { _ in
                            activeHandle = nil
                        }
                )
        }
    }

    private func edgeHandle(rect: CGRect, handle: CropHandle, scale: CGFloat, offset: CGPoint) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: rect.width, height: rect.height)
            .contentShape(Rectangle())
            .position(x: rect.midX, y: rect.midY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if activeHandle == nil {
                            activeHandle = handle
                            initialRect = cropRect
                            dragStart = value.startLocation
                        }
                        handleDrag(value: value, handle: handle, scale: scale, offset: offset)
                    }
                    .onEnded { _ in
                        activeHandle = nil
                    }
            )
    }

    // MARK: - Drag Handling

    private func handleDrag(value: DragGesture.Value, handle: CropHandle, scale: CGFloat, offset: CGPoint) {
        let delta = CGPoint(
            x: (value.location.x - dragStart.x) / scale / imageSize.width,
            y: (value.location.y - dragStart.y) / scale / imageSize.height
        )

        var newRect = initialRect

        switch handle {
        case .topLeft:
            newRect.origin.x = min(initialRect.origin.x + delta.x, initialRect.maxX - minimumSize / imageSize.width)
            newRect.origin.y = min(initialRect.origin.y + delta.y, initialRect.maxY - minimumSize / imageSize.height)
            newRect.size.width = initialRect.maxX - newRect.origin.x
            newRect.size.height = initialRect.maxY - newRect.origin.y

        case .topRight:
            newRect.origin.y = min(initialRect.origin.y + delta.y, initialRect.maxY - minimumSize / imageSize.height)
            newRect.size.width = max(initialRect.width + delta.x, minimumSize / imageSize.width)
            newRect.size.height = initialRect.maxY - newRect.origin.y

        case .bottomLeft:
            newRect.origin.x = min(initialRect.origin.x + delta.x, initialRect.maxX - minimumSize / imageSize.width)
            newRect.size.width = initialRect.maxX - newRect.origin.x
            newRect.size.height = max(initialRect.height + delta.y, minimumSize / imageSize.height)

        case .bottomRight:
            newRect.size.width = max(initialRect.width + delta.x, minimumSize / imageSize.width)
            newRect.size.height = max(initialRect.height + delta.y, minimumSize / imageSize.height)

        case .top:
            newRect.origin.y = min(initialRect.origin.y + delta.y, initialRect.maxY - minimumSize / imageSize.height)
            newRect.size.height = initialRect.maxY - newRect.origin.y

        case .bottom:
            newRect.size.height = max(initialRect.height + delta.y, minimumSize / imageSize.height)

        case .left:
            newRect.origin.x = min(initialRect.origin.x + delta.x, initialRect.maxX - minimumSize / imageSize.width)
            newRect.size.width = initialRect.maxX - newRect.origin.x

        case .right:
            newRect.size.width = max(initialRect.width + delta.x, minimumSize / imageSize.width)

        case .center:
            newRect.origin.x = initialRect.origin.x + delta.x
            newRect.origin.y = initialRect.origin.y + delta.y
        }

        // Apply aspect ratio constraint if needed
        if let aspect = aspectRatio, handle != .center {
            newRect = constrainToAspectRatio(rect: newRect, aspectRatio: aspect, handle: handle)
        }

        // Clamp to image bounds
        newRect.origin.x = max(0, min(newRect.origin.x, 1 - newRect.width))
        newRect.origin.y = max(0, min(newRect.origin.y, 1 - newRect.height))
        newRect.size.width = min(newRect.width, 1 - newRect.origin.x)
        newRect.size.height = min(newRect.height, 1 - newRect.origin.y)

        cropRect = newRect
    }

    private func constrainToAspectRatio(rect: CGRect, aspectRatio: CGFloat, handle: CropHandle) -> CGRect {
        var newRect = rect
        let imageAspect = imageSize.width / imageSize.height
        let targetAspect = aspectRatio / imageAspect

        // Adjust based on which handle was used
        switch handle {
        case .top, .bottom:
            newRect.size.width = newRect.height * targetAspect
        case .left, .right:
            newRect.size.height = newRect.width / targetAspect
        default:
            // For corners, maintain the larger dimension
            if newRect.width / newRect.height > targetAspect {
                newRect.size.height = newRect.width / targetAspect
            } else {
                newRect.size.width = newRect.height * targetAspect
            }
        }

        return newRect
    }

    // MARK: - Coordinate Conversion

    private func calculateScale(viewSize: CGSize) -> CGFloat {
        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        return min(scaleX, scaleY)
    }

    private func calculateOffset(viewSize: CGSize, scale: CGFloat) -> CGPoint {
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        return CGPoint(
            x: (viewSize.width - scaledWidth) / 2,
            y: (viewSize.height - scaledHeight) / 2
        )
    }

    private func cropRectInViewCoordinates(scale: CGFloat, offset: CGPoint) -> CGRect {
        CGRect(
            x: offset.x + cropRect.origin.x * imageSize.width * scale,
            y: offset.y + cropRect.origin.y * imageSize.height * scale,
            width: cropRect.width * imageSize.width * scale,
            height: cropRect.height * imageSize.height * scale
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

        var body: some View {
            ZStack {
                Color.gray

                CropOverlay(
                    cropRect: $cropRect,
                    aspectRatio: nil,
                    imageSize: CGSize(width: 4000, height: 3000),
                    viewSize: CGSize(width: 400, height: 300)
                )
            }
            .frame(width: 400, height: 300)
        }
    }

    return PreviewWrapper()
}
