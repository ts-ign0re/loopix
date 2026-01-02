import SwiftUI
import Photos
import CoreImage

/// Horizontal scrolling strip of filter previews in VSCO style
struct VSCOFilterPreviewStrip: View {
    let filters: [FilterPreset]
    @Binding var selectedFilter: FilterPreset?
    let sourceImage: CIImage?
    let onFilterTapWhenSelected: (FilterPreset?) -> Void
    let onFilterDoubleTap: (FilterPreset?) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: VSCOFilterPreviewCell.spacing) {
                    // Original (no filter) cell
                    VSCOFilterPreviewCell(
                        filter: nil,
                        sourceImage: sourceImage,
                        isSelected: selectedFilter == nil,
                        onTap: {
                            selectFilter(nil)
                        },
                        onDoubleTap: {
                            onFilterDoubleTap(nil)
                        }
                    )
                    .id("original")

                    // Filter cells
                    ForEach(filters) { filter in
                        VSCOFilterPreviewCell(
                            filter: filter,
                            sourceImage: sourceImage,
                            isSelected: selectedFilter?.id == filter.id,
                            onTap: {
                                selectFilter(filter)
                            },
                            onDoubleTap: {
                                onFilterDoubleTap(filter)
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
                    } else {
                        proxy.scrollTo("original", anchor: .center)
                    }
                }
            }
        }
        .frame(height: VSCOFilterPreviewCell.cellHeight + 8)
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
        VSCOFilterPreviewStrip(
            filters: [],
            selectedFilter: .constant(nil),
            sourceImage: nil,
            onFilterTapWhenSelected: { _ in },
            onFilterDoubleTap: { _ in }
        )
    }
    .background(Color.black)
}
