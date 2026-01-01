import Foundation
import Photos
import Observation

// MARK: - Export State

/// Current state of the export operation
enum ExportState: Equatable {
    case idle
    case preparing
    case exporting(current: Int, total: Int)
    case saving
    case completed(successCount: Int, failureCount: Int)
    case failed(String)
    case cancelled

    var isActive: Bool {
        switch self {
        case .preparing, .exporting, .saving:
            return true
        default:
            return false
        }
    }
}

// MARK: - Export View Model

/// View model for managing export operations
@Observable
@MainActor
final class ExportViewModel: @unchecked Sendable {
    // MARK: - Published Properties

    /// Current export settings
    var settings: ExportSettings

    /// Assets selected for export (PHAsset mode)
    var selectedAssets: [PHAsset] = []

    /// Per-asset parameters (asset local identifier -> parameters)
    var assetParameters: [String: FilterParameters] = [:]

    /// Local photos for export (local storage mode)
    var localPhotos: [(photo: ImportedPhoto, parameters: FilterParameters?)] = []

    /// Whether we're exporting from local storage
    var isLocalExport: Bool = false

    /// Current export progress (0.0 to 1.0)
    var exportProgress: Double = 0

    /// Current number of processed items
    var currentItem: Int = 0

    /// Total number of items to export
    var totalItems: Int = 0

    /// Current export state
    var exportState: ExportState = .idle

    /// Whether an export is currently in progress
    var isExporting: Bool {
        exportState.isActive
    }

    /// Results from the last export operation
    var exportResults: [ExportResult] = []

    /// Optional filter to apply during export
    var filterPreset: FilterPreset?

    /// Error message to display
    var errorMessage: String?

    // MARK: - Private Properties

    private let exportEngine: ExportEngine
    private var exportTask: Task<Void, Never>?

    // MARK: - Initialization

    init(assets: [PHAsset] = [], filter: FilterPreset? = nil) {
        self.settings = ExportSettings.loadFromUserDefaults()
        self.selectedAssets = assets
        self.filterPreset = filter
        self.exportEngine = ExportEngine(concurrencyLimit: 4)
    }

    /// Initialize with assets and per-asset parameters
    init(assetsWithParameters: [(asset: PHAsset, parameters: FilterParameters?)]) {
        self.settings = ExportSettings.loadFromUserDefaults()
        self.selectedAssets = assetsWithParameters.map { $0.asset }
        self.assetParameters = Dictionary(
            uniqueKeysWithValues: assetsWithParameters.compactMap { item in
                guard let params = item.parameters else { return nil }
                return (item.asset.localIdentifier, params)
            }
        )
        self.filterPreset = nil
        self.exportEngine = ExportEngine(concurrencyLimit: 4)
    }

    /// Initialize with local photos (from local storage)
    init(localPhotos: [(photo: ImportedPhoto, parameters: FilterParameters?)]) {
        self.exportEngine = ExportEngine(concurrencyLimit: 4)
        self.settings = ExportSettings.loadFromUserDefaults()
        // Force JPEG for local export
        self.settings.format = .jpeg
        self.localPhotos = localPhotos
        self.isLocalExport = true
        self.filterPreset = nil
    }

    // MARK: - Public Methods

    /// Start the export process
    @MainActor
    func startExport() {
        let hasItems = isLocalExport ? !localPhotos.isEmpty : !selectedAssets.isEmpty
        guard hasItems else {
            errorMessage = "No photos selected for export"
            return
        }

        guard !isExporting else { return }

        // Save settings for next time
        settings.saveToUserDefaults()

        // Reset state
        exportProgress = 0
        currentItem = 0
        totalItems = isLocalExport ? localPhotos.count : selectedAssets.count
        exportResults = []
        errorMessage = nil
        exportState = .preparing

        // Start export task
        exportTask = Task { [weak self] in
            await self?.performExport()
        }
    }

    /// Cancel the current export
    @MainActor
    func cancelExport() {
        exportTask?.cancel()
        exportTask = nil

        Task {
            await exportEngine.cancel()
        }

        exportState = .cancelled
        exportProgress = 0
        currentItem = 0
    }

    /// Reset the export state for a new export
    @MainActor
    func resetExport() {
        exportState = .idle
        exportProgress = 0
        currentItem = 0
        totalItems = 0
        exportResults = []
        errorMessage = nil

        Task {
            await exportEngine.reset()
        }
    }

