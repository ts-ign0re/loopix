import SwiftUI
import CoreImage

// MARK: - Image Preview

/// A view that displays a CIImage with zoom and pan capabilities
struct ImagePreview: View {

    // MARK: - Properties

    let image: CIImage
    @Binding var zoomScale: CGFloat
    @Binding var panOffset: CGSize

    @State private var currentZoom: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                if let uiImage = convertToUIImage(image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(currentZoom * zoomScale)
                        .offset(x: currentOffset.width + panOffset.width,
                                y: currentOffset.height + panOffset.height)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        currentZoom = value
                                    }
                                    .onEnded { value in
                                        zoomScale *= value
                                        currentZoom = 1.0

                                        // Clamp zoom scale
                                        zoomScale = min(max(zoomScale, 0.5), 5.0)
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        currentOffset = CGSize(
                                            width: value.translation.width,
                                            height: value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        panOffset = CGSize(
                                            width: panOffset.width + value.translation.width,
                                            height: panOffset.height + value.translation.height
                                        )
                                        currentOffset = .zero
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if zoomScale > 1.0 {
                                    zoomScale = 1.0
                                    panOffset = .zero
                                } else {
                                    zoomScale = 2.0
                                }
                            }
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }

    // MARK: - Helper Methods

    private func convertToUIImage(_ ciImage: CIImage) -> UIImage? {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview

#Preview("Image Preview") {
    @Previewable @State var zoom: CGFloat = 1.0
    @Previewable @State var offset: CGSize = .zero

    ImagePreview(
        image: CIImage(color: .blue),
        zoomScale: $zoom,
        panOffset: $offset
    )
}
