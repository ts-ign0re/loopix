import SwiftUI

/// VSCO-style tool category bar with flat text and underline selection
struct ToolCategoryBar: View {
    @Binding var selectedCategory: ToolDefinition.ToolCategory
    @Namespace private var underlineNamespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(ToolDefinition.ToolCategory.allCases, id: \.self) { category in
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
    private func categoryButton(for category: ToolDefinition.ToolCategory) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 4) {
                // Category label
                Text(category.rawValue.lowercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(selectedCategory == category ? .white : .gray)

                // Underline for selected category
                if selectedCategory == category {
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "toolUnderline", in: underlineNamespace)
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

// MARK: - Preview

#Preview {
    VStack {
        ToolCategoryBar(selectedCategory: .constant(.all))
        ToolCategoryBar(selectedCategory: .constant(.effects))
    }
    .background(Color.black)
}
