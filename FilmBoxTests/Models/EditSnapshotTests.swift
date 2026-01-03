import XCTest
@testable import FilmBox

/// Tests for EditSnapshot model
final class EditSnapshotTests: XCTestCase {

    // MARK: - Initialization Tests

    /// Test: Default initialization
    func testDefaultInitialization() {
        let snapshot = EditSnapshot()

        XCTAssertEqual(snapshot.parameters, .identity)
        XCTAssertNil(snapshot.selectedPresetID)
        XCTAssertEqual(snapshot.filterIntensity, 100)
    }

    /// Test: Full initialization
    func testFullInitialization() {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 25
        let presetID = UUID()

        let snapshot = EditSnapshot(
            parameters: params,
            selectedPresetID: presetID,
            filterIntensity: 75
        )

        XCTAssertEqual(snapshot.parameters.exposure, 0.5)
        XCTAssertEqual(snapshot.parameters.contrast, 25)
        XCTAssertEqual(snapshot.selectedPresetID, presetID)
        XCTAssertEqual(snapshot.filterIntensity, 75)
    }

    /// Test: Initialization with only parameters
    func testInitializationWithOnlyParameters() {
        var params = FilterParameters()
        params.saturation = 30

        let snapshot = EditSnapshot(parameters: params)

        XCTAssertEqual(snapshot.parameters.saturation, 30)
        XCTAssertNil(snapshot.selectedPresetID)
        XCTAssertEqual(snapshot.filterIntensity, 100)
    }

    /// Test: Initialization with only preset ID
    func testInitializationWithOnlyPresetID() {
        let presetID = UUID()

        let snapshot = EditSnapshot(selectedPresetID: presetID)

        XCTAssertEqual(snapshot.parameters, .identity)
        XCTAssertEqual(snapshot.selectedPresetID, presetID)
        XCTAssertEqual(snapshot.filterIntensity, 100)
    }

    // MARK: - Codable Tests

    /// Test: Snapshot encodes and decodes correctly
    func testCodableRoundTrip() throws {
        var params = FilterParameters()
        params.exposure = 1.0
        params.contrast = 50
        params.grain.amount = 20
        let presetID = UUID()

        let original = EditSnapshot(
            parameters: params,
            selectedPresetID: presetID,
            filterIntensity: 80
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EditSnapshot.self, from: data)

        XCTAssertEqual(original, decoded)
        XCTAssertEqual(decoded.parameters.exposure, 1.0)
        XCTAssertEqual(decoded.parameters.contrast, 50)
        XCTAssertEqual(decoded.parameters.grain.amount, 20)
        XCTAssertEqual(decoded.selectedPresetID, presetID)
        XCTAssertEqual(decoded.filterIntensity, 80)
    }

    /// Test: Snapshot without preset encodes correctly
    func testCodableWithoutPreset() throws {
        var params = FilterParameters()
        params.temperature = 25

        let original = EditSnapshot(parameters: params)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EditSnapshot.self, from: data)