    /// Update the selected assets
    @MainActor
    func updateAssets(_ assets: [PHAsset]) {
        selectedAssets = assets
        totalItems = assets.count
    }

    /// Update the filter preset
    @MainActor
    func updateFilter(_ filter: FilterPreset?) {
        filterPreset = filter
    }

    // MARK: - Private Methods

    @MainActor
    private func performExport() async {
        if isLocalExport {
            await performLocalExport()
        } else {
            await performAssetExport()
        }
    }

    @MainActor
    private func performAssetExport() async {
        exportState = .exporting(current: 0, total: selectedAssets.count)

        let results = await exportEngine.export(
            assets: selectedAssets,
            filter: filterPreset,
            assetParameters: assetParameters,
            settings: settings
        ) { progress in
            // Progress is handled via exportState updates
        }

        // Check if cancelled
        guard !Task.isCancelled else {
            exportState = .cancelled
            return
        }

        exportResults = results

        // Save to destination based on settings
        exportState = .saving
        await saveExportedFiles(results)

        // Update final state
        let successCount = results.filter { $0.isSuccess }.count
        let failureCount = results.count - successCount

        exportState = .completed(successCount: successCount, failureCount: failureCount)
    }

    @MainActor
    private func performLocalExport() async {
        exportState = .exporting(current: 0, total: localPhotos.count)

        let results = await exportEngine.exportFromLocalStorage(
            photos: localPhotos
        ) { [weak self] progress in
            Task { @MainActor in
                self?.exportProgress = progress.fraction
                self?.currentItem = progress.current
                self?.exportState = .exporting(current: progress.current, total: progress.total)
            }
        }

        // Check if cancelled
        guard !Task.isCancelled else {
            exportState = .cancelled
            return
        }

        // Update final state (photos already saved to library by exportFromLocalStorage)
        let successCount = results.filter { $0.isSuccess }.count
        let failureCount = results.count - successCount

        exportState = .completed(successCount: successCount, failureCount: failureCount)
    }

    @MainActor
    private func handleProgress(_ progress: ExportProgress) {
        exportProgress = progress.fraction
        currentItem = progress.current
        totalItems = progress.total
        exportState = .exporting(current: progress.current, total: progress.total)
    }

    private func saveExportedFiles(_ results: [ExportResult]) async {
        let successfulResults = results.filter { $0.isSuccess }

        switch settings.destination {
        case .photoLibrary:
            await saveToPhotoLibrary(successfulResults)

        case .files:
            // Files are already in temp directory
            // In a real app, you would present a document picker
            break

        case .share:
            // Share sheet will be presented by the view
            break
        }
    }

    private func saveToPhotoLibrary(_ results: [ExportResult]) async {
        for result in results {
            guard let outputURL = result.outputURL else { continue }

            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: outputURL)
                }
            } catch {
                print("Failed to save to photo library: \(error)")
            }
        }
    }

    // MARK: - Computed Properties

    /// Progress text for display
    var progressText: String {
        switch exportState {
        case .idle:
            return "Ready to export"
        case .preparing:
            return "Preparing..."
        case .exporting(let current, let total):
            return "Exporting \(current) of \(total)..."
        case .saving:
            return "Saving..."
        case .completed(let success, let failure):
            if failure == 0 {
                return "Exported \(success) photos successfully"
            } else {
                return "Exported \(success) photos, \(failure) failed"
            }
        case .failed(let message):
            return "Export failed: \(message)"
        case .cancelled:
            return "Export cancelled"
        }
    }

    /// Whether the export can be started
    var canStartExport: Bool {
        let hasItems = isLocalExport ? !localPhotos.isEmpty : !selectedAssets.isEmpty
        return hasItems && !isExporting
    }

    /// Number of items to export
    var itemCount: Int {
        isLocalExport ? localPhotos.count : selectedAssets.count
    }

    /// Summary text for the export configuration
    var configurationSummary: String {
        var parts: [String] = []
        parts.append("\(itemCount) photo\(itemCount == 1 ? "" : "s")")
        parts.append(settings.format.rawValue)
        parts.append(settings.size.displayName)

        if settings.format.supportsQuality {
            parts.append("\(settings.qualityPercentage)% quality")
        }

        return parts.joined(separator: " | ")
    }

    /// URLs of successfully exported files (for sharing)
    var exportedURLs: [URL] {
        exportResults.compactMap { $0.outputURL }
    }
}
