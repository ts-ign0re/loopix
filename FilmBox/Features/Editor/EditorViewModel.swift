import Foundation
import CoreImage
import Combine
import SwiftUI

// MARK: - Editor Tab

/// Available tabs in the editor interface
enum EditorTab: String, CaseIterable, Identifiable, Sendable {
    case filters = "Filters"
    case adjust = "Adjust"
    case effects = "Effects"
    case crop = "Crop"
    case presets = "Presets"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .filters: return "camera.filters"
        case .adjust: return "slider.horizontal.3"
        case .effects: return "sparkles"
        case .crop: return "crop"
        case .presets: return "square.stack.3d.up"
        }
    }
}

// MARK: - Undo/Redo State

/// Represents a snapshot of editor state for undo/redo
private struct EditorState: Equatable {
    let parameters: FilterParameters
    let preset: FilterPreset?

    static func == (lhs: EditorState, rhs: EditorState) -> Bool {
        lhs.parameters == rhs.parameters && lhs.preset?.id == rhs.preset?.id
    }
}

// MARK: - Editor View Model

/// Main view model for the photo editor
@Observable
@MainActor
final class EditorViewModel {

    // MARK: - Published Properties

    /// The currently displayed (processed) image
    private(set) var currentImage: CIImage?

    /// The original unedited image
    private(set) var originalImage: CIImage?

    /// Currently selected filter preset
    var selectedPreset: FilterPreset? {
        didSet {
            if let preset = selectedPreset {
                applyPreset(preset)
            }
        }
    }

    /// Current adjustment parameters
    var currentParameters: FilterParameters = .identity {
        didSet {
            schedulePreviewUpdate()
        }
    }

    /// Currently selected tab
    var selectedTab: EditorTab = .filters

    /// Whether the image has unsaved changes
    var hasChanges: Bool {
        currentParameters != .identity || selectedPreset != nil
    }

    /// Whether undo is available
    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// Whether redo is available
    var canRedo: Bool {
        !redoStack.isEmpty
    }

    /// Whether the editor is currently processing
    private(set) var isProcessing: Bool = false

    /// Whether before/after comparison is active
    var isShowingOriginal: Bool = false

    /// Current zoom scale for preview
    var zoomScale: CGFloat = 1.0

    /// Current pan offset for preview
    var panOffset: CGSize = .zero

    // MARK: - Private Properties

    /// Undo stack for parameter changes
    private var undoStack: [EditorState] = []

    /// Redo stack for parameter changes
    private var redoStack: [EditorState] = []

    /// Maximum number of undo states to keep
    private let maxUndoStates = 50

    /// Debounce timer for preview updates
    private var previewUpdateTask: Task<Void, Never>?

    /// Debounce interval in seconds
    private let debounceInterval: TimeInterval = 0.1

