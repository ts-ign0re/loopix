import Foundation
import Photos
import CoreImage
import UniformTypeIdentifiers
import ImageIO
import PhotosUI

// MARK: - Export Result

/// Result of a single asset export operation
struct ExportResult: Sendable {
    /// The original asset that was exported
    let asset: PHAsset

    /// URL of the exported file (nil if export failed)
    let outputURL: URL?

    /// Error if export failed
    let error: Error?

    /// Whether the export was successful
    var isSuccess: Bool {
        outputURL != nil && error == nil
    }

    static func success(asset: PHAsset, outputURL: URL) -> ExportResult {
        ExportResult(asset: asset, outputURL: outputURL, error: nil)
    }

    static func failure(asset: PHAsset, error: Error) -> ExportResult {
        ExportResult(asset: asset, outputURL: nil, error: error)
    }
}

// MARK: - Export Error

/// Errors that can occur during export
enum ExportError: LocalizedError {
    case assetNotFound
    case imageLoadFailed
    case filterApplicationFailed
    case encodingFailed(format: ExportFormat)
    case writeFailed(URL)
    case cancelled
    case noWritePermission
    case invalidSettings

    var errorDescription: String? {
        switch self {
        case .assetNotFound:
            return "The photo could not be found."
        case .imageLoadFailed:
            return "Failed to load the image data."
        case .filterApplicationFailed:
            return "Failed to apply the filter."
        case .encodingFailed(let format):
            return "Failed to encode the image as \(format.rawValue)."
        case .writeFailed(let url):
            return "Failed to write to \(url.lastPathComponent)."
        case .cancelled:
            return "Export was cancelled."
        case .noWritePermission:
            return "No permission to write to the destination."
        case .invalidSettings:
            return "Invalid export settings."
        }
    }
}

// MARK: - Export Progress

/// Progress information for batch export
struct ExportProgress: Sendable {
    let current: Int
    let total: Int
    let currentAssetIdentifier: String?

    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var percentage: Int {
        Int(fraction * 100)
    }

    var isComplete: Bool {
        current >= total
    }
}

// MARK: - Export Engine Actor

