import XCTest
import CoreImage
import ImageIO
import UniformTypeIdentifiers
@testable import FilmBox

/// Calibration tests that apply film presets to test images and compare against CLUT reference
/// Outputs results to film-test-results/ directory for visual inspection and calibration
@available(iOS 17.0, *)
final class FilmCalibrationTests: XCTestCase {

    // MARK: - Properties

    private var engine: FilterEngine!
    private var clutLoader: HALDCLUTLoader!
    private var testImage: CIImage!
    private var context: CIContext!

    private var projectRoot: URL!
    private var testImageURL: URL!
    private var clutBaseURL: URL!
    private var outputBaseURL: URL!

    // MARK: - CLUT Mapping

    /// Maps app filter IDs to their corresponding CLUT files
    private let filterToCLUTMapping: [String: String] = [
        // Kodak Color
        "kodak_portra_160": "Film Simulation/Color/Kodak/Kodak Portra 160 2.png",
        "kodak_portra_400": "Film Simulation/Color/Kodak/Kodak Portra 400 2.png",
        "kodak_portra_800": "Film Simulation/Color/Kodak/Kodak Portra 800 2.png",
        "kodak_ektar_100": "Film Simulation/Color/Kodak/Kodak Ektar 100.png",
        "kodak_ektachrome_100": "Film Simulation/Color/Kodak/Kodak Ektachrome 100 VS.png",
        "kodak_kodachrome_25": "Film Simulation/Color/Kodak/Kodak Kodachrome 25.png",
        "kodak_kodachrome_64": "Film Simulation/Color/Kodak/Kodak Kodachrome 64.png",
        "kodak_kodachrome_200": "Film Simulation/Color/Kodak/Kodak Kodachrome 200.png",
        "kodak_elite_chrome_200": "Film Simulation/Color/Kodak/Kodak Elite Chrome 200.png",
        "kodak_elite_chrome_400": "Film Simulation/Color/Kodak/Kodak Elite Chrome 400.png",

        // Kodak B&W
        "kodak_trix_400": "Film Simulation/Black and White/Kodak/Kodak TRI-X 400 2.png",
        "kodak_tmax_100": "Film Simulation/Black and White/Kodak/Kodak T-Max 100.png",
        "kodak_tmax_400": "Film Simulation/Black and White/Kodak/Kodak T-Max 400.png",
        "kodak_tmax_3200": "Film Simulation/Black and White/Kodak/Kodak TMAX 3200 2.png",
        "kodak_bw_400cn": "Film Simulation/Black and White/Kodak/Kodak BW 400 CN.png",

        // Fuji Color
        "fuji_160c": "Film Simulation/Color/Fuji/Fuji 160C 2.png",
        "fuji_400h": "Film Simulation/Color/Fuji/Fuji 400H 2.png",
        "fuji_800z": "Film Simulation/Color/Fuji/Fuji 800Z 2.png",
        "fuji_velvia_50": "Film Simulation/Color/Fuji/Fuji Velvia 50.png",
        "fuji_velvia_100": "Film Simulation/Color/Fuji/Fuji Velvia 100 Generic.png",
        "fuji_provia_100f": "Film Simulation/Color/Fuji/Fuji Provia 100F.png",
        "fuji_provia_400f": "Film Simulation/Color/Fuji/Fuji Provia 400F.png",
        "fuji_astia_100f": "Film Simulation/Color/Fuji/Fuji Astia 100F.png",
        "fuji_sensia_100": "Film Simulation/Color/Fuji/Fuji Sensia 100.png",
        "fuji_superia_200_xpro": "Film Simulation/Color/Fuji/Fuji Superia 200 XPRO.png",
        "fuji_superia_400": "Film Simulation/Color/Fuji/Fuji Superia 400 2.png",
        "fuji_superia_800": "Film Simulation/Color/Fuji/Fuji Superia 800 2.png",
        "fuji_superia_1600": "Film Simulation/Color/Fuji/Fuji Superia 1600 2.png",
        "fuji_superia_xtra_800": "Film Simulation/Color/Fuji/Fuji Superia X-Tra 800.png",

        // Fuji B&W
        "fuji_acros_100": "Film Simulation/Black and White/Fuji/Fuji Neopan Acros 100.png",
        "fuji_neopan_1600": "Film Simulation/Black and White/Fuji/Fuji Neopan 1600 2.png",

        // Ilford B&W
        "ilford_hp5_400": "Film Simulation/Black and White/Ilford/Ilford HP5 Plus 400.png",
        "ilford_delta_100": "Film Simulation/Black and White/Ilford/Ilford Delta 100.png",
        "ilford_delta_400": "Film Simulation/Black and White/Ilford/Ilford Delta 400.png",
        "ilford_delta_3200": "Film Simulation/Black and White/Ilford/Ilford Delta 3200 2.png",
        "ilford_fp4_125": "Film Simulation/Black and White/Ilford/Ilford FP4 Plus 125.png",
        "ilford_panf_50": "Film Simulation/Black and White/Ilford/Ilford Pan F Plus 50.png",
        "ilford_xp2": "Film Simulation/Black and White/Ilford/Ilford XP2.png",
        "ilford_hps_800": "Film Simulation/Black and White/Ilford/Ilford HPS 800.png",

        // Polaroid
        "polaroid_664": "Film Simulation/Black and White/Polaroid/Polaroid 664.png",
        "polaroid_665": "Film Simulation/Black and White/Polaroid/Polaroid 665 3.png",
        "polaroid_667": "Film Simulation/Black and White/Polaroid/Polaroid 667.png",
        "polaroid_672": "Film Simulation/Black and White/Polaroid/Polaroid 672.png",

        // Agfa
        "agfa_apx_100": "Film Simulation/Black and White/Agfa/Agfa APX 100.png",
        "agfa_apx_25": "Film Simulation/Black and White/Agfa/Agfa APX 25.png",

        // Rollei
        "rollei_ir_400": "Film Simulation/Black and White/Rollei/Rollei IR 400.png",
        "rollei_ortho_25": "Film Simulation/Black and White/Rollei/Rollei Ortho 25.png",
        "rollei_retro_80s": "Film Simulation/Black and White/Rollei/Rollei Retro 80s.png",
        "rollei_retro_100_tonal": "Film Simulation/Black and White/Rollei/Rollei Retro 100 Tonal.png",
    ]

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()

