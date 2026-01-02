import SwiftUI
import Photos

/// Root content view - displays MainTabView as the main screen
struct ContentView: View {

    var body: some View {
        MainTabView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
