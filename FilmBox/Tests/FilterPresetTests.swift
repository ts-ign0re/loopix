import XCTest
@testable import FilmBox

/// Unit tests for FilterPreset struct and related types
final class FilterPresetTests: XCTestCase {

    // MARK: - Preset Creation Tests

    func testPresetCreationWithDefaults() {
        let preset = FilterPreset(name: "Test Preset")

        XCTAssertEqual(preset.name, "Test Preset")
        XCTAssertEqual(preset.category, .custom)
        XCTAssertEqual(preset.source, .userCreated)
        XCTAssertEqual(preset.parameters, .identity)
        XCTAssertFalse(preset.metadata.isFavorite)
        XCTAssertEqual(preset.metadata.usageCount, 0)
    }

    func testPresetCreationWithCustomParameters() {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 25

        let preset = FilterPreset(
            name: "Custom Preset",
            category: .warm,
            parameters: params
        )

        XCTAssertEqual(preset.name, "Custom Preset")
        XCTAssertEqual(preset.category, .warm)
        XCTAssertEqual(preset.parameters.exposure, 0.5)
        XCTAssertEqual(preset.parameters.contrast, 25)
    }

    func testPresetCreationWithMetadata() {
        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Kodak Portra 400",
            era: "2000s",
            characteristics: ["warm", "natural skin tones"],
            author: "Test Author",
            isFavorite: true,
            usageCount: 10
        )

        let preset = FilterPreset(
            name: "Film Preset",
            category: .film,
            metadata: metadata
        )

