import SwiftUI

/// Horizontal scrolling category bar for filter selection
/// Displays filter categories as scrollable pills with selection state
struct FilterCategoryBar: View {

    // MARK: - Properties

    /// Currently selected category
    @Binding var selectedCategory: FilterCategory

    /// Namespace for matched geometry effect animations
    @Namespace private var categoryNamespace

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category,
                            namespace: categoryNamespace
                        )
                        .id(category)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: selectedCategory) { _, newCategory in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newCategory, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Category Pill

/// Individual category pill button
private struct CategoryPill: View {

    let category: FilterCategory
    let isSelected: Bool
    let namespace: Namespace.ID

    var body: some View {
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
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.yellow)
                    .matchedGeometryEffect(id: "categoryBackground", in: namespace)
            } else {
                Capsule()
                    .fill(Color.white.opacity(0.1))
            }
        }
        .contentShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedCategory: FilterCategory = .all

        var body: some View {
            VStack {
                FilterCategoryBar(selectedCategory: $selectedCategory)

                Spacer()

                Text("Selected: \(selectedCategory.displayName)")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}
