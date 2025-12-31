import SwiftUI
import CoreImage

/// Compact cell for displaying a film simulation preset
/// Shows preview thumbnail, name, and optional ISO badge
struct FilmPresetCell: View {

    // MARK: - Properties

    let preset: FilterPreset
    let isSelected: Bool
    let previewImage: CGImage?
    let onTap: () -> Void
    let onDoubleTap: (() -> Void)?
    let onLongPress: (() -> Void)?

    // MARK: - Constants

    private let cellSize: CGFloat = 80
    private let cornerRadius: CGFloat = 8
    private let selectedBorderWidth: CGFloat = 2

    // MARK: - Initialization

    init(
        preset: FilterPreset,
        isSelected: Bool = false,
        previewImage: CGImage? = nil,
        onTap: @escaping () -> Void,
        onDoubleTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.preset = preset
        self.isSelected = isSelected
        self.previewImage = previewImage
        self.onTap = onTap
        self.onDoubleTap = onDoubleTap
        self.onLongPress = onLongPress
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            // Preview thumbnail
            previewThumbnail
                .frame(width: cellSize, height: cellSize)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: selectedBorderWidth
                        )
                )
                .shadow(
                    color: isSelected ? Color.accentColor.opacity(0.3) : Color.clear,
                    radius: 4
                )

            // Name label
            Text(displayName)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: cellSize)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onDoubleTap?()
            }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                onLongPress?()
            }
        )
    }

    // MARK: - Preview Thumbnail

    @ViewBuilder
    private var previewThumbnail: some View {
        ZStack {
            // Background gradient placeholder
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Actual preview image
            if let cgImage = previewImage {
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }

            // ISO badge overlay
            if let iso = preset.metadata.iso {
                isoBadge(iso: iso)
            }

            // Favorite indicator
            if preset.metadata.isFavorite {
                favoriteIndicator
            }
        }
    }

    // MARK: - ISO Badge

    private func isoBadge(iso: Int) -> some View {
        VStack {
            HStack {
                Spacer()
                Text("ISO \(iso)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(4)
            }
            Spacer()
        }
    }

    // MARK: - Favorite Indicator

    private var favoriteIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .padding(4)
                Spacer()
            }
        }
    }

    // MARK: - Helpers

    /// Simplified display name (removes brand prefix if already in section)
    private var displayName: String {
        let name = preset.name

        // Try to extract just the film stock name
        if let brand = preset.metadata.brand {
            if name.hasPrefix(brand + " ") {
                let stockName = String(name.dropFirst(brand.count + 1))
                return stockName
            }
        }

        return name
    }

    /// Generate gradient colors based on preset characteristics
    private var gradientColors: [Color] {
        switch preset.metadata.warmth {
        case .warm:
            return [Color.orange.opacity(0.3), Color.red.opacity(0.2)]
        case .cool:
            return [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]
        case .neutral, .none:
            return [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
        }
    }
}

// MARK: - Loading State Cell

/// Placeholder cell shown while preview is loading
struct FilmPresetCellLoading: View {
    private let cellSize: CGFloat = 80
    private let cornerRadius: CGFloat = 8

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    ProgressView()
                        .scaleEffect(0.5)
                )

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.2))
                .frame(width: cellSize * 0.8, height: 10)
        }
    }
}

// MARK: - Async Loading Cell

/// Film preset cell with automatic async preview loading from cache
@available(iOS 17.0, *)
struct FilmPresetCellAsync: View {

    let preset: FilterPreset
    let isSelected: Bool
    let onTap: () -> Void
    let onDoubleTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let priority: FilterPreviewCache.LoadPriority

    @State private var previewImage: CGImage?
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?

    init(
        preset: FilterPreset,
        isSelected: Bool = false,
        priority: FilterPreviewCache.LoadPriority = .medium,
        onTap: @escaping () -> Void,
        onDoubleTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.preset = preset
        self.isSelected = isSelected
        self.priority = priority
        self.onTap = onTap
        self.onDoubleTap = onDoubleTap
        self.onLongPress = onLongPress
    }

    var body: some View {
        FilmPresetCell(
            preset: preset,
            isSelected: isSelected,
            previewImage: previewImage,
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress
        )
        .task(id: preset.id) {
            await loadPreview()
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    private func loadPreview() async {
        // Check cached first
        if let cached = await FilterPreviewCache.shared.cachedPreview(for: preset) {
            await MainActor.run {
                self.previewImage = cached
                self.isLoading = false
            }
            return
        }

        // Load from cache with generation
        let image = await FilterPreviewCache.shared.preview(for: preset, priority: priority)

        guard !Task.isCancelled else { return }

        await MainActor.run {
            self.previewImage = image
            self.isLoading = false
        }
    }
}

// MARK: - Preview

#Preview("Film Preset Cell") {
    HStack(spacing: 16) {
        FilmPresetCell(
            preset: FilterPreset(
                name: "Kodak Portra 400",
                category: .film,
                metadata: FilterPreset.FilterMetadata(
                    filmStock: "Portra 400",
                    brand: "Kodak",
                    iso: 400,
                    warmth: .warm
                )
            ),
            isSelected: false,
            onTap: {}
        )

        FilmPresetCell(
            preset: FilterPreset(
                name: "Fuji Velvia 50",
                category: .film,
                metadata: FilterPreset.FilterMetadata(
                    filmStock: "Velvia 50",
                    brand: "Fuji",
                    iso: 50,
                    warmth: .neutral,
                    isFavorite: true
                )
            ),
            isSelected: true,
            onTap: {}
        )

        FilmPresetCell(
            preset: FilterPreset(
                name: "Ilford HP5",
                category: .bw,
                metadata: FilterPreset.FilterMetadata(
                    filmStock: "HP5 Plus",
                    brand: "Ilford",
                    iso: 400,
                    warmth: .neutral
                )
            ),
            isSelected: false,
            onTap: {}
        )

        FilmPresetCellLoading()
    }
    .padding()
}
