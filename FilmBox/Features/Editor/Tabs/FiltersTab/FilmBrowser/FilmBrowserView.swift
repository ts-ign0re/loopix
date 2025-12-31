import SwiftUI
import Photos
import CoreImage

/// Full-screen browser for film simulation presets
/// Features search, filtering by brand/type, and organized sections
@available(iOS 17.0, *)
struct FilmBrowserView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    /// Current filter selection
    @Binding var selectedPreset: FilterPreset?

    /// Source asset for generating previews
    let asset: PHAsset?

    /// Callback when preset is confirmed (double-tap or explicit confirm)
    var onPresetConfirmed: ((FilterPreset) -> Void)?

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedBrand: String? = nil
    @State private var selectedFilmType: FilterPreset.FilterMetadata.FilmType? = nil
    @State private var selectedWarmth: FilterPreset.FilterMetadata.WarmthLevel? = nil
    @State private var previewImages: [UUID: CGImage] = [:]
    @State private var isLoading = true
    @State private var allPresets: [FilterPreset] = []
    @State private var recentPresets: [FilterPreset] = []
    @State private var favoriteIDs: Set<UUID> = []

    // MARK: - Services

    private let catalogLoader = FilmSimulationCatalogLoader()
    private let recentManager = RecentlyUsedFiltersManager.shared

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips bar
                filterChipsBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Divider()

                // Main content
                if isLoading {
                    loadingView
                } else if filteredPresets.isEmpty {
                    emptyStateView
                } else {
                    presetListView
                }
            }
            .navigationTitle("Film Simulations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if selectedPreset != nil {
                        Button("Apply") {
                            if let preset = selectedPreset {
                                recordPresetUsage(preset)
                                onPresetConfirmed?(preset)
                            }
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search films...")
        }
        .task {
            await loadPresets()
        }
    }

    // MARK: - Filter Chips Bar

    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Brand filter chips
                BrandChip(
                    brand: "All",
                    count: allPresets.count,
                    isSelected: selectedBrand == nil,
                    onTap: { selectedBrand = nil }
                )

                ForEach(sortedBrands, id: \.self) { brand in
                    BrandChip(
                        brand: brandDisplayName(brand),
                        count: presetsByBrand[brand]?.count ?? 0,
                        isSelected: selectedBrand == brand,
                        onTap: { selectedBrand = brand }
                    )
                }

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)

                // Type filter chips
                filmTypeChip(.colorNegative, label: "Color")
                filmTypeChip(.blackAndWhite, label: "B&W")
                filmTypeChip(.colorSlide, label: "Slide")
                filmTypeChip(.instant, label: "Instant")

                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)

                // Warmth filter chips
                warmthChip(.warm, label: "Warm")
                warmthChip(.cool, label: "Cool")
            }
        }
    }

    private func filmTypeChip(_ type: FilterPreset.FilterMetadata.FilmType, label: String) -> some View {
        Button(action: {
            if selectedFilmType == type {
                selectedFilmType = nil
            } else {
                selectedFilmType = type
            }
        }) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(selectedFilmType == type ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedFilmType == type ? Color.accentColor : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }

    private func warmthChip(_ warmth: FilterPreset.FilterMetadata.WarmthLevel, label: String) -> some View {
        Button(action: {
            if selectedWarmth == warmth {
                selectedWarmth = nil
            } else {
                selectedWarmth = warmth
            }
        }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(warmth == .warm ? Color.orange : Color.blue)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline)
            }
            .foregroundStyle(selectedWarmth == warmth ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selectedWarmth == warmth ? Color.accentColor : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preset List

    private var presetListView: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: .sectionHeaders) {
                // Recently used section
                if !recentPresets.isEmpty && searchText.isEmpty && selectedBrand == nil {
                    recentlyUsedSection
                }

                // Brand sections or search results
                if searchText.isEmpty && selectedBrand == nil {
                    // Show by brand
                    ForEach(sortedBrands, id: \.self) { brand in
                        if let presets = presetsByBrand[brand], !presets.isEmpty {
                            let filtered = applyFilters(to: presets)
                            if !filtered.isEmpty {
                                BrandFilterSection(
                                    brand: brand,
                                    presets: filtered,
                                    selectedPreset: selectedPreset,
                                    previewImages: previewImages,
                                    onPresetSelected: { preset in
                                        selectedPreset = preset
                                    },
                                    onPresetDoubleTapped: { preset in
                                        selectedPreset = preset
                                        onPresetConfirmed?(preset)
                                        dismiss()
                                    },
                                    onPresetLongPressed: { preset in
                                        toggleFavorite(preset)
                                    }
                                )
                            }
                        }
                    }
                } else {
                    // Show filtered/searched results
                    searchResultsSection
                }
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Recently Used Section

    private var recentlyUsedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                Text("Recently Used")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(recentPresets.prefix(10)) { preset in
                        FilmPresetCell(
                            preset: preset,
                            isSelected: selectedPreset?.id == preset.id,
                            previewImage: previewImages[preset.id],
                            onTap: { selectedPreset = preset },
                            onDoubleTap: {
                                selectedPreset = preset
                                onPresetConfirmed?(preset)
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 120)
        }
    }

    // MARK: - Search Results Section

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(filteredPresets.count) results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(filteredPresets) { preset in
                    FilmPresetCell(
                        preset: preset,
                        isSelected: selectedPreset?.id == preset.id,
                        previewImage: previewImages[preset.id],
                        onTap: { selectedPreset = preset },
                        onDoubleTap: {
                            selectedPreset = preset
                            onPresetConfirmed?(preset)
                            dismiss()
                        },
                        onLongPress: { toggleFavorite(preset) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading film simulations...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.filters")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No films found")
                .font(.headline)

            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if selectedBrand != nil || selectedFilmType != nil || selectedWarmth != nil {
                Button("Clear Filters") {
                    selectedBrand = nil
                    selectedFilmType = nil
                    selectedWarmth = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadPresets() async {
        isLoading = true
        allPresets = await catalogLoader.loadPresets()

        // Load recent presets
        recentPresets = await recentManager.getRecentPresets(from: allPresets)

        // Load favorites
        favoriteIDs = await recentManager.getFavoriteIDs()

        isLoading = false

        // Load previews asynchronously
        await loadPreviewImages()
    }

    private func loadPreviewImages() async {
        // In a real implementation, this would use ThumbnailCache
        // For now, we'll generate previews on-demand
    }

    // MARK: - Filtering

    private var filteredPresets: [FilterPreset] {
        var result = allPresets

        // Filter by search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { preset in
                preset.name.lowercased().contains(query) ||
                (preset.metadata.filmStock?.lowercased().contains(query) ?? false) ||
                (preset.metadata.brand?.lowercased().contains(query) ?? false)
            }
        }

        // Filter by brand
        if let brand = selectedBrand {
            result = result.filter { $0.metadata.brand == brand }
        }

        return applyFilters(to: result)
    }

    private func applyFilters(to presets: [FilterPreset]) -> [FilterPreset] {
        var result = presets

        // Filter by film type
        if let filmType = selectedFilmType {
            result = result.filter { $0.metadata.filmType == filmType }
        }

        // Filter by warmth
        if let warmth = selectedWarmth {
            result = result.filter { $0.metadata.warmth == warmth }
        }

        return result
    }

    private var presetsByBrand: [String: [FilterPreset]] {
        Dictionary(grouping: allPresets) { $0.metadata.brand ?? "Other" }
    }

    private var sortedBrands: [String] {
        let order = ["Kodak", "Fuji", "Ilford", "Agfa", "Polaroid", "Lomography", "Rollei", "Apple", "Fujifilm XTrans"]
        return order.filter { presetsByBrand[$0] != nil }
    }

    private func brandDisplayName(_ brand: String) -> String {
        switch brand {
        case "Fuji": return "Fujifilm"
        case "Fujifilm XTrans": return "X-Trans"
        default: return brand
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ preset: FilterPreset) {
        Task {
            let isFavorited = await recentManager.toggleFavorite(preset)
            if isFavorited {
                favoriteIDs.insert(preset.id)
            } else {
                favoriteIDs.remove(preset.id)
            }
        }
    }

    private func recordPresetUsage(_ preset: FilterPreset) {
        Task {
            await recentManager.recordUsage(of: preset)
            // Update local recent list
            recentPresets = await recentManager.getRecentPresets(from: allPresets)
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Film Browser") {
    FilmBrowserView(
        selectedPreset: .constant(nil),
        asset: nil
    )
}