        XCTAssertEqual(original, decoded)
        XCTAssertNil(decoded.selectedPresetID)
    }

    /// Test: Default snapshot encodes correctly
    func testDefaultCodable() throws {
        let original = EditSnapshot()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EditSnapshot.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    // MARK: - Equatable Tests

    /// Test: Same properties means equal
    func testSamePropertiesEqual() {
        let presetID = UUID()
        var params = FilterParameters()
        params.exposure = 0.5

        let a = EditSnapshot(parameters: params, selectedPresetID: presetID, filterIntensity: 50)
        let b = EditSnapshot(parameters: params, selectedPresetID: presetID, filterIntensity: 50)

        XCTAssertEqual(a, b)
    }

    /// Test: Different parameters means not equal
    func testDifferentParametersNotEqual() {
        var params1 = FilterParameters()
        params1.exposure = 0.5

        var params2 = FilterParameters()
        params2.exposure = 1.0

        let a = EditSnapshot(parameters: params1)
        let b = EditSnapshot(parameters: params2)

        XCTAssertNotEqual(a, b)
    }

    /// Test: Different preset ID means not equal
    func testDifferentPresetIDNotEqual() {
        let a = EditSnapshot(selectedPresetID: UUID())
        let b = EditSnapshot(selectedPresetID: UUID())

        XCTAssertNotEqual(a, b)
    }

    /// Test: Different intensity means not equal
    func testDifferentIntensityNotEqual() {
        let presetID = UUID()

        let a = EditSnapshot(selectedPresetID: presetID, filterIntensity: 50)
        let b = EditSnapshot(selectedPresetID: presetID, filterIntensity: 100)

        XCTAssertNotEqual(a, b)
    }

    /// Test: Nil preset vs non-nil preset not equal
    func testNilVsNonNilPresetNotEqual() {
        let a = EditSnapshot()
        let b = EditSnapshot(selectedPresetID: UUID())

        XCTAssertNotEqual(a, b)
    }

    // MARK: - Mutability Tests

    /// Test: Parameters can be modified
    func testParametersMutation() {
        var snapshot = EditSnapshot()
        snapshot.parameters.exposure = 1.5
        snapshot.parameters.contrast = 50

        XCTAssertEqual(snapshot.parameters.exposure, 1.5)
        XCTAssertEqual(snapshot.parameters.contrast, 50)
    }

    /// Test: Preset ID can be modified
    func testPresetIDMutation() {
        var snapshot = EditSnapshot()
        XCTAssertNil(snapshot.selectedPresetID)

        let presetID = UUID()
        snapshot.selectedPresetID = presetID

        XCTAssertEqual(snapshot.selectedPresetID, presetID)
    }

    /// Test: Intensity can be modified
    func testIntensityMutation() {
        var snapshot = EditSnapshot()
        XCTAssertEqual(snapshot.filterIntensity, 100)

        snapshot.filterIntensity = 50

        XCTAssertEqual(snapshot.filterIntensity, 50)
    }

    // MARK: - Edge Case Tests

    /// Test: Zero intensity is valid
    func testZeroIntensity() {
        let snapshot = EditSnapshot(filterIntensity: 0)

        XCTAssertEqual(snapshot.filterIntensity, 0)
    }

    /// Test: Negative intensity is stored (validation is elsewhere)
    func testNegativeIntensityStored() {
        let snapshot = EditSnapshot(filterIntensity: -50)

        XCTAssertEqual(snapshot.filterIntensity, -50)
    }

    /// Test: Above 100 intensity is stored (validation is elsewhere)
    func testAbove100IntensityStored() {
        let snapshot = EditSnapshot(filterIntensity: 150)

        XCTAssertEqual(snapshot.filterIntensity, 150)
    }

    /// Test: Complex parameters in snapshot
    func testComplexParameters() {
        var params = FilterParameters()
        params.exposure = 1.5
        params.contrast = 50
        params.highlights = -30
        params.shadows = 40
        params.temperature = 25
        params.saturation = 15
        params.grain.amount = 20
        params.grain.size = 0.8
        params.vignette.amount = -25
        params.cropRect = CGRect(x: 100, y: 100, width: 800, height: 600)

        let snapshot = EditSnapshot(parameters: params, filterIntensity: 85)

        XCTAssertEqual(snapshot.parameters.exposure, 1.5)
        XCTAssertEqual(snapshot.parameters.contrast, 50)
        XCTAssertEqual(snapshot.parameters.highlights, -30)
        XCTAssertEqual(snapshot.parameters.shadows, 40)
        XCTAssertEqual(snapshot.parameters.temperature, 25)
        XCTAssertEqual(snapshot.parameters.saturation, 15)
        XCTAssertEqual(snapshot.parameters.grain.amount, 20)
        XCTAssertEqual(snapshot.parameters.grain.size, 0.8)
        XCTAssertEqual(snapshot.parameters.vignette.amount, -25)
        XCTAssertNotNil(snapshot.parameters.cropRect)
        XCTAssertEqual(snapshot.filterIntensity, 85)
    }
}
