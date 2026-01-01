import SwiftUI
import CoreImage

// MARK: - Filter Preview Cache

/// Actor that manages filter preview image generation and caching
/// Uses a test image to show how each filter affects photos
@available(iOS 17.0, *)
actor FilterPreviewCache {

    // MARK: - Singleton

    static let shared = FilterPreviewCache()

    // MARK: - Properties

    /// Preview image size (square thumbnails)
    private let previewSize = CGSize(width: 200, height: 200)

    /// In-memory cache for quick access
    private var memoryCache: [UUID: CGImage] = [:]

    /// URL for disk cache directory
    private let cacheDirectory: URL

    /// Source image for previews (loaded from assets)
    private var sourceImage: CIImage?

    /// CIContext for rendering
    private let context: CIContext

    /// Flag to track if initial generation has been done
    private var initialGenerationCompleted = false

    // MARK: - Initialization

    private init() {
        // Create cache directory
        let cacheDir = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FilterPreviews", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        self.cacheDirectory = cacheDir

        // Create CIContext
        self.context = CIContext(options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer: false
        ])
    }

    // MARK: - Source Image

    /// Load the source preview image from assets
    private func loadSourceImage() -> CIImage? {
        if let source = sourceImage {
            return source
        }

        // Load from Assets.xcassets
        guard let uiImage = UIImage(named: "FilterPreviewImage"),
              let ciImage = CIImage(image: uiImage) else {
            print("FilterPreviewCache: Failed to load FilterPreviewImage from assets")
            return nil
        }

        // Crop to square and resize
        let extent = ciImage.extent
        let minDim = min(extent.width, extent.height)
        let cropRect = CGRect(
            x: (extent.width - minDim) / 2,
            y: (extent.height - minDim) / 2,
            width: minDim,
            height: minDim
        )

        let cropped = ciImage.cropped(to: cropRect)
        let scale = previewSize.width / minDim
        let scaled = cropped.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        sourceImage = scaled
        return scaled
    }

    // MARK: - Preview Generation

    /// Generate preview for a single filter
    /// - Parameter filter: The filter preset to generate preview for
    /// - Returns: CGImage preview or nil if generation failed
    func generatePreview(for filter: FilterPreset) async -> CGImage? {
        guard let source = loadSourceImage() else { return nil }

        // Apply filter using FilterEngine
        let processed = await FilterEngine.shared.apply(filter, to: source)

        // Render to CGImage
        guard let cgImage = context.createCGImage(processed, from: processed.extent) else {
            return nil
        }

        // Cache in memory
        memoryCache[filter.id] = cgImage

        // Save to disk
        await saveToDisk(cgImage, for: filter.id)

        return cgImage
    }

    /// Get cached preview for a filter (from memory or disk)
    /// - Parameter filter: The filter preset
    /// - Returns: Cached CGImage or nil if not cached
    func getCachedPreview(for filter: FilterPreset) async -> CGImage? {
        // Check memory cache first
        if let cached = memoryCache[filter.id] {
            return cached
        }

        // Try loading from disk
        if let diskCached = await loadFromDisk(for: filter.id) {
            memoryCache[filter.id] = diskCached
            return diskCached
        }

        return nil
    }

    /// Get or generate preview for a filter
    /// - Parameter filter: The filter preset
    /// - Returns: CGImage preview
    func getPreview(for filter: FilterPreset) async -> CGImage? {
        // Try cached first
        if let cached = await getCachedPreview(for: filter) {
            return cached
        }

        // Generate if not cached
        return await generatePreview(for: filter)
    }

    // MARK: - Batch Operations

    /// Generate previews for all filters on first app start
    /// - Parameter filters: Array of filter presets
    func generateInitialPreviews(for filters: [FilterPreset]) async {
        guard !initialGenerationCompleted else { return }

        // Check if previews already exist
        let needsGeneration = filters.filter { filter in
            let url = cacheURL(for: filter.id)
            return !FileManager.default.fileExists(atPath: url.path)
        }

        // Generate missing previews
        for filter in needsGeneration {
            _ = await generatePreview(for: filter)
        }

        initialGenerationCompleted = true
    }

    /// Regenerate preview for a filter (called when filter is modified)
    /// - Parameter filter: The modified filter preset
    func regeneratePreview(for filter: FilterPreset) async {
        // Remove old cache
        memoryCache.removeValue(forKey: filter.id)
        await deleteFromDisk(for: filter.id)

        // Generate new preview
        _ = await generatePreview(for: filter)
    }

    /// Delete preview for a filter (called when filter is deleted)
    /// - Parameter filterId: The ID of the deleted filter
    func deletePreview(for filterId: UUID) async {
        memoryCache.removeValue(forKey: filterId)
        await deleteFromDisk(for: filterId)
    }

    // MARK: - Disk Cache

    private func cacheURL(for filterId: UUID) -> URL {
        cacheDirectory.appendingPathComponent("\(filterId.uuidString).jpg")
    }

    private func saveToDisk(_ image: CGImage, for filterId: UUID) async {
        let url = cacheURL(for: filterId)

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return }

        CGImageDestinationAddImage(destination, image, [
            kCGImageDestinationLossyCompressionQuality: 0.85
        ] as CFDictionary)

        CGImageDestinationFinalize(destination)
    }

    private func loadFromDisk(for filterId: UUID) async -> CGImage? {
        let url = cacheURL(for: filterId)

        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                  jpegDataProviderSource: provider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              ) else {
            return nil
        }

        return image
    }

    private func deleteFromDisk(for filterId: UUID) async {
        let url = cacheURL(for: filterId)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Cache Management

    /// Clear all cached previews
    func clearCache() async {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        initialGenerationCompleted = false
    }

    /// Get cache size in bytes
    func getCacheSize() async -> Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var totalSize: Int64 = 0

        for fileURL in contents {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else { continue }
            totalSize += Int64(fileSize)
        }

        return totalSize
    }
}

// MARK: - SwiftUI Image Extension

@available(iOS 17.0, *)
extension FilterPreviewCache {
    /// Get preview as SwiftUI Image
    func getPreviewImage(for filter: FilterPreset) async -> Image? {
        guard let cgImage = await getPreview(for: filter) else {
            return nil
        }
        return Image(decorative: cgImage, scale: 1.0)
    }
}
