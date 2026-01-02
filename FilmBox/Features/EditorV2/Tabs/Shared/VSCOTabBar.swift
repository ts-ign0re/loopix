import SwiftUI

/// VSCO-style bottom tab bar with 5 icons
struct VSCOTabBar: View {
    @Binding var selectedTab: EditorV2Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(EditorV2Tab.allCases) { tab in
                VSCOTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            Color.black.opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Single tab bar item
struct VSCOTabBarItem: View {
    let tab: EditorV2Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .yellow : .gray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        VSCOTabBar(selectedTab: .constant(.filters))
    }
    .background(Color.black)
}
