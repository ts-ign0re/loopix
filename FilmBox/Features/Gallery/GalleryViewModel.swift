import Foundation
import Photos
import Observation

/// ViewModel for the Gallery screen managing photo library access and selection
@Observable
final class GalleryViewModel {

    // MARK: - Published Properties

    /// Current fetch result of photos
    private(set) var photos: PHFetchResult<PHAsset>?

    /// Set of selected photo identifiers
    var selectedPhotos: Set<String> = []

    /// Whether the gallery is in selection mode
    var isSelectionMode: Bool = false

    /// Currently selected album
    var currentAlbum: PHAssetCollection?

    /// Authorization status for photo library
    private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined

    /// Loading state
    private(set) var isLoading: Bool = false

    /// Error message if any
    private(set) var errorMessage: String?

    /// Whether to show album picker
    var showAlbumPicker: Bool = false

    // MARK: - Private Properties

    private let imageManager = PHCachingImageManager()
    private var previousPreheatRect: CGRect = .zero

    // MARK: - Computed Properties

    /// Number of selected photos
    var selectedCount: Int {
        selectedPhotos.count
    }

    /// Array of PHAssets for easier access
    var photoAssets: [PHAsset] {
        guard let photos = photos else { return [] }
        var assets: [PHAsset] = []
        photos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Selected PHAssets
    var selectedAssets: [PHAsset] {
        guard let photos = photos else { return [] }
        var assets: [PHAsset] = []
        photos.enumerateObjects { asset, _, _ in
            if self.selectedPhotos.contains(asset.localIdentifier) {
                assets.append(asset)
            }
        }
        return assets
    }

    /// Album title for display
    var albumTitle: String {
        currentAlbum?.localizedTitle ?? "Photos"
    }

    /// Whether all photos are selected
    var allSelected: Bool {
        guard let photos = photos else { return false }
        return selectedPhotos.count == photos.count && photos.count > 0
    }

    // MARK: - Initialization

    init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - Public Methods

    /// Request authorization and load photos
    @MainActor
    func requestAuthorizationAndLoad() async {
        isLoading = true
        errorMessage = nil

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status

        switch status {
        case .authorized, .limited:
            await loadPhotos()
        case .denied, .restricted:
            errorMessage = "Photo library access is required to use this feature. Please enable it in Settings."
            isLoading = false
        case .notDetermined:
            isLoading = false
        @unknown default:
            isLoading = false
        }
    }

    /// Load photos from the current album or all photos
    @MainActor
    func loadPhotos() async {
        isLoading = true
        errorMessage = nil

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeHiddenAssets = false

        if let album = currentAlbum {
            photos = PHAsset.fetchAssets(in: album, options: fetchOptions)
        } else {
            photos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }

        isLoading = false
    }

    /// Toggle selection for a photo
    func toggleSelection(for asset: PHAsset) {
        let identifier = asset.localIdentifier
        if selectedPhotos.contains(identifier) {
            selectedPhotos.remove(identifier)
        } else {
            selectedPhotos.insert(identifier)
        }

        // Auto-enable selection mode when first photo is selected
        if !selectedPhotos.isEmpty && !isSelectionMode {
            isSelectionMode = true
        }

        // Auto-disable selection mode when all photos are deselected
        if selectedPhotos.isEmpty && isSelectionMode {
            isSelectionMode = false
        }
    }

    /// Select all photos
    func selectAll() {
        guard let photos = photos else { return }
        selectedPhotos.removeAll()
        photos.enumerateObjects { asset, _, _ in
            self.selectedPhotos.insert(asset.localIdentifier)
        }
        isSelectionMode = true
    }

    /// Deselect all photos
    func deselectAll() {
        selectedPhotos.removeAll()
        isSelectionMode = false
    }

    /// Toggle selection mode
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedPhotos.removeAll()
        }
    }

    /// Set the current album and reload
    @MainActor
    func setAlbum(_ album: PHAssetCollection?) async {
        currentAlbum = album
        selectedPhotos.removeAll()
        await loadPhotos()
    }

    /// Check if a photo is selected
    func isSelected(_ asset: PHAsset) -> Bool {
        selectedPhotos.contains(asset.localIdentifier)
    }

    // MARK: - Prefetching

    /// Start caching images for the given assets (for prefetching)
    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
    }

    /// Stop caching images for the given assets
    func stopCaching(assets: [PHAsset], targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic

        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        )
    }

    /// Stop all caching
    func stopAllCaching() {
        imageManager.stopCachingImagesForAllAssets()
    }

    /// Update caching for visible and prefetch rects
    func updateCaching(visibleRect: CGRect, prefetchRect: CGRect, itemSize: CGSize) {
        guard let photos = photos, photos.count > 0 else { return }

        // Calculate indices for visible and prefetch areas
        let visibleAssets = assets(in: visibleRect, itemSize: itemSize)
        let prefetchAssets = assets(in: prefetchRect, itemSize: itemSize)

        // Start caching prefetch assets
        let assetsToCache = prefetchAssets.filter { !visibleAssets.contains($0) }
        if !assetsToCache.isEmpty {
            startCaching(assets: assetsToCache, targetSize: itemSize)
        }
    }

    /// Get assets in a given rect based on grid layout
    private func assets(in rect: CGRect, itemSize: CGSize) -> [PHAsset] {
        guard let photos = photos else { return [] }

        let columns = 4
        let startRow = max(0, Int(rect.minY / itemSize.height))
        let endRow = Int(ceil(rect.maxY / itemSize.height))

        let startIndex = startRow * columns
        let endIndex = min(endRow * columns, photos.count)

        guard startIndex < endIndex else { return [] }

        var assets: [PHAsset] = []
        for i in startIndex..<endIndex {
            assets.append(photos.object(at: i))
        }
        return assets
    }
}
