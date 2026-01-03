import XCTest
@testable import FilmBox

/// Tests for FilterPreset data model
final class FilterPresetTests: XCTestCase {

    // MARK: - Initialization Tests

    /// Test: Default initialization
    func testDefaultInitialization() {
        let preset = FilterPreset(name: "Test Preset")

        XCTAssertEqual(preset.name, "Test Preset")
        XCTAssertEqual(preset.category, .custom)
        XCTAssertEqual(preset.source, .userCreated)
        XCTAssertEqual(preset.parameters, .identity)
        XCTAssertNotNil(preset.id)
        XCTAssertNotNil(preset.createdAt)
        XCTAssertNotNil(preset.modifiedAt)
    }

    /// Test: Full initialization
    func testFullInitialization() {
        let id = UUID()
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 20

        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Kodak Portra 400",
            era: "2000s",
            characteristics: ["warm", "soft"],
            author: "Test Author"
        )

        let preset = FilterPreset(
            id: id,
            name: "Portra Style",
            category: .film,
            source: .builtIn,
            parameters: params,
            metadata: metadata
        )

        XCTAssertEqual(preset.id, id)
        XCTAssertEqual(preset.name, "Portra Style")
        XCTAssertEqual(preset.category, .film)
        XCTAssertEqual(preset.source, .builtIn)
        XCTAssertEqual(preset.parameters.exposure, 0.5)
        XCTAssertEqual(preset.metadata.filmStock, "Kodak Portra 400")
        XCTAssertEqual(preset.metadata.characteristics.count, 2)
    }

    // MARK: - Original Preset Tests

    /// Test: Original preset has identity parameters
    func testOriginalPresetIsIdentity() {
        let original = FilterPreset.original

        XCTAssertEqual(original.name, "Original")
        XCTAssertEqual(original.parameters, .identity)
        XCTAssertEqual(original.source, .builtIn)
        XCTAssertFalse(original.parameters.hasAdjustments)
    }

    /// Test: Original preset has fixed UUID
    func testOriginalPresetHasFixedUUID() {
        let original = FilterPreset.original
        let expectedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        XCTAssertEqual(original.id, expectedUUID)
    }

    // MARK: - Duplication Tests

    /// Test: Duplicate creates new preset with new ID
    func testDuplicateCreatesNewID() {
        let original = FilterPreset(name: "Original Name")
        let duplicate = original.duplicate(newName: "Copy")

        XCTAssertNotEqual(original.id, duplicate.id)
        XCTAssertEqual(duplicate.name, "Copy")
    }

    /// Test: Duplicate preserves parameters
    func testDuplicatePreservesParameters() {
        var params = FilterParameters()
        params.exposure = 1.0
        params.contrast = 50
        params.grain.amount = 25

        let original = FilterPreset(
            name: "Original",
            parameters: params
        )

        let duplicate = original.duplicate(newName: "Copy")

        XCTAssertEqual(duplicate.parameters.exposure, 1.0)
        XCTAssertEqual(duplicate.parameters.contrast, 50)
        XCTAssertEqual(duplicate.parameters.grain.amount, 25)
    }

    /// Test: Duplicate changes source to userCreated
    func testDuplicateChangesSource() {
        let original = FilterPreset(
            name: "Built-in",
            source: .builtIn
        )

        let duplicate = original.duplicate(newName: "My Copy")

        XCTAssertEqual(duplicate.source, .userCreated)
    }

    // MARK: - Touch Tests

    /// Test: Touch updates modifiedAt
    func testTouchUpdatesModifiedAt() {
        var preset = FilterPreset(name: "Test")
        let originalModified = preset.modifiedAt

        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        preset.touch()

        XCTAssertGreaterThan(preset.modifiedAt, originalModified)
    }

    // MARK: - Usage Recording Tests

    /// Test: Record usage increments count
    func testRecordUsageIncrementsCount() {
        var preset = FilterPreset(name: "Test")
        XCTAssertEqual(preset.metadata.usageCount, 0)

        preset.recordUsage()
        XCTAssertEqual(preset.metadata.usageCount, 1)

        preset.recordUsage()
        preset.recordUsage()
        XCTAssertEqual(preset.metadata.usageCount, 3)
    }

    /// Test: Record usage updates modifiedAt
    func testRecordUsageUpdatesModifiedAt() {
        var preset = FilterPreset(name: "Test")
        let originalModified = preset.modifiedAt

        Thread.sleep(forTimeInterval: 0.01)

        preset.recordUsage()

        XCTAssertGreaterThan(preset.modifiedAt, originalModified)
    }

    // MARK: - Intensity Application Tests

    /// Test: Parameters at 100% returns full parameters
    func testParametersAtFullIntensity() {
        var params = FilterParameters()
        params.exposure = 2.0
        params.contrast = 50

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 100)

        XCTAssertEqual(result.exposure, 2.0)
        XCTAssertEqual(result.contrast, 50)
    }

    /// Test: Parameters at 0% returns identity
    func testParametersAtZeroIntensity() {
        var params = FilterParameters()
        params.exposure = 2.0
        params.contrast = 50

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 0)

        XCTAssertEqual(result.exposure, 0)
        XCTAssertEqual(result.contrast, 0)
    }

    /// Test: Parameters at 50% returns interpolated
    func testParametersAtHalfIntensity() {
        var params = FilterParameters()
        params.exposure = 2.0
        params.contrast = 100

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 50)

        XCTAssertEqual(result.exposure, 1.0, accuracy: 0.01)
        XCTAssertEqual(result.contrast, 50, accuracy: 0.1)
    }

    // MARK: - Codable Tests

    /// Test: FilterPreset encodes and decodes correctly
    func testCodableRoundTrip() throws {
        var params = FilterParameters()
        params.exposure = 0.8
        params.saturation = 15

        let original = FilterPreset(
            name: "Test Filter",
            category: .warm,
            source: .userCreated,
            parameters: params,
            metadata: FilterPreset.FilterMetadata(
                filmStock: "Test Stock",
                characteristics: ["warm", "soft"]
            )
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FilterPreset.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.category, decoded.category)
        XCTAssertEqual(original.parameters.exposure, decoded.parameters.exposure)
        XCTAssertEqual(original.metadata.filmStock, decoded.metadata.filmStock)
    }

    /// Test: FilterSource builtIn encodes correctly
    func testFilterSourceBuiltInCodable() throws {
        let source = FilterPreset.FilterSource.builtIn

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(FilterPreset.FilterSource.self, from: data)

        XCTAssertEqual(source, decoded)
    }

    /// Test: FilterSource userCreated encodes correctly
    func testFilterSourceUserCreatedCodable() throws {
        let source = FilterPreset.FilterSource.userCreated

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(FilterPreset.FilterSource.self, from: data)

        XCTAssertEqual(source, decoded)
    }

    /// Test: FilterSource calibrated encodes correctly
    func testFilterSourceCalibratedCodable() throws {
        let source = FilterPreset.FilterSource.calibrated(referenceImageHash: "abc123")

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(FilterPreset.FilterSource.self, from: data)

        if case .calibrated(let hash) = decoded {
            XCTAssertEqual(hash, "abc123")
        } else {
            XCTFail("Decoded source should be calibrated")
        }
    }

    /// Test: FilterSource imported encodes correctly
    func testFilterSourceImportedCodable() throws {
        let source = FilterPreset.FilterSource.imported(sourceName: "Lightroom Export")

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(FilterPreset.FilterSource.self, from: data)

        if case .imported(let name) = decoded {
            XCTAssertEqual(name, "Lightroom Export")
        } else {
            XCTFail("Decoded source should be imported")
        }
    }

    // MARK: - Metadata Tests

    /// Test: Metadata default values
    func testMetadataDefaults() {
        let metadata = FilterPreset.FilterMetadata()

        XCTAssertNil(metadata.filmStock)
        XCTAssertNil(metadata.era)
        XCTAssertTrue(metadata.characteristics.isEmpty)
        XCTAssertNil(metadata.author)
        XCTAssertFalse(metadata.isFavorite)
        XCTAssertEqual(metadata.usageCount, 0)
    }

    /// Test: Metadata with all fields
    func testMetadataWithAllFields() {
        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Kodak Tri-X 400",
            era: "1960s",
            characteristics: ["high contrast", "grainy", "classic"],
            author: "Ansel Adams",
            isFavorite: true,
            usageCount: 42
        )

        XCTAssertEqual(metadata.filmStock, "Kodak Tri-X 400")
        XCTAssertEqual(metadata.era, "1960s")
        XCTAssertEqual(metadata.characteristics.count, 3)
        XCTAssertEqual(metadata.author, "Ansel Adams")
        XCTAssertTrue(metadata.isFavorite)
        XCTAssertEqual(metadata.usageCount, 42)
    }

    // MARK: - Hashable Tests

    /// Test: Preset equals itself
    func testPresetEqualsItself() {
        let preset = FilterPreset(name: "Test")
        XCTAssertEqual(preset, preset, "Preset should equal itself")
    }

    /// Test: Encoded and decoded preset equals original
    func testEncodedDecodedPresetEqualsOriginal() throws {
        let original = FilterPreset(name: "Test", category: .warm)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FilterPreset.self, from: data)

        XCTAssertEqual(original, decoded, "Decoded preset should equal original")
    }

    /// Test: Different properties means not equal
    func testDifferentPropertiesMeansNotEqual() {
        let id = UUID()

        let a = FilterPreset(id: id, name: "A")
        let b = FilterPreset(id: id, name: "B")

        XCTAssertNotEqual(a, b, "Presets with different names should not be equal")
    }

    /// Test: Presets can be used in Set
    func testPresetsInSet() {
        let preset = FilterPreset(name: "Test")

        var set: Set<FilterPreset> = [preset, preset]
        XCTAssertEqual(set.count, 1, "Set should deduplicate same preset")

        let another = FilterPreset(name: "Another")
        set.insert(another)
        XCTAssertEqual(set.count, 2, "Set should have 2 different presets")
    }

    // MARK: - Category Tests

    /// Test: All categories have display names
    func testAllCategoriesHaveDisplayNames() {
        for category in FilterCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category) should have a display name")
        }
    }
}
