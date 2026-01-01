import SwiftUI
import Photos

/// Horizontal scrolling strip of filter preview cells
/// Displays Original plus all available filters with live thumbnails
struct FilterPreviewStrip: View {

    // MARK: - Properties

    /// Available filter presets to display
    let filters: [FilterPreset]

    /// Currently selected filter (nil for Original)
    @Binding var selectedFilter: FilterPreset?

    /// Source asset for generating thumbnails
    let asset: PHAsset?

    /// Set of favorite filter IDs
    var favoriteIDs: Set<UUID> = []

    /// Callback for long press to toggle favorite
    var onToggleFavorite: ((FilterPreset) -> Void)? = nil

    /// Whether to show the add button (for MY category)
    var showAddButton: Bool = false

    /// Callback for add button tap
    var onAddTap: (() -> Void)? = nil

    /// Cell size
    private let cellSize: CGFloat = 72

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    // Add button (only for MY category)
                    if showAddButton {
                        addButton
                            .id("add-button")
                    }

                    // Original (no filter) cell
                    FilterPreviewCell(
                        filter: nil,
                        asset: asset,
                        isSelected: selectedFilter == nil,
                        size: cellSize,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = nil
                            }
                        }
                    )
                    .id("original")

                    // Filter cells
                    ForEach(filters) { filter in
                        FilterPreviewCell(
                            filter: filter,
                            asset: asset,
                            isSelected: selectedFilter?.id == filter.id,
                            isFavorite: favoriteIDs.contains(filter.id),
                            size: cellSize,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            },
                            onLongPress: {
                                onToggleFavorite?(filter)
                            }
                        )
                        .id(filter.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedFilter) { _, newFilter in
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let filter = newFilter {
                        proxy.scrollTo(filter.id, anchor: .center)
                    } else {
                        proxy.scrollTo("original", anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button(action: { onAddTap?() }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: cellSize, height: cellSize)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.yellow)
                }

                Text("new")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: cellSize)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedFilter: FilterPreset? = nil

        let sampleFilters: [FilterPreset] = [
            FilterPreset(name: "Warm", category: .warm),
            FilterPreset(name: "Cool", category: .cool),
            FilterPreset(name: "Portra 400", category: .film),
            FilterPreset(name: "Cinematic", category: .pro),
            FilterPreset(name: "Sunset", category: .warm),
            FilterPreset(name: "Nordic", category: .cool),
            FilterPreset(name: "Vintage", category: .vintage),
            FilterPreset(name: "B&W Classic", category: .bw)
        ]

        var body: some View {
            VStack {
                Spacer()

                FilterPreviewStrip(
                    filters: sampleFilters,
                    selectedFilter: $selectedFilter,
                    asset: nil
                )
                .background(Color(.systemBackground))

                Text("Selected: \(selectedFilter?.name ?? "Original")")
                    .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
