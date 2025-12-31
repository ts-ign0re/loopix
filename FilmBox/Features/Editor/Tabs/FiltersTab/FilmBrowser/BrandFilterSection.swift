import SwiftUI

/// Section displaying all film simulation presets from a single brand
/// Features horizontal scroll, expandable view, and brand icon
struct BrandFilterSection: View {

    // MARK: - Properties

    let brand: String
    let presets: [FilterPreset]
    let selectedPreset: FilterPreset?
    let previewImages: [UUID: CGImage]
    let onPresetSelected: (FilterPreset) -> Void
    let onPresetDoubleTapped: ((FilterPreset) -> Void)?
    let onPresetLongPressed: ((FilterPreset) -> Void)?
    let onSeeAllTapped: (() -> Void)?

    // MARK: - State

    @State private var isExpanded = false

    // MARK: - Constants

    private let maxVisibleInCompact = 6
    private let sectionHeight: CGFloat = 140
    private let brandIconSize: CGFloat = 32

    // MARK: - Initialization

    init(
        brand: String,
        presets: [FilterPreset],
        selectedPreset: FilterPreset? = nil,
        previewImages: [UUID: CGImage] = [:],
        onPresetSelected: @escaping (FilterPreset) -> Void,
        onPresetDoubleTapped: ((FilterPreset) -> Void)? = nil,
        onPresetLongPressed: ((FilterPreset) -> Void)? = nil,
        onSeeAllTapped: (() -> Void)? = nil
    ) {
        self.brand = brand
        self.presets = presets
        self.selectedPreset = selectedPreset
        self.previewImages = previewImages
        self.onPresetSelected = onPresetSelected
        self.onPresetDoubleTapped = onPresetDoubleTapped
        self.onPresetLongPressed = onPresetLongPressed
        self.onSeeAllTapped = onSeeAllTapped
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            headerView

            // Preset scroll
            presetScrollView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            // Brand icon
            brandIcon

            // Brand name
            Text(brandDisplayName)
                .font(.headline)
                .foregroundStyle(.primary)

            // Preset count
            Text("\(presets.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color(.systemGray5))
                )

            Spacer()

            // See all button (if more than visible)
            if presets.count > maxVisibleInCompact {
                Button(action: { onSeeAllTapped?() }) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Brand Icon

    private var brandIcon: some View {
        ZStack {
            Circle()
                .fill(brandColor.opacity(0.15))
                .frame(width: brandIconSize, height: brandIconSize)

            Text(brandInitials)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(brandColor)
        }
    }

    // MARK: - Preset Scroll

    private var presetScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(presets) { preset in
                    FilmPresetCell(
                        preset: preset,
                        isSelected: selectedPreset?.id == preset.id,
                        previewImage: previewImages[preset.id],
                        onTap: { onPresetSelected(preset) },
                        onDoubleTap: { onPresetDoubleTapped?(preset) },
                        onLongPress: { onPresetLongPressed?(preset) }
                    )
                }

                // "More" indicator if many presets
                if presets.count > maxVisibleInCompact {
                    moreIndicator
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: sectionHeight)
    }

    // MARK: - More Indicator

    private var moreIndicator: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)

                VStack(spacing: 4) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("+\(presets.count - maxVisibleInCompact)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onTapGesture {
                onSeeAllTapped?()
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 80)
        }
    }

    // MARK: - Helpers

    private var brandDisplayName: String {
        switch brand {
        case "Fuji": return "Fujifilm"
        case "Fujifilm XTrans": return "X-Trans III"
        default: return brand
        }
    }

    private var brandInitials: String {
        switch brand {
        case "Kodak": return "K"
        case "Fuji", "Fujifilm": return "F"
        case "Ilford": return "I"
        case "Agfa": return "A"
        case "Polaroid": return "P"
        case "Lomography": return "L"
        case "Rollei": return "R"
        case "Apple": return ""
        case "Fujifilm XTrans": return "X"
        default: return String(brand.prefix(1)).uppercased()
        }
    }

    private var brandColor: Color {
        switch brand {
        case "Kodak": return .orange
        case "Fuji", "Fujifilm", "Fujifilm XTrans": return .green
        case "Ilford": return .gray
        case "Agfa": return .red
        case "Polaroid": return .blue
        case "Lomography": return .purple
        case "Rollei": return .brown
        case "Apple": return .blue
        default: return .gray
        }
    }
}

// MARK: - Compact Brand Chip

/// Small brand chip for the brand selector bar
struct BrandChip: View {
    let brand: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(brand)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                        )
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Brand Filter Section") {
    ScrollView {
        VStack(spacing: 24) {
            BrandFilterSection(
                brand: "Kodak",
                presets: [
                    FilterPreset(name: "Kodak Portra 160", category: .film, metadata: .init(filmStock: "Portra 160", brand: "Kodak", iso: 160, warmth: .warm)),
                    FilterPreset(name: "Kodak Portra 400", category: .film, metadata: .init(filmStock: "Portra 400", brand: "Kodak", iso: 400, warmth: .warm)),
                    FilterPreset(name: "Kodak Portra 800", category: .film, metadata: .init(filmStock: "Portra 800", brand: "Kodak", iso: 800, warmth: .warm)),
                    FilterPreset(name: "Kodak Ektar 100", category: .film, metadata: .init(filmStock: "Ektar 100", brand: "Kodak", iso: 100, warmth: .neutral)),
                    FilterPreset(name: "Kodak Gold 200", category: .film, metadata: .init(filmStock: "Gold 200", brand: "Kodak", iso: 200, warmth: .warm))
                ],
                onPresetSelected: { _ in }
            )

            BrandFilterSection(
                brand: "Ilford",
                presets: [
                    FilterPreset(name: "Ilford HP5 Plus", category: .bw, metadata: .init(filmStock: "HP5 Plus", brand: "Ilford", iso: 400, warmth: .neutral)),
                    FilterPreset(name: "Ilford Delta 100", category: .bw, metadata: .init(filmStock: "Delta 100", brand: "Ilford", iso: 100, warmth: .neutral)),
                    FilterPreset(name: "Ilford Delta 3200", category: .bw, metadata: .init(filmStock: "Delta 3200", brand: "Ilford", iso: 3200, warmth: .neutral))
                ],
                onPresetSelected: { _ in }
            )
        }
    }
}

#Preview("Brand Chips") {
    HStack(spacing: 8) {
        BrandChip(brand: "All", count: 350, isSelected: true, onTap: {})
        BrandChip(brand: "Kodak", count: 45, isSelected: false, onTap: {})
        BrandChip(brand: "Fuji", count: 72, isSelected: false, onTap: {})
        BrandChip(brand: "Ilford", count: 24, isSelected: false, onTap: {})
    }
    .padding()
}
