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
                // Filter preview placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradientColors(for: filter),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1, contentMode: .fit)

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
                    .font(.system(size: 12, weight: .medium))
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

        var newFilter = filter
        newFilter = FilterPreset(
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
            selectedFilter = nil
            await loadFilters()
        } catch {
            print("Failed to delete filter: \(error)")
        }
    }

    private func handleFilterSaved(_ filter: FilterPreset) async {
        await loadFilters()
        selectedFilter = filter
    }
}

// MARK: - Filter Editor View (Placeholder)

@available(iOS 17.0, *)
struct FilterEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let filter: FilterPreset?
    let onSave: (FilterPreset) -> Void

    @State private var filterName: String = ""
    @State private var parameters: FilterParameters = .identity

    private var isNewFilter: Bool { filter == nil }
    private var isReadOnly: Bool {
        guard let filter else { return false }
        return filter.source == .builtIn
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Filter name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter Name")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        TextField("My Filter", text: $filterName)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                            .disabled(isReadOnly)
                    }
                    .padding(.horizontal, 20)

                    // Parameters section placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Parameters")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))

                        VStack(spacing: 16) {
                            parameterSlider(title: "Exposure", value: $parameters.exposure, range: -2...2)
                            parameterSlider(title: "Contrast", value: $parameters.contrast, range: -100...100)
                            parameterSlider(title: "Saturation", value: $parameters.saturation, range: -100...100)
                            parameterSlider(title: "Temperature", value: $parameters.temperature, range: -100...100)
                        }
                        .disabled(isReadOnly)
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    if isReadOnly {
                        Text("Built-in filters are read-only. Use Duplicate to create an editable copy.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.top, 20)
            }
            .navigationTitle(isNewFilter ? "New Filter" : (isReadOnly ? "View Filter" : "Edit Filter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }

                if !isReadOnly {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            saveFilter()
                        }
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

    private func parameterSlider(title: String, value: Binding<Float>, range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }

            Slider(value: value, in: range)
                .tint(.yellow)
        }
    }

    private func saveFilter() {
        let newFilter = FilterPreset(
            id: filter?.id ?? UUID(),
            name: filterName,
            category: .custom,
            source: .userCreated,
            parameters: parameters,
            metadata: filter?.metadata ?? FilterMetadata()
        )

        Task {
            try? await FilterStorage.shared.save(newFilter)
            onSave(newFilter)
            dismiss()
        }
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
    FiltersManagementView()
}
