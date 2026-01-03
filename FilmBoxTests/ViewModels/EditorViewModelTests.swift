import XCTest
import CoreImage
@testable import FilmBox

/// Tests for EditorViewModel
@available(iOS 17.0, *)
@MainActor
final class EditorViewModelTests: XCTestCase {

    // MARK: - Properties

    private var viewModel: EditorViewModel!
    private var testImage: CIImage!
    private let testSize = CGSize(width: 100, height: 100)

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        viewModel = EditorViewModel()
        testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            size: testSize
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        testImage = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    /// Test: ViewModel starts with no image
    func testInitialStateHasNoImage() {
        XCTAssertNil(viewModel.currentImage)
        XCTAssertNil(viewModel.originalImage)
    }

    /// Test: ViewModel starts with identity parameters
    func testInitialStateHasIdentityParameters() {
        XCTAssertEqual(viewModel.currentParameters, .identity)
    }

    /// Test: ViewModel starts with no preset
    func testInitialStateHasNoPreset() {
        XCTAssertNil(viewModel.selectedPreset)
    }

    /// Test: ViewModel starts with default filter intensity
    func testInitialFilterIntensity() {
        XCTAssertEqual(viewModel.filterIntensity, 75)
    }

    /// Test: ViewModel starts without changes
    func testInitialStateHasNoChanges() {
        XCTAssertFalse(viewModel.hasChanges)
    }

    /// Test: ViewModel starts without undo/redo
    func testInitialStateCannotUndoRedo() {
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }

    // MARK: - Image Loading Tests

    /// Test: Loading image sets original and current
    func testLoadImageSetsImages() {
        viewModel.loadImage(testImage)

        XCTAssertNotNil(viewModel.originalImage)
        XCTAssertNotNil(viewModel.currentImage)
    }

    /// Test: Loading image resets parameters
    func testLoadImageResetsParameters() {
        // First modify parameters
        viewModel.currentParameters.exposure = 1.0
        viewModel.loadImage(testImage)

        XCTAssertEqual(viewModel.currentParameters, .identity)
    }

    /// Test: Loading image resets zoom and pan
    func testLoadImageResetsZoomPan() {
        viewModel.zoomScale = 2.0
        viewModel.panOffset = CGSize(width: 50, height: 50)

        viewModel.loadImage(testImage)

        XCTAssertEqual(viewModel.zoomScale, 1.0)
        XCTAssertEqual(viewModel.panOffset, .zero)
    }

