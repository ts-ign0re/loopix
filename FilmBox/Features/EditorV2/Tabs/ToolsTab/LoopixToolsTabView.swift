import SwiftUI

/// Main tools tab view in Loopix style - shows tools for a specific category
struct LoopixToolsTabView: View {
    @Bindable var viewModel: EditorV2ViewModel
    let category: ToolDefinition.ToolCategory

    var body: some View {
        VStack(spacing: 12) {
            // Tool icon strip - shows only tools for this category
            ToolIconStrip(
                tools: ToolDefinition.tools(for: category),
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
    LoopixToolsTabView(
        viewModel: EditorV2ViewModel(),
        category: .effects
    )
    .frame(height: 200)
    .background(Color.black)
}
