import SwiftUI

/// FilmBox - A film-inspired photo editing app
/// Main entry point for the iOS application
@main
struct FilmBoxApp: App {
    /// App-wide navigation coordinator
    @State private var coordinator = AppCoordinator()

    /// Shared dependencies container
    @State private var dependencies = Dependencies.shared

    /// Controls splash screen visibility
    @State private var showSplash = true

    /// App lifecycle observer for analytics
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize analytics
        Task { @MainActor in
            Analytics.shared.trackAppLaunch()
        }

        // Sync iCloud backup on launch
        Task {
            await CloudBackupManager.shared.syncOnLaunch()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(coordinator)
                    .environment(dependencies)
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        handleScenePhaseChange(from: oldPhase, to: newPhase)
                    }

                // Animated splash screen overlay
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Hide splash after 2 seconds (animation duration)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
    }

    // MARK: - App Lifecycle Analytics

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        Task { @MainActor in
            switch newPhase {
            case .active:
                if oldPhase == .background {
                    Analytics.shared.trackAppForeground()
                }
            case .background:
                Analytics.shared.trackAppBackground()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
