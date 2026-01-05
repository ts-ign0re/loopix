import SwiftUI
import Photos
import CoreImage

/// Horizontal scrolling strip of filter previews in Loopix style
struct LoopixFilterPreviewStrip: View {
    let filters: [FilterPreset]
    @Binding var selectedFilter: FilterPreset?
    let sourceImage: CIImage?
    var favoriteIDs: Set<UUID> = []
    let onFilterTapWhenSelected: (FilterPreset?) -> Void
    let onFilterDoubleTap: (FilterPreset?) -> Void
    var onFilterLongPress: ((FilterPreset) -> Void)? = nil
    var onAddRecipeTap: (() -> Void)? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: LoopixFilterPreviewCell.spacing) {
                    // Add recipe button (replaces original)
                    addRecipeButton
                        .id("addRecipe")

                    // Filter cells
                    ForEach(filters) { filter in
                        LoopixFilterPreviewCell(
                            filter: filter,
                            sourceImage: sourceImage,
                            isSelected: selectedFilter?.id == filter.id,
                            isFavorite: favoriteIDs.contains(filter.id),
                            onTap: {
                                selectFilter(filter)
                            },
                            onDoubleTap: {
                                onFilterDoubleTap(filter)
                            },
                            onLongPress: {
                                onFilterLongPress?(filter)
                            }
                        )
                        .id(filter.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: selectedFilter?.id) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    if let id = newValue {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .frame(height: LoopixFilterPreviewCell.cellHeight + 8)
    }

    // MARK: - Add Recipe Button

    private var addRecipeButton: some View {
        Button {
            onAddRecipeTap?()
        } label: {
            VStack(spacing: 4) {
                // Plus icon in rounded rect
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: LoopixFilterPreviewCell.cellWidth, height: LoopixFilterPreviewCell.imageHeight)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                    )

                // Label
                Text("new")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.yellow.opacity(0.8))
            }
            .frame(width: LoopixFilterPreviewCell.cellWidth)
        }
        .buttonStyle(.plain)
    }

    private func selectFilter(_ filter: FilterPreset?) {
        // Check BEFORE setting binding - if already selected, open detail view
        if filter?.id == selectedFilter?.id {
            onFilterTapWhenSelected(filter)
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedFilter = filter
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        LoopixFilterPreviewStrip(
            filters: [],
            selectedFilter: .constant(nil),
            sourceImage: nil,
            onFilterTapWhenSelected: { _ in },
            onFilterDoubleTap: { _ in }
        )
    }
    .background(Color.black)
}