        engine = FilterEngine()
        clutLoader = HALDCLUTLoader()
        context = CIContext(options: [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ])

        // Setup paths - use environment variable or fallback to known location
        if let envPath = ProcessInfo.processInfo.environment["PROJECT_ROOT"] {
            projectRoot = URL(fileURLWithPath: envPath)
        } else {
            // Try #file first (works in Xcode), fallback to hardcoded path
            let fileBasedPath = URL(fileURLWithPath: #file)
                .deletingLastPathComponent()  // Calibration
                .deletingLastPathComponent()  // FilmBoxTests
                .deletingLastPathComponent()  // FilmBox project root

            // Check if this path is valid
            if FileManager.default.fileExists(atPath: fileBasedPath.appendingPathComponent("test-assets").path) {
                projectRoot = fileBasedPath
            } else {
                // Fallback to hardcoded project path
                projectRoot = URL(fileURLWithPath: "/Users/user/_work/photo-editor")
            }
        }

        testImageURL = projectRoot.appendingPathComponent("test-assets/test.jpg")
        clutBaseURL = projectRoot.appendingPathComponent("hald-clut-master/HaldCLUT")
        outputBaseURL = projectRoot.appendingPathComponent("film-test-results")

        // Create output directories
        try createOutputDirectories()

        // Load test image
        guard FileManager.default.fileExists(atPath: testImageURL.path) else {
            throw XCTSkip("Test image not found at: \(testImageURL.path)")
        }

        guard let imageData = try? Data(contentsOf: testImageURL),
              let ciImage = CIImage(data: imageData) else {
            throw XCTSkip("Failed to load test image")
        }

        testImage = ciImage
    }

