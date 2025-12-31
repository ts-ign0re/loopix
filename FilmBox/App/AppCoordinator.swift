import SwiftUI

/// App-wide navigation coordinator using iOS 17+ Observable macro
@Observable
final class AppCoordinator {

    // MARK: - Navigation Destinations

    /// All possible navigation destinations in the app
    enum Destination: Hashable {
        case gallery
        case editor(photoId: String)
        case filterBuilder
        case settings
        case export(photoId: String)
    }

    // MARK: - Properties

    /// Navigation path for programmatic navigation
    var path = NavigationPath()

    /// Currently presented sheet, if any
    var presentedSheet: Destination?

    /// Currently presented full screen cover, if any
    var presentedFullScreenCover: Destination?

    /// Whether the app is in editing mode
    var isEditing: Bool {
        if case .editor = currentDestination {
            return true
        }
        return false
    }

    /// The current top-level destination
    private(set) var currentDestination: Destination = .gallery

    // MARK: - Navigation Methods

    /// Navigate to the gallery view
    func showGallery() {
        path.removeLast(path.count)
        currentDestination = .gallery
    }

    /// Navigate to the photo editor
    /// - Parameter photoId: The unique identifier of the photo to edit
    func showEditor(photoId: String) {
        let destination = Destination.editor(photoId: photoId)
        path.append(destination)
        currentDestination = destination
    }

    /// Navigate to the filter builder
    func showFilterBuilder() {
        let destination = Destination.filterBuilder
        path.append(destination)
        currentDestination = destination
    }

    /// Present the filter builder as a sheet
    func presentFilterBuilderSheet() {
        presentedSheet = .filterBuilder
    }

    /// Navigate to settings
    func showSettings() {
        let destination = Destination.settings
        path.append(destination)
        currentDestination = destination
    }

    /// Present settings as a sheet
    func presentSettingsSheet() {
        presentedSheet = .settings
    }

    /// Navigate to export view
    /// - Parameter photoId: The unique identifier of the photo to export
    func showExport(photoId: String) {
        let destination = Destination.export(photoId: photoId)
        path.append(destination)
        currentDestination = destination
    }

    /// Present export as a sheet
    /// - Parameter photoId: The unique identifier of the photo to export
    func presentExportSheet(photoId: String) {
        presentedSheet = .export(photoId: photoId)
    }

    /// Dismiss any presented sheet
    func dismissSheet() {
        presentedSheet = nil
    }

    /// Dismiss any presented full screen cover
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }

    /// Go back one level in the navigation stack
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()

        // Update current destination based on remaining path
        if path.isEmpty {
            currentDestination = .gallery
        }
    }

    /// Pop to the root of the navigation stack
    func popToRoot() {
        path.removeLast(path.count)
        currentDestination = .gallery
    }
}

// MARK: - Destination View Builder

extension AppCoordinator {
    /// Build the view for a given destination
    @ViewBuilder
    func view(for destination: Destination) -> some View {
        switch destination {
        case .gallery:
            GalleryViewPlaceholder()
        case .editor(let photoId):
            EditorViewPlaceholder(photoId: photoId)
        case .filterBuilder:
            FilterBuilderViewPlaceholder()
        case .settings:
            SettingsViewPlaceholder()
        case .export(let photoId):
            ExportViewPlaceholder(photoId: photoId)
        }
    }
}

// MARK: - Placeholder Views

/// Placeholder for the gallery view
struct GalleryViewPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Gallery")
                .font(.title)
                .fontWeight(.semibold)
            Text("Your photos will appear here")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// Placeholder for the editor view
struct EditorViewPlaceholder: View {
    let photoId: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Editor")
                .font(.title)
                .fontWeight(.semibold)
            Text("Editing photo: \(photoId)")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// Placeholder for the filter builder view
struct FilterBuilderViewPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Filter Builder")
                .font(.title)
                .fontWeight(.semibold)
            Text("Create custom filters")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// Placeholder for the settings view
struct SettingsViewPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Settings")
                .font(.title)
                .fontWeight(.semibold)
            Text("App preferences")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

/// Placeholder for the export view
struct ExportViewPlaceholder: View {
    let photoId: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Export")
                .font(.title)
                .fontWeight(.semibold)
            Text("Exporting photo: \(photoId)")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
