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

    /// Cell size
    private let cellSize: CGFloat = 72

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
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
                            size: cellSize,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
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
