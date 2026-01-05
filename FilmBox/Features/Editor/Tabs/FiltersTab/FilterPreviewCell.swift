import SwiftUI
import Photos

/// Individual filter preview cell displaying thumbnail with filter applied
/// Shows filter name and selection indicator
struct FilterPreviewCell: View {

    // MARK: - Properties

    /// The filter preset to display (nil for Original)
    let filter: FilterPreset?

    /// The source asset for generating thumbnails
    let asset: PHAsset?

    /// Whether this cell is currently selected
    let isSelected: Bool

    /// Whether this filter is in favorites
    var isFavorite: Bool = false

    /// Cell size (square)
    let size: CGFloat

    /// Action when tapped
    let onTap: () -> Void

    /// Action when long pressed (toggle favorite)
    var onLongPress: (() -> Void)? = nil

    // MARK: - State

    /// Loaded thumbnail image
    @State private var thumbnailImage: CGImage?

    /// Loading state
    @State private var isLoading: Bool = false

    // MARK: - Computed Properties

    /// Display name for the filter
    private var displayName: String {
        filter?.name ?? "Original"
    }

    /// Whether this is the original (no filter) cell
    private var isOriginal: Bool {
        filter == nil || filter?.id == FilterPreset.original.id
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            thumbnailView
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    // Favorite indicator
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.5))
                            )
                            .padding(4)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: 3
                        )
                }
                .shadow(
                    color: isSelected ? Color.accentColor.opacity(0.3) : .clear,
                    radius: 4,
                    y: 2
                )

            Text(displayName)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: size, height: 28, alignment: .top)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress?()
        }
        .task(id: filter?.id) {
            await loadThumbnail()
        }
    }

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnailImage {
            Image(decorative: thumbnailImage, scale: 1.0)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if isLoading {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay {
                    ProgressView()
                        .scaleEffect(0.8)
                }
        } else {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: isOriginal ? "photo" : "photo.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail() async {
        guard let asset else { return }

        isLoading = true
        defer { isLoading = false }

        // Use ThumbnailCache to get cached or generate thumbnail
        let image = await ThumbnailCache.shared.thumbnail(
            for: asset,
            filter: isOriginal ? nil : filter
        )

        // Update on main actor
        await MainActor.run {
            self.thumbnailImage = image
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        FilterPreviewCell(
            filter: nil,
            asset: nil,
            isSelected: true,
            size: 72,
            onTap: {}
        )

        FilterPreviewCell(
            filter: FilterPreset(name: "Warm"),
            asset: nil,
            isSelected: false,
            size: 72,
            onTap: {}
        )

        FilterPreviewCell(
            filter: FilterPreset(name: "Cool Tone"),
            asset: nil,
            isSelected: false,
            size: 72,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
