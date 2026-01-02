import SwiftUI

/// Horizontal strip of tool icons in VSCO style
struct ToolIconStrip: View {
    let tools: [ToolDefinition]
    let onToolTap: (ToolDefinition) -> Void

    /// Get current value for a tool (to show indicator)
    var getValueForTool: ((ToolDefinition) -> Float)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(tools) { tool in
                    toolButton(for: tool)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func toolButton(for tool: ToolDefinition) -> some View {
        let hasValue = hasNonDefaultValue(for: tool)

        Button {
            onToolTap(tool)
        } label: {
            VStack(spacing: 6) {
                // Icon with optional NEW badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: tool.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)

                    // NEW badge
                    if tool.isNew {
                        Text("new")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Color.yellow)
                            .cornerRadius(2)
                            .offset(x: 4, y: -4)
                    }
                }

                // Tool name
                Text(tool.name.lowercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)

                // Value indicator dot
                Circle()
                    .fill(hasValue ? Color.yellow : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }

    private func hasNonDefaultValue(for tool: ToolDefinition) -> Bool {
        guard let getValue = getValueForTool else { return false }
        let value = getValue(tool)
        return abs(value - tool.defaultValue) > 0.01
    }
}

// MARK: - Preview

#Preview {
    ToolIconStrip(
        tools: ToolDefinition.tools(for: .effects),
        onToolTap: { _ in }
    )
    .frame(height: 100)
    .background(Color.black)
}
