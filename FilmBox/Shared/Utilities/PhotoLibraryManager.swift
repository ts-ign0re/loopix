//
//  PhotoLibraryManager.swift
//  FilmBox
//
//  Created for FilmBox iOS App
//

import Photos
import UIKit

// MARK: - Photo Library Manager

/// Actor for thread-safe Photos framework access
actor PhotoLibraryManager {

    // MARK: - Shared Instance

    /// Shared instance for convenient access
    static let shared = PhotoLibraryManager()

    // MARK: - Properties

    /// Cached image manager for efficient image requests
    private let imageManager = PHCachingImageManager()

    /// Default options for image requests
    private let defaultImageOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        return options
    }()

    // MARK: - Initialization

    init() {
        // Configure caching image manager
        imageManager.allowsCachingHighQualityImages = true
    }

    // MARK: - Authorization

    /// Current authorization status for photo library access
    nonisolated var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Checks if photo library access is authorized
    nonisolated var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    /// Requests authorization to access the photo library
    /// - Returns: The resulting authorization status
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Ensures photo library access is authorized, requesting if needed
    /// - Throws: PhotoLibraryError.accessDenied if access is denied
    func ensureAuthorization() async throws {
        let status = authorizationStatus

        switch status {
        case .authorized, .limited:
            return
        case .notDetermined:
            let newStatus = await requestAuthorization()
            if newStatus != .authorized && newStatus != .limited {
                throw PhotoLibraryError.accessDenied
            }
        case .denied, .restricted:
            throw PhotoLibraryError.accessDenied
        @unknown default:
            throw PhotoLibraryError.accessDenied
        }
    }

    // MARK: - Fetch All Photos

    /// Fetches all photos from the library
    /// - Parameter options: Optional fetch options for filtering and sorting
    /// - Returns: A PHFetchResult containing PHAssets
    func fetchAllPhotos(options: PHFetchOptions? = nil) async throws -> PHFetchResult<PHAsset> {
        try await ensureAuthorization()

        let fetchOptions = options ?? {
            let opts = PHFetchOptions()
            opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            return opts
        }()

        return PHAsset.fetchAssets(with: fetchOptions)
    }

    /// Fetches all photos as an array
    /// - Parameter options: Optional fetch options
    /// - Returns: An array of PHAssets
    func fetchAllPhotosArray(options: PHFetchOptions? = nil) async throws -> [PHAsset] {
        let result = try await fetchAllPhotos(options: options)
        return result.toArray()
    }

    // MARK: - Fetch by Album

    /// Fetches all user-created albums
    /// - Returns: A PHFetchResult containing PHAssetCollections
    func fetchAlbums() async throws -> PHFetchResult<PHAssetCollection> {
        try await ensureAuthorization()

        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
    }

    /// Fetches all smart albums (e.g., Favorites, Recently Added)
    /// - Returns: A PHFetchResult containing PHAssetCollections
    func fetchSmartAlbums() async throws -> PHFetchResult<PHAssetCollection> {
        try await ensureAuthorization()

        return PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
    }

    /// Fetches photos from a specific album
    /// - Parameters:
    ///   - album: The album to fetch photos from
    ///   - options: Optional fetch options
    /// - Returns: A PHFetchResult containing PHAssets
    func fetchPhotos(from album: PHAssetCollection, options: PHFetchOptions? = nil) async throws -> PHFetchResult<PHAsset> {
        try await ensureAuthorization()

        let fetchOptions = options ?? {
            let opts = PHFetchOptions()
            opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            return opts
        }()

        return PHAsset.fetchAssets(in: album, options: fetchOptions)
    }

    /// Fetches photos from an album as an array
    /// - Parameters:
    ///   - album: The album to fetch photos from
    ///   - options: Optional fetch options
    /// - Returns: An array of PHAssets
    func fetchPhotosArray(from album: PHAssetCollection, options: PHFetchOptions? = nil) async throws -> [PHAsset] {
        let result = try await fetchPhotos(from: album, options: options)
        return result.toArray()
    }

    // MARK: - Request Image

    /// Requests an image for the specified asset at the target size
    /// - Parameters:
    ///   - asset: The PHAsset to request an image for
    ///   - targetSize: The desired size for the image
    ///   - contentMode: How the image should fit the target size
    ///   - options: Optional image request options
    /// - Returns: A tuple containing the UIImage and degraded flag
    func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        options: PHImageRequestOptions? = nil
    ) async -> (image: UIImage?, isDegraded: Bool) {
        await withCheckedContinuation { continuation in
            let requestOptions = options ?? defaultImageOptions

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: requestOptions
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                // Only return on final image (not degraded preview)
                if !isDegraded || requestOptions.deliveryMode == .fastFormat {
                    continuation.resume(returning: (image, isDegraded))
                }
            }
        }
    }

    /// Requests an image for the specified asset, returning only the image
    /// - Parameters:
    ///   - asset: The PHAsset to request an image for
    ///   - targetSize: The desired size for the image
    /// - Returns: A UIImage, or nil if the request fails
    func requestImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let result = await requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill)
        return result.image
    }

    // MARK: - Request Full Resolution Image

    /// Requests the full resolution image for the specified asset
    /// - Parameters:
    ///   - asset: The PHAsset to request the image for
    ///   - options: Optional image request options
    /// - Returns: A UIImage, or nil if the request fails
    func requestFullResolutionImage(
        for asset: PHAsset,
        options: PHImageRequestOptions? = nil
    ) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let requestOptions = options ?? {
                let opts = PHImageRequestOptions()
                opts.deliveryMode = .highQualityFormat
                opts.isNetworkAccessAllowed = true
                opts.isSynchronous = false
                return opts
            }()

            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: requestOptions
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                // Only return on final image
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// Requests full resolution image data for the specified asset
    /// - Parameter asset: The PHAsset to request data for
    /// - Returns: A tuple containing the data, UTI, and orientation
    func requestFullResolutionImageData(
        for asset: PHAsset
    ) async -> (data: Data?, uti: String?, orientation: CGImagePropertyOrientation) {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, uti, orientation, _ in
                continuation.resume(returning: (data, uti, orientation))
            }
        }
    }

    // MARK: - Caching

    /// Starts caching images for the specified assets
    /// - Parameters:
    ///   - assets: The assets to cache
    ///   - targetSize: The size to cache at
    ///   - contentMode: The content mode for caching
    func startCaching(
        assets: [PHAsset],
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill
    ) {
        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: contentMode,
            options: defaultImageOptions
        )
    }

    /// Stops caching images for the specified assets
    /// - Parameters:
    ///   - assets: The assets to stop caching
    ///   - targetSize: The size that was being cached
    ///   - contentMode: The content mode that was being used
    func stopCaching(
        assets: [PHAsset],
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill
    ) {
        imageManager.stopCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: contentMode,
            options: defaultImageOptions
        )
    }

    /// Stops all image caching
    func stopCachingAll() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Photo Library Changes

    /// Registers an observer for photo library changes
    /// - Parameter observer: The observer to register
    nonisolated func registerChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        PHPhotoLibrary.shared().register(observer)
    }

    /// Unregisters an observer for photo library changes
    /// - Parameter observer: The observer to unregister
    nonisolated func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
        PHPhotoLibrary.shared().unregisterChangeObserver(observer)
    }
}

