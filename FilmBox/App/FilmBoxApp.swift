import SwiftUI

/// FilmBox - A film-inspired photo editing app
/// Main entry point for the iOS application
@main
struct FilmBoxApp: App {
    /// App-wide navigation coordinator
    @State private var coordinator = AppCoordinator()

    /// Shared dependencies container
    @State private var dependencies = Dependencies.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .environment(dependencies)
        }
    }
}
