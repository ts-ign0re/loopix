import SwiftUI
import Photos
import CoreImage

/// Loopix-style filter preview cell (64x96 vertical rectangle)
struct LoopixFilterPreviewCell: View {
    let filter: FilterPreset?
    let sourceImage: CIImage?
    let isSelected: Bool
    var isFavorite: Bool = false
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    var onLongPress: (() -> Void)? = nil

    /// Cell dimensions (Loopix style - vertical rectangle)
    static let cellWidth: CGFloat = 64
    static let cellHeight: CGFloat = 96
    static let imageHeight: CGFloat = 80
    static let spacing: CGFloat = 8

    @State private var thumbnailImage: CGImage?
    @State private var isLoading: Bool = false

    private var isOriginal: Bool {
        filter == nil
    }

    var body: some View {
        VStack(spacing: 4) {
            // Thumbnail image with edit indicator
            thumbnailView
                .frame(width: Self.cellWidth, height: Self.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    // Edit icon when selected (indicates tap to edit)
                    if isSelected && !isOriginal {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .overlay {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    // Favorite star badge
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                            .padding(4)
                    }
                }

            // Filter name
            Text(displayName)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(isSelected ? .yellow : .white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(width: Self.cellWidth)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress?()
                }
        )
        .task(id: sourceImage) {
            await loadThumbnail()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailView: some View {
        if let image = thumbnailImage {
            Image(decorative: image, scale: 3.0)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if isLoading {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                        .scaleEffect(0.6)
                }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.5))
                }
        }
    }

    private var displayName: String {
        if isOriginal {
            return "orig"
        }
        // Shorten long names
        let name = filter?.name ?? ""
        if name.count > 8 {
            return String(name.prefix(6)).lowercased() + ".."
        }
        return name.lowercased()
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        guard let source = sourceImage else { return }

        isLoading = true

        // Generate thumbnail with filter applied
        let image = await generateThumbnail(from: source, filter: isOriginal ? nil : filter)

        thumbnailImage = image
        isLoading = false
    }

    private func generateThumbnail(from image: CIImage, filter: FilterPreset?) async -> CGImage? {
        // Scale for Retina displays (@3x)
        let displayScale: CGFloat = 3.0
        let targetSize = CGSize(
            width: Self.cellWidth * displayScale,
            height: Self.imageHeight * displayScale
        )
        let scale = min(
            targetSize.width / image.extent.width,
            targetSize.height / image.extent.height
        )
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Apply filter if needed
        var result = scaledImage
        if let filter = filter {
            result = await FilterEngine.shared.apply(filter, to: scaledImage)
        }

        // Render to CGImage
        let context = CIContext(options: [.useSoftwareRenderer: false])
        return context.createCGImage(result, from: result.extent)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: LoopixFilterPreviewCell.spacing) {
        LoopixFilterPreviewCell(
            filter: nil,
            sourceImage: nil,
            isSelected: false,
            onTap: {},
            onDoubleTap: {}
        )

        LoopixFilterPreviewCell(
            filter: FilterPreset.original,
            sourceImage: nil,
            isSelected: true,
            onTap: {},
            onDoubleTap: {}
        )

        LoopixFilterPreviewCell(
            filter: FilterPreset.original,
            sourceImage: nil,
            isSelected: false,
            onTap: {},
            onDoubleTap: {}
        )
    }
    .padding()
    .background(Color.black)
}
