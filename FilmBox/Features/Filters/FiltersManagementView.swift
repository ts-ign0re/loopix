import SwiftUI

/// Filters Management screen with FAB menu for filter operations
/// Accessible from home screen FAB → "filters"
@available(iOS 17.0, *)
struct FiltersManagementView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - State

    /// All built-in filters
    @State private var builtInFilters: [FilterPreset] = []

    /// User-created filters
    @State private var userFilters: [FilterPreset] = []

    /// Currently selected filter IDs (supports multi-selection)
    @State private var selectedFilterIDs: Set<UUID> = []

    /// FAB expanded state
    @State private var isFabExpanded = false

    /// Show delete confirmation alert
    @State private var showDeleteConfirmation = false

    /// Show more menu popup
    @State private var showMoreMenu = false

    /// Show Fuji recipe form
    @State private var showFujiRecipeForm = false

    /// Show QR code export view
    @State private var showQRExport = false

    /// Show QR code scanner for import
    @State private var showQRScanner = false

    /// Show import loading overlay
    @State private var isImporting = false

    /// Recently imported filter ID for highlight animation
    @State private var recentlyImportedID: UUID?

    /// Filter being edited (nil for new filter)
    @State private var filterToEdit: FilterPreset?

    /// Search text
    @State private var searchText = ""

    /// Selected category for filtering
    @State private var selectedCategory: FilterCategory = .all

    /// Favorite filter IDs
    @State private var favoriteIDs: Set<UUID> = []

    /// Cached filter preview images

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
        case .fujiRecipes:
            result = FujiRecipes.all
        default:
            result = result.filter { $0.category == selectedCategory }
        }

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    /// Get selected filters
    private var selectedFilters: [FilterPreset] {
        allFilters.filter { selectedFilterIDs.contains($0.id) }
    }

    /// Single selected filter (for FAB actions that need one filter)
    private var singleSelectedFilter: FilterPreset? {
        guard selectedFilterIDs.count == 1,
              let id = selectedFilterIDs.first else { return nil }
        return allFilters.first { $0.id == id }
    }

    /// Whether any selected filter is user-created (can be deleted)
    private var anySelectedIsUserCreated: Bool {
        selectedFilters.contains { filter in
            switch filter.source {
            case .builtIn:
                return false
            case .userCreated, .calibrated, .imported, .haldCLUT:
                return true
            }
        }
    }

    /// Whether all selected filters are user-created
    private var allSelectedAreUserCreated: Bool {
        !selectedFilters.isEmpty && selectedFilters.allSatisfy { filter in
            switch filter.source {
            case .builtIn:
                return false
            case .userCreated, .calibrated, .imported, .haldCLUT:
                return true
            }
        }
    }

    /// Whether a filter is selected
    private var hasSelection: Bool {
        !selectedFilterIDs.isEmpty
    }

    /// Whether single filter is selected
    private var isSingleSelection: Bool {
        selectedFilterIDs.count == 1
    }

    /// Favorite state for selected filters
    private enum FavoriteState {
        case none      // No selected filters are favorites
        case some      // Some are favorites, some are not
        case all       // All selected filters are favorites
    }

    private var selectedFavoriteState: FavoriteState {
        guard !selectedFilterIDs.isEmpty else { return .none }
        let favoriteCount = selectedFilterIDs.filter { favoriteIDs.contains($0) }.count
        if favoriteCount == 0 {
            return .none
        } else if favoriteCount == selectedFilterIDs.count {
            return .all
        } else {
            return .some
        }
    }

    /// Delete alert title based on selection count
    private var deleteAlertTitle: String {
        let count = selectedFilters.filter { filter in
            switch filter.source {
            case .builtIn: return false
            default: return true
            }
        }.count
        return count == 1 ? "Delete Filter" : "Delete \(count) Filters"
    }

    /// Delete alert message based on selection
    private var deleteAlertMessage: String {
        let deletableFilters = selectedFilters.filter { filter in
            switch filter.source {
            case .builtIn: return false
            default: return true
            }
        }
        if deletableFilters.count == 1 {
            return "Are you sure you want to delete \"\(deletableFilters.first?.name ?? "")\"? This action cannot be undone."
        } else {
            return "Are you sure you want to delete \(deletableFilters.count) filters? This action cannot be undone."
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

                // Action bar overlay (left side when filter selected)
                actionBarOverlay

                // FAB overlay (right side)
                fabMenuOverlay

                // Import loading overlay
                if isImporting {
                    importingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ filters")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
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
            // Track screen view
            Analytics.shared.trackScreen(.filters)

            await loadFilters()
            await loadFavorites()

            // Generate initial previews for all filters on first app start
            let allFiltersForPreview = builtInFilters + userFilters
            await FilterPreviewCache.shared.generateInitialPreviews(for: allFiltersForPreview)
        }
        .alert(deleteAlertTitle, isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSelectedFilters()
                }
            }
        } message: {
            Text(deleteAlertMessage)
        }
        .sheet(item: $filterToEdit) { filter in
            FujiRecipeFormView(
                existingFilter: filter,
                onSave: { savedFilter in
                    Task {
                        await handleFilterSaved(savedFilter)
                    }
                }
            )
        }
        .sheet(isPresented: $showFujiRecipeForm) {
            FujiRecipeFormView { newPreset in
                Task {
                    await handleFilterSaved(newPreset)
                }
            }
        }
        .sheet(isPresented: $showQRExport) {
            if let filter = singleSelectedFilter {
                RecipeQRCodeView(filter: filter)
            }
        }
        .sheet(isPresented: $showQRScanner) {
            RecipeScannerView(
                existingNames: Set(allFilters.map { $0.name })
            ) { importedFilter in
                Task {
                    await handleFilterImported(importedFilter)
                }
            }
        }
    }

    // MARK: - Category Bar

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterCategory.displayOrder, id: \.self) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func categoryChip(_ category: FilterCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
                selectedFilterIDs.removeAll()  // Clear selection on category switch
            }
            // Track category switch
            Analytics.shared.trackFilterCategorySwitch(category: category.displayName)
        } label: {
            HStack(spacing: 6) {
                if category == .favorites {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? .black : .yellow)
                } else if category == .custom {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                }
                Text(category.displayName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
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

    /// Adaptive column count for iPad
    private var gridColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 5 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }

    private var filtersGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: gridColumns,
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
        FilterCellView(
            filter: filter,
            isSelected: selectedFilterIDs.contains(filter.id),
            isFavorite: favoriteIDs.contains(filter.id),
            onTap: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    if selectedFilterIDs.contains(filter.id) {
                        selectedFilterIDs.remove(filter.id)
                    } else {
                        selectedFilterIDs.insert(filter.id)
                    }
                }
            },
            onLongPress: {
                toggleFavorite(filter)
            }
        )
    }

    // MARK: - Action Bar (left side when filter selected)

    private var actionBarOverlay: some View {
        ZStack(alignment: .bottom) {
            // Dismiss overlay for popup menu
            if showMoreMenu {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            showMoreMenu = false
                        }
                    }
            }

            // Left side - Action tabs (when filter selected)
            if hasSelection {
                VStack {
                    Spacer()
                    HStack {
                        actionTabsView
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 28)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasSelection)
    }

    private var actionTabsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Floating popup menu positioned above action bar
            if showMoreMenu {
                floatingMoreMenu
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity),
                            removal: .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity)
                        )
                    )
            }

            // Main action bar
            HStack(spacing: 0) {
                // Edit/View button - only for single selection
                if isSingleSelection {
                    if let filter = singleSelectedFilter {
                        let isUserCreated = anySelectedIsUserCreated
                        Button {
                            filterToEdit = filter
                        } label: {
                            Text(isUserCreated ? L10n.Action.edit : "view")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.yellow)
                                )
                        }
                        .buttonStyle(.plain)

                        actionTabDivider
                    }
                }

                // Favorite button with state-dependent icon
                actionButton(
                    icon: favoriteIconName,
                    iconColor: favoriteIconColor
                ) {
                    toggleFavoritesForSelection()
                }

                // Delete button - only if all selected are user-created
                if allSelectedAreUserCreated {
                    actionTabDivider

                    actionButton(icon: "trash", iconColor: .white) {
                        showDeleteConfirmation = true
                    }
                }

                // More menu button - only for single selection (duplicate available)
                if isSingleSelection {
                    actionTabDivider

                    actionButton(icon: "ellipsis", iconColor: .white) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showMoreMenu.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
    }

    // MARK: - Floating More Menu

    private var floatingMoreMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Duplicate - always available for single selection
            menuItem(title: "duplicate", icon: "doc.on.doc") {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    showMoreMenu = false
                }
                duplicateSelectedFilter()
            }

            Divider()
                .background(Color.white.opacity(0.15))

            // Export recipe as QR code
            menuItem(title: "export recipe", icon: "qrcode") {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    showMoreMenu = false
                }
                showQRExport = true
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        )
    }

    private func menuItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Icon name based on favorite state
    private var favoriteIconName: String {
        switch selectedFavoriteState {
        case .none:
            return "star"
        case .some:
            return "star.leadinghalf.filled"
        case .all:
            return "star.fill"
        }
    }

    /// Icon color based on favorite state
    private var favoriteIconColor: Color {
        switch selectedFavoriteState {
        case .none:
            return .white
        case .some, .all:
            return .yellow
        }
    }

    /// Toggle favorites for all selected filters
    private func toggleFavoritesForSelection() {
        let shouldAdd = selectedFavoriteState != .all  // Add if not all are favorites

        withAnimation(.easeInOut(duration: 0.2)) {
            for id in selectedFilterIDs {
                if shouldAdd {
                    favoriteIDs.insert(id)
                } else {
                    favoriteIDs.remove(id)
                }
            }
        }

        // Track analytics for each filter
        for filter in selectedFilters {
            Analytics.shared.trackFilterFavorite(filterName: filter.name, isFavorite: shouldAdd)
        }

        // Persist to UserDefaults
        let idStrings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: "favoriteFilterIDs")

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func actionButton(icon: String, iconColor: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var actionTabDivider: some View {
        Text("|")
            .font(.system(size: 14, weight: .light, design: .monospaced))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 2)
    }

    // MARK: - Importing Overlay

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    .scaleEffect(1.5)

                Text("importing recipe...")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
        }
        .transition(.opacity)
    }

    // MARK: - FAB Menu

    private var fabMenuOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Expanded menu items - creation/import actions
                    if isFabExpanded {
                        VStack(alignment: .trailing, spacing: 8) {
                            // Import recipe via QR
                            fabMenuItem(title: "import recipe", icon: "qrcode.viewfinder") {
                                isFabExpanded = false
                                showQRScanner = true
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            // Create Fuji recipe
                            fabMenuItem(title: "fuji recipe", icon: "camera.aperture") {
                                isFabExpanded = false
                                showFujiRecipeForm = true
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

                    // Main FAB button - Yellow (always plus for creation)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFabExpanded.toggle()
                        }
                    } label: {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 56, height: 56)
                            .shadow(color: .yellow.opacity(0.4), radius: 8, y: 2)
                            .overlay {
                                Image(systemName: isFabExpanded ? "xmark" : "plus")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .rotationEffect(.degrees(isFabExpanded ? 90 : 0))
                            }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
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
                    .font(.system(size: 14, weight: .medium, design: .monospaced))

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
        let builtIn = FilmEmulations.all + CreativeFilters.all + FujiRecipes.all
        let user = await FilterStorage.shared.getUserPresets()
        await MainActor.run {
            builtInFilters = builtIn
            userFilters = user
        }
    }

    private func loadFavorites() async {
        // Load from UserDefaults
        if let savedIDs = UserDefaults.standard.array(forKey: "favoriteFilterIDs") as? [String] {
            favoriteIDs = Set(savedIDs.compactMap { UUID(uuidString: $0) })
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ filter: FilterPreset) {
        let isFavorite: Bool
        if favoriteIDs.contains(filter.id) {
            withAnimation(.easeInOut(duration: 0.2)) {
                favoriteIDs.remove(filter.id)
            }
            isFavorite = false
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                favoriteIDs.insert(filter.id)
            }
            isFavorite = true
        }

        // Track filter favorite/unfavorite
        Analytics.shared.trackFilterFavorite(filterName: filter.name, isFavorite: isFavorite)

        // Persist to UserDefaults
        let idStrings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: "favoriteFilterIDs")

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func duplicateSelectedFilter() {
        guard let filter = singleSelectedFilter else { return }

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

        // Track filter duplicate as creation
        Analytics.shared.trackFilterCreate(name: newFilter.name, source: "duplicate")

        Task {
            try? await FilterStorage.shared.save(newFilter)

            // Generate preview for the new filter (cached for cell loaders)
            _ = await FilterPreviewCache.shared.generatePreview(for: newFilter)

            await loadFilters()
            // Select the new filter
            selectedFilterIDs = [newFilter.id]
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func deleteSelectedFilters() async {
        // Only delete user-created filters
        let filtersToDelete = selectedFilters.filter { filter in
            switch filter.source {
            case .builtIn: return false
            default: return true
            }
        }

        for filter in filtersToDelete {
            do {
                try await FilterStorage.shared.delete(id: filter.id)

                // Track filter delete
                Analytics.shared.trackEvent(
                    category: .filter,
                    action: .delete,
                    name: filter.name
                )

                // Delete the preview for this filter
                await FilterPreviewCache.shared.deletePreview(for: filter.id)
            } catch {
                print("Failed to delete filter \(filter.name): \(error)")
            }
        }

        selectedFilterIDs.removeAll()
        await loadFilters()
    }

    private func handleFilterSaved(_ filter: FilterPreset) async {
        // Save filter to storage if it's a new user filter
        do {
            // Check if filter already exists
            let existingFilters = await FilterStorage.shared.getUserPresets()
            if existingFilters.contains(where: { $0.id == filter.id }) {
                // Update existing filter
                try await FilterStorage.shared.update(filter)
            } else {
                // Save new filter
                try await FilterStorage.shared.save(filter)
            }
        } catch {
            print("Failed to save filter: \(error)")
        }

        // Regenerate preview for the saved filter (cached for cell loaders)
        await FilterPreviewCache.shared.regeneratePreview(for: filter)

        await loadFilters()
        selectedFilterIDs = [filter.id]
    }

    private func handleFilterImported(_ filter: FilterPreset) async {
        // Show importing state
        await MainActor.run {
            isImporting = true
        }

        // Fake delay for perceived value
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Save filter to storage
        do {
            try await FilterStorage.shared.save(filter)
            Analytics.shared.trackFilterCreate(name: filter.name, source: "qr_import")
        } catch {
            print("Failed to save imported filter: \(error)")
        }

        // Generate preview (cached for cell loaders)
        await FilterPreviewCache.shared.regeneratePreview(for: filter)

        await loadFilters()

        // Switch to "my" category and highlight the imported filter
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedCategory = .custom
                isImporting = false
            }

            // Small delay then select and highlight
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedFilterIDs = [filter.id]
                        recentlyImportedID = filter.id
                    }
                }

                // Remove highlight after a moment
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.5)) {
                        recentlyImportedID = nil
                    }
                }
            }
        }
    }
}

// MARK: - Filter Cell View (with proper preview loading)

@available(iOS 17.0, *)
private struct FilterCellView: View {
    let filter: FilterPreset
    let isSelected: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @StateObject private var previewLoader = FilterPreviewLoader()

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Filter preview image
                ZStack {
                    // Background / Preview image
                    if let cgImage = previewLoader.image {
                        Image(decorative: cgImage, scale: 1.0)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        // Loading placeholder with gradient
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
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
                    onLongPress()
                }
        )
        .onAppear {
            previewLoader.load(preset: filter)
        }
        .onDisappear {
            previewLoader.cancel()
        }
        .animation(.easeInOut(duration: 0.2), value: previewLoader.image != nil)
    }

    private var gradientColors: [Color] {
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
        case .fujiRecipes:
            return [Color.green.opacity(0.4), Color.teal.opacity(0.3)]
        default:
            return [Color.gray.opacity(0.4), Color.gray.opacity(0.6)]
        }
    }
}

// MARK: - Preview

#Preview {
    FiltersManagementView()
}
