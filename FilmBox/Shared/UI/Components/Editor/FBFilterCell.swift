import SwiftUI

// MARK: - Filter Cell

/// Filter preview cell for the filter strip
struct FBFilterCell: View {

    // MARK: - Properties

    let name: String
    let thumbnail: Image?
    let isSelected: Bool
    let isOriginal: Bool
    let action: () -> Void

    // MARK: - Constants

    private let cellWidth: CGFloat = 72
    private let cellHeight: CGFloat = 96
    private let thumbnailHeight: CGFloat = 72

    // MARK: - Initialization

    init(
        name: String,
        thumbnail: Image? = nil,
        isSelected: Bool = false,
        isOriginal: Bool = false,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.thumbnail = thumbnail
        self.isSelected = isSelected
        self.isOriginal = isOriginal
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: Spacing.xxs) {
                // Thumbnail
                thumbnailView
                    .frame(width: cellWidth, height: thumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.filterPreview))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.filterPreview)
                            .strokeBorder(
                                isSelected ? Color.fbFilterSelected : Color.fbFilterBorder,
                                lineWidth: isSelected ? 2 : 0.5
                            )
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if isSelected {
                            selectedIndicator
                        }
                    }

                // Label
                Text(name)
                    .font(.fbFilterName)
                    .foregroundStyle(isSelected ? .fbAccent : .fbLabel)
                    .lineLimit(1)
            }
            .frame(width: cellWidth)
        }
        .buttonStyle(FilterCellButtonStyle())
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = thumbnail {
            thumbnail
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if isOriginal {
            // Original placeholder
            ZStack {
                Color.fbBackgroundSecondary

                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(.fbLabelTertiary)
            }
        } else {
            // Loading placeholder
            ZStack {
                Color.fbBackgroundSecondary

                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    // MARK: - Selected Indicator

    private var selectedIndicator: some View {
        Circle()
            .fill(Color.fbAccent)
            .frame(width: 20, height: 20)
            .overlay(
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            )
            .offset(x: -4, y: -4)
    }

    // MARK: - Action

    private func handleTap() {
        Haptics.shared.selection()
        action()
    }
}

// MARK: - Button Style

private struct FilterCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(AnimationCurve.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Filter Strip

/// Horizontal scrolling filter strip
struct FBFilterStrip: View {

    let filters: [FilterDisplayItem]
    @Binding var selectedId: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.filterItemGap) {
                ForEach(filters) { filter in
                    FBFilterCell(
                        name: filter.name,
                        thumbnail: filter.thumbnail,
                        isSelected: filter.id == selectedId,
                        isOriginal: filter.isOriginal
                    ) {
                        selectedId = filter.id
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}

/// Filter display item for the strip
struct FilterDisplayItem: Identifiable {
    let id: UUID
    let name: String
    let thumbnail: Image?
    var isOriginal: Bool = false

    static let original = FilterDisplayItem(
        id: UUID(),
        name: "Original",
        thumbnail: nil,
        isOriginal: true
    )
}

// MARK: - Category Bar

/// Horizontal scrolling category bar for filter categories
struct FBCategoryBar: View {

    let categories: [String]
    @Binding var selectedCategory: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(categories, id: \.self) { category in
                    categoryButton(category)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    private func categoryButton(_ category: String) -> some View {
        Button {
            Haptics.shared.selection()
            selectedCategory = category
        } label: {
            Text(category)
                .font(.fbCaption1.weight(.semibold))
                .foregroundStyle(selectedCategory == category ? .fbLabelInverse : .fbLabel)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(selectedCategory == category ? Color.fbAccent : Color.fbFillSecondary)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Filter Components") {
    struct FilterPreview: View {
        @State private var selectedId: UUID?
        @State private var selectedCategory = "FILTERS"

        let filters = [
            FilterDisplayItem.original,
            FilterDisplayItem(id: UUID(), name: "Portra 400", thumbnail: nil),
            FilterDisplayItem(id: UUID(), name: "Tri-X", thumbnail: nil),
            FilterDisplayItem(id: UUID(), name: "Velvia", thumbnail: nil),
            FilterDisplayItem(id: UUID(), name: "CineStill", thumbnail: nil),
        ]

        let categories = ["FILTERS", "COOL", "WARM", "PRO", "PORTRAIT", "FILM", "B&W"]

        var body: some View {
            VStack(spacing: Spacing.md) {
                FBCategoryBar(categories: categories, selectedCategory: $selectedCategory)

                FBFilterStrip(filters: filters, selectedId: $selectedId)

                Spacer()
            }
            .padding(.vertical)
            .background(Color.fbBackground)
        }
    }

    return FilterPreview()
}