/// Actor responsible for batch exporting photos with applied filters
actor ExportEngine {
    /// Maximum number of concurrent export operations
    private let concurrencyLimit: Int

    /// Core Image context for rendering
    private let ciContext: CIContext

    /// Image manager for fetching asset data
    private let imageManager: PHImageManager

    /// Flag to track cancellation
    private var isCancelled: Bool = false

    init(concurrencyLimit: Int = 4) {
        self.concurrencyLimit = concurrencyLimit
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true,
            .priorityRequestLow: false
        ])
        self.imageManager = PHImageManager.default()
    }

    /// Cancel ongoing export operations
    func cancel() {
        isCancelled = true
    }

    /// Reset cancellation state
    func reset() {
        isCancelled = false
    }

    /// Export multiple assets with the specified filter and settings
    /// - Parameters:
    ///   - assets: The assets to export
    ///   - filter: Optional filter preset to apply
    ///   - settings: Export settings
    ///   - progress: Progress callback
    /// - Returns: Array of export results
    func export(
        assets: [PHAsset],
        filter: FilterPreset?,
        settings: ExportSettings,
        progress: @escaping @Sendable (ExportProgress) -> Void
    ) async -> [ExportResult] {
        isCancelled = false

        let total = assets.count
        var results: [ExportResult] = []
        results.reserveCapacity(total)

        // Create temporary directory for exports
        let tempDirectory = createTemporaryDirectory()

        // Process in batches with concurrency limit
        await withTaskGroup(of: (Int, ExportResult).self) { group in
            var currentIndex = 0
            var activeCount = 0

            for (index, asset) in assets.enumerated() {
                // Check for cancellation
                if isCancelled {
                    break
                }

                // Wait if we've hit the concurrency limit
                while activeCount >= concurrencyLimit {
                    if let (completedIndex, result) = await group.next() {
                        results.append(result)
                        activeCount -= 1

                        currentIndex += 1
                        progress(ExportProgress(
                            current: currentIndex,
                            total: total,
                            currentAssetIdentifier: assets[safe: completedIndex]?.localIdentifier
                        ))
                    }
                }

                // Start new export task
                group.addTask {
                    let result = await self.exportSingleAsset(
                        asset: asset,
                        filter: filter,
                        settings: settings,
                        outputDirectory: tempDirectory,
                        index: index
                    )
                    return (index, result)
                }
                activeCount += 1
            }

            // Collect remaining results
            for await (completedIndex, result) in group {
                results.append(result)
                currentIndex += 1
                progress(ExportProgress(
                    current: currentIndex,
                    total: total,
                    currentAssetIdentifier: assets[safe: completedIndex]?.localIdentifier
                ))
            }
        }

        // Report cancellation for remaining assets
        if isCancelled {
            let exportedCount = results.count
            for asset in assets.dropFirst(exportedCount) {
                results.append(.failure(asset: asset, error: ExportError.cancelled))
            }
        }

        return results
    }

    /// Export a single asset to the Photos Library with applied filter
    /// - Parameters:
    ///   - asset: The original PHAsset to export
    ///   - filter: Optional filter preset to apply
    ///   - parameters: Optional filter parameters (overrides preset if provided)
    ///   - clutPath: Optional CLUT path for film simulation
    ///   - clutIntensity: CLUT intensity (0-100)
    /// - Returns: The local identifier of the newly created asset
    func exportToPhotosLibrary(
        asset: PHAsset,
        filter: FilterPreset? = nil,
        parameters: FilterParameters? = nil,
        clutPath: String? = nil,
        clutIntensity: Float = 100
    ) async throws -> String {
        // Load full-resolution image data
        let imageData = try await loadImageData(for: asset, settings: .default)

        guard var ciImage = CIImage(data: imageData) else {
            throw ExportError.imageLoadFailed
        }

        // Apply orientation
        if let orientedImage = ciImage.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.up.rawValue)) {
            ciImage = orientedImage
        }

        // Apply filter using FilterEngine if available
        let processedImage: CIImage
        if #available(iOS 17.0, *) {
            if let filter = filter {
                processedImage = await FilterEngine.shared.apply(filter, to: ciImage)
            } else if let params = parameters, params.hasAdjustments {
                processedImage = await FilterEngine.shared.apply(params, to: ciImage)
            } else {
                processedImage = ciImage
            }
        } else {
            // Fallback: use local filter application
            if let filter = filter {
                processedImage = applyFilter(filter, to: ciImage)
            } else if let params = parameters, params.hasAdjustments {
                let tempPreset = FilterPreset(name: "temp", parameters: params)
                processedImage = applyFilter(tempPreset, to: ciImage)
            } else {
                processedImage = ciImage
            }
        }

        // Render to JPEG data with high quality
        guard let jpegData = ciContext.jpegRepresentation(
            of: processedImage,
            colorSpace: processedImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            options: [
                CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.95
            ]
        ) else {
            throw ExportError.encodingFailed(format: .jpeg)
        }

        // Save to Photos Library
        var localIdentifier: String?

        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: jpegData, options: nil)

            // Copy metadata from original if available
            if let originalDate = asset.creationDate {
                creationRequest.creationDate = originalDate
            }
            if let location = asset.location {
                creationRequest.location = location
            }

            localIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
        }

        guard let identifier = localIdentifier else {
            throw ExportError.writeFailed(URL(fileURLWithPath: "Photos Library"))
        }

        return identifier
    }

    /// Export multiple assets to Photos Library
    /// - Parameters:
    ///   - assets: The assets to export
    ///   - filter: Optional filter preset to apply
    ///   - progress: Progress callback
    /// - Returns: Array of export results with Photos Library identifiers
    func exportToPhotosLibrary(
        assets: [PHAsset],
        filter: FilterPreset?,
        progress: @escaping @Sendable (ExportProgress) -> Void
    ) async -> [ExportResult] {
        isCancelled = false

        let total = assets.count
        var results: [ExportResult] = []
        results.reserveCapacity(total)

        for (index, asset) in assets.enumerated() {
            guard !isCancelled else {
                results.append(.failure(asset: asset, error: ExportError.cancelled))
                continue
            }

            do {
                let identifier = try await exportToPhotosLibrary(asset: asset, filter: filter)
                // Use the identifier as URL path for result
                let resultURL = URL(fileURLWithPath: identifier)
                results.append(.success(asset: asset, outputURL: resultURL))
            } catch {
                results.append(.failure(asset: asset, error: error))
            }

            progress(ExportProgress(
                current: index + 1,
                total: total,
                currentAssetIdentifier: asset.localIdentifier
            ))
        }

        return results
    }

    // MARK: - Private Methods

    /// Export a single asset
    private func exportSingleAsset(
        asset: PHAsset,
        filter: FilterPreset?,
        settings: ExportSettings,
        outputDirectory: URL,
        index: Int
    ) async -> ExportResult {
        guard !isCancelled else {
            return .failure(asset: asset, error: ExportError.cancelled)
        }

        do {
            // Load the full-resolution image
            let imageData = try await loadImageData(for: asset, settings: settings)

            guard let ciImage = CIImage(data: imageData) else {
                return .failure(asset: asset, error: ExportError.imageLoadFailed)
            }

            // Apply filter if specified
            let processedImage: CIImage
            if let filter = filter, filter.parameters.hasAdjustments {
                processedImage = applyFilter(filter, to: ciImage)
            } else {
                processedImage = ciImage
            }

            // Resize if needed
            let resizedImage = resizeImage(processedImage, settings: settings)

            // Encode to output format
            let outputData = try encodeImage(
                resizedImage,
                format: settings.format,
                quality: settings.quality,
                preserveMetadata: settings.preserveEXIF,
                includeLocation: settings.includeLocation,
                originalImageData: imageData
            )

            // Write to file
            let filename = generateFilename(for: asset, format: settings.format, index: index)
            let outputURL = outputDirectory.appendingPathComponent(filename)

            try outputData.write(to: outputURL)

            return .success(asset: asset, outputURL: outputURL)

        } catch {
            return .failure(asset: asset, error: error)
        }
    }

    /// Load image data from asset
    private func loadImageData(for asset: PHAsset, settings: ExportSettings) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            options.version = .current

            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: ExportError.imageLoadFailed)
                }
            }
        }
    }

    /// Apply filter preset to image
    private func applyFilter(_ filter: FilterPreset, to image: CIImage) -> CIImage {
        var result = image
        let params = filter.parameters

        // Apply basic adjustments using Core Image filters
        if params.exposure != 0 {
            result = result.applyingFilter("CIExposureAdjust", parameters: [
                kCIInputEVKey: params.exposure
            ])
        }

        if params.contrast != 0 {
            let contrast = 1 + (params.contrast / 100)
            result = result.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: contrast
            ])
        }

        if params.saturation != 0 {
            let saturation = 1 + (params.saturation / 100)
            result = result.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: saturation
            ])
        }

        if params.vibrance != 0 {
            result = result.applyingFilter("CIVibrance", parameters: [
                "inputAmount": params.vibrance / 100
            ])
        }

        if params.temperature != 0 || params.tint != 0 {
            // Temperature/tint adjustment using CITemperatureAndTint
            let neutral = CIVector(x: 6500 + CGFloat(params.temperature * 50), y: CGFloat(params.tint))
            result = result.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": neutral
            ])
        }

        if params.highlights != 0 || params.shadows != 0 {
            result = result.applyingFilter("CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": 1 - (params.highlights / 200),
                "inputShadowAmount": params.shadows / 100
            ])
        }

        if params.sharpness > 0 {
            result = result.applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: params.sharpness / 100,
                kCIInputRadiusKey: params.sharpenRadius
            ])
        }

        if params.vignette.isActive {
            result = result.applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: params.vignette.amount / 100,
                kCIInputRadiusKey: params.vignette.midpoint * 2
            ])
        }

        if params.grain.isActive {
            // Add noise for grain effect
            if let noiseGenerator = CIFilter(name: "CIRandomGenerator"),
               let noiseImage = noiseGenerator.outputImage {
                let scaledNoise = noiseImage
                    .transformed(by: CGAffineTransform(scaleX: params.grain.size, y: params.grain.size))
                    .cropped(to: result.extent)

                let grainAmount = params.grain.amount / 100 * 0.1
                result = result.applyingFilter("CISourceOverCompositing", parameters: [
                    kCIInputBackgroundImageKey: result,
                    kCIInputImageKey: scaledNoise.applyingFilter("CIColorMatrix", parameters: [
                        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(grainAmount))
                    ])
                ])
            }
        }

        return result
    }

    /// Resize image based on settings
    private func resizeImage(_ image: CIImage, settings: ExportSettings) -> CIImage {
        guard let maxDimension = settings.maxDimension else {
            return image
        }

        let extent = image.extent
        let currentMax = max(extent.width, extent.height)

        guard currentMax > CGFloat(maxDimension) else {
            return image
        }

        let scale = CGFloat(maxDimension) / currentMax
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    /// Encode processed image to output format
    private func encodeImage(
        _ image: CIImage,
        format: ExportFormat,
        quality: Double,
        preserveMetadata: Bool,
        includeLocation: Bool,
        originalImageData: Data
    ) throws -> Data {
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!

        // Extract metadata from original if needed
        var metadata: [String: Any]?
        if preserveMetadata {
            if let source = CGImageSourceCreateWithData(originalImageData as CFData, nil) {
                metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]

                // Remove location if not including
                if !includeLocation {
                    metadata?.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
                }
            }
        }

        let outputData: Data

        switch format {
        case .heic:
            guard let data = ciContext.heifRepresentation(
                of: image,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [
                    CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): quality
                ]
            ) else {
                throw ExportError.encodingFailed(format: format)
            }
            outputData = data

        case .jpeg:
            guard let data = ciContext.jpegRepresentation(
                of: image,
                colorSpace: colorSpace,
                options: [
                    CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): quality
                ]
            ) else {
                throw ExportError.encodingFailed(format: format)
            }
            outputData = data

        case .png:
            guard let data = ciContext.pngRepresentation(
                of: image,
                format: .RGBA8,
                colorSpace: colorSpace,
                options: [:]
            ) else {
                throw ExportError.encodingFailed(format: format)
            }
            outputData = data

        case .webp:
            // WebP encoding using CGImageDestination (iOS 14+)
            if #available(iOS 14.0, *) {
                guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
                    throw ExportError.encodingFailed(format: format)
                }

                let mutableData = NSMutableData()
                guard let destination = CGImageDestinationCreateWithData(
                    mutableData,
                    UTType.webP.identifier as CFString,
                    1,
                    nil
                ) else {
                    throw ExportError.encodingFailed(format: format)
                }

                let options: [CFString: Any] = [
                    kCGImageDestinationLossyCompressionQuality: quality
                ]

                CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

                guard CGImageDestinationFinalize(destination) else {
                    throw ExportError.encodingFailed(format: format)
                }

                outputData = mutableData as Data
            } else {
                // Fallback to JPEG on older iOS versions
                guard let data = ciContext.jpegRepresentation(
                    of: image,
                    colorSpace: colorSpace,
                    options: [
                        CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): quality
                    ]
                ) else {
                    throw ExportError.encodingFailed(format: format)
                }
                outputData = data
            }
        }

        // If we need to embed metadata, we need to reprocess
        if let metadata = metadata, !metadata.isEmpty {
            return embedMetadata(metadata, in: outputData, format: format) ?? outputData
        }

        return outputData
    }

    /// Embed metadata into image data
    private func embedMetadata(_ metadata: [String: Any], in data: Data, format: ExportFormat) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let utType = UTType(format.utType) else {
            return nil
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            utType.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }

    /// Generate filename for exported image
    private func generateFilename(for asset: PHAsset, format: ExportFormat, index: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"

        let timestamp: String
        if let creationDate = asset.creationDate {
            timestamp = dateFormatter.string(from: creationDate)
        } else {
            timestamp = dateFormatter.string(from: Date())
        }

        return "FilmBox_\(timestamp)_\(index).\(format.fileExtension)"
    }

    /// Create a temporary directory for exports
    private func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FilmBoxExport_\(UUID().uuidString)")

        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        return tempDir
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Shared Instance

extension ExportEngine {
    /// Shared singleton instance
    static let shared = ExportEngine()
}
