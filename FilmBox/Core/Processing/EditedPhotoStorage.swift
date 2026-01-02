import Foundation
import Photos
import CoreImage
import ImageIO
import UniformTypeIdentifiers

// MARK: - Edited Photo Metadata

/// Metadata for an edited photo
struct EditedPhotoMetadata: Codable, Sendable {
    /// The PHAsset local identifier
    let assetIdentifier: String

    /// Name of the applied filter preset
    var filterName: String?

    /// UUID of the applied filter preset
    var filterID: UUID?

    /// Path to CLUT file if using film simulation
    var clutPath: String?

    /// CLUT intensity (0-100)
    var clutIntensity: Float

    /// Date when editing was last modified
    var lastModifiedDate: Date

    /// Date when the edit was created
    let createdDate: Date

    init(
        assetIdentifier: String,
        filterName: String? = nil,
        filterID: UUID? = nil,
        clutPath: String? = nil,
        clutIntensity: Float = 75
    ) {
        self.assetIdentifier = assetIdentifier
        self.filterName = filterName
        self.filterID = filterID
        self.clutPath = clutPath
        self.clutIntensity = clutIntensity
        self.lastModifiedDate = Date()
        self.createdDate = Date()
    }
}

// MARK: - Edited Photo Storage Actor

/// Actor responsible for storing and retrieving edited photo data
/// Stores WebP previews and filter parameters in the app sandbox
actor EditedPhotoStorage {

    // MARK: - Constants

    private static let editedPhotosDirectoryName = "EditedPhotos"
    private static let previewFileName = "preview.webp"
    private static let parametersFileName = "parameters.json"
    private static let metadataFileName = "metadata.json"
    private static let webpQuality: Float = 0.85

    // MARK: - Properties

    /// Base URL for edited photos storage
    private let baseURL: URL

    /// JSON encoder for serialization
    private let encoder: JSONEncoder

    /// JSON decoder for deserialization
    private let decoder: JSONDecoder

    /// Core Image context for rendering
    private let ciContext: CIContext

    // MARK: - Initialization

    init() {
        // Setup base directory in app's Documents
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.baseURL = documentsURL.appendingPathComponent(Self.editedPhotosDirectoryName, isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)

        // Setup encoder/decoder
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Setup CIContext for WebP encoding
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true
        ])
    }

    // MARK: - Public Methods

    /// Save an edited photo with preview image and parameters
    /// - Parameters:
    ///   - asset: The PHAsset being edited
    ///   - previewImage: The processed preview image (with filter applied)
    ///   - parameters: The filter parameters used
    ///   - preset: Optional filter preset for metadata
    func saveEdit(
        for asset: PHAsset,
        previewImage: CIImage,
        parameters: FilterParameters,
        preset: FilterPreset? = nil
    ) async throws {
        let assetID = sanitizeAssetID(asset.localIdentifier)
        let editDirectory = baseURL.appendingPathComponent(assetID, isDirectory: true)

        // Create directory for this edit
        try FileManager.default.createDirectory(at: editDirectory, withIntermediateDirectories: true)

        // Save preview as WebP
        let previewURL = editDirectory.appendingPathComponent(Self.previewFileName)
        try await saveWebPPreview(previewImage, to: previewURL)

        // Save parameters
        let parametersURL = editDirectory.appendingPathComponent(Self.parametersFileName)
        let parametersData = try encoder.encode(parameters)
        try parametersData.write(to: parametersURL)

        // Save metadata
        let metadataURL = editDirectory.appendingPathComponent(Self.metadataFileName)
        let metadata = EditedPhotoMetadata(
            assetIdentifier: asset.localIdentifier,
            filterName: preset?.name,
            filterID: preset?.id,
            clutPath: preset?.clutPath,
            clutIntensity: preset?.clutIntensity ?? 100
        )
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataURL)
    }

    /// Load filter parameters for an edited asset
    /// - Parameter asset: The PHAsset to load parameters for
    /// - Returns: The saved FilterParameters, or nil if not found
    func loadParameters(for asset: PHAsset) async -> FilterParameters? {
        let assetID = sanitizeAssetID(asset.localIdentifier)
        let parametersURL = baseURL
            .appendingPathComponent(assetID, isDirectory: true)
            .appendingPathComponent(Self.parametersFileName)

        guard let data = try? Data(contentsOf: parametersURL),
              let parameters = try? decoder.decode(FilterParameters.self, from: data) else {
            return nil
        }

        return parameters
    }

    /// Load metadata for an edited asset
    /// - Parameter asset: The PHAsset to load metadata for
    /// - Returns: The saved metadata, or nil if not found
    func loadMetadata(for asset: PHAsset) async -> EditedPhotoMetadata? {
        let assetID = sanitizeAssetID(asset.localIdentifier)
        let metadataURL = baseURL
            .appendingPathComponent(assetID, isDirectory: true)
            .appendingPathComponent(Self.metadataFileName)

        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? decoder.decode(EditedPhotoMetadata.self, from: data) else {
            return nil
        }

        return metadata
    }

    /// Load the preview image for an edited asset
    /// - Parameter asset: The PHAsset to load preview for
    /// - Returns: The preview CGImage, or nil if not found
    func loadPreview(for asset: PHAsset) async -> CGImage? {
        let assetID = sanitizeAssetID(asset.localIdentifier)
        let previewURL = baseURL
            .appendingPathComponent(assetID, isDirectory: true)
            .appendingPathComponent(Self.previewFileName)

        guard FileManager.default.fileExists(atPath: previewURL.path) else {
            return nil
        }

        // Load WebP image using ImageIO
        guard let imageSource = CGImageSourceCreateWithURL(previewURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }

        return cgImage
    }

    /// Check if an asset has saved edits
    /// - Parameter asset: The PHAsset to check
    /// - Returns: True if edits exist
    func hasEdits(for asset: PHAsset) async -> Bool {
        let assetID = sanitizeAssetID(asset.localIdentifier)
        let editDirectory = baseURL.appendingPathComponent(assetID, isDirectory: true)
        return FileManager.default.fileExists(atPath: editDirectory.path)
    }

    /// Delete saved edits for an asset
    /// - Parameter asset: The PHAsset to delete edits for
    func deleteEdits(for asset: PHAsset) async throws {
        let assetID = sanitizeAssetID(asset.localIdentifier)
        let editDirectory = baseURL.appendingPathComponent(assetID, isDirectory: true)

        if FileManager.default.fileExists(atPath: editDirectory.path) {
            try FileManager.default.removeItem(at: editDirectory)
        }
    }

    /// Get all edited asset identifiers
    /// - Returns: Array of asset identifiers that have edits
    func allEditedAssetIdentifiers() async -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return contents.compactMap { url -> String? in
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return nil
            }
            // Restore the original asset identifier format
            return url.lastPathComponent.replacingOccurrences(of: "_", with: "/")
        }
    }

    /// Calculate total storage used by edited photos
    /// - Returns: Size in bytes
    func totalStorageUsed() async -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: baseURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else {
            return 0
        }

        // Collect all URLs first to avoid async iteration issues
        let allURLs = enumerator.compactMap { $0 as? URL }

        var totalSize = 0
        for fileURL in allURLs {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    /// Clear all edited photo storage
    func clearAllEdits() async throws {
        if FileManager.default.fileExists(atPath: baseURL.path) {
            try FileManager.default.removeItem(at: baseURL)
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    // MARK: - Private Methods

    /// Sanitize asset identifier for use as directory name
    private func sanitizeAssetID(_ identifier: String) -> String {
        // Replace / with _ to make it filesystem-safe
        return identifier.replacingOccurrences(of: "/", with: "_")
    }

    /// Save a CIImage as WebP to the specified URL
    private func saveWebPPreview(_ image: CIImage, to url: URL) async throws {
        // Render CIImage to CGImage
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
            throw EditedPhotoStorageError.renderFailed
        }

        // Try WebP first (iOS 14+)
        if #available(iOS 14.0, *) {
            if saveAsWebP(cgImage, to: url) {
                return
            }
        }

        // Fallback to JPEG if WebP fails
        let jpegURL = url.deletingPathExtension().appendingPathExtension("jpg")
        try saveAsJPEG(cgImage, to: jpegURL)
    }

    /// Save CGImage as WebP
    @available(iOS 14.0, *)
    private func saveAsWebP(_ image: CGImage, to url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.webP.identifier as CFString,
            1,
            nil
        ) else {
            return false
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Self.webpQuality
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }

    /// Save CGImage as JPEG (fallback)
    private func saveAsJPEG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw EditedPhotoStorageError.destinationCreationFailed
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Self.webpQuality
        ]

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw EditedPhotoStorageError.writeFailed
        }
    }
}

// MARK: - Errors

enum EditedPhotoStorageError: LocalizedError {
    case renderFailed
    case destinationCreationFailed
    case writeFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Failed to render preview image."
        case .destinationCreationFailed:
            return "Failed to create image destination."
        case .writeFailed:
            return "Failed to write preview image."
        case .notFound:
            return "Edited photo not found."
        }
    }
}

// MARK: - Shared Instance

extension EditedPhotoStorage {
    /// Shared singleton instance
    static let shared = EditedPhotoStorage()
}
