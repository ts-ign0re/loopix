import Foundation
import Photos
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

/// Thread-safe thumbnail cache using actor isolation
/// Provides memory and disk caching for photo thumbnails with optional filter application
actor ThumbnailCache {

    // MARK: - Constants

    private static let targetSize = CGSize(width: 512, height: 512)
    private static let memoryCacheLimit = 100
    private static let diskCacheDirectoryName = "ThumbnailCache"

    // MARK: - Cache Storage

    /// Memory cache using NSCache for automatic memory management
    private let memoryCache: NSCache<NSString, CGImageWrapper>

    /// URL to the disk cache directory
    private let diskCacheURL: URL

    // MARK: - Initialization

    init() {
        // Configure memory cache
        let cache = NSCache<NSString, CGImageWrapper>()
        cache.countLimit = Self.memoryCacheLimit
        self.memoryCache = cache

        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheURL = cacheDirectory.appendingPathComponent(Self.diskCacheDirectoryName, isDirectory: true)

        // Create disk cache directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    // MARK: - Public Methods

    /// Retrieves or generates a thumbnail for the given asset with optional filter
    /// - Parameters:
    ///   - asset: The PHAsset to generate a thumbnail for
    ///   - filter: Optional filter preset to apply
    /// - Returns: The cached or generated thumbnail, or nil if generation fails
    func thumbnail(for asset: PHAsset, filter: FilterPreset?) async -> CGImage? {
        let key = cacheKey(asset: asset, filter: filter)

        // Check memory cache first
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached.image
        }

        // Check disk cache
        if let diskImage = await loadFromDisk(key: key) {
            // Store in memory cache for faster subsequent access
            memoryCache.setObject(CGImageWrapper(diskImage), forKey: key as NSString)
            return diskImage
        }

        // Generate new thumbnail
        guard let thumbnail = await generateThumbnail(asset: asset, filter: filter) else {
            return nil
        }

        // Store in both caches
        memoryCache.setObject(CGImageWrapper(thumbnail), forKey: key as NSString)
        await saveToDisk(thumbnail, key: key)

        return thumbnail
    }

    /// Preloads thumbnails for multiple assets in parallel
    /// - Parameters:
    ///   - assets: Array of PHAssets to preload
    ///   - filter: Optional filter preset to apply
    func preloadThumbnails(for assets: [PHAsset], filter: FilterPreset?) async {
        await withTaskGroup(of: Void.self) { group in
            for asset in assets {
                group.addTask {
                    _ = await self.thumbnail(for: asset, filter: filter)
                }
            }
        }
    }

    /// Clears all cached thumbnails from memory and disk
    func clearCache() async {
        // Clear memory cache
        memoryCache.removeAllObjects()

        // Clear disk cache
        if let contents = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: nil
        ) {
            for fileURL in contents {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// Returns the total size of the disk cache in bytes
    /// - Returns: Size of disk cache in bytes
    func cacheSize() async -> Int {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        var totalSize = 0
        for fileURL in contents {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    // MARK: - Helper Methods

    /// Generates a unique cache key for an asset and filter combination
    /// - Parameters:
    ///   - asset: The PHAsset
    ///   - filter: Optional filter preset
    /// - Returns: A unique string key for caching
    private func cacheKey(asset: PHAsset, filter: FilterPreset?) -> String {
        let assetIdentifier = asset.localIdentifier
        let modificationDate = asset.modificationDate?.timeIntervalSince1970 ?? 0

        // Include filter ID and parameter hash for proper cache invalidation
        let filterPart: String
        if let filter = filter {
            // Hash the filter parameters to detect changes
            let paramHash = filter.parameters.hashValue
            let clutPart = filter.clutPath ?? "noclut"
            let intensityPart = Int(filter.clutIntensity)
            filterPart = "\(filter.id.uuidString)_\(paramHash)_\(clutPart)_\(intensityPart)"
        } else {
            filterPart = "original"
        }

        return "\(assetIdentifier)_\(filterPart)_\(Int(modificationDate))"
            .replacingOccurrences(of: "/", with: "_")
    }

    /// Generates a thumbnail for the given asset with optional filter application
    /// - Parameters:
    ///   - asset: The PHAsset to generate a thumbnail for
    ///   - filter: Optional filter preset to apply
    /// - Returns: The generated thumbnail, or nil if generation fails
    private func generateThumbnail(asset: PHAsset, filter: FilterPreset?) async -> CGImage? {
        // Request image from Photos framework
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        options.resizeMode = .exact

        let targetSize = Self.targetSize
        let contentMode = PHImageContentMode.aspectFill

        // Fetch the image using async/await wrapper
        let image: CGImage? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, info in
                // Check if this is the final result (not a degraded placeholder)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image?.cgImage)
                }
            }
        }

        guard let cgImage = image else {
            return nil
        }

        // Apply filter if provided and has effects or CLUT
        if let filter = filter, (filter.parameters.hasAdjustments || filter.usesCLUT) {
            return await applyFilter(filter, to: cgImage)
        }

        return cgImage
    }

    /// Applies a filter preset to a CGImage using FilterEngine
    /// - Parameters:
    ///   - filter: The filter preset to apply
    ///   - image: The source image
    /// - Returns: The filtered image, or the original if filtering fails
    private func applyFilter(_ filter: FilterPreset, to image: CGImage) async -> CGImage? {
        // Use FilterEngine to apply the filter preset
        if #available(iOS 17.0, *) {
            return await FilterEngine.shared.process(cgImage: image, with: filter)
        } else {
            // Fallback for older iOS versions - return original
            return image
        }
    }

    /// Loads a cached thumbnail from disk
    /// - Parameter key: The cache key
    /// - Returns: The cached image, or nil if not found
    private func loadFromDisk(key: String) async -> CGImage? {
        let sanitizedKey = sanitizeFilename(key)

        // Try WebP first
        let webpURL = diskCacheURL.appendingPathComponent("\(sanitizedKey).webp")
        if FileManager.default.fileExists(atPath: webpURL.path) {
            if let image = loadImage(from: webpURL) {
                return image
            }
        }

        // Fallback to JPEG
        let jpegURL = diskCacheURL.appendingPathComponent("\(sanitizedKey).jpg")
        if FileManager.default.fileExists(atPath: jpegURL.path) {
            if let image = loadImage(from: jpegURL) {
                return image
            }
        }

        return nil
    }

    /// Loads an image from a file URL
    /// - Parameter url: The file URL
    /// - Returns: The loaded CGImage, or nil if loading fails
    private func loadImage(from url: URL) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }

    /// Saves a thumbnail to disk cache
    /// - Parameters:
    ///   - image: The image to save
    ///   - key: The cache key
    private func saveToDisk(_ image: CGImage, key: String) async {
        let sanitizedKey = sanitizeFilename(key)

        // Try WebP first if available (iOS 14+)
        if #available(iOS 14.0, *) {
            let webpURL = diskCacheURL.appendingPathComponent("\(sanitizedKey).webp")
            if saveImage(image, to: webpURL, type: UTType.webP.identifier) {
                return
            }
        }

        // Fallback to JPEG
        let jpegURL = diskCacheURL.appendingPathComponent("\(sanitizedKey).jpg")
        _ = saveImage(image, to: jpegURL, type: UTType.jpeg.identifier)
    }

    /// Saves an image to a file URL
    /// - Parameters:
    ///   - image: The CGImage to save
    ///   - url: The destination URL
    ///   - type: The UTI type identifier
    /// - Returns: True if save succeeded
    @discardableResult
    private func saveImage(_ image: CGImage, to url: URL, type: String) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            type as CFString,
            1,
            nil
        ) else {
            return false
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }

    /// Sanitizes a cache key for use as a filename
    /// - Parameter key: The original key
    /// - Returns: A sanitized filename-safe string
    private func sanitizeFilename(_ key: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return key.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - CGImage Wrapper for NSCache

/// Wrapper class to store CGImage in NSCache (which requires class types)
private final class CGImageWrapper: @unchecked Sendable {
    let image: CGImage

    init(_ image: CGImage) {
        self.image = image
    }
}

// MARK: - Shared Instance

extension ThumbnailCache {
    /// Shared singleton instance for app-wide thumbnail caching
    static let shared = ThumbnailCache()
}