    /// Test: Loading image clears undo stack
    func testLoadImageClearsUndoStack() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.0)
        XCTAssertTrue(viewModel.canUndo)

        viewModel.loadImage(testImage)
        XCTAssertFalse(viewModel.canUndo)
    }

    /// Test: Load CIImage with initial parameters
    func testLoadCIImageWithParameters() {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 20

        viewModel.loadCIImage(testImage, initialParameters: params)

        XCTAssertEqual(viewModel.currentParameters.exposure, 0.5)
        XCTAssertEqual(viewModel.currentParameters.contrast, 20)
    }

    // MARK: - Has Changes Tests

    /// Test: Modified parameters indicate changes
    func testModifiedParametersHaveChanges() {
        viewModel.loadImage(testImage)
        viewModel.currentParameters.exposure = 0.5

        XCTAssertTrue(viewModel.hasChanges)
    }

    /// Test: Selected preset indicates changes
    func testSelectedPresetHasChanges() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .cool)
        viewModel.selectedPreset = preset

        XCTAssertTrue(viewModel.hasChanges)
    }

    // MARK: - Undo/Redo Tests

    /// Test: Parameter update enables undo
    func testParameterUpdateEnablesUndo() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.0)

        XCTAssertTrue(viewModel.canUndo)
    }

    /// Test: Undo restores previous parameters
    func testUndoRestoresPreviousParameters() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.0)

        viewModel.undo()

        XCTAssertEqual(viewModel.currentParameters.exposure, 0)
    }

    /// Test: Undo enables redo
    func testUndoEnablesRedo() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.0)
        viewModel.undo()

        XCTAssertTrue(viewModel.canRedo)
    }

    /// Test: Redo restores undone changes
    func testRedoRestoresUndoneChanges() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.0)
        viewModel.undo()
        viewModel.redo()

        XCTAssertEqual(viewModel.currentParameters.exposure, 1.0)
    }

    /// Test: New action clears redo stack
    func testNewActionClearsRedoStack() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.0)
        viewModel.undo()
        XCTAssertTrue(viewModel.canRedo)

        viewModel.updateContrast(50)

        XCTAssertFalse(viewModel.canRedo)
    }

    /// Test: Multiple undos work in sequence
    func testMultipleUndos() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(0.5)
        viewModel.updateContrast(25)
        viewModel.updateSaturation(30)

        viewModel.undo() // Undo saturation
        XCTAssertEqual(viewModel.currentParameters.saturation, 0)
        XCTAssertEqual(viewModel.currentParameters.contrast, 25)

        viewModel.undo() // Undo contrast
        XCTAssertEqual(viewModel.currentParameters.contrast, 0)
        XCTAssertEqual(viewModel.currentParameters.exposure, 0.5)

        viewModel.undo() // Undo exposure
        XCTAssertEqual(viewModel.currentParameters.exposure, 0)
    }

    /// Test: Undo/Redo with preset
    func testUndoRedoWithPreset() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .cool)

        viewModel.applyPreset(preset)
        XCTAssertNotNil(viewModel.selectedPreset)

        viewModel.undo()
        XCTAssertNil(viewModel.selectedPreset)

        viewModel.redo()
        XCTAssertNotNil(viewModel.selectedPreset)
    }

    // MARK: - Parameter Update Tests

    /// Test: updateExposure sets exposure
    func testUpdateExposure() {
        viewModel.loadImage(testImage)
        viewModel.updateExposure(1.5)

        XCTAssertEqual(viewModel.currentParameters.exposure, 1.5)
    }

    /// Test: updateContrast sets contrast
    func testUpdateContrast() {
        viewModel.loadImage(testImage)
        viewModel.updateContrast(50)

        XCTAssertEqual(viewModel.currentParameters.contrast, 50)
    }

    /// Test: updateHighlights sets highlights
    func testUpdateHighlights() {
        viewModel.loadImage(testImage)
        viewModel.updateHighlights(-30)

        XCTAssertEqual(viewModel.currentParameters.highlights, -30)
    }

    /// Test: updateShadows sets shadows
    func testUpdateShadows() {
        viewModel.loadImage(testImage)
        viewModel.updateShadows(40)

        XCTAssertEqual(viewModel.currentParameters.shadows, 40)
    }

    /// Test: updateTemperature sets temperature
    func testUpdateTemperature() {
        viewModel.loadImage(testImage)
        viewModel.updateTemperature(20)

        XCTAssertEqual(viewModel.currentParameters.temperature, 20)
    }

    /// Test: updateSaturation sets saturation
    func testUpdateSaturation() {
        viewModel.loadImage(testImage)
        viewModel.updateSaturation(-15)

        XCTAssertEqual(viewModel.currentParameters.saturation, -15)
    }

    /// Test: Generic updateParameter works
    func testGenericUpdateParameter() {
        viewModel.loadImage(testImage)
        viewModel.updateParameter(\.vibrance, value: Float(25))

        XCTAssertEqual(viewModel.currentParameters.vibrance, 25)
    }

    // MARK: - Transform Tests

    /// Test: Rotate left decreases rotation by 90
    func testRotateLeft() {
        viewModel.loadImage(testImage)
        viewModel.rotateLeft()

        XCTAssertEqual(viewModel.currentParameters.rotation, 270)
    }

    /// Test: Rotate right increases rotation by 90
    func testRotateRight() {
        viewModel.loadImage(testImage)
        viewModel.rotateRight()

        XCTAssertEqual(viewModel.currentParameters.rotation, 90)
    }

    /// Test: Rotation wraps at 360
    func testRotationWraps() {
        viewModel.loadImage(testImage)
        viewModel.rotateRight()
        viewModel.rotateRight()
        viewModel.rotateRight()
        viewModel.rotateRight()

        XCTAssertEqual(viewModel.currentParameters.rotation, 0)
    }

    /// Test: Flip horizontal toggles flag
    func testFlipHorizontal() {
        viewModel.loadImage(testImage)
        XCTAssertFalse(viewModel.currentParameters.flipHorizontal)

        viewModel.flipHorizontal()
        XCTAssertTrue(viewModel.currentParameters.flipHorizontal)

        viewModel.flipHorizontal()
        XCTAssertFalse(viewModel.currentParameters.flipHorizontal)
    }

    /// Test: Flip vertical toggles flag
    func testFlipVertical() {
        viewModel.loadImage(testImage)
        XCTAssertFalse(viewModel.currentParameters.flipVertical)

        viewModel.flipVertical()
        XCTAssertTrue(viewModel.currentParameters.flipVertical)

        viewModel.flipVertical()
        XCTAssertFalse(viewModel.currentParameters.flipVertical)
    }

    // MARK: - Reset Tests

    /// Test: Reset to original clears all changes
    func testResetToOriginal() {
        viewModel.loadImage(testImage)
        viewModel.currentParameters.exposure = 1.0
        viewModel.currentParameters.contrast = 50
        let preset = FilterPreset(name: "Test", category: .cool)
        viewModel.selectedPreset = preset

        viewModel.resetToOriginal()

        XCTAssertEqual(viewModel.currentParameters, .identity)
        XCTAssertNil(viewModel.selectedPreset)
    }

    /// Test: Reset can be undone
    func testResetCanBeUndone() {
        viewModel.loadImage(testImage)
        viewModel.currentParameters.exposure = 1.0
        viewModel.resetToOriginal()

        viewModel.undo()

        XCTAssertEqual(viewModel.currentParameters.exposure, 1.0)
    }

    /// Test: Reset single parameter
    func testResetSingleParameter() {
        viewModel.loadImage(testImage)
        viewModel.currentParameters.exposure = 1.5
        viewModel.currentParameters.contrast = 50

        viewModel.resetParameter(\.exposure)

        XCTAssertEqual(viewModel.currentParameters.exposure, 0)
        XCTAssertEqual(viewModel.currentParameters.contrast, 50) // Unchanged
    }

    // MARK: - Preset Tests

    /// Test: Apply preset sets selected preset
    func testApplyPreset() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .warm)

        viewModel.applyPreset(preset)

        XCTAssertNotNil(viewModel.selectedPreset)
        XCTAssertEqual(viewModel.selectedPreset?.name, "Test")
    }

    /// Test: Apply nil preset clears selection
    func testApplyNilPreset() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .warm)
        viewModel.applyPreset(preset)

        viewModel.applyPreset(nil)

        XCTAssertNil(viewModel.selectedPreset)
    }

    /// Test: Filter intensity can be set
    func testSetFilterIntensity() {
        viewModel.loadImage(testImage)
        viewModel.setFilterIntensity(50)

        XCTAssertEqual(viewModel.filterIntensity, 50)
    }

    // MARK: - Processing State Tests

    /// Test: isProcessing starts false
    func testIsProcessingStartsFalse() {
        XCTAssertFalse(viewModel.isProcessing)
    }

    /// Test: isLoading starts false
    func testIsLoadingStartsFalse() {
        XCTAssertFalse(viewModel.isLoading)
    }

    /// Test: isShowingOriginal starts false
    func testIsShowingOriginalStartsFalse() {
        XCTAssertFalse(viewModel.isShowingOriginal)
    }

    // MARK: - Tab Selection Tests

    /// Test: Default tab is filters
    func testDefaultTabIsFilters() {
        XCTAssertEqual(viewModel.selectedTab, .filters)
    }

    /// Test: Tab can be changed
    func testTabCanBeChanged() {
        viewModel.selectedTab = .adjust

        XCTAssertEqual(viewModel.selectedTab, .adjust)
    }

    // MARK: - Export Tests

    /// Test: Save changes without image throws error
    func testSaveChangesWithoutImageThrows() async {
        do {
            _ = try await viewModel.saveChanges()
            XCTFail("Should throw error when no image loaded")
        } catch {
            XCTAssertTrue(error is EditorError)
        }
    }

    /// Test: Save changes with image returns CIImage
    func testSaveChangesWithImageReturnsCIImage() async throws {
        viewModel.loadImage(testImage)

        let result = try await viewModel.saveChanges()

        XCTAssertFalse(result.extent.isEmpty)
    }

    /// Test: Export as JPEG data succeeds
    func testExportAsJPEGData() async throws {
        viewModel.loadImage(testImage)

        let data = try await viewModel.exportAsJPEGData(quality: 0.8)

        XCTAssertFalse(data.isEmpty)
    }

    /// Test: Export as UIImage succeeds
    func testExportAsUIImage() async throws {
        viewModel.loadImage(testImage)

        let image = try await viewModel.exportAsUIImage()

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    // MARK: - Histogram Tests

    /// Test: Calculate histogram returns data
    func testCalculateHistogramReturnsData() async {
        viewModel.loadImage(testImage)

        // Wait for preview update
        try? await Task.sleep(for: .milliseconds(100))

        let histogram = await viewModel.calculateHistogram()

        XCTAssertNotNil(histogram)
        XCTAssertEqual(histogram?.red.count, 256)
        XCTAssertEqual(histogram?.green.count, 256)
        XCTAssertEqual(histogram?.blue.count, 256)
        XCTAssertEqual(histogram?.luminance.count, 256)
    }

    /// Test: Calculate histogram without image returns nil
    func testCalculateHistogramWithoutImageReturnsNil() async {
        let histogram = await viewModel.calculateHistogram()

        XCTAssertNil(histogram)
    }
}
