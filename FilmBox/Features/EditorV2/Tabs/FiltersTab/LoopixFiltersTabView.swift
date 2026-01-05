import SwiftUI

/// Main filters tab view in Loopix style
struct LoopixFiltersTabView: View {
    @Bindable var viewModel: EditorV2ViewModel
    @State private var filters: [FilterPreset] = []
    @State private var isLoadingFilters: Bool = false
    @State private var favoriteIDs: Set<UUID> = []
    @State private var starAnimationFilterID: UUID? = nil
    @State private var showFujiRecipeForm: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                // Category bar
                LoopixFilterCategoryBar(selectedCategory: $viewModel.selectedFilterCategory)

                // Filter preview strip
                LoopixFilterPreviewStrip(
                    filters: filteredPresets,
                    selectedFilter: Binding(
                        get: { viewModel.editor.selectedPreset },
                        set: { viewModel.selectFilter($0) }
                    ),
                    sourceImage: viewModel.editor.originalImage,
                    favoriteIDs: favoriteIDs,
                    onFilterTapWhenSelected: { filter in
                        if filter != nil {
                            viewModel.enterFilterDetailMode()
                        }
                    },
                    onFilterDoubleTap: { _ in },
                    onFilterLongPress: { filter in
                        toggleFavorite(filter)
                    },
                    onAddRecipeTap: {
                        showFujiRecipeForm = true
                    }
                )
            }

            // Star animation overlay
            if starAnimationFilterID != nil {
                StarBurstAnimation()
                    .allowsHitTesting(false)
            }
        }
        .task {
            await loadFilters()
            loadFavorites()
        }
        .onAppear {
            // Reload filters when view reappears (e.g., after importing from FiltersManagementView)
            Task {
                await loadFilters()
            }
        }
        .onChange(of: viewModel.selectedFilterCategory) { _, _ in
            // Filters are recalculated via filteredPresets
        }
        .fullScreenCover(isPresented: $showFujiRecipeForm) {
            FujiRecipeFormView { newPreset in
                // Add to filters and select it
                filters.append(newPreset)
                viewModel.selectFilter(newPreset)
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredPresets: [FilterPreset] {
        switch viewModel.selectedFilterCategory {
        case .all:
            // User filters first (newest first), then built-in alphabetically
            let userFilters = filters
                .filter { $0.source != .builtIn }
                .sorted { $0.createdAt > $1.createdAt }
            let builtInFilters = filters
                .filter { $0.source == .builtIn }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return userFilters + builtInFilters
        case .favorites:
            // Favorites sorted by modifiedAt (newest first)
            return filters
                .filter { favoriteIDs.contains($0.id) }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        case .custom:
            // User filters sorted by createdAt (newest first)
            return filters
                .filter { $0.source != .builtIn }
                .sorted { $0.createdAt > $1.createdAt }
        default:
            // Category filters with brand-priority sorting for FILM category
            let categoryFilters = filters.filter { $0.category == viewModel.selectedFilterCategory }

            if viewModel.selectedFilterCategory == .film {
                // Sort by brand: Kodak → Fuji → Cinestill → others, then alphabetically within each brand
                return categoryFilters.sorted { a, b in
                    let priorityA = brandPriority(a.name)
                    let priorityB = brandPriority(b.name)
                    if priorityA != priorityB {
                        return priorityA < priorityB
                    }
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            } else {
                return categoryFilters.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }

    /// Brand priority for FILM category sorting: Kodak (0) → Fuji (1) → Cinestill (2) → others (3)
    private func brandPriority(_ name: String) -> Int {
        let lowercased = name.lowercased()
        if lowercased.hasPrefix("kodak") { return 0 }
        if lowercased.hasPrefix("fuji") { return 1 }
        if lowercased.hasPrefix("cinestill") { return 2 }
        return 3
    }

    // MARK: - Data Loading

    private func loadFilters() async {
        await MainActor.run {
            isLoadingFilters = true
        }

        let loadedFilters = await FilterStorage.shared.allPresets

        await MainActor.run {
            filters = loadedFilters
            isLoadingFilters = false
        }
    }

    private func loadFavorites() {
        if let savedIDs = UserDefaults.standard.array(forKey: "favoriteFilterIDs") as? [String] {
            favoriteIDs = Set(savedIDs.compactMap { UUID(uuidString: $0) })
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ filter: FilterPreset) {
        let wasAdded: Bool
        if favoriteIDs.contains(filter.id) {
            favoriteIDs.remove(filter.id)
            wasAdded = false
        } else {
            favoriteIDs.insert(filter.id)
            wasAdded = true
        }

        // Persist to UserDefaults
        let idStrings = favoriteIDs.map { $0.uuidString }
        UserDefaults.standard.set(idStrings, forKey: "favoriteFilterIDs")

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Show star animation only when adding
        if wasAdded {
            withAnimation(.easeOut(duration: 0.1)) {
                starAnimationFilterID = filter.id
            }

            // Hide after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    starAnimationFilterID = nil
                }
            }
        }
    }
}

// MARK: - Star Burst Animation

struct StarBurstAnimation: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Multiple stars bursting out
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(starOffset(for: index))
                    .opacity(opacity)
                    .scaleEffect(scale * 0.6)
            }

            // Center star
            Image(systemName: "star.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .yellow.opacity(0.8), radius: 10)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                scale = 1.2
                rotation = 20
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                opacity = 0
                scale = 1.5
            }
        }
    }

    private func starOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 8.0) * .pi / 180
        let distance: CGFloat = 50 * scale
        return CGSize(
            width: cos(angle) * distance,
            height: sin(angle) * distance
        )
    }
}

// MARK: - Preview

#Preview {
    LoopixFiltersTabView(viewModel: EditorV2ViewModel())
        .frame(height: 200)
        .background(Color.black)
}
