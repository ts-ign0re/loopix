import Foundation
import CoreImage
import Combine
import SwiftUI
import Photos

// MARK: - Editor Tab

/// Available tabs in the editor interface
enum EditorTab: String, CaseIterable, Identifiable, Sendable {
    case filters = "filters"
    case adjust = "adjust"
    case effects = "effects"
    case crop = "crop"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .filters: return "camera.filters"
        case .adjust: return "slider.horizontal.3"
        case .effects: return "sparkles"
        case .crop: return "crop"
        }
    }
}

// MARK: - Undo/Redo State

/// Represents a snapshot of editor state for undo/redo
private struct EditorState: Equatable {
    let parameters: FilterParameters      // User adjustments (independent of filter)
    let preset: FilterPreset?             // Selected filter
    let intensity: Float                   // Filter intensity (0-100)

    static func == (lhs: EditorState, rhs: EditorState) -> Bool {
        lhs.parameters == rhs.parameters &&
        lhs.preset?.id == rhs.preset?.id &&
        lhs.intensity == rhs.intensity
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

    /// Currently selected filter preset (Filter Layer - independent of user adjustments)
    var selectedPreset: FilterPreset? {
        didSet {
            if let preset = selectedPreset {
                filterIntensity = preset.clutIntensity
                // DON'T modify currentParameters - filter is a separate layer
                schedulePreviewUpdate()
            } else {
                // Filter deselected - still don't touch currentParameters
                schedulePreviewUpdate()
            }
        }
    }

    /// Current filter intensity (0-100)
    var filterIntensity: Float = 75

    /// Update filter intensity without triggering preset didSet loop
    func setFilterIntensity(_ intensity: Float) {
        filterIntensity = intensity
        schedulePreviewUpdate()
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

    /// Whether image is currently loading from asset
    private(set) var isLoading: Bool = false

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

    /// Initialize with a PHAsset and optional saved parameters
    convenience init(asset: PHAsset, initialParameters: FilterParameters? = nil) {
        self.init()
        loadAsset(asset, initialParameters: initialParameters)
    }

    /// Initialize with a CIImage and optional saved parameters (for local storage)
    convenience init(ciImage: CIImage, initialParameters: FilterParameters? = nil) {
        self.init()
        loadCIImage(ciImage, initialParameters: initialParameters)
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

    /// Load image from PHAsset with optional initial parameters
    func loadAsset(_ asset: PHAsset, initialParameters: FilterParameters? = nil) {
        isLoading = true

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: options
        ) { [weak self] data, _, orientation, _ in
            guard let self = self, let data = data else {
                Task { @MainActor in
                    self?.isLoading = false
                }
                return
            }

            Task { @MainActor in
                if var ciImage = CIImage(data: data) {
                    // Apply orientation
                    ciImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
                    self.originalImage = ciImage
                    self.currentImage = ciImage

                    // Apply initial parameters if provided
                    if let params = initialParameters {
                        self.currentParameters = params
                        self.schedulePreviewUpdate()
                    } else {
                        self.currentParameters = .identity
                    }

                    self.selectedPreset = nil
                    self.undoStack.removeAll()
                    self.redoStack.removeAll()
                    self.zoomScale = 1.0
                    self.panOffset = .zero
                }
                self.isLoading = false
            }
        }
    }

    /// Load CIImage from local storage with optional initial parameters
    func loadCIImage(_ ciImage: CIImage, initialParameters: FilterParameters? = nil) {
        originalImage = ciImage
        currentImage = ciImage

        // Apply initial parameters if provided
        if let params = initialParameters {
            currentParameters = params
            schedulePreviewUpdate()
        } else {
            currentParameters = .identity
        }

        selectedPreset = nil
        undoStack.removeAll()
        redoStack.removeAll()
        zoomScale = 1.0
        panOffset = .zero
    }

    // MARK: - Preset Application

    /// Select a filter preset (Filter Layer) - does NOT modify user adjustments
    /// Use this for programmatic preset selection with undo support
    func applyPreset(_ preset: FilterPreset?) {
        pushUndoState()
        // Set the filter - this does NOT modify currentParameters (user adjustments)
        // The filter is applied as a separate layer in updatePreview()
        selectedPreset = preset
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

    // MARK: - Transform Operations

    /// Rotate image 90 degrees counter-clockwise
    func rotateLeft() {
        pushUndoState()
        currentParameters.rotation -= 90
        if currentParameters.rotation < 0 {
            currentParameters.rotation += 360
        }
        schedulePreviewUpdate()
    }

    /// Rotate image 90 degrees clockwise
    func rotateRight() {
        pushUndoState()
        currentParameters.rotation += 90
        if currentParameters.rotation >= 360 {
            currentParameters.rotation -= 360
        }
        schedulePreviewUpdate()
    }

    /// Flip image horizontally
    func flipHorizontal() {
        pushUndoState()
        currentParameters.flipHorizontal.toggle()
        schedulePreviewUpdate()
    }

    /// Flip image vertically
    func flipVertical() {
        pushUndoState()
        currentParameters.flipVertical.toggle()
        schedulePreviewUpdate()
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
        let state = EditorState(
            parameters: currentParameters,
            preset: selectedPreset,
            intensity: filterIntensity
        )
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
        let currentState = EditorState(
            parameters: currentParameters,
            preset: selectedPreset,
            intensity: filterIntensity
        )
        redoStack.append(currentState)

        // Restore previous state without pushing to undo
        // IMPORTANT: Order matters!
        // 1. Set parameters first (triggers schedulePreviewUpdate via didSet)
        // 2. Set preset (triggers didSet which overwrites filterIntensity with clutIntensity)
        // 3. Set intensity LAST to override what didSet set
        currentParameters = previousState.parameters
        selectedPreset = previousState.preset
        filterIntensity = previousState.intensity
    }

    /// Redo the last undone change
    func redo() {
        guard let nextState = redoStack.popLast() else { return }

        // Save current state to undo stack
        let currentState = EditorState(
            parameters: currentParameters,
            preset: selectedPreset,
            intensity: filterIntensity
        )
        undoStack.append(currentState)

        // Apply redo state
        // IMPORTANT: Order matters! Set intensity LAST to override didSet
        currentParameters = nextState.parameters
        selectedPreset = nextState.preset
        filterIntensity = nextState.intensity
    }

    // MARK: - Preview Updates

    /// Public method to schedule a preview update (for external callers like crop)
    func schedulePreviewUpdatePublic() {
        schedulePreviewUpdate()
    }

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

        // Scale down image for preview based on quality setting
        let previewImage = scaleForPreview(original)

        // Apply two-layer filter pipeline
        let processed = await applyFilterPipeline(to: previewImage)

        currentImage = processed
    }

    // MARK: - Two-Layer Filter Pipeline

    /// Apply filter pipeline: Filter Layer + User Adjustments (DRY - used by both preview and save)
    /// - Layer 1: Filter Effect (selectedPreset + filterIntensity)
    /// - Layer 2: User Adjustments (currentParameters - independent of filter)
    private func applyFilterPipeline(to image: CIImage) async -> CIImage {
        var processed = image

        // === LAYER 1: Filter Effect ===
        // Apply the selected filter preset with intensity
        if let preset = selectedPreset {
            if let clutPath = preset.clutPath {
                // CLUT-based filter: apply CLUT file with intensity blending
                processed = await FilterEngine.shared.applyCLUT(
                    at: clutPath,
                    to: processed,
                    intensity: filterIntensity
                )
            } else {
                // Parameter-based filter: interpolate preset parameters by intensity
                let filterParams = preset.parameters(at: filterIntensity)
                processed = await applyFilters(to: processed, parameters: filterParams)
            }
        }

        // === LAYER 2: User Adjustments ===
        // Apply user's manual adjustments on top of filter (if any)
        // These are independent of filter selection - always start from .identity
        if currentParameters != .identity {
            processed = await applyFilters(to: processed, parameters: currentParameters)
        }

        return processed
    }

    /// Scale image for preview based on AppSettings.previewQuality
    private func scaleForPreview(_ image: CIImage) -> CIImage {
        let maxDimension = AppSettings.shared.previewQuality.resolution
        let extent = image.extent
        let currentMax = max(extent.width, extent.height)

        // Only scale down if image is larger than target
        guard currentMax > maxDimension else { return image }

        let scale = maxDimension / currentMax
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    /// Apply filter parameters to an image
    private func applyFilters(to image: CIImage, parameters: FilterParameters) async -> CIImage {
        var output = image

        // === GEOMETRY TRANSFORMS ===

        // Apply flip horizontal
        if parameters.flipHorizontal {
            let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
            output = output.transformed(by: flipTransform)
            // Translate back to positive coordinates
            let extent = output.extent
            if extent.origin.x < 0 {
                output = output.transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: 0))
            }
        }

        // Apply flip vertical
        if parameters.flipVertical {
            let flipTransform = CGAffineTransform(scaleX: 1, y: -1)
            output = output.transformed(by: flipTransform)
            // Translate back to positive coordinates
            let extent = output.extent
            if extent.origin.y < 0 {
                output = output.transformed(by: CGAffineTransform(translationX: 0, y: -extent.origin.y))
            }
        }

        // Apply rotation (in 90-degree increments)
        if parameters.rotation != 0 {
            let radians = CGFloat(parameters.rotation) * .pi / 180.0
            let transform = CGAffineTransform(rotationAngle: radians)
            output = output.transformed(by: transform)

            // Translate back to origin since rotation pivots around origin
            let extent = output.extent
            if extent.origin.x < 0 || extent.origin.y < 0 {
                let translateTransform = CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
                output = output.transformed(by: translateTransform)
            }
        }

        // Apply crop rect if set
        if let cropRect = parameters.cropRect {
            output = output.cropped(to: cropRect)
            // Translate to origin
            let translateTransform = CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
            output = output.transformed(by: translateTransform)
        }

        // Save target extent - filters must not change image dimensions
        let targetExtent = output.extent

        // === LIGHT ADJUSTMENTS ===

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

        // Apply highlights and shadows adjustment
        if parameters.highlights != 0 || parameters.shadows != 0 {
            if let filter = CIFilter(name: "CIHighlightShadowAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                let highlightAmount = 1.0 - (parameters.highlights / 100.0)
                filter.setValue(highlightAmount, forKey: "inputHighlightAmount")
                let shadowAmount = parameters.shadows / 100.0
                filter.setValue(shadowAmount, forKey: "inputShadowAmount")
                output = filter.outputImage ?? output
            }
        }

        // Apply whites adjustment
        if parameters.whites != 0 {
            output = applyWhites(parameters.whites, to: output)
        }

        // Apply blacks adjustment
        if parameters.blacks != 0 {
            output = applyBlacks(parameters.blacks, to: output)
        }

        // === COLOR ADJUSTMENTS ===

        // Apply temperature and tint adjustment
        // Temperature: -100 (cool/blue/10000K) to +100 (warm/orange/3000K)
        // CITemperatureAndTint: lower targetTemp = warmer, higher = cooler
        if parameters.temperature != 0 || parameters.tint != 0 {
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                // Invert: positive temperature = lower Kelvin = warmer
                let targetTemp = 6500 - (parameters.temperature * 35)
                filter.setValue(CIVector(x: CGFloat(targetTemp), y: CGFloat(parameters.tint)), forKey: "inputTargetNeutral")
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

        // Apply vibrance adjustment
        if parameters.vibrance != 0 {
            if let filter = CIFilter(name: "CIVibrance") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(parameters.vibrance / 100.0, forKey: "inputAmount")
                output = filter.outputImage ?? output
            }
        }

        // === EFFECTS ===

        // Apply clarity (local contrast)
        if parameters.clarity != 0 {
            output = applyClarity(parameters.clarity, to: output)
        }

        // Apply fade (lifts blacks for matte film look)
        if parameters.fade > 0 {
            output = applyFade(parameters.fade, to: output)
        }

        // Apply sharpness with radius
        if parameters.sharpness > 0 {
            output = applySharpness(amount: parameters.sharpness, radius: parameters.sharpenRadius, to: output)
        }

        // Apply vignette
        if parameters.vignette.isActive {
            output = applyVignette(parameters.vignette, to: output)
        }

        // Apply grain
        if parameters.grain.isActive {
            output = applyGrain(parameters.grain, to: output)
        }

        // Apply bloom
        if parameters.bloom.isActive {
            output = applyBloom(parameters.bloom, to: output)
        }

        // Apply halation
        if parameters.halation.isActive {
            output = applyHalation(parameters.halation, to: output)
        }

        // Ensure filters didn't change dimensions
        output = output.cropped(to: targetExtent)

        return output
    }

    // MARK: - Whites & Blacks

    private func applyWhites(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIToneCurve") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)

        let adjustment = amount / 100.0 * 0.15

        filter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
        filter.setValue(CIVector(x: 0.25, y: 0.25), forKey: "inputPoint1")
        filter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        filter.setValue(CIVector(x: 0.75, y: 0.75 + CGFloat(adjustment * 0.5)), forKey: "inputPoint3")
        filter.setValue(CIVector(x: 1.0, y: min(1.0, max(0.5, 1.0 + CGFloat(adjustment)))), forKey: "inputPoint4")

        return filter.outputImage ?? image
    }

    private func applyBlacks(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIToneCurve") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)

        let adjustment = amount / 100.0 * 0.15

        filter.setValue(CIVector(x: 0.0, y: max(0.0, min(0.5, CGFloat(adjustment)))), forKey: "inputPoint0")
        filter.setValue(CIVector(x: 0.25, y: 0.25 + CGFloat(adjustment * 0.5)), forKey: "inputPoint1")
        filter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        filter.setValue(CIVector(x: 0.75, y: 0.75), forKey: "inputPoint3")
        filter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")

        return filter.outputImage ?? image
    }

    // MARK: - Clarity

    private func applyClarity(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(20.0, forKey: kCIInputRadiusKey)
        filter.setValue(amount / 100.0 * 0.8, forKey: kCIInputIntensityKey)

        return filter.outputImage ?? image
    }

    // MARK: - Fade

    private func applyFade(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        let fadeAmount = amount / 100.0 * 0.15

        filter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: CGFloat(fadeAmount), y: CGFloat(fadeAmount), z: CGFloat(fadeAmount), w: 0), forKey: "inputBiasVector")

