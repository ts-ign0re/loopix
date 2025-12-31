import SwiftUI
import Photos

/// Main filters tab view for the photo editor
/// Displays category bar, filter preview strip, and intensity slider
@available(iOS 17.0, *)
struct FiltersTabView: View {

    // MARK: - Properties

    /// Currently selected category
    @State private var selectedCategory: FilterCategory = .all

    /// Currently selected filter (nil for Original)
    @State private var selectedFilter: FilterPreset?

    /// Filter intensity (0-100%)
    @State private var intensity: Float = 100

    /// Show film browser sheet
    @State private var showFilmBrowser = false

    /// Film simulation presets loaded from catalog
    @State private var filmSimulationPresets: [FilterPreset] = []

    /// Is loading film presets
    @State private var isLoadingFilmPresets = false

    /// Source asset for thumbnails
    let asset: PHAsset?

    /// Callback when filter changes
    var onFilterChanged: ((FilterPreset?, Float) -> Void)?

    // MARK: - Services

    private let filmCatalogLoader = FilmSimulationCatalogLoader()

    // MARK: - Sample Data (Replace with actual data source)

    /// All available filters - replace with actual data source
    private var allFilters: [FilterPreset] {
        // Sample filters for each category
        // In production, this would come from a FilterManager or similar
        [
            FilterPreset(name: "Warm Glow", category: .warm),
            FilterPreset(name: "Golden Hour", category: .warm),
            FilterPreset(name: "Sunset", category: .warm),
            FilterPreset(name: "Cool Breeze", category: .cool),
            FilterPreset(name: "Arctic", category: .cool),
            FilterPreset(name: "Nordic", category: .cool),
            FilterPreset(name: "Cinematic", category: .pro),
            FilterPreset(name: "Teal & Orange", category: .pro),
            FilterPreset(name: "Moody", category: .pro),
            FilterPreset(name: "Soft Skin", category: .portrait),
            FilterPreset(name: "Studio", category: .portrait),
            FilterPreset(name: "Street", category: .urban),
            FilterPreset(name: "Neon Nights", category: .urban),
            FilterPreset(name: "Portra 400", category: .film),
            FilterPreset(name: "Ektar 100", category: .film),
            FilterPreset(name: "Tri-X 400", category: .film),
            FilterPreset(name: "Classic B&W", category: .bw),
            FilterPreset(name: "High Contrast B&W", category: .bw),
            FilterPreset(name: "Film Noir", category: .bw),
            FilterPreset(name: "70s Fade", category: .vintage),
            FilterPreset(name: "Retro", category: .vintage),
            FilterPreset(name: "Polaroid", category: .vintage)
        ]
    }

    /// Filters filtered by selected category
    private var filteredPresets: [FilterPreset] {
        if selectedCategory == .all {
            return allFilters
        }
        return allFilters.filter { $0.category == selectedCategory }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Category bar with film browser button
            HStack(spacing: 0) {
                FilterCategoryBar(selectedCategory: $selectedCategory)

                // Film browser button
                filmBrowserButton
                    .padding(.trailing, 8)
            }
            .background(Color(.systemBackground))

            Divider()

            // Filter preview strip
            if selectedCategory == .film && !filmSimulationPresets.isEmpty {
                // Show film simulation presets
                filmPreviewStrip
            } else {
                FilterPreviewStrip(
                    filters: filteredPresets,
                    selectedFilter: $selectedFilter,
                    asset: asset
                )
            }
            .background(Color(.systemBackground))

            // Intensity slider (only shown when a filter is selected)
            if selectedFilter != nil {
                Divider()

                intensitySlider
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedFilter != nil)
        .onChange(of: selectedFilter) { _, newFilter in
            onFilterChanged?(newFilter, intensity)
        }
        .onChange(of: intensity) { _, newIntensity in
            onFilterChanged?(selectedFilter, newIntensity)
        }
        .onChange(of: selectedCategory) { _, newCategory in
            if newCategory == .film {
                Task {
                    await loadFilmPresets()
                }
            }
        }
        .sheet(isPresented: $showFilmBrowser) {
            FilmBrowserView(
                selectedPreset: $selectedFilter,
                asset: asset,
                onPresetConfirmed: { preset in
                    selectedFilter = preset
                    onFilterChanged?(preset, intensity)
                }
            )
        }
        .task {
            // Preload film presets in background
            await loadFilmPresets()
        }
    }

    // MARK: - Film Browser Button

    private var filmBrowserButton: some View {
        Button(action: { showFilmBrowser = true }) {
            HStack(spacing: 4) {
                Image(systemName: "camera.filters")
                    .font(.system(size: 14))
                Text("\(filmSimulationPresets.count)")
                    .font(.caption)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(.systemGray5))
            )
        }
    }

    // MARK: - Film Preview Strip

    private var filmPreviewStrip: some View {
        VStack(spacing: 8) {
            // Quick brand selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topBrands, id: \.self) { brand in
                        quickBrandChip(brand)
                    }

                    Button(action: { showFilmBrowser = true }) {
                        Text("Browse All...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Filtered presets
            FilterPreviewStrip(
                filters: filmFilteredPresets,
                selectedFilter: $selectedFilter,
                asset: asset
            )
        }
        .padding(.top, 8)
    }

    private func quickBrandChip(_ brand: String) -> some View {
        let isSelected = selectedFilmBrand == brand

        return Button(action: {
            if selectedFilmBrand == brand {
                selectedFilmBrand = nil
            } else {
                selectedFilmBrand = brand
            }
        }) {
            Text(brand)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }

    @State private var selectedFilmBrand: String? = nil

    private var topBrands: [String] {
        ["Kodak", "Fuji", "Ilford", "Polaroid"]
    }

    private var filmFilteredPresets: [FilterPreset] {
        if let brand = selectedFilmBrand {
            return filmSimulationPresets.filter { $0.metadata.brand == brand }
        }
        return Array(filmSimulationPresets.prefix(20))  // Show first 20 by default
    }

    // MARK: - Data Loading

    private func loadFilmPresets() async {
        guard filmSimulationPresets.isEmpty && !isLoadingFilmPresets else { return }
        isLoadingFilmPresets = true
        filmSimulationPresets = await filmCatalogLoader.loadPresets()
        isLoadingFilmPresets = false
    }

    // MARK: - Intensity Slider

    private var intensitySlider: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Intensity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(intensity))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { Double(intensity) },
                    set: { intensity = Float($0) }
                ),
                in: 0...100,
                step: 1
            )
            .tint(.accentColor)
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    VStack {
        Spacer()

        FiltersTabView(
            asset: nil,
            onFilterChanged: { filter, intensity in
                print("Filter: \(filter?.name ?? "Original"), Intensity: \(intensity)%")
            }
        )
    }
    .background(Color(.systemGroupedBackground))
}
