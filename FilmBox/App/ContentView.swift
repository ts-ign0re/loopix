import SwiftUI

/// Root content view with navigation stack
/// Uses AppCoordinator for programmatic navigation
struct ContentView: View {

    /// App-wide navigation coordinator
    @Environment(AppCoordinator.self) private var coordinator

    /// Shared dependencies
    @Environment(Dependencies.self) private var dependencies

    var body: some View {
        @Bindable var coordinator = coordinator

        NavigationStack(path: $coordinator.path) {
            // Root view: Gallery
            GalleryViewPlaceholder()
                .navigationTitle("FilmBox")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            coordinator.presentSettingsSheet()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            coordinator.presentFilterBuilderSheet()
                        } label: {
                            Image(systemName: "wand.and.stars")
                        }
                    }
                }
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    coordinator.view(for: destination)
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
        .sheet(item: $coordinator.presentedSheet) { destination in
            NavigationStack {
                coordinator.view(for: destination)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") {
                                coordinator.dismissSheet()
                            }
                        }
                    }
            }
        }
        .fullScreenCover(item: $coordinator.presentedFullScreenCover) { destination in
            NavigationStack {
                coordinator.view(for: destination)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                coordinator.dismissFullScreenCover()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Identifiable Conformance for Destinations

extension AppCoordinator.Destination: Identifiable {
    var id: String {
        switch self {
        case .gallery:
            return "gallery"
        case .editor(let photoId):
            return "editor-\(photoId)"
        case .filterBuilder:
            return "filterBuilder"
        case .settings:
            return "settings"
        case .export(let photoId):
            return "export-\(photoId)"
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(AppCoordinator())
        .environment(Dependencies.shared)
}