        return filter.outputImage ?? image
    }

    // MARK: - Sharpness

    private func applySharpness(amount: Float, radius: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount / 100.0 * 2.5, forKey: kCIInputIntensityKey)
        filter.setValue(CGFloat(radius), forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    // MARK: - Vignette

    private func applyVignette(_ vignette: VignetteData, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIVignetteEffect") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        let center = CIVector(x: image.extent.midX, y: image.extent.midY)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(vignette.amount / 100.0 * 1.5, forKey: kCIInputIntensityKey)
        let maxRadius = min(image.extent.width, image.extent.height) / 2
        filter.setValue(maxRadius * CGFloat(vignette.midpoint), forKey: kCIInputRadiusKey)
        filter.setValue(CGFloat(vignette.feather), forKey: "inputFalloff")

        return filter.outputImage ?? image
    }

    // MARK: - Grain

    private func applyGrain(_ grain: GrainData, to image: CIImage) -> CIImage {
        // Use Metal kernel for realistic film grain
        let amount = grain.amount / 100.0
        let size = 0.5 + (1.0 - grain.size) * 3.5  // Invert: UI 0 → Metal 4.0, UI 1 → Metal 0.5
        let roughness = grain.roughness
        let monochromatic = grain.monochromatic

        do {
            return try MetalFilterLoader.shared.applyGrain(
                to: image,
                amount: amount,
                size: size,
                roughness: roughness,
                monochromatic: monochromatic,
                time: 0.0  // Static grain for photos
            )
        } catch {
            // Fallback: return original image if Metal fails
            return image
        }
    }

    // MARK: - Bloom

    private func applyBloom(_ bloom: BloomData, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIBloom") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(bloom.intensity / 100.0 * 2.0, forKey: kCIInputIntensityKey)
        filter.setValue(CGFloat(bloom.radius * 50.0), forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    // MARK: - Halation

    private func applyHalation(_ halation: HalationData, to image: CIImage) -> CIImage {
        let extent = image.extent

        // Extract bright areas
        guard let colorClampFilter = CIFilter(name: "CIColorClamp") else { return image }
        colorClampFilter.setValue(image, forKey: kCIInputImageKey)
        colorClampFilter.setValue(CIVector(x: 0.7, y: 0.7, z: 0.7, w: 0), forKey: "inputMinComponents")
        colorClampFilter.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")

        guard let brightAreas = colorClampFilter.outputImage else { return image }

        // Tint bright areas with halation color
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else { return image }
        colorMatrixFilter.setValue(brightAreas, forKey: kCIInputImageKey)

        let hue = halation.hue / 360.0
        let r: CGFloat = max(0, min(1, 1.0 - abs(CGFloat(hue) * 6.0 - 3.0) + 1.0))
        let g: CGFloat = max(0, min(1, 2.0 - abs(CGFloat(hue) * 6.0 - 2.0)))
        let b: CGFloat = max(0, min(1, 2.0 - abs(CGFloat(hue) * 6.0 - 4.0)))

        colorMatrixFilter.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: g * 0.3, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: b * 0.1, w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard let tintedBright = colorMatrixFilter.outputImage else { return image }

        // Blur the tinted highlights
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(tintedBright, forKey: kCIInputImageKey)
        let blurRadius = 5.0 + halation.spread * 45.0
        blurFilter.setValue(CGFloat(blurRadius), forKey: kCIInputRadiusKey)

        guard let blurredHalation = blurFilter.outputImage?.cropped(to: extent) else { return image }

        // Adjust intensity
        guard let opacityFilter = CIFilter(name: "CIColorMatrix") else { return image }
        opacityFilter.setValue(blurredHalation, forKey: kCIInputImageKey)
        let opacity = halation.intensity / 100.0 * 0.7
        opacityFilter.setValue(CIVector(x: CGFloat(opacity), y: 0, z: 0, w: 0), forKey: "inputRVector")
        opacityFilter.setValue(CIVector(x: 0, y: CGFloat(opacity), z: 0, w: 0), forKey: "inputGVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: CGFloat(opacity), w: 0), forKey: "inputBVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard let adjustedHalation = opacityFilter.outputImage else { return image }

        // Blend with original using screen blend
        guard let blendFilter = CIFilter(name: "CIScreenBlendMode") else { return image }
        blendFilter.setValue(adjustedHalation, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }

    // MARK: - Save

    /// Save the edited image (full resolution with two-layer pipeline)
    func saveChanges() async throws -> CIImage {
        guard let original = originalImage else {
            throw EditorError.noImageLoaded
        }

        isProcessing = true
        defer { isProcessing = false }

        // Apply two-layer filter pipeline at full resolution
        let finalImage = await applyFilterPipeline(to: original)

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
        var scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Translate to origin (0, 0) - required for correct bitmap rendering
        let extent = scaledImage.extent
        if extent.origin != .zero {
            scaledImage = scaledImage.transformed(by: CGAffineTransform(
                translationX: -extent.origin.x,
                y: -extent.origin.y
            ))
        }

        // Render to bitmap
        let width = Int(scaledImage.extent.width)
        let height = Int(scaledImage.extent.height)

        guard width > 0 && height > 0 else {
            return HistogramData(red: red, green: green, blue: blue, luminance: luminance)
        }

        var bitmap = [UInt8](repeating: 0, count: width * height * 4)
        let renderBounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))

        context.render(
            scaledImage,
            toBitmap: &bitmap,
            rowBytes: width * 4,
            bounds: renderBounds,
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        // Build histogram from bitmap
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
