import XCTest
import CoreImage
@testable import FilmBox

/// Tests for EditorV2ViewModel
@available(iOS 17.0, *)
@MainActor
final class EditorV2ViewModelTests: XCTestCase {

    // MARK: - Properties

    private var viewModel: EditorV2ViewModel!
    private var testImage: CIImage!
    private let testSize = CGSize(width: 100, height: 100)

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        viewModel = EditorV2ViewModel()
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

    /// Test: ViewModel starts in browse mode
    func testInitialModeIsBrowse() {
        XCTAssertEqual(viewModel.mode, .browse)
    }

    /// Test: ViewModel starts with filters tab selected
    func testInitialTabIsFilters() {
        XCTAssertEqual(viewModel.selectedTab, .filters)
    }

    /// Test: Tab bar is visible in browse mode
    func testShowTabBarInBrowseMode() {
        XCTAssertTrue(viewModel.showTabBar)
    }

    /// Test: Initial filter name is Original
    func testInitialFilterNameIsOriginal() {
        XCTAssertEqual(viewModel.currentFilterName, "Original")
    }

    /// Test: Initial tool category is all
    func testInitialToolCategoryIsAll() {
        XCTAssertEqual(viewModel.selectedToolCategory, .all)
    }

    /// Test: Initial filter category is film
    func testInitialFilterCategoryIsFilm() {
        XCTAssertEqual(viewModel.selectedFilterCategory, .film)
    }

    /// Test: No active tool initially
    func testNoActiveToolInitially() {
        XCTAssertNil(viewModel.activeTool)
    }

    // MARK: - Mode Transition Tests