    /// Core Image context for rendering
    private let ciContext: CIContext

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        // Create Metal-based CIContext for optimal performance
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: metalDevice, options: [
                .cacheIntermediates: false,
                .priorityRequestLow: false
            ])
        } else {
            self.ciContext = CIContext(options: [
                .useSoftwareRenderer: false
            ])
        }
    }

    /// Initialize with an image
    convenience init(image: CIImage) {
        self.init()
        loadImage(image)
    }

    /// Initialize with a UIImage
    convenience init(uiImage: UIImage) {
        self.init()
        if let ciImage = CIImage(image: uiImage) {
            loadImage(ciImage)
        }
    }

    // MARK: - Image Loading

    /// Load a new image into the editor
    func loadImage(_ image: CIImage) {
        originalImage = image
        currentImage = image
        currentParameters = .identity
        selectedPreset = nil
        undoStack.removeAll()
        redoStack.removeAll()
        zoomScale = 1.0
        panOffset = .zero
    }

    /// Load image from URL
    func loadImage(from url: URL) async throws {
        guard let image = CIImage(contentsOf: url) else {
            throw EditorError.imageLoadFailed
        }
        loadImage(image)
    }

    // MARK: - Preset Application

    /// Apply a filter preset to the current image
    func applyPreset(_ preset: FilterPreset) {
        pushUndoState()
        currentParameters = preset.parameters
        schedulePreviewUpdate()
    }

    /// Apply preset at a specific intensity (0-100)
    func applyPreset(_ preset: FilterPreset, intensity: Float) {
        pushUndoState()
        currentParameters = preset.parameters(at: intensity)
        schedulePreviewUpdate()
    }

    // MARK: - Parameter Updates

    /// Update a single parameter value
    func updateParameter<T>(_ keyPath: WritableKeyPath<FilterParameters, T>, value: T) {
        pushUndoState()
        currentParameters[keyPath: keyPath] = value
    }

    /// Update exposure
    func updateExposure(_ value: Float) {
        updateParameter(\.exposure, value: value)
    }

    /// Update contrast
    func updateContrast(_ value: Float) {
        updateParameter(\.contrast, value: value)
    }

    /// Update highlights
    func updateHighlights(_ value: Float) {
        updateParameter(\.highlights, value: value)
    }

    /// Update shadows
    func updateShadows(_ value: Float) {
        updateParameter(\.shadows, value: value)
    }

    /// Update temperature
    func updateTemperature(_ value: Float) {
        updateParameter(\.temperature, value: value)
    }

    /// Update saturation
    func updateSaturation(_ value: Float) {
        updateParameter(\.saturation, value: value)
    }

    // MARK: - Reset

    /// Reset all changes to original image
    func resetToOriginal() {
        pushUndoState()
        currentParameters = .identity
        selectedPreset = nil
        currentImage = originalImage
    }

    /// Reset a specific parameter to its default value
    func resetParameter(_ keyPath: WritableKeyPath<FilterParameters, Float>, defaultValue: Float = 0) {
        pushUndoState()
        currentParameters[keyPath: keyPath] = defaultValue
    }

    // MARK: - Undo/Redo

    /// Push current state to undo stack
    private func pushUndoState() {
        let state = EditorState(parameters: currentParameters, preset: selectedPreset)
        undoStack.append(state)

        // Limit undo stack size
        if undoStack.count > maxUndoStates {
            undoStack.removeFirst()
        }

        // Clear redo stack when new action is performed
        redoStack.removeAll()
    }

    /// Undo the last change
    func undo() {
        guard let previousState = undoStack.popLast() else { return }

        // Save current state to redo stack
        let currentState = EditorState(parameters: currentParameters, preset: selectedPreset)
        redoStack.append(currentState)

        // Restore previous state without pushing to undo
        currentParameters = previousState.parameters
        selectedPreset = previousState.preset
        schedulePreviewUpdate()
    }

    /// Redo the last undone change
    func redo() {
        guard let nextState = redoStack.popLast() else { return }

        // Save current state to undo stack
        let currentState = EditorState(parameters: currentParameters, preset: selectedPreset)
        undoStack.append(currentState)

        // Apply redo state
        currentParameters = nextState.parameters
        selectedPreset = nextState.preset
        schedulePreviewUpdate()
    }

    // MARK: - Preview Updates

    /// Schedule a debounced preview update
    private func schedulePreviewUpdate() {
        previewUpdateTask?.cancel()

        previewUpdateTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.debounceInterval ?? 0.1))

            guard !Task.isCancelled else { return }

            await self?.updatePreview()
        }
    }

    /// Update the preview image with current parameters
    private func updatePreview() async {
        guard let original = originalImage else { return }

        isProcessing = true
        defer { isProcessing = false }

        // Apply filters using the filter pipeline
        // This would integrate with your Metal-based filter processing
        let processed = await applyFilters(to: original, parameters: currentParameters)

        currentImage = processed
    }

    /// Apply filter parameters to an image
    /// This is a placeholder that should integrate with your actual filter pipeline
    private func applyFilters(to image: CIImage, parameters: FilterParameters) async -> CIImage {
        var output = image

        // Apply exposure adjustment
        if parameters.exposure != 0 {
            if let filter = CIFilter(name: "CIExposureAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(parameters.exposure, forKey: kCIInputEVKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply contrast adjustment
        if parameters.contrast != 0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(1.0 + (parameters.contrast / 100.0), forKey: kCIInputContrastKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply saturation adjustment
        if parameters.saturation != 0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(1.0 + (parameters.saturation / 100.0), forKey: kCIInputSaturationKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply temperature adjustment
        if parameters.temperature != 0 {
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(output, forKey: kCIInputImageKey)
                let targetTemp = 6500 + (parameters.temperature * 30) // Approximate Kelvin shift
                filter.setValue(CIVector(x: CGFloat(targetTemp), y: 0), forKey: "inputNeutral")
                output = filter.outputImage ?? output
            }
        }

        // Apply vignette
        if parameters.vignette.isActive {
            if let filter = CIFilter(name: "CIVignette") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(parameters.vignette.amount / 100.0 * 2, forKey: kCIInputIntensityKey)
                filter.setValue(parameters.vignette.midpoint * 100, forKey: kCIInputRadiusKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply sharpness
        if parameters.sharpness > 0 {
            if let filter = CIFilter(name: "CISharpenLuminance") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(parameters.sharpness / 100.0, forKey: kCIInputSharpnessKey)
                output = filter.outputImage ?? output
            }
        }

        return output
    }

    // MARK: - Save

    /// Save the edited image
    func saveChanges() async throws -> CIImage {
        guard let original = originalImage else {
            throw EditorError.noImageLoaded
        }

        isProcessing = true
        defer { isProcessing = false }

        // Apply full quality filters
        let finalImage = await applyFilters(to: original, parameters: currentParameters)

        return finalImage
    }

    /// Export the edited image as UIImage
    func exportAsUIImage() async throws -> UIImage {
        let ciImage = try await saveChanges()

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            throw EditorError.exportFailed
        }

        return UIImage(cgImage: cgImage)
    }

    /// Export the edited image as Data (JPEG)
    func exportAsJPEGData(quality: CGFloat = 0.9) async throws -> Data {
        let ciImage = try await saveChanges()

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let data = ciContext.jpegRepresentation(of: ciImage, colorSpace: colorSpace, options: [
                  kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: quality
              ]) else {
            throw EditorError.exportFailed
        }

        return data
    }

    // MARK: - Histogram Data

    /// Calculate histogram data for the current image
    func calculateHistogram() async -> HistogramData? {
        guard let image = currentImage else { return nil }

        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) { [ciContext] in
                let histogram = HistogramData.calculate(from: image, context: ciContext)
                continuation.resume(returning: histogram)
            }
        }
    }
}

