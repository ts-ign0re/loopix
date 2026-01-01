//
//  ImportedPhotosManager.swift
//  FilmBox
//
//  Manages the collection of user-imported photos with local storage
//

import Foundation
import Photos
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Imported Photo Model

/// Represents a photo imported into the app with local storage
struct ImportedPhoto: Identifiable, Hashable, Codable {
    let id: UUID
    let assetIdentifier: String
    let importedAt: Date
    var editedParametersData: Data?

    /// Version counter for thumbnail - incremented when thumbnail is regenerated
    /// Used to trigger UI refresh in HomePhotoCell
    var thumbnailVersion: Int = 0

    /// Local file name for the stored image
    var localFileName: String {
        "\(id.uuidString).heic"
    }

    /// Local file name for the thumbnail
    var thumbnailFileName: String {
        "\(id.uuidString)_thumb.heic"
    }

    init(asset: PHAsset) {
        self.id = UUID()
        self.assetIdentifier = asset.localIdentifier
        self.importedAt = Date()
        self.editedParametersData = nil
        self.thumbnailVersion = 0
    }

    init(id: UUID = UUID(), assetIdentifier: String, importedAt: Date = Date(), editedParametersData: Data? = nil, thumbnailVersion: Int = 0) {
        self.id = id
        self.assetIdentifier = assetIdentifier
        self.importedAt = importedAt
        self.editedParametersData = editedParametersData
        self.thumbnailVersion = thumbnailVersion
    }
}

// MARK: - Imported Photos Manager

/// Manages imported photos with local storage persistence
@Observable
@MainActor
final class ImportedPhotosManager {

    // MARK: - Singleton

    static let shared = ImportedPhotosManager()

    // MARK: - Properties

    /// All imported photos
    private(set) var photos: [ImportedPhoto] = []

    /// Selected photo IDs
    var selectedPhotoIDs: Set<UUID> = []

    /// Whether selection mode is active
    var isSelectionMode: Bool = false

    /// Loading state
    private(set) var isLoading: Bool = false

    // MARK: - Private

    private let userDefaultsKey = "importedPhotos"

    /// In-memory thumbnail cache for fast scrolling
    private let thumbnailCache = NSCache<NSString, UIImage>()

    /// Directory for storing imported images
    private var imagesDirectory: URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDir = documentsDir.appendingPathComponent("ImportedImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        return imagesDir
    }

    /// Directory for storing thumbnails
    private var thumbnailsDirectory: URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbsDir = documentsDir.appendingPathComponent("Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: thumbsDir, withIntermediateDirectories: true)
        return thumbsDir
    }

    // MARK: - Initialization

    private init() {
        // Configure thumbnail cache - limit to ~100MB assuming ~1MB per thumbnail
        thumbnailCache.countLimit = 100
        thumbnailCache.totalCostLimit = 100 * 1024 * 1024
        loadFromStorage()
    }

    // MARK: - Public API

    /// Import photos from PHAssets - saves full images locally
    func importPhotos(_ assets: [PHAsset]) {
        print("📥 Importing \(assets.count) photos")
        isLoading = true

        Task {
            for asset in assets {
                await importSingleAsset(asset)
            }

            await MainActor.run {
                self.isLoading = false
                self.saveMetadataToStorage()
            }
        }
    }

