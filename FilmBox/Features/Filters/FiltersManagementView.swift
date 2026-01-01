import SwiftUI

/// Filters Management screen with FAB menu for filter operations
/// Accessible from home screen FAB → "filters"
@available(iOS 17.0, *)
struct FiltersManagementView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// All built-in filters
    @State private var builtInFilters: [FilterPreset] = []

    /// User-created filters
    @State private var userFilters: [FilterPreset] = []

    /// Currently selected filter (for FAB menu context)
    @State private var selectedFilter: FilterPreset?

    /// FAB expanded state
    @State private var isFabExpanded = false

    /// Show delete confirmation alert
    @State private var showDeleteConfirmation = false

    /// Show filter editor sheet
    @State private var showFilterEditor = false

    /// Filter being edited (nil for new filter)
    @State private var filterToEdit: FilterPreset?

    /// Search text
    @State private var searchText = ""

    /// Selected category for filtering
    @State private var selectedCategory: FilterCategory = .all

    /// Favorite filter IDs
    @State private var favoriteIDs: Set<UUID> = []

    /// Cached filter preview images
    @State private var previewImages: [UUID: CGImage] = [:]

    /// Loading state for previews
    @State private var isLoadingPreviews = false

    // MARK: - Computed Properties

    private var allFilters: [FilterPreset] {
        builtInFilters + userFilters
    }

    private var filteredFilters: [FilterPreset] {
        var result = allFilters

        // Filter by category
        switch selectedCategory {
        case .favorites:
            result = result.filter { favoriteIDs.contains($0.id) }
        case .custom:
            result = userFilters
        case .all:
            break
        default:
            result = result.filter { $0.category == selectedCategory }
        }

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    /// Whether selected filter is user-created (can be deleted/edited)
    private var selectedFilterIsUserCreated: Bool {
        guard let filter = selectedFilter else { return false }
        switch filter.source {
        case .builtIn:
            return false
        case .userCreated, .calibrated, .imported, .haldCLUT:
            return true
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category bar
                    categoryBar
                        .padding(.top, 8)

                    // Filters grid
                    filtersGrid
                }

                // FAB overlay
                fabMenuOverlay
            }
            .navigationTitle("filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search filters")
        }
        .preferredColorScheme(.dark)
        .task {
            await loadFilters()
            await loadFavorites()

            // Generate initial previews for all filters on first app start
            let allFiltersForPreview = builtInFilters + userFilters
            await FilterPreviewCache.shared.generateInitialPreviews(for: allFiltersForPreview)
        }
        .alert("Delete Filter", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSelectedFilter()
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(selectedFilter?.name ?? "")\"? This action cannot be undone.")
        }
        .sheet(isPresented: $showFilterEditor) {
            FilterEditorView(
                filter: filterToEdit,
                onSave: { savedFilter in
                    Task {
                        await handleFilterSaved(savedFilter)
                    }
                }
            )
        }
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func categoryChip(_ category: FilterCategory) -> some View {
        let isSelected = selectedCategory == category
        let isFavorites = category == .favorites

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 4) {
                if isFavorites {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .black : .yellow)
                }
                Text(category.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.yellow : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filters Grid

    private var filtersGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 16
            ) {
                ForEach(filteredFilters) { filter in
                    filterCell(filter)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 100) // Space for FAB
        }
    }

    private func filterCell(_ filter: FilterPreset) -> some View {
        let isSelected = selectedFilter?.id == filter.id
        let isFavorite = favoriteIDs.contains(filter.id)
        let previewImage = previewImages[filter.id]

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if selectedFilter?.id == filter.id {
                    selectedFilter = nil
                } else {
                    selectedFilter = filter
                }
            }
        } label: {
            VStack(spacing: 8) {
                // Filter preview image
                ZStack {
                    // Background / Preview image
                    if let cgImage = previewImage {
                        Image(decorative: cgImage, scale: 1.0)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Loading placeholder with gradient
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors(for: filter),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .tint(.white.opacity(0.5))
                            )
                    }

                    // Selection indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow, lineWidth: 3)
                    }

                    // Favorite star
                    if isFavorite {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.yellow)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }

                    // User filter badge
                    if filter.source != .builtIn {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(.black.opacity(0.5))
                                    )
                                    .padding(6)
                                Spacer()
                            }
                        }
                    }
                }

                // Filter name
                Text(filter.name)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    toggleFavorite(filter)
                }
        )
        .task {
            // Load preview for this filter if not already loaded
            if previewImages[filter.id] == nil {
                if let preview = await FilterPreviewCache.shared.getPreview(for: filter) {
                    previewImages[filter.id] = preview
                }
            }
        }
    }

    private func gradientColors(for filter: FilterPreset) -> [Color] {
        // Generate gradient based on filter category/characteristics
        switch filter.category {
        case .cool:
            return [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)]
        case .warm:
            return [Color.orange.opacity(0.6), Color.red.opacity(0.4)]
        case .bw:
            return [Color.gray.opacity(0.6), Color.black.opacity(0.8)]
        case .vintage:
            return [Color.brown.opacity(0.5), Color.orange.opacity(0.3)]
        case .film:
            return [Color.purple.opacity(0.4), Color.pink.opacity(0.3)]
        case .portrait:
            return [Color.pink.opacity(0.4), Color.orange.opacity(0.3)]
        case .urban:
            return [Color.gray.opacity(0.5), Color.blue.opacity(0.3)]
        case .pro:
            return [Color.indigo.opacity(0.5), Color.purple.opacity(0.3)]
        case .custom:
            return [Color.yellow.opacity(0.4), Color.orange.opacity(0.3)]
        default:
            return [Color.gray.opacity(0.4), Color.gray.opacity(0.6)]
        }
    }

    // MARK: - FAB Menu

    private var fabMenuOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Expanded menu items
                    if isFabExpanded {
                        VStack(alignment: .trailing, spacing: 8) {
                            // Add new - always visible
                            fabMenuItem(title: "add new", icon: "plus.circle") {
                                filterToEdit = nil
                                showFilterEditor = true
                                isFabExpanded = false
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            // Duplicate - only when filter selected
                            if selectedFilter != nil {
                                fabMenuItem(title: "duplicate", icon: "doc.on.doc") {
                                    duplicateSelectedFilter()
                                    isFabExpanded = false
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Show config - only when filter selected
                            if selectedFilter != nil {
                                fabMenuItem(
                                    title: selectedFilterIsUserCreated ? "edit" : "view",
                                    icon: selectedFilterIsUserCreated ? "slider.horizontal.3" : "eye"
                                ) {
                                    filterToEdit = selectedFilter
                                    showFilterEditor = true
                                    isFabExpanded = false
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            // Delete - only for user filters
                            if selectedFilter != nil && selectedFilterIsUserCreated {
                                fabMenuItem(title: "delete", icon: "trash") {
                                    showDeleteConfirmation = true
                                    isFabExpanded = false
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }

                    // Main FAB button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFabExpanded.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Circle()
                                        .stroke(Color.yellow.opacity(0.6), lineWidth: 1.5)
                                )

                            Image(systemName: isFabExpanded ? "xmark" : (selectedFilter != nil ? "ellipsis" : "plus"))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.yellow)
                                .rotationEffect(.degrees(isFabExpanded ? 90 : 0))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private func fabMenuItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadFilters() async {
        builtInFilters = FilmEmulations.all + CreativeFilters.all
        userFilters = await FilterStorage.shared.getUserPresets()
    }

    private func loadFavorites() async {
        // Load from UserDefaults
        if let savedIDs = UserDefaults.standard.array(forKey: "favoriteFilterIDs") as? [String] {
            favoriteIDs = Set(savedIDs.compactMap { UUID(uuidString: $0) })
        }
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

        // Persist to UserDefaults
        let idStrings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: "favoriteFilterIDs")

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func duplicateSelectedFilter() {
        guard let filter = selectedFilter else { return }

        let newFilter = FilterPreset(
            id: UUID(),
            name: "Copy of \(filter.name)",
            category: .custom,
            source: .userCreated,
            parameters: filter.parameters,
            metadata: filter.metadata,
            clutPath: filter.clutPath,
            clutIntensity: filter.clutIntensity
        )

        Task {
            try? await FilterStorage.shared.save(newFilter)

            // Generate preview for the new filter
            if let preview = await FilterPreviewCache.shared.generatePreview(for: newFilter) {
                previewImages[newFilter.id] = preview
            }

            await loadFilters()
            selectedFilter = newFilter
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func deleteSelectedFilter() async {
        guard let filter = selectedFilter else { return }

        do {
            try await FilterStorage.shared.delete(id: filter.id)

            // Delete the preview for this filter
            await FilterPreviewCache.shared.deletePreview(for: filter.id)
            previewImages.removeValue(forKey: filter.id)

            selectedFilter = nil
            await loadFilters()
        } catch {
            print("Failed to delete filter: \(error)")
        }
    }

    private func handleFilterSaved(_ filter: FilterPreset) async {
        // Regenerate preview for the saved filter
        await FilterPreviewCache.shared.regeneratePreview(for: filter)
        if let preview = await FilterPreviewCache.shared.getPreview(for: filter) {
            previewImages[filter.id] = preview
        }

        await loadFilters()
        selectedFilter = filter
    }
}

// MARK: - Filter Editor View

/// Expanded section state
enum FilterEditorSection: String, CaseIterable {
    case light = "Light"
    case color = "Color"
    case effects = "Effects"
    case fuji = "Film Simulation"
    case grain = "Grain"
    case vignette = "Vignette"
}

@available(iOS 17.0, *)
struct FilterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let filter: FilterPreset?
    let onSave: (FilterPreset) -> Void

    @State private var filterName: String = ""
    @State private var parameters: FilterParameters = .identity
    @State private var expandedSections: Set<FilterEditorSection> = [.light, .fuji]

    private var isNewFilter: Bool { filter == nil }
    private var isReadOnly: Bool {
        guard let filter else { return false }
        return filter.source == .builtIn
    }

    /// Convert internal temperature value (-100...+100) to Kelvin for display
    private func temperatureToKelvin(_ value: Float) -> Int {
        // -100 = 2500K, 0 = 6500K, +100 = 10500K
        Int(6500 + value * 40)
    }

    /// Convert Kelvin to internal temperature value
    private func kelvinToTemperature(_ kelvin: Int) -> Float {
        Float(kelvin - 6500) / 40
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Filter name input
                    nameSection

                    // Parameter sections
                    lightSection
                    colorSection
                    effectsSection
                    fujiSection
                    grainSection
                    vignetteSection

                    // Read-only notice
                    if isReadOnly {
                        Text("Built-in filters are read-only. Use Duplicate to create an editable copy.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.black)
            .navigationTitle(isNewFilter ? "new filter" : (isReadOnly ? "view filter" : "edit filter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                }

                if !isReadOnly {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("save") {
                            saveFilter()
                        }
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.yellow)
                        .disabled(filterName.isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if let filter {
                filterName = filter.name
                parameters = filter.parameters
            }
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("filter name")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))

            TextField("my filter", text: $filterName)
                .textFieldStyle(.plain)
                .font(.system(.title3, design: .monospaced))
                .foregroundStyle(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .disabled(isReadOnly)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Light Section

    private var lightSection: some View {
        collapsibleSection(title: "light", section: .light) {
            VStack(spacing: 14) {
                parameterSlider(title: "exposure", value: $parameters.exposure, range: -2...2, format: "%.2f EV")
                parameterSlider(title: "contrast", value: $parameters.contrast, range: -100...100)
                parameterSlider(title: "highlights", value: $parameters.highlights, range: -100...100)
                parameterSlider(title: "shadows", value: $parameters.shadows, range: -100...100)
                parameterSlider(title: "whites", value: $parameters.whites, range: -100...100)
                parameterSlider(title: "blacks", value: $parameters.blacks, range: -100...100)
            }
            .disabled(isReadOnly)
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        collapsibleSection(title: "color", section: .color) {
            VStack(spacing: 14) {
                // Temperature with Kelvin scale and gradient
                temperatureSlider

                // Tint with green-magenta gradient
                tintSlider

                parameterSlider(title: "saturation", value: $parameters.saturation, range: -100...100)
                parameterSlider(title: "vibrance", value: $parameters.vibrance, range: -100...100)
            }
            .disabled(isReadOnly)
        }
    }

    // MARK: - Temperature Slider (Kelvin with gradient)

    private var temperatureSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("temperature")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(temperatureToKelvin(parameters.temperature))K")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(minWidth: 60, alignment: .trailing)
            }

            // Custom gradient slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Temperature gradient track (blue → neutral → orange)
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.6, blue: 1.0),   // Cool blue (2500K)
                            Color(red: 0.7, green: 0.8, blue: 1.0),   // Light blue
                            Color.white,                               // Neutral (6500K)
                            Color(red: 1.0, green: 0.9, blue: 0.7),   // Light orange
                            Color(red: 1.0, green: 0.6, blue: 0.3)    // Warm orange (10500K)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())

                    // Thumb
                    let thumbPosition = CGFloat((parameters.temperature + 100) / 200) * geometry.size.width
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: thumbPosition - 12)
                }
                .frame(height: 24)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let percent = max(0, min(1, value.location.x / geometry.size.width))
                            parameters.temperature = Float(percent * 200 - 100)
                        }
                )
            }
            .frame(height: 24)

            // Kelvin scale labels
            HStack {
                Text("2500K")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                Text("6500K")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                Text("10500K")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    // MARK: - Tint Slider (Green-Magenta gradient)

    private var tintSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("tint")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%+.0f", parameters.tint))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(minWidth: 50, alignment: .trailing)
            }

            // Custom gradient slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Tint gradient track (green ↔ magenta)
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.9, blue: 0.4),   // Green (-100)
                            Color(red: 0.5, green: 0.95, blue: 0.6),  // Light green
                            Color.white,                               // Neutral (0)
                            Color(red: 0.95, green: 0.6, blue: 0.8),  // Light magenta
                            Color(red: 0.9, green: 0.3, blue: 0.7)    // Magenta (+100)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 8)
                    .clipShape(Capsule())

                    // Thumb
                    let thumbPosition = CGFloat((parameters.tint + 100) / 200) * geometry.size.width
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: thumbPosition - 12)
                }
                .frame(height: 24)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let percent = max(0, min(1, value.location.x / geometry.size.width))
                            parameters.tint = Float(percent * 200 - 100)
                        }
                )
            }
            .frame(height: 24)

            // Labels
            HStack {
                Text("green")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(red: 0.2, green: 0.9, blue: 0.4).opacity(0.7))
                Spacer()
                Text("magenta")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.7).opacity(0.7))
            }
        }
    }

    // MARK: - Effects Section

    private var effectsSection: some View {
        collapsibleSection(title: "effects", section: .effects) {
            VStack(spacing: 14) {
                parameterSlider(title: "clarity", value: $parameters.clarity, range: -100...100)
                parameterSlider(title: "sharpness", value: $parameters.sharpness, range: 0...100)
                parameterSlider(title: "sharpen radius", value: $parameters.sharpenRadius, range: 0.5...3.0, format: "%.1f")
                parameterSlider(title: "fade", value: $parameters.fade, range: 0...100)
            }
            .disabled(isReadOnly)
        }
    }

    // MARK: - Fuji Simulation Section

    private var fujiSection: some View {
        collapsibleSection(title: "film simulation", section: .fuji) {
            VStack(spacing: 14) {
                // Film Simulation Picker
                pickerRow(title: "film type") {
                    Picker("Film Simulation", selection: $parameters.filmSimulation) {
                        ForEach(FilmSimulationType.allCases, id: \.self) { sim in
                            Text(sim.displayName.lowercased())
                                .font(.system(.body, design: .monospaced))
                                .tag(sim)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.yellow)
                }

                // Dynamic Range Picker
                pickerRow(title: "dynamic range") {
                    Picker("Dynamic Range", selection: $parameters.dynamicRange) {
                        ForEach(DynamicRangeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                                .font(.system(.body, design: .monospaced))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.yellow)
                }

                // Color Chrome Effect
                pickerRow(title: "color chrome") {
                    Picker("Color Chrome", selection: $parameters.colorChrome.effect) {
                        ForEach(ColorChromeData.ColorChromeLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.lowercased())
                                .font(.system(.body, design: .monospaced))
                                .tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.yellow)
                }

                // Color Chrome FX Blue
                pickerRow(title: "chrome fx blue") {
                    Picker("FX Blue", selection: $parameters.colorChrome.fxBlue) {
                        ForEach(ColorChromeData.ColorChromeLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.lowercased())
                                .font(.system(.body, design: .monospaced))
                                .tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.yellow)
                }

                Divider().background(Color.white.opacity(0.2))

                // White Balance Shifts
                Text("white balance shift")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                intSlider(title: "red shift", value: Binding(
                    get: { parameters.whiteBalanceShift.redShift },
                    set: { parameters.whiteBalanceShift.redShift = $0 }
                ), range: -9...9)

                intSlider(title: "blue shift", value: Binding(
                    get: { parameters.whiteBalanceShift.blueShift },
                    set: { parameters.whiteBalanceShift.blueShift = $0 }
                ), range: -9...9)
            }
            .disabled(isReadOnly)
        }
    }

    // MARK: - Grain Section

    private var grainSection: some View {
        collapsibleSection(title: "grain", section: .grain) {
            VStack(spacing: 14) {
                parameterSlider(title: "amount", value: $parameters.grain.amount, range: 0...100)
                parameterSlider(title: "size", value: $parameters.grain.size, range: 0...1, format: "%.2f")
                parameterSlider(title: "roughness", value: $parameters.grain.roughness, range: 0...1, format: "%.2f")

                Toggle("monochromatic", isOn: $parameters.grain.monochromatic)
                    .font(.system(.body, design: .monospaced))
                    .tint(.yellow)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .disabled(isReadOnly)
        }
    }

    // MARK: - Vignette Section

    private var vignetteSection: some View {
        collapsibleSection(title: "vignette", section: .vignette) {
            VStack(spacing: 14) {
                parameterSlider(title: "amount", value: $parameters.vignette.amount, range: -100...100)
                parameterSlider(title: "midpoint", value: $parameters.vignette.midpoint, range: 0...1, format: "%.2f")
                parameterSlider(title: "roundness", value: $parameters.vignette.roundness, range: -100...100)
                parameterSlider(title: "feather", value: $parameters.vignette.feather, range: 0...1, format: "%.2f")
            }
            .disabled(isReadOnly)
        }
    }

    // MARK: - Collapsible Section

    private func collapsibleSection<Content: View>(
        title: String,
        section: FilterEditorSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedSections.contains(section) {
                        expandedSections.remove(section)
                    } else {
                        expandedSections.insert(section)
                    }
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: expandedSections.contains(section) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
            }
            .buttonStyle(.plain)

            // Content
            if expandedSections.contains(section) {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.02))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Parameter Controls

    private func parameterSlider(
        title: String,
        value: Binding<Float>,
        range: ClosedRange<Float>,
        format: String = "%.0f"
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(minWidth: 50, alignment: .trailing)
            }

            Slider(value: value, in: range)
                .tint(.yellow)
        }
    }

    private func intSlider(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(value.wrappedValue > 0 ? "+" : "")\(value.wrappedValue)")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(minWidth: 40, alignment: .trailing)
            }

            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(.yellow)
        }
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder picker: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            picker()
        }
    }

    // MARK: - Save

    private func saveFilter() {
        let newFilter = FilterPreset(
            id: filter?.id ?? UUID(),
            name: filterName,
            category: .custom,
            source: .userCreated,
            parameters: parameters,
            metadata: filter?.metadata ?? FilterPreset.FilterMetadata()
        )

        Task {
            try? await FilterStorage.shared.save(newFilter)
            onSave(newFilter)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    FiltersManagementView()
}
