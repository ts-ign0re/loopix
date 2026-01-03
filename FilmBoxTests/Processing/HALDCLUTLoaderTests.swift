import XCTest
import CoreImage
@testable import FilmBox

/// Tests for HALDCLUTLoader actor
@available(iOS 17.0, *)
final class HALDCLUTLoaderTests: XCTestCase {

    // MARK: - Properties

    private var loader: HALDCLUTLoader!
    private var testCLUTURL: URL!

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        loader = HALDCLUTLoader()

        // Use an actual CLUT file from the hald-clut-master directory for testing
        // This assumes the test is run from a context where this path is accessible
        let projectRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        testCLUTURL = projectRoot
            .appendingPathComponent("hald-clut-master")
            .appendingPathComponent("HaldCLUT")
            .appendingPathComponent("Film Simulation")
            .appendingPathComponent("Color")
            .appendingPathComponent("Kodak")
            .appendingPathComponent("Kodak Portra 400 1 -.png")
    }

    override func tearDown() async throws {
        loader = nil
        testCLUTURL = nil
        try await super.tearDown()
    }

    // MARK: - Loading Tests

    /// Test: Load a valid CLUT file
    func testLoadValidCLUT() async throws {
        // Skip if test file doesn't exist
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available at: \(testCLUTURL.path)")
        }

        let (filter, info) = try await loader.loadCLUT(from: testCLUTURL)

        XCTAssertNotNil(filter, "Should return a valid filter")
        XCTAssertEqual(info.url, testCLUTURL)
        XCTAssertEqual(info.effectiveLevel, 64, "Should downsample to max 64 for CIColorCube")
        XCTAssertTrue(info.wasDownsampled, "1728x1728 CLUT should be downsampled")
    }

    /// Test: Load CLUT data without creating filter
    func testLoadCLUTData() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        let (data, info) = try await loader.loadCLUTData(from: testCLUTURL)

        // Cube data should be 64^3 * 4 floats * 4 bytes per float
        let expectedSize = 64 * 64 * 64 * 4 * MemoryLayout<Float>.size
        XCTAssertEqual(data.count, expectedSize, "Cube data should be correct size")
        XCTAssertEqual(info.effectiveLevel, 64)
    }

    /// Test: File not found error
    func testFileNotFoundError() async {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/clut.png")

        do {
            _ = try await loader.loadCLUT(from: invalidURL)
            XCTFail("Should throw file not found error")
        } catch let error as HALDCLUTLoader.CLUTError {
            if case .fileNotFound = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Caching Tests

    /// Test: CLUT is cached after first load
    func testCLUTCaching() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        // First load
        let (filter1, _) = try await loader.loadCLUT(from: testCLUTURL)

        // Second load should use cache
        let (filter2, _) = try await loader.loadCLUT(from: testCLUTURL)

        XCTAssertNotNil(filter1)
        XCTAssertNotNil(filter2)
    }

    /// Test: Clear cache
    func testClearCache() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        // Load to populate cache
        _ = try await loader.loadCLUT(from: testCLUTURL)

        // Clear cache
        await loader.clearCache()

        // Should still work after clearing
        let (filter, _) = try await loader.loadCLUT(from: testCLUTURL)
        XCTAssertNotNil(filter)
    }

    /// Test: Remove specific URL from cache
    func testRemoveFromCache() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        // Load to populate cache
        _ = try await loader.loadCLUT(from: testCLUTURL)

        // Remove from cache
        await loader.removeFromCache(url: testCLUTURL)

        // Should still work (will reload)
        let (filter, _) = try await loader.loadCLUT(from: testCLUTURL)
        XCTAssertNotNil(filter)
    }

    // MARK: - Filter Application Tests

    /// Test: Apply CLUT filter to image
    func testApplyCLUTFilter() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        let (filter, _) = try await loader.loadCLUT(from: testCLUTURL)

        // Create a test image
        let testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            size: CGSize(width: 100, height: 100)
        )

        // Apply the filter
        filter.setValue(testImage, forKey: kCIInputImageKey)
        let output = filter.outputImage

        XCTAssertNotNil(output, "CLUT filter should produce output")
        if let output = output {
            XCTAssertEqual(output.extent.width, testImage.extent.width, accuracy: 1)
            XCTAssertEqual(output.extent.height, testImage.extent.height, accuracy: 1)
        }
    }

    /// Test: CLUT changes colors
    func testCLUTChangesColors() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        let (filter, _) = try await loader.loadCLUT(from: testCLUTURL)
        let context = CIContext()

        // Create a test image
        let testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0),
            size: CGSize(width: 100, height: 100)
        )

        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // Apply the filter
        filter.setValue(testImage, forKey: kCIInputImageKey)
        guard let output = filter.outputImage else {
            XCTFail("Filter should produce output")
            return
        }

        let adjustedColor = ImageTestUtilities.averageColor(of: output, context: context)

        // Colors should be different (film simulation changes colors)
        let colorDifference = abs(originalColor.r - adjustedColor.r) +
                             abs(originalColor.g - adjustedColor.g) +
                             abs(originalColor.b - adjustedColor.b)

        XCTAssertGreaterThan(colorDifference, 0.01, "CLUT should change colors")
    }

    // MARK: - Batch Loading Tests

    /// Test: Load multiple CLUTs concurrently
    func testBatchLoading() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        // Get a few different CLUT files
        let baseDir = testCLUTURL.deletingLastPathComponent()
        let contents = try FileManager.default.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil)
        let pngFiles = contents.filter { $0.pathExtension == "png" }.prefix(3)

        guard pngFiles.count >= 2 else {
            throw XCTSkip("Not enough test CLUT files available")
        }

        let results = await loader.loadCLUTs(from: Array(pngFiles))

        XCTAssertEqual(results.count, pngFiles.count)

        var successCount = 0
        for (_, result) in results {
            if case .success = result {
                successCount += 1
            }
        }

        XCTAssertEqual(successCount, pngFiles.count, "All CLUTs should load successfully")
    }

    // MARK: - Performance Tests

    /// Test: CLUT loading performance
    func testCLUTLoadingPerformance() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        // Clear cache first
        await loader.clearCache()

        measure {
            let expectation = XCTestExpectation(description: "Load CLUT")

            Task {
                _ = try? await self.loader.loadCLUT(from: self.testCLUTURL)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

    /// Test: Cached CLUT access performance
    func testCachedCLUTPerformance() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        // Pre-load to cache
        _ = try await loader.loadCLUT(from: testCLUTURL)

        measure {
            let expectation = XCTestExpectation(description: "Access cached CLUT")

            Task {
                _ = try? await self.loader.loadCLUT(from: self.testCLUTURL)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }

    /// Test: CLUT application performance
    func testCLUTApplicationPerformance() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        let (filter, _) = try await loader.loadCLUT(from: testCLUTURL)
        let context = CIContext()

        let largeImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 1000, height: 1000)
        )

        measure {
            filter.setValue(largeImage, forKey: kCIInputImageKey)
            if let output = filter.outputImage {
                _ = context.createCGImage(output, from: output.extent)
            }
        }
    }

    // MARK: - Integration with FilterEngine Tests

    /// Test: FilterEngine can apply CLUT via preset
    func testFilterEngineWithCLUTPreset() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        let engine = FilterEngine()
        let testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            size: CGSize(width: 100, height: 100)
        )

        // Create a preset with CLUT
        let preset = FilterPreset(
            name: "Test Portra",
            category: .film,
            source: .haldCLUT(manufacturer: "Kodak", filmStock: "Portra 400"),
            parameters: .identity,
            metadata: FilterPreset.FilterMetadata(filmStock: "Kodak Portra 400"),
            clutPath: testCLUTURL.path,
            clutIntensity: 100
        )

        let result = await engine.apply(preset, to: testImage)

        XCTAssertFalse(result.extent.isEmpty, "Result should not be empty")
    }

    /// Test: FilterEngine CLUT with intensity
    func testFilterEngineCLUTIntensity() async throws {
        guard FileManager.default.fileExists(atPath: testCLUTURL.path) else {
            throw XCTSkip("Test CLUT file not available")
        }

        let engine = FilterEngine()
        let context = CIContext()

        let testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            size: CGSize(width: 100, height: 100)
        )

        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // Full intensity
        let result100 = await engine.applyCLUT(
            at: testCLUTURL.path,
            to: testImage,
            intensity: 100
        )
        let color100 = ImageTestUtilities.averageColor(of: result100, context: context)

        // Half intensity
        let result50 = await engine.applyCLUT(
            at: testCLUTURL.path,
            to: testImage,
            intensity: 50
        )
        let color50 = ImageTestUtilities.averageColor(of: result50, context: context)

        // Half intensity should be between original and full intensity
        let diff100 = abs(color100.r - originalColor.r)
        let diff50 = abs(color50.r - originalColor.r)

        XCTAssertLessThan(diff50, diff100, "50% intensity should change colors less than 100%")
    }
}