    /// Import a single asset - saves to local storage
    private func importSingleAsset(_ asset: PHAsset) async {
        // Check for duplicates
        let existingIdentifiers = Set(photos.map { $0.assetIdentifier })
        guard !existingIdentifiers.contains(asset.localIdentifier) else {
            print("⏭️ Skipping duplicate: \(asset.localIdentifier)")
            return
        }

        let photo = ImportedPhoto(asset: asset)

        // Request full-size image
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { [weak self] data, _, _, _ in
                guard let self = self, let imageData = data else {
                    print("❌ Failed to get image data for: \(asset.localIdentifier)")
                    continuation.resume()
                    return
                }

                // Save full image - preserve original data with EXIF orientation
                // Orientation will be applied when loading via loadCIImage()
                let imageURL = self.imagesDirectory.appendingPathComponent(photo.localFileName)
                do {
                    // Save original data to preserve EXIF orientation metadata
                    try imageData.write(to: imageURL)
                    print("✅ Saved full image: \(photo.localFileName)")

                    // Generate and save thumbnail
                    self.generateThumbnail(from: imageURL, for: photo)

                    // Add to photos array on main thread
                    Task { @MainActor in
                        self.photos.insert(photo, at: 0)
                    }
                } catch {
                    print("❌ Failed to save image: \(error)")
                }

                continuation.resume()
            }
        }
    }

    /// Generate thumbnail for a photo from already-saved image file
    private func generateThumbnail(from imageURL: URL, for photo: ImportedPhoto) {
        guard var ciImage = CIImage(contentsOf: imageURL) else { return }

        // Apply EXIF orientation if present
        if let orientation = ciImage.properties[kCGImagePropertyOrientation as String] as? Int32 {
            ciImage = ciImage.oriented(forExifOrientation: orientation)
        }

        // Scale to thumbnail size
        let maxSize: CGFloat = 512
        let scale = min(maxSize / ciImage.extent.width, maxSize / ciImage.extent.height, 1.0)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(photo.thumbnailFileName)

        if let heicData = context.heifRepresentation(
            of: scaledImage,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7]
        ) {
            try? heicData.write(to: thumbnailURL)
            print("✅ Saved thumbnail: \(photo.thumbnailFileName)")
        }
    }

    /// Remove photos by IDs - also deletes local files
    func removePhotos(_ ids: Set<UUID>) {
        for id in ids {
            if let photo = photos.first(where: { $0.id == id }) {
                // Delete local files
                let imageURL = imagesDirectory.appendingPathComponent(photo.localFileName)
                let thumbURL = thumbnailsDirectory.appendingPathComponent(photo.thumbnailFileName)
                try? FileManager.default.removeItem(at: imageURL)
                try? FileManager.default.removeItem(at: thumbURL)
            }
        }

        photos.removeAll { ids.contains($0.id) }
        selectedPhotoIDs.subtract(ids)
        saveMetadataToStorage()

        if selectedPhotoIDs.isEmpty {
            isSelectionMode = false
        }
    }

    /// Remove selected photos
    func removeSelectedPhotos() {
        removePhotos(selectedPhotoIDs)
    }

    /// Get local image URL for photo
    func getLocalImageURL(for photo: ImportedPhoto) -> URL {
        imagesDirectory.appendingPathComponent(photo.localFileName)
    }

    /// Get local thumbnail URL for photo
    func getThumbnailURL(for photo: ImportedPhoto) -> URL {
        thumbnailsDirectory.appendingPathComponent(photo.thumbnailFileName)
    }

    /// Load CIImage from local storage with proper orientation
    func loadCIImage(for photo: ImportedPhoto) -> CIImage? {
        let imageURL = getLocalImageURL(for: photo)
        guard var ciImage = CIImage(contentsOf: imageURL) else { return nil }

        // Apply EXIF orientation if present in the image properties
        if let orientation = ciImage.properties[kCGImagePropertyOrientation as String] as? Int32 {
            ciImage = ciImage.oriented(forExifOrientation: orientation)
        }

        return ciImage
    }

    /// Load UIImage from local storage
    func loadUIImage(for photo: ImportedPhoto) -> UIImage? {
        let imageURL = getLocalImageURL(for: photo)
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return UIImage(data: data)
    }

    /// Load thumbnail UIImage with in-memory caching
    func loadThumbnail(for photo: ImportedPhoto) -> UIImage? {
        let cacheKey = "\(photo.id.uuidString)_v\(photo.thumbnailVersion)" as NSString

        // Check cache first
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        // Load from disk
        let thumbURL = getThumbnailURL(for: photo)
        guard let data = try? Data(contentsOf: thumbURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // Store in cache
        thumbnailCache.setObject(image, forKey: cacheKey)
        return image
    }

    /// Clear thumbnail cache
    func clearThumbnailCache() {
        thumbnailCache.removeAllObjects()
    }

    /// Remove specific thumbnail from cache
    func invalidateThumbnailCache(for photoID: UUID, version: Int) {
        let cacheKey = "\(photoID.uuidString)_v\(version)" as NSString
        thumbnailCache.removeObject(forKey: cacheKey)
    }

    /// Check if local image exists
    func hasLocalImage(for photo: ImportedPhoto) -> Bool {
        let imageURL = getLocalImageURL(for: photo)
        return FileManager.default.fileExists(atPath: imageURL.path)
    }

    // MARK: - Legacy PHAsset support (for compatibility)

    /// Get PHAsset for imported photo (deprecated - use loadCIImage instead)
    func getAsset(for photo: ImportedPhoto) -> PHAsset? {
        let identifier = photo.assetIdentifier
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.firstObject
    }

    // MARK: - Selection

    /// Toggle selection for a photo
    func toggleSelection(_ photo: ImportedPhoto) {
        if !isSelectionMode {
            isSelectionMode = true
        }

        if selectedPhotoIDs.contains(photo.id) {
            selectedPhotoIDs.remove(photo.id)
            if selectedPhotoIDs.isEmpty {
                isSelectionMode = false
            }
        } else {
            selectedPhotoIDs.insert(photo.id)
        }
    }

    /// Check if photo is selected
    func isSelected(_ photo: ImportedPhoto) -> Bool {
        selectedPhotoIDs.contains(photo.id)
    }

    /// Clear all selections
    func clearSelection() {
        selectedPhotoIDs.removeAll()
        isSelectionMode = false
    }

    /// Select all photos
    func selectAll() {
        isSelectionMode = true
        selectedPhotoIDs = Set(photos.map { $0.id })
    }

    /// Number of selected photos
    var selectedCount: Int {
        selectedPhotoIDs.count
    }

    // MARK: - Persistence

    private func saveMetadataToStorage() {
        if let data = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let savedPhotos = try? JSONDecoder().decode([ImportedPhoto].self, from: data) else {
            return
        }

        // Only keep photos that have local files, sorted by import date (newest first)
        photos = savedPhotos
            .filter { hasLocalImage(for: $0) }
            .sorted { $0.importedAt > $1.importedAt }

        // Re-save if some were removed
        if photos.count != savedPhotos.count {
            saveMetadataToStorage()
        }
    }

    /// Reload photos (called after permission granted)
    func reloadPhotos() {
        loadFromStorage()
    }

    /// Update edited parameters for a photo
    func updateEditedParameters(for photoID: UUID, parameters: FilterParameters) {
        guard let index = photos.firstIndex(where: { $0.id == photoID }) else { return }
        photos[index].editedParametersData = try? JSONEncoder().encode(parameters)
        saveMetadataToStorage()
    }

    /// Get edited parameters for a photo
    func getEditedParameters(for photoID: UUID) -> FilterParameters? {
        guard let photo = photos.first(where: { $0.id == photoID }),
              let data = photo.editedParametersData else { return nil }
        return try? JSONDecoder().decode(FilterParameters.self, from: data)
    }

    /// Get selected photos for export with their local images and parameters
    func getSelectedPhotosForExport() -> [(asset: PHAsset, parameters: FilterParameters?)] {
        let selectedPhotos = photos.filter { selectedPhotoIDs.contains($0.id) }
        var result: [(asset: PHAsset, parameters: FilterParameters?)] = []

        for photo in selectedPhotos {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetIdentifier], options: nil)
            if let asset = fetchResult.firstObject {
                let params = getEditedParameters(for: photo.id)
                result.append((asset: asset, parameters: params))
            }
        }

        return result
    }

    /// Get selected photos for local export
    func getSelectedPhotosForLocalExport() -> [(photo: ImportedPhoto, parameters: FilterParameters?)] {
        let selectedPhotos = photos.filter { selectedPhotoIDs.contains($0.id) }
        return selectedPhotos.map { photo in
            (photo: photo, parameters: getEditedParameters(for: photo.id))
        }
    }

    // MARK: - Thumbnail Regeneration

    /// Regenerate thumbnail for a photo after editing
    @MainActor
    func regenerateThumbnail(for photoID: UUID) async {
        guard let index = photos.firstIndex(where: { $0.id == photoID }),
              let ciImage = loadCIImage(for: photos[index]) else {
            print("❌ Failed to load image for thumbnail regeneration")
            return
        }

        let photo = photos[index]

        // Get edited parameters if any
        let parameters = getEditedParameters(for: photoID)

        var processedImage = ciImage

        // Apply filter parameters FIRST (including crop) on full resolution
        if let params = parameters {
            if #available(iOS 17.0, *) {
                processedImage = await FilterEngine.shared.apply(params, to: processedImage)
            }
        }

        // Then scale to thumbnail size
        let maxSize: CGFloat = 512
        let scale = min(maxSize / processedImage.extent.width, maxSize / processedImage.extent.height, 1.0)
        let scaledImage = processedImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Save the new thumbnail
        let context = CIContext()
        let thumbnailURL = thumbnailsDirectory.appendingPathComponent(photo.thumbnailFileName)

        if let heicData = context.heifRepresentation(
            of: scaledImage,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7]
        ) {
            try? heicData.write(to: thumbnailURL)

            // Increment thumbnail version to trigger UI refresh
            photos[index].thumbnailVersion += 1
            saveMetadataToStorage()

            print("✅ Regenerated thumbnail for: \(photo.thumbnailFileName) (v\(photos[index].thumbnailVersion))")
        }
    }

    // MARK: - Storage Management

    /// Calculate total storage used by imported images and thumbnails
    func calculateStorageUsed() -> Int {
        var totalSize = 0

        // Calculate ImportedImages size
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            for fileURL in contents {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += fileSize
                }
            }
        }

        // Calculate Thumbnails size
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: thumbnailsDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            for fileURL in contents {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += fileSize
                }
            }
        }

        return totalSize
    }

    /// Check if storage limit is exceeded
    func isStorageLimitExceeded() -> Bool {
        let used = calculateStorageUsed()
        let limit = AppSettings.shared.storageLimitBytes
        return used >= limit
    }

    /// Get remaining storage space in bytes
    func getRemainingStorage() -> Int {
        let used = calculateStorageUsed()
        let limit = AppSettings.shared.storageLimitBytes
        return max(0, limit - used)
    }

    /// Clear all imported photos and thumbnails (preserves user presets and settings)
    func clearAllPhotos() {
        // Delete all files in ImportedImages
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: nil
        ) {
            for fileURL in contents {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        // Delete all files in Thumbnails
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: thumbnailsDirectory,
            includingPropertiesForKeys: nil
        ) {
            for fileURL in contents {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }

        // Clear photos array and metadata
        photos.removeAll()
        selectedPhotoIDs.removeAll()
        isSelectionMode = false
        thumbnailCache.removeAllObjects()
        saveMetadataToStorage()

        print("🗑️ Cleared all photos and thumbnails")
    }

    /// Get photo count
    var photoCount: Int {
        photos.count
    }
}
