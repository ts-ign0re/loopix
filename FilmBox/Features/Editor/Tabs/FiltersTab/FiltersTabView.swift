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

    /// Set of favorite filter IDs
    @State private var favoriteIDs: Set<UUID> = []

    /// User-created presets
    @State private var userPresets: [FilterPreset] = []

    /// Source asset for thumbnails
    let asset: PHAsset?

    /// Callback when filter changes
    var onFilterChanged: ((FilterPreset?, Float) -> Void)?

    /// Callback to open filter editor (closes this editor first)
    var onCreateNewFilter: (() -> Void)?

    // MARK: - Services

    private let filmCatalogLoader = FilmSimulationCatalogLoader()

    // MARK: - Built-in Filters

    /// All built-in filters from FilmEmulations + CreativeFilters
    private var builtInFilters: [FilterPreset] {
        FilmEmulations.all + CreativeFilters.all
    }

    /// All available filters (built-in + user-created)
    private var allFilters: [FilterPreset] {
        builtInFilters + userPresets
    }

    /// Filters filtered by selected category
    private var filteredPresets: [FilterPreset] {
        switch selectedCategory {
        case .favorites:
            return allFilters.filter { favoriteIDs.contains($0.id) }
        case .custom:
            return userPresets
        case .all:
            return allFilters
        default:
            return allFilters.filter { $0.category == selectedCategory }
        }
    }

    /// Whether to show the add button in the current category
    private var showAddButton: Bool {
        selectedCategory == .custom
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
                    asset: asset,
                    favoriteIDs: favoriteIDs,
                    onToggleFavorite: { filter in
                        toggleFavorite(filter)
                    },
                    showAddButton: showAddButton,
                    onAddTap: {
                        onCreateNewFilter?()
                    }
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
            // Preload film presets and favorites in background
            await loadFilmPresets()
            await loadFavorites()
            await loadUserPresets()
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

    private func loadFavorites() async {
        // Load favorites from FilterStorage (user presets)
        let userFavorites = await FilterStorage.shared.favoritePresets
        favoriteIDs = Set(userFavorites.map { $0.id })

        // Also add built-in favorites from UserDefaults
        if let savedIDs = UserDefaults.standard.array(forKey: "favoriteFilterIDs") as? [String] {
            for idString in savedIDs {
                if let uuid = UUID(uuidString: idString) {
                    favoriteIDs.insert(uuid)
                }
            }
        }
    }

    private func loadUserPresets() async {
        userPresets = await FilterStorage.shared.getUserPresets()
    }

    // MARK: - Actions

    private func toggleFavorite(_ filter: FilterPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if favoriteIDs.contains(filter.id) {
                favoriteIDs.remove(filter.id)
            } else {
                favoriteIDs.insert(filter.id)
            }
        }

        // Save to UserDefaults for built-in filters
        let idStrings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: "favoriteFilterIDs")

        // Also update FilterStorage for user presets
        Task {
            try? await FilterStorage.shared.toggleFavorite(id: filter.id)
        }
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
