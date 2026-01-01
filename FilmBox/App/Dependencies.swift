import SwiftUI

/// Dependency injection container for app-wide services
/// Provides singleton access to core services and managers
@Observable
@MainActor
final class Dependencies {

    // MARK: - Singleton

    /// Shared instance of the dependencies container
    static let shared = Dependencies()

    // MARK: - Services

    /// Filter processing engine (actor singleton)
    @available(iOS 17.0, *)
    var filterEngine: FilterEngine {
        FilterEngine.shared
    }

    /// Thumbnail caching service (actor singleton)
    var thumbnailCache: ThumbnailCache {
        ThumbnailCache.shared
    }

    /// Photo library access manager (actor singleton)
    var photoLibraryManager: PhotoLibraryManager {
        PhotoLibraryManager.shared
    }

    /// Filter preset storage
    let filterStorage: FilterStorage

    // MARK: - Initialization

    private init() {
        self.filterStorage = FilterStorage.shared
    }
}
