import XCTest
@testable import FilmBox

/// Tests for FilterStorage actor
@available(iOS 17.0, *)
final class FilterStorageTests: XCTestCase {

    // MARK: - Error Tests

    /// Test: FilterStorageError descriptions
    func testFilterStorageErrorDescriptions() {
        let testUUID = UUID()

        let presetNotFound = FilterStorageError.presetNotFound(testUUID)
        XCTAssertTrue(presetNotFound.errorDescription?.contains(testUUID.uuidString) ?? false)

        let cannotModify = FilterStorageError.cannotModifyBuiltIn
        XCTAssertNotNil(cannotModify.errorDescription)
        XCTAssertTrue(cannotModify.errorDescription?.contains("built-in") ?? false)

        let encodingFailed = FilterStorageError.encodingFailed
        XCTAssertNotNil(encodingFailed.errorDescription)
        XCTAssertTrue(encodingFailed.errorDescription?.contains("encode") ?? false)

        let decodingFailed = FilterStorageError.decodingFailed
        XCTAssertNotNil(decodingFailed.errorDescription)
        XCTAssertTrue(decodingFailed.errorDescription?.contains("decode") ?? false)

        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let fileOpFailed = FilterStorageError.fileOperationFailed(testError)
        XCTAssertNotNil(fileOpFailed.errorDescription)
        XCTAssertTrue(fileOpFailed.errorDescription?.contains("File operation") ?? false)
    }

    // MARK: - Built-in Presets Tests

    /// Test: Built-in presets are available
    func testBuiltInPresetsNotEmpty() async {
        let builtIn = FilterStorage.shared.builtInPresets
        XCTAssertFalse(builtIn.isEmpty, "Built-in presets should not be empty")
    }

    /// Test: Built-in presets include Original
    func testBuiltInPresetsIncludeOriginal() async {
        let builtIn = FilterStorage.shared.builtInPresets
        let hasOriginal = builtIn.contains { $0.name == "Original" }
        XCTAssertTrue(hasOriginal, "Built-in presets should include Original")
    }

    /// Test: Built-in presets are marked as builtIn source
    func testBuiltInPresetsHaveCorrectSource() async {
        let builtIn = FilterStorage.shared.builtInPresets

        // Original preset should be builtIn
        let original = builtIn.first { $0.name == "Original" }
        XCTAssertNotNil(original)
        if case .builtIn = original?.source {
            // Expected
        } else {
            XCTFail("Original preset should have builtIn source")
        }
    }

    /// Test: Built-in presets have unique IDs
    func testBuiltInPresetsHaveUniqueIDs() async {
        let builtIn = FilterStorage.shared.builtInPresets
        let ids = builtIn.map { $0.id }
        let uniqueIDs = Set(ids)

        XCTAssertEqual(ids.count, uniqueIDs.count, "All built-in preset IDs should be unique")
    }

    // MARK: - All Presets Tests

    /// Test: All presets includes built-in
    func testAllPresetsIncludesBuiltIn() async {
        let all = await FilterStorage.shared.allPresets
        let builtIn = FilterStorage.shared.builtInPresets

        for preset in builtIn {
            XCTAssertTrue(all.contains { $0.id == preset.id }, "All presets should include \(preset.name)")
        }
    }

    // MARK: - Category Filtering Tests

    /// Test: Filter by .all returns all presets
    func testFilterByCategoryAll() async {
        let all = await FilterStorage.shared.allPresets
        let filtered = await FilterStorage.shared.presets(for: .all)

        XCTAssertEqual(all.count, filtered.count)
    }

    /// Test: Filter by category returns only matching presets
    func testFilterByCategoryWarm() async {
        let warmPresets = await FilterStorage.shared.presets(for: .warm)

        for preset in warmPresets {
            XCTAssertEqual(preset.category, .warm, "Filtered preset \(preset.name) should have warm category")
        }
    }

    /// Test: Filter by category returns only matching presets for film
    func testFilterByCategoryFilm() async {
        let filmPresets = await FilterStorage.shared.presets(for: .film)

        for preset in filmPresets {
            XCTAssertEqual(preset.category, .film, "Filtered preset \(preset.name) should have film category")
        }
    }

    // MARK: - Get Preset By ID Tests

    /// Test: Get existing preset by ID
    func testGetPresetByValidID() async {
        let builtIn = FilterStorage.shared.builtInPresets
        guard let firstPreset = builtIn.first else {
            XCTFail("Should have at least one built-in preset")
            return
        }

        let found = await FilterStorage.shared.getPreset(by: firstPreset.id)
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, firstPreset.id)
        XCTAssertEqual(found?.name, firstPreset.name)
    }

    /// Test: Get non-existent preset returns nil
    func testGetPresetByInvalidID() async {
        let randomID = UUID()
        let found = await FilterStorage.shared.getPreset(by: randomID)

        XCTAssertNil(found, "Should return nil for non-existent preset ID")
    }

    // MARK: - Export Tests

    /// Test: Export preset produces valid JSON
    func testExportPresetProducesValidJSON() async throws {
        let builtIn = FilterStorage.shared.builtInPresets
        guard let preset = builtIn.first else {
            throw XCTSkip("No built-in presets available")
        }

        let data = try await FilterStorage.shared.exportPreset(id: preset.id)

        // Verify it's valid JSON - use ISO8601 date strategy to match FilterStorage
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FilterPreset.self, from: data)
        XCTAssertEqual(decoded.id, preset.id)
        XCTAssertEqual(decoded.name, preset.name)
    }

    /// Test: Export non-existent preset throws error
    func testExportNonExistentPresetThrows() async {
        let randomID = UUID()

        do {
            _ = try await FilterStorage.shared.exportPreset(id: randomID)
            XCTFail("Should throw error for non-existent preset")
        } catch let error as FilterStorageError {
            if case .presetNotFound(let id) = error {
                XCTAssertEqual(id, randomID)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Delete Built-in Tests

    /// Test: Cannot delete built-in preset
    func testCannotDeleteBuiltInPreset() async {
        let original = FilterPreset.original

        do {
            try await FilterStorage.shared.delete(id: original.id)
            XCTFail("Should throw error when deleting built-in preset")
        } catch let error as FilterStorageError {
            if case .cannotModifyBuiltIn = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Import Tests

    /// Test: Import preset creates new user preset
    func testImportPresetCreatesUserPreset() async throws {
        // Create a test preset JSON
        let testPreset = FilterPreset(
            name: "Import Test \(UUID().uuidString.prefix(8))",
            category: .warm,
            parameters: FilterParameters()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(testPreset)

        // Import it
        let imported = try await FilterStorage.shared.importPreset(from: data)

        // Verify it was imported with new ID
        XCTAssertNotEqual(imported.id, testPreset.id, "Imported preset should have new ID")
        XCTAssertEqual(imported.category, testPreset.category)

        // Clean up
        try? await FilterStorage.shared.delete(id: imported.id)
    }
}
