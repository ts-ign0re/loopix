import SwiftUI
import Photos

/// Single photo cell in the grid with async thumbnail loading and selection overlay
struct PhotoGridItem: View {

    // MARK: - Properties

    let asset: PHAsset
    let isSelected: Bool
    let isSelectionMode: Bool
    let targetSize: CGSize
    let onTap: () -> Void
    let onLongPress: () -> Void

    // MARK: - State

    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?

    // MARK: - Private Properties

    private static let imageManager = PHCachingImageManager()

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Thumbnail image
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    // Placeholder while loading
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .scaleEffect(0.8)
                            }
                        }
                }

                // Selection overlay
                if isSelectionMode {
                    selectionOverlay
                }

                // Video duration badge if video
                if asset.mediaType == .video {
                    videoDurationBadge
                }

                // Favorite indicator
                if asset.isFavorite {
                    favoriteIndicator
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelectionMode {
                    onLongPress()
                } else {
                    onTap()
                }
            }
            .onLongPressGesture(minimumDuration: 0.3) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onLongPress()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .task(id: asset.localIdentifier) {
            await loadThumbnail()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    // MARK: - Subviews

    private var selectionOverlay: some View {
        ZStack {
            // Dimming overlay when selected
            if isSelected {
                Color.black.opacity(0.3)
            }

            // Selection checkmark
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.white.opacity(0.8))
                            .frame(width: 24, height: 24)

                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .padding(6)
                }
                Spacer()
            }
        }
    }

    private var videoDurationBadge: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text(formatDuration(asset.duration))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(4)
            }
        }
    }

    private var favoriteIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .padding(6)
                Spacer()
            }
        }
    }

    // MARK: - Private Methods

    private func loadThumbnail() async {
        isLoading = true

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        // Use a larger size for better quality on retina displays
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(
            width: targetSize.width * scale,
            height: targetSize.height * scale
        )

        let result: UIImage? = await withCheckedContinuation { continuation in
            Self.imageManager.requestImage(
                for: asset,
                targetSize: scaledSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // Only use the final result (not degraded placeholder)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded || image != nil {
                    continuation.resume(returning: image)
                }
            }
        }

        await MainActor.run {
            self.thumbnail = result
            self.isLoading = false
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    PhotoGridItem(
        asset: PHAsset(),
        isSelected: true,
        isSelectionMode: true,
        targetSize: CGSize(width: 100, height: 100),
        onTap: {},
        onLongPress: {}
    )
    .frame(width: 100, height: 100)
}