// MARK: - Editor Errors

enum EditorError: LocalizedError {
    case imageLoadFailed
    case noImageLoaded
    case exportFailed
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "Failed to load the image."
        case .noImageLoaded:
            return "No image is currently loaded."
        case .exportFailed:
            return "Failed to export the image."
        case .processingFailed:
            return "Image processing failed."
        }
    }
}

// MARK: - Histogram Data

/// Histogram data for RGB and luminance channels
struct HistogramData: Sendable {
    let red: [Float]
    let green: [Float]
    let blue: [Float]
    let luminance: [Float]

    static let binCount = 256

    static func calculate(from image: CIImage, context: CIContext) -> HistogramData {
        // Create histogram bins
        var red = [Float](repeating: 0, count: binCount)
        var green = [Float](repeating: 0, count: binCount)
        var blue = [Float](repeating: 0, count: binCount)
        var luminance = [Float](repeating: 0, count: binCount)

        // Sample the image at reduced resolution for performance
        let scale = min(1.0, 256.0 / max(image.extent.width, image.extent.height))
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Render to bitmap
        let width = Int(scaledImage.extent.width)
        let height = Int(scaledImage.extent.height)

        guard width > 0 && height > 0 else {
            return HistogramData(red: red, green: green, blue: blue, luminance: luminance)
        }

        var bitmap = [UInt8](repeating: 0, count: width * height * 4)

        context.render(
            scaledImage,
            toBitmap: &bitmap,
            rowBytes: width * 4,
            bounds: scaledImage.extent,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        // Build histogram from bitmap
        let totalPixels = Float(width * height)

        for i in stride(from: 0, to: bitmap.count, by: 4) {
            let r = Int(bitmap[i])
            let g = Int(bitmap[i + 1])
            let b = Int(bitmap[i + 2])

            red[r] += 1
            green[g] += 1
            blue[b] += 1

            // Calculate luminance (BT.709)
            let lum = Int(Float(r) * 0.2126 + Float(g) * 0.7152 + Float(b) * 0.0722)
            luminance[min(255, lum)] += 1
        }

        // Normalize
        let maxRed = red.max() ?? 1
        let maxGreen = green.max() ?? 1
        let maxBlue = blue.max() ?? 1
        let maxLum = luminance.max() ?? 1

        for i in 0..<binCount {
            red[i] /= maxRed
            green[i] /= maxGreen
            blue[i] /= maxBlue
            luminance[i] /= maxLum
        }

        return HistogramData(red: red, green: green, blue: blue, luminance: luminance)
    }
}
