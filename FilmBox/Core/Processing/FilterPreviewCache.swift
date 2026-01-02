import Foundation
import Photos
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import UIKit

/// Specialized cache for filter preview thumbnails in the filter strip
/// Optimized for 350+ presets with small size, progressive loading, and cancellation support
@available(iOS 17.0, *)
actor FilterPreviewCache {

    // MARK: - Types

    /// Priority level for preview generation
    enum LoadPriority: Int, Comparable {
        case high = 0      // Currently visible
        case medium = 1    // About to scroll into view
        case low = 2       // Background preload

        static func < (lhs: LoadPriority, rhs: LoadPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Request for preview generation
    struct PreviewRequest: Sendable {
        let presetID: UUID
        let clutPath: String?
        let priority: LoadPriority
    }

    // MARK: - Constants

    /// Small preview size optimized for filter strip (16x smaller than 512px)
    private static let previewSize = CGSize(width: 128, height: 128)

    /// Maximum in-memory previews (128x128 ~= 64KB each, 200 × 64KB = 12.8MB)
    private static let memoryCacheLimit = 200

    /// Disk cache directory
    private static let diskCacheDirectoryName = "FilterPreviews"

    /// Disk cache quality (lower for smaller files)
    private static let diskQuality: CGFloat = 0.7

    // MARK: - State

    /// Memory cache for quick access
    private let memoryCache: NSCache<NSString, CGImageWrapper>

    /// Disk cache URL
    private let diskCacheURL: URL

    /// Reference image for generating previews (the sample image all filters are applied to)
    private var referenceImage: CGImage?

    /// Active generation tasks (for cancellation)
    private var activeTasks: [UUID: Task<CGImage?, Never>] = [:]

    /// Pending requests queue
    private var pendingRequests: [PreviewRequest] = []

    /// Maximum concurrent generations
    private let maxConcurrentGenerations = 4

    /// Current generation count
    private var currentGenerationCount = 0

    /// CIContext for rendering
    private let ciContext: CIContext

    // MARK: - Initialization

    init() {
        // Configure memory cache
        let cache = NSCache<NSString, CGImageWrapper>()
        cache.countLimit = Self.memoryCacheLimit
        cache.name = "FilterPreviewCache"
        self.memoryCache = cache

        // Setup disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheURL = cacheDirectory.appendingPathComponent(Self.diskCacheDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Setup CIContext
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ])

        // Load bundled reference image from Asset Catalog
        self.referenceImage = Self.loadBundledReferenceImageSync()
    }

    /// Load the bundled reference image from Asset Catalog (synchronous, non-isolated)
    private nonisolated static func loadBundledReferenceImageSync() -> CGImage? {
        // Try to load from Asset Catalog first
        if let uiImage = UIImage(named: "FilterPreviewImage"),
           let cgImage = uiImage.cgImage {
            return scaleImageSync(cgImage, to: previewSize)
        }

        // Fallback: try to load from bundle directly
        if let url = Bundle.main.url(forResource: "image", withExtension: "jpg"),
           let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
            return scaleImageSync(cgImage, to: previewSize)
        }

        return nil
    }

    /// Scale image synchronously with aspect-fill (cover) - non-isolated helper
    private nonisolated static func scaleImageSync(_ image: CGImage, to size: CGSize) -> CGImage {
        let targetWidth = Int(size.width)
        let targetHeight = Int(size.height)

        let sourceWidth = CGFloat(image.width)
        let sourceHeight = CGFloat(image.height)

        // Calculate scale to cover (aspect-fill)
        let scaleX = size.width / sourceWidth
        let scaleY = size.height / sourceHeight
        let scale = max(scaleX, scaleY)  // Use max for cover/fill

        // Calculate scaled size and crop offset (center crop)
        let scaledWidth = sourceWidth * scale
        let scaledHeight = sourceHeight * scale
        let offsetX = (scaledWidth - size.width) / 2
        let offsetY = (scaledHeight - size.height) / 2

        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }

        context.interpolationQuality = .high

        // Draw with offset to center-crop
        let drawRect = CGRect(
            x: -offsetX,
            y: -offsetY,
            width: scaledWidth,
            height: scaledHeight
        )
        context.draw(image, in: drawRect)

        return context.makeImage() ?? image
    }

    // MARK: - Reference Image

    /// Set the reference image used for all filter previews
    /// - Parameter image: The reference CGImage (will be scaled to preview size)
    func setReferenceImage(_ image: CGImage) {
        // Scale reference image to preview size
        let scaledImage = scaleImage(image, to: Self.previewSize)
        self.referenceImage = scaledImage

        // Clear existing previews since reference changed
        clearMemoryCache()
    }

    /// Set reference image from a PHAsset
    /// - Parameter asset: The asset to use as reference
    func setReferenceImage(from asset: PHAsset) async {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false

        let image: CGImage? = await withCheckedContinuation { (continuation: CheckedContinuation<CGImage?, Never>) in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: Self.previewSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image?.cgImage)
                }
            }
        }
        if let image {
            await setReferenceImage(image)
        }
    }

    // MARK: - Preview Access

    /// Get preview for a filter preset
    /// - Parameters:
    ///   - preset: The filter preset
    ///   - priority: Load priority for queue ordering
    /// - Returns: Cached or generated preview, nil if not available yet
    func preview(for preset: FilterPreset, priority: LoadPriority = .medium) async -> CGImage? {
        let key = cacheKey(for: preset)

        // Check memory cache
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached.image
        }

        // Check disk cache
        if let diskImage = loadFromDisk(key: key) {
            memoryCache.setObject(CGImageWrapper(diskImage), forKey: key as NSString)
            return diskImage
        }

        // Generate if we have a reference image
        guard referenceImage != nil else {
            return nil
        }

        // Request generation
        return await generatePreview(for: preset, priority: priority)
    }

    /// Check if preview exists without loading
    /// - Parameter preset: The filter preset
    /// - Returns: True if preview is cached
    func hasPreview(for preset: FilterPreset) -> Bool {
        let key = cacheKey(for: preset)
        if memoryCache.object(forKey: key as NSString) != nil {
            return true
        }
        return FileManager.default.fileExists(atPath: diskURL(for: key).path)
    }

    /// Get preview synchronously if cached (does not generate)
    /// - Parameter preset: The filter preset
    /// - Returns: Cached preview or nil
    func cachedPreview(for preset: FilterPreset) -> CGImage? {
        let key = cacheKey(for: preset)
        return memoryCache.object(forKey: key as NSString)?.image
    }

    // MARK: - Bulk Operations

    /// Request previews for multiple presets with priority ordering
    /// - Parameters:
    ///   - presets: Presets to load
    ///   - priority: Load priority
    func requestPreviews(for presets: [FilterPreset], priority: LoadPriority) {
        let requests = presets.map { preset in
            PreviewRequest(
                presetID: preset.id,
                clutPath: preset.clutPath,
                priority: priority
            )
        }

        // Add to pending queue, sorted by priority
        pendingRequests.append(contentsOf: requests)
        pendingRequests.sort { $0.priority < $1.priority }
    }

    /// Cancel all pending and active preview generations
    func cancelAllGenerations() {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        pendingRequests.removeAll()
    }

    /// Cancel generation for specific presets (e.g., when scrolling away)
    /// - Parameter presetIDs: Preset IDs to cancel
    func cancelGenerations(for presetIDs: Set<UUID>) {
        for presetID in presetIDs {
            activeTasks[presetID]?.cancel()
            activeTasks.removeValue(forKey: presetID)
        }
        pendingRequests.removeAll { presetIDs.contains($0.presetID) }
    }

    // MARK: - Cache Management

    /// Clear memory cache only
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Clear all caches (memory and disk)
    func clearAllCaches() {
        memoryCache.removeAllObjects()

        if let contents = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) {
            for url in contents {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// Get disk cache size
    /// - Returns: Size in bytes
    func diskCacheSize() -> Int {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + size
        }
    }

    // MARK: - Private Methods

    private func generatePreview(for preset: FilterPreset, priority: LoadPriority) async -> CGImage? {
        // Check if already generating
        if let existingTask = activeTasks[preset.id] {
            return await existingTask.value
        }

        // Check concurrency limit
        if currentGenerationCount >= maxConcurrentGenerations {
            // Queue the request
            pendingRequests.append(PreviewRequest(
                presetID: preset.id,
                clutPath: preset.clutPath,
                priority: priority
            ))
            return nil
        }

        // Start generation
        currentGenerationCount += 1

        let task = Task<CGImage?, Never> { [weak self] in
            guard let self = self else { return nil }

            guard !Task.isCancelled else { return nil }
            guard let referenceImage = await self.referenceImage else { return nil }

            // Apply filter to reference image
            let filteredImage = await self.applyFilter(preset, to: referenceImage)

            guard !Task.isCancelled else { return nil }

            // Cache result
            if let image = filteredImage {
                let key = await self.cacheKey(for: preset)
                await self.cacheImage(image, forKey: key)
            }

            // Cleanup and process next
            await self.generationCompleted(for: preset.id)

            return filteredImage
        }

        activeTasks[preset.id] = task

        return await task.value
    }

    private func generationCompleted(for presetID: UUID) {
        activeTasks.removeValue(forKey: presetID)
        currentGenerationCount -= 1

        // Process next pending request if any
        if !pendingRequests.isEmpty && currentGenerationCount < maxConcurrentGenerations {
            let next = pendingRequests.removeFirst()
            Task {
                // Create a minimal preset for generation
                // In real implementation, you'd lookup the preset from a registry
            }
        }
    }

    private func applyFilter(_ preset: FilterPreset, to image: CGImage) async -> CGImage? {
        // Use FilterEngine for filter application
        return await FilterEngine.shared.process(cgImage: image, with: preset)
    }

    private func cacheImage(_ image: CGImage, forKey key: String) {
        // Memory cache
        memoryCache.setObject(CGImageWrapper(image), forKey: key as NSString)

        // Disk cache
        saveToDisk(image, key: key)
    }

    private func cacheKey(for preset: FilterPreset) -> String {
        // Use only stable components (hashValue changes between app launches!)
        // - preset.id (UUID is stable)
        // - clutPath (if any)
        // - clutIntensity
        let clutPart = preset.clutPath ?? "noclut"
        let intensityPart = Int(preset.clutIntensity)
        return "filter_\(preset.id.uuidString)_\(clutPart)_\(intensityPart)"
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private func diskURL(for key: String) -> URL {
        return diskCacheURL.appendingPathComponent("\(key).jpg")
    }

    private func loadFromDisk(key: String) -> CGImage? {
        let url = diskURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return image
    }

    private func saveToDisk(_ image: CGImage, key: String) {
        let url = diskURL(for: key)

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Self.diskQuality
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        CGImageDestinationFinalize(destination)
    }

    private func scaleImage(_ image: CGImage, to size: CGSize) -> CGImage {
        // Use static method for consistency
        Self.scaleImageSync(image, to: size)
    }
}

// MARK: - CGImage Wrapper

private final class CGImageWrapper: @unchecked Sendable {
    let image: CGImage

    init(_ image: CGImage) {
        self.image = image
    }
}

// MARK: - Shared Instance

@available(iOS 17.0, *)
extension FilterPreviewCache {
    static let shared = FilterPreviewCache()
}

// MARK: - Convenience Methods for FiltersManagementView

@available(iOS 17.0, *)
extension FilterPreviewCache {

    /// Generate initial previews for a set of filters
    func generateInitialPreviews(for presets: [FilterPreset]) async {
        requestPreviews(for: presets, priority: .low)
    }

    /// Get or generate preview for a filter
    func getPreview(for preset: FilterPreset) async -> CGImage? {
        return await preview(for: preset, priority: .medium)
    }

    /// Generate a preview for a filter (public wrapper)
    func generatePreview(for preset: FilterPreset) async -> CGImage? {
        return await preview(for: preset, priority: .high)
    }

    /// Delete cached preview for a filter
    func deletePreview(for presetID: UUID) async {
        let prefix = "filter_\(presetID.uuidString)_"

        // Remove from disk cache - find all files matching the prefix
        if let contents = try? FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil) {
            for url in contents where url.lastPathComponent.hasPrefix(prefix) {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // Note: NSCache doesn't support prefix removal, but items will be
        // regenerated with correct key on next access
    }

    /// Regenerate preview for a filter
    func regeneratePreview(for preset: FilterPreset) async {
        // Remove old cache entry
        await deletePreview(for: preset.id)
        // Generate new preview
        _ = await preview(for: preset, priority: .high)
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// Observable wrapper for async filter preview loading
@available(iOS 17.0, *)
@MainActor
final class FilterPreviewLoader: ObservableObject {
    @Published var image: CGImage?
    @Published var isLoading = false

    private var loadTask: Task<Void, Never>?

    func load(preset: FilterPreset, priority: FilterPreviewCache.LoadPriority = .medium) {
        // Cancel any existing load
        loadTask?.cancel()

        isLoading = true

        loadTask = Task {
            // Check for cached first
            if let cached = await FilterPreviewCache.shared.cachedPreview(for: preset) {
                await MainActor.run {
                    self.image = cached
                    self.isLoading = false
                }
                return
            }

            let preview = await FilterPreviewCache.shared.preview(for: preset, priority: priority)

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self.image = preview
                self.isLoading = false
            }
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }

    deinit {
        loadTask?.cancel()
    }
}
