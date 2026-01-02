import SwiftUI

/// Main tools tab view in VSCO style (Light, Adjust, Color, Effects)
struct VSCOToolsTabView: View {
    @Bindable var viewModel: EditorV2ViewModel
    let category: ToolDefinition.ToolCategory

    @State private var localCategory: ToolDefinition.ToolCategory

    init(viewModel: EditorV2ViewModel, category: ToolDefinition.ToolCategory) {
        self.viewModel = viewModel
        self.category = category
        self._localCategory = State(initialValue: category)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Category bar
            ToolCategoryBar(selectedCategory: $localCategory)

            // Tool icon strip
            ToolIconStrip(
                tools: ToolDefinition.tools(for: localCategory),
                onToolTap: { tool in
                    viewModel.enterToolDetailMode(tool)
                },
                getValueForTool: { tool in
                    viewModel.getValue(for: tool)
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VSCOToolsTabView(
        viewModel: EditorV2ViewModel(),
        category: .effects
    )
    .frame(height: 200)
    .background(Color.black)
}