    override func tearDown() async throws {
        engine = nil
        clutLoader = nil
        testImage = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createOutputDirectories() throws {
        let directories = [
            outputBaseURL,
            outputBaseURL.appendingPathComponent("app-output"),
            outputBaseURL.appendingPathComponent("clut-reference"),
            outputBaseURL.appendingPathComponent("comparison"),
            outputBaseURL.appendingPathComponent("reports")
        ]

        for dir in directories {
            try FileManager.default.createDirectory(
                at: dir!,
                withIntermediateDirectories: true
            )
        }
    }

    private func saveImage(_ cgImage: CGImage, to url: URL, quality: CGFloat = 0.95) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw CalibrationError.saveFailed
        }

        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw CalibrationError.saveFailed
        }
    }

    private func applyCLUTDirectly(to image: CIImage, clutURL: URL) async throws -> CIImage {
        let (filter, _) = try await clutLoader.loadCLUT(from: clutURL)
        filter.setValue(image, forKey: kCIInputImageKey)
        guard let output = filter.outputImage else {
            throw CalibrationError.filterFailed
        }
        return output
    }

    private func compareImages(_ image1: CIImage, _ image2: CIImage) -> CalibrationResult {
        let extent = image1.extent
        let width = Int(extent.width)
        let height = Int(extent.height)

        var bitmap1 = [UInt8](repeating: 0, count: width * height * 4)
        var bitmap2 = [UInt8](repeating: 0, count: width * height * 4)

        context.render(image1, toBitmap: &bitmap1, rowBytes: width * 4, bounds: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        context.render(image2, toBitmap: &bitmap2, rowBytes: width * 4, bounds: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        var totalR: Float = 0, totalG: Float = 0, totalB: Float = 0
        var sumSquaredDiff: Float = 0
        let pixelCount = Float(width * height)

        for i in stride(from: 0, to: bitmap1.count, by: 4) {
            let diffR = Float(bitmap1[i]) - Float(bitmap2[i])
            let diffG = Float(bitmap1[i+1]) - Float(bitmap2[i+1])
            let diffB = Float(bitmap1[i+2]) - Float(bitmap2[i+2])

            totalR += diffR
            totalG += diffG
            totalB += diffB
            sumSquaredDiff += diffR * diffR + diffG * diffG + diffB * diffB
        }

        let meanR = totalR / pixelCount
        let meanG = totalG / pixelCount
        let meanB = totalB / pixelCount
        let mae = (abs(totalR) + abs(totalG) + abs(totalB)) / (pixelCount * 3)
        let mse = sumSquaredDiff / (pixelCount * 3)
        let psnr = mse > 0 ? 10 * log10(255 * 255 / mse) : 100

        // Calculate suggested corrections
        let temperatureCorrection = -(meanR - meanB) / 2.55  // Red vs Blue shift
        let tintCorrection = -(meanG - (meanR + meanB) / 2) / 2.55  // Green shift
        let exposureCorrection = -(meanR + meanG + meanB) / (3 * 25.5)

        return CalibrationResult(
            mae: mae,
            mse: mse,
            psnr: psnr,
            meanDeltaR: meanR,
            meanDeltaG: meanG,
            meanDeltaB: meanB,
            suggestedTemperature: temperatureCorrection,
            suggestedTint: tintCorrection,
            suggestedExposure: exposureCorrection,
            pass: mae < 5.0
        )
    }

    private func createComparisonImage(app: CGImage, reference: CGImage) -> CGImage? {
        let width = app.width
        let height = app.height

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(
                  data: nil,
                  width: width * 2,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        // Draw app output on left
        ctx.draw(app, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Draw reference on right
        ctx.draw(reference, in: CGRect(x: width, y: 0, width: width, height: height))

        return ctx.makeImage()
    }

    // MARK: - Main Calibration Test

    /// Run calibration for all mapped filters
    func testCalibrateAllFilters() async throws {
        var results: [String: CalibrationResult] = [:]
        var errors: [String: String] = [:]

        for (filterID, clutPath) in filterToCLUTMapping {
            let clutURL = clutBaseURL.appendingPathComponent(clutPath)

            // Skip if CLUT file doesn't exist
            guard FileManager.default.fileExists(atPath: clutURL.path) else {
                errors[filterID] = "CLUT file not found: \(clutPath)"
                continue
            }

            do {
                let result = try await calibrateSingleFilter(filterID: filterID, clutURL: clutURL)
                results[filterID] = result

                print("[\(result.pass ? "✓" : "✗")] \(filterID): MAE=\(String(format: "%.2f", result.mae))")
            } catch {
                errors[filterID] = error.localizedDescription
                print("[ERROR] \(filterID): \(error)")
            }
        }

        // Generate report
        try generateReport(results: results, errors: errors)

        // Summary
        let passed = results.values.filter { $0.pass }.count
        let failed = results.values.filter { !$0.pass }.count
        let errorCount = errors.count

        print("\n=== CALIBRATION SUMMARY ===")
        print("Passed: \(passed)")
        print("Failed: \(failed)")
        print("Errors: \(errorCount)")
        print("Report saved to: \(outputBaseURL.appendingPathComponent("reports/calibration_report.json").path)")

        // Don't fail the test, just report
        XCTAssertTrue(true, "Calibration completed. Check film-test-results/reports/ for details.")
    }

    /// Calibrate a single filter
    private func calibrateSingleFilter(filterID: String, clutURL: URL) async throws -> CalibrationResult {
        // 1. Apply app filter (using parameters or CLUT path)
        let preset = createPresetForFilter(filterID: filterID, clutURL: clutURL)
        let appResult = await engine.apply(preset, to: testImage)

        // 2. Apply CLUT directly as reference
        let clutResult = try await applyCLUTDirectly(to: testImage, clutURL: clutURL)

        // 3. Render both to CGImage
        guard let appCGImage = context.createCGImage(appResult, from: appResult.extent),
              let clutCGImage = context.createCGImage(clutResult, from: clutResult.extent) else {
            throw CalibrationError.renderFailed
        }

        // 4. Save outputs
        let appOutputURL = outputBaseURL
            .appendingPathComponent("app-output")
            .appendingPathComponent("\(filterID).jpg")
        let clutOutputURL = outputBaseURL
            .appendingPathComponent("clut-reference")
            .appendingPathComponent("\(filterID).jpg")

        try saveImage(appCGImage, to: appOutputURL)
        try saveImage(clutCGImage, to: clutOutputURL)

        // 5. Create side-by-side comparison
        if let comparisonImage = createComparisonImage(app: appCGImage, reference: clutCGImage) {
            let comparisonURL = outputBaseURL
                .appendingPathComponent("comparison")
                .appendingPathComponent("\(filterID)_comparison.jpg")
            try saveImage(comparisonImage, to: comparisonURL)
        }

        // 6. Compare and return result
        return compareImages(appResult, clutResult)
    }

    /// Create a preset for testing
    private func createPresetForFilter(filterID: String, clutURL: URL) -> FilterPreset {
        FilterPreset(
            name: filterID,
            category: .film,
            source: .haldCLUT(manufacturer: "Test", filmStock: filterID),
            parameters: .identity,
            metadata: FilterPreset.FilterMetadata(filmStock: filterID),
            clutPath: clutURL.path,
            clutIntensity: 100
        )
    }

    /// Generate JSON report
    private func generateReport(results: [String: CalibrationResult], errors: [String: String]) throws {
        var reportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "testImage": testImageURL.lastPathComponent,
            "totalFilters": filterToCLUTMapping.count,
            "passed": results.values.filter { $0.pass }.count,
            "failed": results.values.filter { !$0.pass }.count,
            "errors": errors.count
        ]

        var filterResults: [[String: Any]] = []
        for (filterID, result) in results.sorted(by: { $0.key < $1.key }) {
            filterResults.append([
                "filterID": filterID,
                "pass": result.pass,
                "mae": result.mae,
                "mse": result.mse,
                "psnr": result.psnr,
                "meanDelta": [
                    "r": result.meanDeltaR,
                    "g": result.meanDeltaG,
                    "b": result.meanDeltaB
                ],
                "suggestedCorrections": [
                    "temperature": result.suggestedTemperature,
                    "tint": result.suggestedTint,
                    "exposure": result.suggestedExposure
                ]
            ])
        }
        reportData["results"] = filterResults

        var errorList: [[String: String]] = []
        for (filterID, message) in errors.sorted(by: { $0.key < $1.key }) {
            errorList.append(["filterID": filterID, "error": message])
        }
        reportData["errors"] = errorList

        let jsonData = try JSONSerialization.data(withJSONObject: reportData, options: [.prettyPrinted, .sortedKeys])
        let reportURL = outputBaseURL.appendingPathComponent("reports/calibration_report.json")
        try jsonData.write(to: reportURL)
    }

    // MARK: - Individual Filter Tests

    /// Test Kodak Portra 400 specifically
    func testKodakPortra400() async throws {
        let filterID = "kodak_portra_400"
        guard let clutPath = filterToCLUTMapping[filterID] else {
            throw XCTSkip("No CLUT mapping for \(filterID)")
        }

        let clutURL = clutBaseURL.appendingPathComponent(clutPath)
        guard FileManager.default.fileExists(atPath: clutURL.path) else {
            throw XCTSkip("CLUT file not found")
        }

        let result = try await calibrateSingleFilter(filterID: filterID, clutURL: clutURL)

        print("Kodak Portra 400 Calibration:")
        print("  MAE: \(result.mae)")
        print("  PSNR: \(result.psnr) dB")
        print("  Suggested corrections:")
        print("    Temperature: \(result.suggestedTemperature)")
        print("    Tint: \(result.suggestedTint)")
        print("    Exposure: \(result.suggestedExposure)")

        // Assert reasonable values
        XCTAssertLessThan(result.mae, 20, "MAE should be reasonable")
    }

    /// Test Fuji Velvia 50 specifically
    func testFujiVelvia50() async throws {
        let filterID = "fuji_velvia_50"
        guard let clutPath = filterToCLUTMapping[filterID] else {
            throw XCTSkip("No CLUT mapping for \(filterID)")
        }

        let clutURL = clutBaseURL.appendingPathComponent(clutPath)
        guard FileManager.default.fileExists(atPath: clutURL.path) else {
            throw XCTSkip("CLUT file not found")
        }

        let result = try await calibrateSingleFilter(filterID: filterID, clutURL: clutURL)

        print("Fuji Velvia 50 Calibration:")
        print("  MAE: \(result.mae)")
        print("  PSNR: \(result.psnr) dB")

        XCTAssertLessThan(result.mae, 20, "MAE should be reasonable")
    }

    /// Test Ilford HP5 400 specifically
    func testIlfordHP5() async throws {
        let filterID = "ilford_hp5_400"
        guard let clutPath = filterToCLUTMapping[filterID] else {
            throw XCTSkip("No CLUT mapping for \(filterID)")
        }

        let clutURL = clutBaseURL.appendingPathComponent(clutPath)
        guard FileManager.default.fileExists(atPath: clutURL.path) else {
            throw XCTSkip("CLUT file not found")
        }

        let result = try await calibrateSingleFilter(filterID: filterID, clutURL: clutURL)

        print("Ilford HP5 400 Calibration:")
        print("  MAE: \(result.mae)")
        print("  PSNR: \(result.psnr) dB")

        XCTAssertLessThan(result.mae, 20, "MAE should be reasonable")
    }
}

// MARK: - Supporting Types

struct CalibrationResult {
    let mae: Float          // Mean Absolute Error
    let mse: Float          // Mean Squared Error
    let psnr: Float         // Peak Signal-to-Noise Ratio
    let meanDeltaR: Float   // Average R channel difference
    let meanDeltaG: Float   // Average G channel difference
    let meanDeltaB: Float   // Average B channel difference
    let suggestedTemperature: Float
    let suggestedTint: Float
    let suggestedExposure: Float
    let pass: Bool          // MAE < threshold
}

enum CalibrationError: Error {
    case saveFailed
    case filterFailed
    case renderFailed
    case clutNotFound
}