        XCTAssertEqual(preset.metadata.filmStock, "Kodak Portra 400")
        XCTAssertEqual(preset.metadata.era, "2000s")
        XCTAssertEqual(preset.metadata.characteristics.count, 2)
        XCTAssertEqual(preset.metadata.author, "Test Author")
        XCTAssertTrue(preset.metadata.isFavorite)
        XCTAssertEqual(preset.metadata.usageCount, 10)
    }

    func testPresetCreationWithAllCategories() {
        for category in FilterCategory.allCases {
            let preset = FilterPreset(name: "Test", category: category)
            XCTAssertEqual(preset.category, category)
        }
    }

    func testPresetHasValidUUID() {
        let preset = FilterPreset(name: "Test")
        XCTAssertNotNil(preset.id)
    }

    func testPresetHasCreatedAtDate() {
        let beforeCreation = Date()
        let preset = FilterPreset(name: "Test")
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(preset.createdAt, beforeCreation)
        XCTAssertLessThanOrEqual(preset.createdAt, afterCreation)
    }

    func testPresetHasModifiedAtDate() {
        let beforeCreation = Date()
        let preset = FilterPreset(name: "Test")
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(preset.modifiedAt, beforeCreation)
        XCTAssertLessThanOrEqual(preset.modifiedAt, afterCreation)
    }

    // MARK: - Duplicate Tests

    func testDuplicateCreatesNewPreset() {
        var params = FilterParameters()
        params.exposure = 1.0
        params.saturation = 50

        let original = FilterPreset(
            name: "Original",
            category: .warm,
            parameters: params
        )

        let duplicate = original.duplicate(newName: "Copy of Original")

        XCTAssertNotEqual(original.id, duplicate.id)
        XCTAssertEqual(duplicate.name, "Copy of Original")
    }

    func testDuplicatePreservesCategory() {
        let original = FilterPreset(name: "Test", category: .film)
        let duplicate = original.duplicate(newName: "Duplicate")

        XCTAssertEqual(duplicate.category, .film)
    }

    func testDuplicatePreservesParameters() {
        var params = FilterParameters()
        params.exposure = 1.5
        params.contrast = -25
        params.grain.amount = 30

        let original = FilterPreset(name: "Test", parameters: params)
        let duplicate = original.duplicate(newName: "Duplicate")

        XCTAssertEqual(duplicate.parameters.exposure, 1.5)
        XCTAssertEqual(duplicate.parameters.contrast, -25)
        XCTAssertEqual(duplicate.parameters.grain.amount, 30)
    }

    func testDuplicatePreservesMetadata() {
        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Fuji Pro 400H",
            characteristics: ["soft", "pastel"]
        )

        let original = FilterPreset(name: "Test", metadata: metadata)
        let duplicate = original.duplicate(newName: "Duplicate")

        XCTAssertEqual(duplicate.metadata.filmStock, "Fuji Pro 400H")
        XCTAssertEqual(duplicate.metadata.characteristics, ["soft", "pastel"])
    }

    func testDuplicateSetsSourceToUserCreated() {
        let original = FilterPreset(
            name: "Built-In",
            source: .builtIn
        )

        let duplicate = original.duplicate(newName: "User Copy")

        XCTAssertEqual(duplicate.source, .userCreated)
    }

    func testDuplicateCreatesNewDates() {
        let original = FilterPreset(name: "Test")

        // Small delay to ensure different timestamps
        Thread.sleep(forTimeInterval: 0.01)

        let duplicate = original.duplicate(newName: "Duplicate")

        XCTAssertGreaterThan(duplicate.createdAt, original.createdAt)
        XCTAssertGreaterThan(duplicate.modifiedAt, original.modifiedAt)
    }

    // MARK: - Original Preset Tests

    func testOriginalPresetHasCorrectName() {
        XCTAssertEqual(FilterPreset.original.name, "Original")
    }

    func testOriginalPresetHasCorrectCategory() {
        XCTAssertEqual(FilterPreset.original.category, .all)
    }

    func testOriginalPresetIsBuiltIn() {
        XCTAssertEqual(FilterPreset.original.source, .builtIn)
    }

    func testOriginalPresetHasIdentityParameters() {
        XCTAssertEqual(FilterPreset.original.parameters, .identity)
        XCTAssertFalse(FilterPreset.original.parameters.hasAdjustments)
    }

    func testOriginalPresetHasFixedUUID() {
        let expectedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        XCTAssertEqual(FilterPreset.original.id, expectedUUID)
    }

    func testOriginalPresetHasNoAdjustmentsCharacteristic() {
        XCTAssertTrue(FilterPreset.original.metadata.characteristics.contains("No adjustments"))
    }

    // MARK: - Touch Method Tests

    func testTouchUpdatesModifiedAt() {
        var preset = FilterPreset(name: "Test")
        let originalModifiedAt = preset.modifiedAt

        Thread.sleep(forTimeInterval: 0.01)
        preset.touch()

        XCTAssertGreaterThan(preset.modifiedAt, originalModifiedAt)
    }

    // MARK: - Record Usage Tests

    func testRecordUsageIncrementsCount() {
        var preset = FilterPreset(name: "Test")
        XCTAssertEqual(preset.metadata.usageCount, 0)

        preset.recordUsage()
        XCTAssertEqual(preset.metadata.usageCount, 1)

        preset.recordUsage()
        XCTAssertEqual(preset.metadata.usageCount, 2)
    }

    func testRecordUsageUpdatesModifiedAt() {
        var preset = FilterPreset(name: "Test")
        let originalModifiedAt = preset.modifiedAt

        Thread.sleep(forTimeInterval: 0.01)
        preset.recordUsage()

        XCTAssertGreaterThan(preset.modifiedAt, originalModifiedAt)
    }

    // MARK: - Parameters at Intensity Tests

    func testParametersAtFullIntensity() {
        var params = FilterParameters()
        params.exposure = 2.0
        params.contrast = 100

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 100)

        XCTAssertEqual(result.exposure, 2.0)
        XCTAssertEqual(result.contrast, 100)
    }

    func testParametersAtZeroIntensity() {
        var params = FilterParameters()
        params.exposure = 2.0
        params.contrast = 100

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 0)

        XCTAssertEqual(result.exposure, 0)
        XCTAssertEqual(result.contrast, 0)
    }

    func testParametersAtHalfIntensity() {
        var params = FilterParameters()
        params.exposure = 2.0
        params.contrast = 100

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 50)

        XCTAssertEqual(result.exposure, 1.0)
        XCTAssertEqual(result.contrast, 50)
    }

    func testParametersAtQuarterIntensity() {
        var params = FilterParameters()
        params.saturation = 80
        params.vibrance = 40

        let preset = FilterPreset(name: "Test", parameters: params)
        let result = preset.parameters(at: 25)

        XCTAssertEqual(result.saturation, 20)
        XCTAssertEqual(result.vibrance, 10)
    }

    // MARK: - FilterSource Encoding/Decoding Tests

    func testFilterSourceBuiltInCodable() throws {
        let source = FilterPreset.FilterSource.builtIn

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.FilterSource.self, from: data)

        XCTAssertEqual(decoded, source)
    }

    func testFilterSourceUserCreatedCodable() throws {
        let source = FilterPreset.FilterSource.userCreated

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.FilterSource.self, from: data)

        XCTAssertEqual(decoded, source)
    }

    func testFilterSourceCalibratedCodable() throws {
        let source = FilterPreset.FilterSource.calibrated(referenceImageHash: "abc123def456")

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.FilterSource.self, from: data)

        if case .calibrated(let hash) = decoded {
            XCTAssertEqual(hash, "abc123def456")
        } else {
            XCTFail("Expected calibrated source")
        }
    }

    func testFilterSourceImportedCodable() throws {
        let source = FilterPreset.FilterSource.imported(sourceName: "Lightroom Export")

        let encoder = JSONEncoder()
        let data = try encoder.encode(source)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.FilterSource.self, from: data)

        if case .imported(let name) = decoded {
            XCTAssertEqual(name, "Lightroom Export")
        } else {
            XCTFail("Expected imported source")
        }
    }

    func testFilterSourceUnknownTypeDefaultsToUserCreated() throws {
        let json = """
        {"type": "unknown"}
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.FilterSource.self, from: data)

        XCTAssertEqual(decoded, .userCreated)
    }

    // MARK: - FilterMetadata Tests

    func testFilterMetadataDefaultInitialization() {
        let metadata = FilterPreset.FilterMetadata()

        XCTAssertNil(metadata.filmStock)
        XCTAssertNil(metadata.era)
        XCTAssertTrue(metadata.characteristics.isEmpty)
        XCTAssertNil(metadata.author)
        XCTAssertFalse(metadata.isFavorite)
        XCTAssertEqual(metadata.usageCount, 0)
    }

    func testFilterMetadataFullInitialization() {
        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Kodak Ektar 100",
            era: "Modern",
            characteristics: ["vivid", "saturated", "sharp"],
            author: "Kodak",
            isFavorite: true,
            usageCount: 100
        )

        XCTAssertEqual(metadata.filmStock, "Kodak Ektar 100")
        XCTAssertEqual(metadata.era, "Modern")
        XCTAssertEqual(metadata.characteristics.count, 3)
        XCTAssertTrue(metadata.characteristics.contains("vivid"))
        XCTAssertEqual(metadata.author, "Kodak")
        XCTAssertTrue(metadata.isFavorite)
        XCTAssertEqual(metadata.usageCount, 100)
    }

    func testFilterMetadataCodable() throws {
        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Ilford HP5",
            era: "1980s",
            characteristics: ["grainy", "contrasty"],
            author: "Test"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.FilterMetadata.self, from: data)

        XCTAssertEqual(decoded.filmStock, "Ilford HP5")
        XCTAssertEqual(decoded.era, "1980s")
        XCTAssertEqual(decoded.characteristics, ["grainy", "contrasty"])
        XCTAssertEqual(decoded.author, "Test")
    }

    // MARK: - Full Preset Codable Tests

    func testPresetCodableRoundTrip() throws {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 30
        params.saturation = -15

        let metadata = FilterPreset.FilterMetadata(
            filmStock: "Fuji Superia 400",
            characteristics: ["warm", "nostalgic"]
        )

        let preset = FilterPreset(
            name: "Test Preset",
            category: .warm,
            source: .userCreated,
            parameters: params,
            metadata: metadata
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(preset)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterPreset.self, from: data)

        XCTAssertEqual(decoded.id, preset.id)
        XCTAssertEqual(decoded.name, "Test Preset")
        XCTAssertEqual(decoded.category, .warm)
        XCTAssertEqual(decoded.parameters.exposure, 0.5)
        XCTAssertEqual(decoded.parameters.contrast, 30)
        XCTAssertEqual(decoded.metadata.filmStock, "Fuji Superia 400")
    }

    // MARK: - Hashable Tests

    func testPresetHashable() {
        let preset1 = FilterPreset(id: UUID(), name: "Test")
        let preset2 = FilterPreset(id: preset1.id, name: "Test")

        // Same ID should have same hash
        XCTAssertEqual(preset1.hashValue, preset2.hashValue)
    }

    func testPresetEquatable() {
        let id = UUID()
        let preset1 = FilterPreset(id: id, name: "Test")
        let preset2 = FilterPreset(id: id, name: "Test")

        XCTAssertEqual(preset1, preset2)
    }

    func testPresetNotEqualWithDifferentID() {
        let preset1 = FilterPreset(name: "Test")
        let preset2 = FilterPreset(name: "Test")

        XCTAssertNotEqual(preset1, preset2)
    }

    // MARK: - Identifiable Tests

    func testPresetIdentifiable() {
        let preset = FilterPreset(name: "Test")
        XCTAssertNotNil(preset.id)

        // ID should be usable in collections
        let presets = [preset]
        XCTAssertTrue(presets.contains(where: { $0.id == preset.id }))
    }
}
