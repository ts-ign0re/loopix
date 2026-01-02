import SwiftUI

/// Main filters tab view in VSCO style
struct VSCOFiltersTabView: View {
    @Bindable var viewModel: EditorV2ViewModel
    @State private var filters: [FilterPreset] = []
    @State private var isLoadingFilters: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Category bar
            VSCOFilterCategoryBar(selectedCategory: $viewModel.selectedFilterCategory)

            // Filter preview strip
            VSCOFilterPreviewStrip(
                filters: filteredPresets,
                selectedFilter: Binding(
                    get: { viewModel.editor.selectedPreset },
                    set: { newFilter in
                        // If tapping on already selected filter, open detail view
                        if newFilter?.id == viewModel.editor.selectedPreset?.id && newFilter != nil {
                            viewModel.enterFilterDetailMode()
                        } else {
                            viewModel.selectFilter(newFilter)
                        }
                    }
                ),
                sourceImage: viewModel.editor.originalImage,
                onFilterDoubleTap: { _ in }
            )
        }
        .task {
            await loadFilters()
        }
        .onChange(of: viewModel.selectedFilterCategory) { _, _ in
            // Filters are recalculated via filteredPresets
        }
    }

    // MARK: - Computed Properties

    private var filteredPresets: [FilterPreset] {
        switch viewModel.selectedFilterCategory {
        case .all:
            return filters
        case .favorites:
            return filters.filter { $0.metadata.isFavorite }
        case .custom:
            return filters.filter {
                if case .userCreated = $0.source { return true }
                return false
            }
        default:
            return filters.filter { $0.category == viewModel.selectedFilterCategory }
        }
    }

    // MARK: - Data Loading

    private func loadFilters() async {
        isLoadingFilters = true
        defer { isLoadingFilters = false }

        filters = await FilterStorage.shared.allPresets
    }
}

// MARK: - Preview

#Preview {
    VSCOFiltersTabView(viewModel: EditorV2ViewModel())
        .frame(height: 200)
        .background(Color.black)
}
