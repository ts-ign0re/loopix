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
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
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
        // Call the new method with empty parameters
        await export(
            assets: assets,
            filter: filter,
            assetParameters: [:],
            settings: settings,
            progress: progress
        )
    }

    /// Export multiple assets with per-asset parameters and settings
    /// - Parameters:
    ///   - assets: The assets to export
    ///   - filter: Optional filter preset to apply (fallback if no per-asset params)
    ///   - assetParameters: Per-asset filter parameters (keyed by asset localIdentifier)
    ///   - settings: Export settings
    ///   - progress: Progress callback
    /// - Returns: Array of export results
    func export(
        assets: [PHAsset],
        filter: FilterPreset?,
        assetParameters: [String: FilterParameters],
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

                // Get per-asset parameters if available
                let params = assetParameters[asset.localIdentifier]

                // Start new export task
                group.addTask {
                    let result = await self.exportSingleAsset(
                        asset: asset,
                        filter: filter,
                        parameters: params,
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
        clutIntensity: Float = 75
    ) async throws -> String {
        // Load full-resolution image data
        let imageData = try await loadImageData(for: asset, settings: .default)

        guard var ciImage = CIImage(data: imageData) else {
            throw ExportError.imageLoadFailed
        }

        // Apply orientation
        ciImage = ciImage.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.up.rawValue))

        // Apply filter using FilterEngine if available
        var processedImage: CIImage
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

        // Apply exposure correction to match editor preview brightness
        // (Metal preview renders slightly darker than export)
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = processedImage
        exposureFilter.ev = -0.3
        processedImage = exposureFilter.outputImage ?? processedImage

        // Render to JPEG data with high quality
        guard var jpegData = ciContext.jpegRepresentation(
            of: processedImage,
            colorSpace: processedImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            options: [
                CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.95
            ]
        ) else {
            throw ExportError.encodingFailed(format: .jpeg)
        }

        // Check security mode
        let securityMode = await MainActor.run { AppSettings.shared.securityMode }

        // Add Loopix iOS as source in EXIF (strip all metadata if security mode)
        jpegData = addSourceMetadata(to: jpegData, securityMode: securityMode) ?? jpegData

        // Save to Photos Library
        var localIdentifier: String?

        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: jpegData, options: nil)

            // Always set current date so photo appears as latest in gallery
            creationRequest.creationDate = Date()

            // Copy location from original if NOT in security mode
            if !securityMode {
                if let location = asset.location {
                    creationRequest.location = location
                }
            }

            localIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
        }

        guard let identifier = localIdentifier else {
            throw ExportError.writeFailed(URL(fileURLWithPath: "Photos Library"))
        }

        // Add to Loopix album
        try? await PhotoLibraryManager.shared.addAssetsToLoopixAlbum(localIdentifiers: [identifier])

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
        parameters: FilterParameters? = nil,
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

            guard var ciImage = CIImage(data: imageData) else {
                return .failure(asset: asset, error: ExportError.imageLoadFailed)
            }

            // Apply orientation
            ciImage = ciImage.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.up.rawValue))

            // Apply parameters or filter if specified
            var processedImage: CIImage
            if let params = parameters, params.hasAdjustments {
                // Use per-asset parameters if available
                if #available(iOS 17.0, *) {
                    processedImage = await FilterEngine.shared.apply(params, to: ciImage)
                } else {
                    let tempPreset = FilterPreset(name: "temp", parameters: params)
                    processedImage = applyFilter(tempPreset, to: ciImage)
                }
            } else if let filter = filter, filter.parameters.hasAdjustments {
                // Fall back to shared filter preset
                processedImage = applyFilter(filter, to: ciImage)
            } else {
                processedImage = ciImage
            }

            // Apply exposure correction to match editor preview brightness
            let exposureFilter = CIFilter.exposureAdjust()
            exposureFilter.inputImage = processedImage
            exposureFilter.ev = -0.3
            processedImage = exposureFilter.outputImage ?? processedImage

            // Resize if needed
            let resizedImage = resizeImage(processedImage, settings: settings)

            // Encode to output format
            let outputData = try await encodeImage(
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

        // Apply RGB channel curves (for orthochromatic B&W etc.) BEFORE saturation
        let hasRGBCurves = !params.toneCurve.red.isEmpty ||
                          !params.toneCurve.green.isEmpty ||
                          !params.toneCurve.blue.isEmpty
        if hasRGBCurves {
            result = applyRGBCurvesLocal(to: result, toneCurve: params.toneCurve)
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
                    .transformed(by: CGAffineTransform(scaleX: CGFloat(params.grain.size), y: CGFloat(params.grain.size)))
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

    /// Apply RGB channel curves using 3D LUT
    private func applyRGBCurvesLocal(to image: CIImage, toneCurve: ToneCurveData) -> CIImage {
        let lutSize = 64
        var cubeData = [Float](repeating: 0, count: lutSize * lutSize * lutSize * 4)

        // Build 1D LUTs for each channel
        let redLUT = buildChannelLUT(from: toneCurve.red, size: lutSize)
        let greenLUT = buildChannelLUT(from: toneCurve.green, size: lutSize)
        let blueLUT = buildChannelLUT(from: toneCurve.blue, size: lutSize)

        // Fill 3D cube
        for b in 0..<lutSize {
            for g in 0..<lutSize {
                for r in 0..<lutSize {
                    let index = (b * lutSize * lutSize + g * lutSize + r) * 4
                    cubeData[index + 0] = redLUT[r]
                    cubeData[index + 1] = greenLUT[g]
                    cubeData[index + 2] = blueLUT[b]
                    cubeData[index + 3] = 1.0
                }
            }
        }

        let data = Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float>.size)

        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(lutSize, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        filter.setValue(CGColorSpaceCreateDeviceRGB(), forKey: "inputColorSpace")

        return filter.outputImage ?? image
    }

    private func buildChannelLUT(from points: [ToneCurveData.CurvePoint], size: Int) -> [Float] {
        if points.isEmpty {
            return (0..<size).map { Float($0) / Float(size - 1) }
        }

        var curvePoints = points.sorted { $0.x < $1.x }

        if curvePoints.first!.x > 0 {
            curvePoints.insert(.init(x: 0, y: curvePoints.first!.y), at: 0)
        }
        if curvePoints.last!.x < 1 {
            curvePoints.append(.init(x: 1, y: curvePoints.last!.y))
        }

        var lut = [Float](repeating: 0, count: size)
        for i in 0..<size {
            let x = Float(i) / Float(size - 1)
            lut[i] = interpolateCurve(x: x, points: curvePoints)
        }

        return lut
    }

    private func interpolateCurve(x: Float, points: [ToneCurveData.CurvePoint]) -> Float {
        guard points.count >= 2 else {
            return points.first?.y ?? x
        }

        for i in 0..<(points.count - 1) {
            if x >= points[i].x && x <= points[i + 1].x {
                let t = (x - points[i].x) / (points[i + 1].x - points[i].x)
                return points[i].y + t * (points[i + 1].y - points[i].y)
            }
        }

        return points.last?.y ?? x
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
    ) async throws -> Data {
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!

        // Check security mode - if enabled, strip ALL metadata
        let securityMode = await MainActor.run { AppSettings.shared.securityMode }

        // Extract metadata from original if needed (and not in security mode)
        var metadata: [String: Any]?
        if preserveMetadata && !securityMode {
            if let source = CGImageSourceCreateWithData(originalImageData as CFData, nil) {
                metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]

                // Remove location if not including
                if !includeLocation {
                    metadata?.removeValue(forKey: kCGImagePropertyGPSDictionary as String)
                }
            }
        }

        // In security mode: only "Protected by Loopix iOS" tag, nothing else
        // Normal mode: add Loopix iOS to existing metadata
        if securityMode {
            let protectedTiffDict: [String: Any] = [
                kCGImagePropertyTIFFSoftware as String: "Protected by Loopix iOS",
                kCGImagePropertyTIFFMake as String: "Loopix",
                kCGImagePropertyTIFFModel as String: "Protected"
            ]
            metadata = [
                kCGImagePropertyTIFFDictionary as String: protectedTiffDict
            ]
        } else {
            if metadata == nil {
                metadata = [:]
            }
            var tiffDict = metadata?[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
            tiffDict[kCGImagePropertyTIFFSoftware as String] = "Loopix iOS"
            tiffDict[kCGImagePropertyTIFFMake as String] = "Loopix"
            tiffDict[kCGImagePropertyTIFFModel as String] = "iOS"
            metadata?[kCGImagePropertyTIFFDictionary as String] = tiffDict
        }

        let outputData: Data

        switch format {
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
        }

        // Always embed metadata (at minimum includes Loopix iOS source)
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

    /// Add Loopix iOS source metadata to image data
    /// When securityMode is true, strips ALL identifying metadata
    private nonisolated func addSourceMetadata(to data: Data, securityMode: Bool = false) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let utType = CGImageSourceGetType(source) else {
            return nil
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            utType,
            1,
            nil
        ) else {
            return nil
        }

        if securityMode {
            // Security mode: strip ALL metadata, only keep "Protected by Loopix iOS"
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }

            let protectedTiffDict: [String: Any] = [
                kCGImagePropertyTIFFSoftware as String: "Protected by Loopix iOS",
                kCGImagePropertyTIFFMake as String: "Loopix",
                kCGImagePropertyTIFFModel as String: "Protected"
            ]
            let cleanMetadata: [String: Any] = [
                kCGImagePropertyTIFFDictionary as String: protectedTiffDict
            ]

            CGImageDestinationAddImage(destination, cgImage, cleanMetadata as CFDictionary)
        } else {
            // Normal mode: preserve existing metadata, add Loopix iOS
            let loopixTiffDict: [String: Any] = [
                kCGImagePropertyTIFFSoftware as String: "Loopix iOS",
                kCGImagePropertyTIFFMake as String: "Loopix",
                kCGImagePropertyTIFFModel as String: "iOS"
            ]
            let metadata: [String: Any] = [
                kCGImagePropertyTIFFDictionary as String: loopixTiffDict
            ]
            CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        }

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

// MARK: - Local Storage Export

extension ExportEngine {
    /// Result for local photo export
    struct LocalExportResult: Sendable {
        let photoID: UUID
        let outputURL: URL?
        let error: Error?

        var isSuccess: Bool {
            outputURL != nil && error == nil
        }
    }

    /// Export photos from local storage to Photos Library as JPG
    /// - Parameters:
    ///   - photos: Array of (ImportedPhoto, FilterParameters?) tuples
    ///   - progress: Progress callback
    /// - Returns: Array of export results
    func exportFromLocalStorage(
        photos: [(photo: ImportedPhoto, parameters: FilterParameters?)],
        progress: @escaping @Sendable (ExportProgress) -> Void
    ) async -> [LocalExportResult] {
        isCancelled = false

        let total = photos.count
        var results: [LocalExportResult] = []
        results.reserveCapacity(total)

        let manager = await MainActor.run { ImportedPhotosManager.shared }

        for (index, item) in photos.enumerated() {
            guard !isCancelled else {
                results.append(LocalExportResult(photoID: item.photo.id, outputURL: nil, error: ExportError.cancelled))
                continue
            }

            do {
                let localIdentifier = try await exportSingleFromLocal(
                    photo: item.photo,
                    parameters: item.parameters,
                    manager: manager
                )
                let resultURL = URL(fileURLWithPath: localIdentifier)
                results.append(LocalExportResult(photoID: item.photo.id, outputURL: resultURL, error: nil))
            } catch {
                results.append(LocalExportResult(photoID: item.photo.id, outputURL: nil, error: error))
            }

            progress(ExportProgress(
                current: index + 1,
                total: total,
                currentAssetIdentifier: item.photo.id.uuidString
            ))
        }

        return results
    }

    /// Export a single photo from local storage to Photos Library as JPG
    @MainActor
    private func exportSingleFromLocal(
        photo: ImportedPhoto,
        parameters: FilterParameters?,
        manager: ImportedPhotosManager
    ) async throws -> String {
        // Load CIImage from local storage
        guard let ciImage = manager.loadCIImage(for: photo) else {
            throw ExportError.imageLoadFailed
        }

        // Apply filter parameters if available
        var processedImage: CIImage
        if let params = parameters, params.hasAdjustments {
            processedImage = await FilterEngine.shared.apply(params, to: ciImage)
        } else {
            processedImage = ciImage
        }

        // Apply exposure correction to match editor preview brightness
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = processedImage
        exposureFilter.ev = -0.3
        processedImage = exposureFilter.outputImage ?? processedImage

        // Render to JPEG data with high quality
        guard var jpegData = ciContext.jpegRepresentation(
            of: processedImage,
            colorSpace: processedImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
            options: [
                CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.95
            ]
        ) else {
            throw ExportError.encodingFailed(format: .jpeg)
        }

        // Check security mode
        let securityMode = AppSettings.shared.securityMode

        // Add Loopix iOS as source in EXIF (strip all metadata if security mode)
        jpegData = addSourceMetadata(to: jpegData, securityMode: securityMode) ?? jpegData

        // Save to Photos Library
        var localIdentifier: String?

        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: jpegData, options: nil)

            // Always set current date so photo appears as latest in gallery
            creationRequest.creationDate = Date()

            localIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
        }

        guard let identifier = localIdentifier else {
            throw ExportError.writeFailed(URL(fileURLWithPath: "Photos Library"))
        }

        // Add to Loopix album
        try? await PhotoLibraryManager.shared.addAssetsToLoopixAlbum(localIdentifiers: [identifier])

        return identifier
    }
}