    /// Test: Enter filter detail mode with preset
    func testEnterFilterDetailModeWithPreset() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .warm)
        viewModel.selectFilter(preset)

        viewModel.enterFilterDetailMode()

        XCTAssertEqual(viewModel.mode, .filterDetail)
        XCTAssertFalse(viewModel.showTabBar)
    }

    /// Test: Enter filter detail mode without preset does nothing
    func testEnterFilterDetailModeWithoutPreset() {
        viewModel.loadImage(testImage)
        // No preset selected

        viewModel.enterFilterDetailMode()

        XCTAssertEqual(viewModel.mode, .browse)
    }

    /// Test: Enter tool detail mode
    func testEnterToolDetailMode() {
        viewModel.loadImage(testImage)
        let tool = ToolDefinition.exposure

        viewModel.enterToolDetailMode(tool)

        XCTAssertEqual(viewModel.mode, .toolDetail(tool))
        XCTAssertEqual(viewModel.activeTool, tool)
        XCTAssertFalse(viewModel.showTabBar)
    }

    /// Test: Confirm changes returns to browse mode
    func testConfirmChangesReturnsToBrowse() {
        viewModel.loadImage(testImage)
        let tool = ToolDefinition.exposure
        viewModel.enterToolDetailMode(tool)

        viewModel.confirmChanges()

        XCTAssertEqual(viewModel.mode, .browse)
        XCTAssertNil(viewModel.activeTool)
    }

    /// Test: Cancel changes returns to browse mode
    func testCancelChangesReturnsToBrowse() {
        viewModel.loadImage(testImage)
        let tool = ToolDefinition.exposure
        viewModel.enterToolDetailMode(tool)

        viewModel.cancelChanges()

        XCTAssertEqual(viewModel.mode, .browse)
        XCTAssertNil(viewModel.activeTool)
    }

    /// Test: Cancel restores parameters snapshot
    func testCancelRestoresParametersSnapshot() {
        viewModel.loadImage(testImage)
        let tool = ToolDefinition.exposure

        // Set initial exposure
        viewModel.editor.currentParameters.exposure = 0.5

        // Enter tool mode (takes snapshot)
        viewModel.enterToolDetailMode(tool)

        // Change exposure
        viewModel.setValue(1.5, for: tool)
        XCTAssertEqual(viewModel.editor.currentParameters.exposure, 1.5)

        // Cancel
        viewModel.cancelChanges()

        // Should restore original value
        XCTAssertEqual(viewModel.editor.currentParameters.exposure, 0.5)
    }

    /// Test: Confirm keeps parameter changes
    func testConfirmKeepsParameterChanges() {
        viewModel.loadImage(testImage)
        let tool = ToolDefinition.exposure

        viewModel.enterToolDetailMode(tool)
        viewModel.setValue(1.5, for: tool)

        viewModel.confirmChanges()

        XCTAssertEqual(viewModel.editor.currentParameters.exposure, 1.5)
    }

    // MARK: - Tool Value Tests

    /// Test: Get value for exposure tool
    func testGetValueForExposure() {
        viewModel.loadImage(testImage)
        viewModel.editor.currentParameters.exposure = 1.0

        let value = viewModel.getValue(for: .exposure)

        XCTAssertEqual(value, 1.0)
    }

    /// Test: Set value for exposure tool
    func testSetValueForExposure() {
        viewModel.loadImage(testImage)

        viewModel.setValue(1.5, for: .exposure)

        XCTAssertEqual(viewModel.editor.currentParameters.exposure, 1.5)
    }

    /// Test: Get value for contrast tool
    func testGetValueForContrast() {
        viewModel.loadImage(testImage)
        viewModel.editor.currentParameters.contrast = 50

        let value = viewModel.getValue(for: .contrast)

        XCTAssertEqual(value, 50)
    }

    /// Test: Set value for contrast tool
    func testSetValueForContrast() {
        viewModel.loadImage(testImage)

        viewModel.setValue(75, for: .contrast)

        XCTAssertEqual(viewModel.editor.currentParameters.contrast, 75)
    }

    /// Test: Get value for grain tool (nested property)
    func testGetValueForGrain() {
        viewModel.loadImage(testImage)
        viewModel.editor.currentParameters.grain.amount = 30

        let value = viewModel.getValue(for: .grain)

        XCTAssertEqual(value, 30)
    }

    /// Test: Set value for grain tool (nested property)
    func testSetValueForGrain() {
        viewModel.loadImage(testImage)

        viewModel.setValue(40, for: .grain)

        XCTAssertEqual(viewModel.editor.currentParameters.grain.amount, 40)
    }

    /// Test: Get/set for all tool types
    func testAllToolTypes() {
        viewModel.loadImage(testImage)

        let tools: [(ToolDefinition, Float)] = [
            (.exposure, 1.0),
            (.contrast, 50),
            (.highlights, -30),
            (.shadows, 40),
            (.saturation, 20),
            (.vibrance, 15),
            (.temperature, 25),
            (.tint, -10),
            (.clarity, 35),
            (.sharpen, 45),
            (.fade, 10),
            (.bloom, 20),
            (.halation, 15),
            (.vignette, -25)
        ]

        for (tool, value) in tools {
            viewModel.setValue(value, for: tool)
            let retrieved = viewModel.getValue(for: tool)
            XCTAssertEqual(retrieved, value, "Tool \(tool.name) should have value \(value)")
        }
    }

    // MARK: - Filter Tests

    /// Test: Select filter updates preset
    func testSelectFilter() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test Filter", category: .cool)

        viewModel.selectFilter(preset)

        XCTAssertEqual(viewModel.editor.selectedPreset?.name, "Test Filter")
        XCTAssertEqual(viewModel.currentFilterName, "Test Filter")
    }

    /// Test: Select nil filter clears preset
    func testSelectNilFilter() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .warm)
        viewModel.selectFilter(preset)

        viewModel.selectFilter(nil)

        XCTAssertNil(viewModel.editor.selectedPreset)
        XCTAssertEqual(viewModel.currentFilterName, "Original")
    }

    /// Test: Filter intensity can be set
    func testSetFilterIntensity() {
        viewModel.loadImage(testImage)

        viewModel.setFilterIntensity(50)

        XCTAssertEqual(viewModel.editor.filterIntensity, 50)
    }

    /// Test: Filter display name format
    func testFilterDisplayName() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "A6", category: .pro)
        viewModel.selectFilter(preset)

        XCTAssertEqual(viewModel.filterDisplayName, "A6 / Pro")
    }

    /// Test: Filter display name without preset
    func testFilterDisplayNameWithoutPreset() {
        XCTAssertEqual(viewModel.filterDisplayName, "Original")
    }

    // MARK: - Tab Navigation Tests

    /// Test: Select tab in browse mode
    func testSelectTabInBrowseMode() {
        viewModel.selectTab(.light)

        XCTAssertEqual(viewModel.selectedTab, .light)
    }

    /// Test: Select tab in detail mode is ignored
    func testSelectTabInDetailModeIgnored() {
        viewModel.loadImage(testImage)
        viewModel.enterToolDetailMode(.exposure)

        viewModel.selectTab(.crop)

        XCTAssertEqual(viewModel.selectedTab, .filters) // Original tab preserved
    }

    // MARK: - Filter Sub-Parameters Tests

    /// Test: Get filter sub-value for strength
    func testGetFilterSubValueStrength() {
        viewModel.loadImage(testImage)
        viewModel.editor.setFilterIntensity(75)

        let value = viewModel.getFilterSubValue(for: .strength)

        XCTAssertEqual(value, 75)
    }

    /// Test: Set filter sub-value for strength
    func testSetFilterSubValueStrength() {
        viewModel.loadImage(testImage)

        viewModel.setFilterSubValue(50, for: .strength)

        XCTAssertEqual(viewModel.editor.filterIntensity, 50)
    }

    /// Test: Get filter sub-value for contrast
    func testGetFilterSubValueContrast() {
        viewModel.loadImage(testImage)
        viewModel.editor.currentParameters.contrast = 30

        let value = viewModel.getFilterSubValue(for: .contrast)

        XCTAssertEqual(value, 30)
    }

    /// Test: Set filter sub-value for color (saturation)
    func testSetFilterSubValueColor() {
        viewModel.loadImage(testImage)

        viewModel.setFilterSubValue(25, for: .color)

        XCTAssertEqual(viewModel.editor.currentParameters.saturation, 25)
    }

    /// Test: Set filter sub-value for tone (temperature)
    func testSetFilterSubValueTone() {
        viewModel.loadImage(testImage)

        viewModel.setFilterSubValue(-15, for: .tone)

        XCTAssertEqual(viewModel.editor.currentParameters.temperature, -15)
    }

    /// Test: Filter sub-parameter ranges
    func testFilterSubParameterRanges() {
        let strengthRange = viewModel.getFilterSubRange(for: .strength)
        XCTAssertEqual(strengthRange, 0...100)

        let contrastRange = viewModel.getFilterSubRange(for: .contrast)
        XCTAssertEqual(contrastRange, -100...100)

        let colorRange = viewModel.getFilterSubRange(for: .color)
        XCTAssertEqual(colorRange, -100...100)

        let toneRange = viewModel.getFilterSubRange(for: .tone)
        XCTAssertEqual(toneRange, -100...100)
    }

    // MARK: - Image Loading Tests

    /// Test: Load image delegates to editor
    func testLoadImage() {
        viewModel.loadImage(testImage)

        XCTAssertNotNil(viewModel.editor.originalImage)
    }

    /// Test: Load image with parameters
    func testLoadImageWithParameters() {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 25

        viewModel.loadImage(testImage, parameters: params)

        XCTAssertEqual(viewModel.editor.currentParameters.exposure, 0.5)
        XCTAssertEqual(viewModel.editor.currentParameters.contrast, 25)
    }

    // MARK: - Category Tests

    /// Test: Filter category can be changed
    func testFilterCategoryChange() {
        viewModel.selectedFilterCategory = .warm

        XCTAssertEqual(viewModel.selectedFilterCategory, .warm)
    }

    /// Test: Tool category can be changed
    func testToolCategoryChange() {
        viewModel.selectedToolCategory = .color

        XCTAssertEqual(viewModel.selectedToolCategory, .color)
    }

    // MARK: - Undo Integration Tests

    /// Test: Cancel in filter detail restores preset
    func testCancelRestoresPreset() {
        viewModel.loadImage(testImage)
        let preset1 = FilterPreset(name: "Preset1", category: .cool)
        let preset2 = FilterPreset(name: "Preset2", category: .warm)

        viewModel.selectFilter(preset1)
        viewModel.enterFilterDetailMode()

        // Change to different preset
        viewModel.selectFilter(preset2)
        XCTAssertEqual(viewModel.currentFilterName, "Preset2")

        // Cancel
        viewModel.cancelChanges()

        // Should restore original preset
        XCTAssertEqual(viewModel.currentFilterName, "Preset1")
    }

    /// Test: Cancel in filter detail restores intensity
    func testCancelRestoresIntensity() {
        viewModel.loadImage(testImage)
        let preset = FilterPreset(name: "Test", category: .pro)
        viewModel.selectFilter(preset)
        viewModel.setFilterIntensity(80)

        viewModel.enterFilterDetailMode()
        viewModel.setFilterIntensity(30)
        XCTAssertEqual(viewModel.editor.filterIntensity, 30)

        viewModel.cancelChanges()

        XCTAssertEqual(viewModel.editor.filterIntensity, 80)
    }
}
