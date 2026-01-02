import SwiftUI

/// VSCO-style filter category bar with flat text and underline selection
struct VSCOFilterCategoryBar: View {
    @Binding var selectedCategory: FilterCategory
    @Namespace private var underlineNamespace

    /// Categories to display (VSCO-style order) - removed .all since we don't show "filters" label
    private let categories: [FilterCategory] = [
        .favorites,
        .cool,
        .warm,
        .pro,
        .portrait,
        .urban,
        .film,
        .bw,
        .vintage,
        .custom
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(categories, id: \.self) { category in
                        categoryButton(for: category)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: selectedCategory) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .frame(height: 36)
    }

    @ViewBuilder
    private func categoryButton(for category: FilterCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 4) {
                // Category label - favorites shows only star icon
                if category == .favorites {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(selectedCategory == category ? .white : .gray)
                } else {
                    Text(category.vscoDisplayName)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(selectedCategory == category ? .white : .gray)
                }

                // Underline for selected category
                if selectedCategory == category {
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .id(category)
    }
}

// MARK: - FilterCategory Extension

extension FilterCategory {
    /// VSCO-style display name (lowercase monospace)
    var vscoDisplayName: String {
        switch self {
        case .all:
            return "" // Not displayed
        case .favorites:
            return "" // Shows star icon instead
        case .custom:
            return "my filters"
        default:
            return rawValue.lowercased()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        VSCOFilterCategoryBar(selectedCategory: .constant(.favorites))
        VSCOFilterCategoryBar(selectedCategory: .constant(.cool))
    }
    .background(Color.black)
}