// MARK: - Photo Library Errors

enum PhotoLibraryError: Error, LocalizedError {
    case accessDenied
    case fetchFailed
    case assetNotFound
    case imageRequestFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photo library access was denied. Please enable access in Settings."
        case .fetchFailed:
            return "Failed to fetch photos from the library."
        case .assetNotFound:
            return "The requested photo could not be found."
        case .imageRequestFailed:
            return "Failed to load the image."
        }
    }
}

// MARK: - PHFetchResult Extension

extension PHFetchResult where ObjectType == PHAsset {

    /// Converts the fetch result to an array of PHAssets
    func toArray() -> [PHAsset] {
        var assets: [PHAsset] = []
        assets.reserveCapacity(count)
        enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Returns assets in the specified range
    func assets(in range: Range<Int>) -> [PHAsset] {
        let validRange = range.clamped(to: 0..<count)
        return (validRange.lowerBound..<validRange.upperBound).map { object(at: $0) }
    }
}

extension PHFetchResult where ObjectType == PHAssetCollection {

    /// Converts the fetch result to an array of PHAssetCollections
    func toArray() -> [PHAssetCollection] {
        var collections: [PHAssetCollection] = []
        collections.reserveCapacity(count)
        enumerateObjects { collection, _, _ in
            collections.append(collection)
        }
        return collections
    }
}

// MARK: - PHAsset Extension

extension PHAsset {

    /// Returns the aspect ratio (width / height) of the asset
    var aspectRatio: CGFloat {
        guard pixelHeight > 0 else { return 1.0 }
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }

    /// Returns the pixel size of the asset
    var pixelSize: CGSize {
        CGSize(width: pixelWidth, height: pixelHeight)
    }
}
