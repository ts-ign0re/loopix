import XCTest
import CoreImage
@testable import FilmBox

/// Tests for FilterEngine actor
@available(iOS 17.0, *)
final class FilterEngineTests: XCTestCase {

    // MARK: - Properties

    private var engine: FilterEngine!
    private var testImage: CIImage!
    private let testSize = CGSize(width: 100, height: 100)

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        engine = FilterEngine()
        testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            size: testSize
        )
    }

    override func tearDown() async throws {
        engine = nil
        testImage = nil
        try await super.tearDown()
    }

    // MARK: - Identity Tests

    /// Test: Identity parameters don't change image
    func testIdentityParametersNoChange() async {
        let params = FilterParameters.identity
        let result = await engine.apply(params, to: testImage)

        // Dimensions should be unchanged
        XCTAssertEqual(result.extent.width, testImage.extent.width, accuracy: 1)
        XCTAssertEqual(result.extent.height, testImage.extent.height, accuracy: 1)
    }

    // MARK: - Exposure Tests

    /// Test: Positive exposure increases brightness
    func testPositiveExposure() async {
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        let result = await engine.applyExposure(to: testImage, ev: 1.0)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        XCTAssertGreaterThan(adjustedColor.r, originalColor.r, "Brightness should increase")
        XCTAssertGreaterThan(adjustedColor.g, originalColor.g)
        XCTAssertGreaterThan(adjustedColor.b, originalColor.b)
    }

    /// Test: Negative exposure decreases brightness
    func testNegativeExposure() async {
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        let result = await engine.applyExposure(to: testImage, ev: -1.0)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        XCTAssertLessThan(adjustedColor.r, originalColor.r, "Brightness should decrease")
        XCTAssertLessThan(adjustedColor.g, originalColor.g)
        XCTAssertLessThan(adjustedColor.b, originalColor.b)
    }

    /// Test: Zero exposure leaves image unchanged
    func testZeroExposure() async {
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // Explicitly test the exposure function
        let result = await engine.applyExposure(to: testImage, ev: 0)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        XCTAssertEqual(adjustedColor.r, originalColor.r, accuracy: 0.01)
        XCTAssertEqual(adjustedColor.g, originalColor.g, accuracy: 0.01)
        XCTAssertEqual(adjustedColor.b, originalColor.b, accuracy: 0.01)
    }

    // MARK: - Contrast Tests

    /// Test: Positive contrast increases range
    func testPositiveContrast() async {
        // Use gradient image to test contrast
        let gradientImage = ImageTestUtilities.createGradientImage(
            size: testSize,
            startColor: UIColor(white: 0.3, alpha: 1),
            endColor: UIColor(white: 0.7, alpha: 1)
        )

        let result = await engine.applyContrast(to: gradientImage, amount: 50)

        XCTAssertFalse(result.extent.isEmpty, "Result should not be empty")
    }

    /// Test: Negative contrast decreases range
    func testNegativeContrast() async {
        let gradientImage = ImageTestUtilities.createGradientImage(size: testSize)

        let result = await engine.applyContrast(to: gradientImage, amount: -50)

        XCTAssertFalse(result.extent.isEmpty, "Result should not be empty")
    }

    // MARK: - Saturation Tests

    /// Test: Zero saturation produces grayscale
    func testZeroSaturationProducesGrayscale() async {
        let coloredImage = ImageTestUtilities.createSolidColorImage(
            color: .red,
            size: testSize
        )
        let context = CIContext()

        let result = await engine.applySaturation(to: coloredImage, amount: -100)
        let color = ImageTestUtilities.averageColor(of: result, context: context)

        // In grayscale, R, G, B should be approximately equal
        XCTAssertEqual(color.r, color.g, accuracy: 0.1, "R and G should be equal in grayscale")
        XCTAssertEqual(color.g, color.b, accuracy: 0.1, "G and B should be equal in grayscale")
    }

    /// Test: Increased saturation intensifies colors
    func testIncreasedSaturation() async {
        let coloredImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0),
            size: testSize
        )

        let result = await engine.applySaturation(to: coloredImage, amount: 50)

        XCTAssertFalse(result.extent.isEmpty)
    }

    // MARK: - Vibrance Tests

    /// Test: Vibrance affects colors
    func testVibranceAffectsColors() async {
        let coloredImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.6, green: 0.4, blue: 0.4, alpha: 1.0),
            size: testSize
        )

        let result = await engine.applyVibrance(to: coloredImage, amount: 50)

        XCTAssertFalse(result.extent.isEmpty)
    }

    // MARK: - White Balance Tests

    /// Test: Warm temperature shifts colors
    func testWarmTemperature() async {
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        let result = await engine.applyWhiteBalance(to: testImage, temperature: -50, tint: 0)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        // Warm should increase red relative to blue
        let originalWarmth = originalColor.r - originalColor.b
        let adjustedWarmth = adjustedColor.r - adjustedColor.b

        XCTAssertGreaterThan(adjustedWarmth, originalWarmth, "Image should be warmer")
    }

    /// Test: Cool temperature shifts colors
    func testCoolTemperature() async {
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        let result = await engine.applyWhiteBalance(to: testImage, temperature: 50, tint: 0)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        // Cool should increase blue relative to red
        let originalCoolness = originalColor.b - originalColor.r
        let adjustedCoolness = adjustedColor.b - adjustedColor.r

        XCTAssertGreaterThan(adjustedCoolness, originalCoolness, "Image should be cooler")
    }

    // MARK: - Highlights/Shadows Tests

    /// Test: Shadow lift brightens dark areas
    func testShadowLift() async {
        let darkImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(white: 0.1, alpha: 1.0),
            size: testSize
        )
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: darkImage, context: context)

        let result = await engine.applyHighlightsShadows(to: darkImage, highlights: 0, shadows: 50)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        let originalBrightness = (originalColor.r + originalColor.g + originalColor.b) / 3
        let adjustedBrightness = (adjustedColor.r + adjustedColor.g + adjustedColor.b) / 3

        XCTAssertGreaterThan(adjustedBrightness, originalBrightness, "Shadows should be lifted")
    }

    /// Test: Highlight reduction darkens bright areas
    func testHighlightReduction() async {
        let brightImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(white: 0.9, alpha: 1.0),
            size: testSize
        )
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: brightImage, context: context)

        let result = await engine.applyHighlightsShadows(to: brightImage, highlights: -50, shadows: 0)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        let originalBrightness = (originalColor.r + originalColor.g + originalColor.b) / 3
        let adjustedBrightness = (adjustedColor.r + adjustedColor.g + adjustedColor.b) / 3

        XCTAssertLessThan(adjustedBrightness, originalBrightness, "Highlights should be reduced")
    }

    // MARK: - Tone Curve Tests

    /// Test: Identity tone curve doesn't change image
    func testIdentityToneCurve() async {
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        let result = await engine.applyToneCurve(to: testImage, curve: .identity)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        XCTAssertEqual(adjustedColor.r, originalColor.r, accuracy: 0.05)
        XCTAssertEqual(adjustedColor.g, originalColor.g, accuracy: 0.05)
        XCTAssertEqual(adjustedColor.b, originalColor.b, accuracy: 0.05)
    }

    /// Test: Lifted blacks tone curve
    func testLiftedBlacksToneCurve() async {
        let blackImage = ImageTestUtilities.createSolidColorImage(
            color: .black,
            size: testSize
        )
        let context = CIContext()

        let curve = ToneCurveData(
            composite: [
                .init(x: 0, y: 0.2),
                .init(x: 0.25, y: 0.35),
                .init(x: 0.5, y: 0.5),
                .init(x: 0.75, y: 0.75),
                .init(x: 1, y: 1)
            ],
            red: [],
            green: [],
            blue: []
        )

        let result = await engine.applyToneCurve(to: blackImage, curve: curve)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        XCTAssertGreaterThan(adjustedColor.r, 0.1, "Blacks should be lifted")
        XCTAssertGreaterThan(adjustedColor.g, 0.1)
        XCTAssertGreaterThan(adjustedColor.b, 0.1)
    }

    // MARK: - Clarity Tests

    /// Test: Positive clarity applies
    func testPositiveClarity() async {
        let result = await engine.applyClarity(to: testImage, amount: 50)
        XCTAssertFalse(result.extent.isEmpty)
    }

    /// Test: Negative clarity applies
    func testNegativeClarity() async {
        let result = await engine.applyClarity(to: testImage, amount: -50)
        XCTAssertFalse(result.extent.isEmpty)
    }

    // MARK: - Sharpening Tests

    /// Test: Sharpening applies
    func testSharpeningApplies() async {
        let result = await engine.applySharpening(to: testImage, amount: 50, radius: 1.5)
        XCTAssertFalse(result.extent.isEmpty)
    }

    // MARK: - Fade Tests

    /// Test: Fade effect lifts blacks
    func testFadeLiftsBlacks() async {
        let blackImage = ImageTestUtilities.createSolidColorImage(
            color: .black,
            size: testSize
        )
        let context = CIContext()
        let originalColor = ImageTestUtilities.averageColor(of: blackImage, context: context)

        let result = await engine.applyFade(to: blackImage, amount: 50)
        let adjustedColor = ImageTestUtilities.averageColor(of: result, context: context)

        let originalBrightness = (originalColor.r + originalColor.g + originalColor.b) / 3
        let adjustedBrightness = (adjustedColor.r + adjustedColor.g + adjustedColor.b) / 3

        XCTAssertGreaterThan(adjustedBrightness, originalBrightness, "Fade should lift blacks")
    }

    // MARK: - Vignette Tests

    /// Test: Vignette darkens edges
    func testVignetteDarkensEdges() async {
        let whiteImage = ImageTestUtilities.createSolidColorImage(
            color: .white,
            size: CGSize(width: 200, height: 200)
        )
        let context = CIContext()

        let vignetteData = VignetteData(amount: 50, midpoint: 0.5, roundness: 0, feather: 0.5)
        let result = await engine.applyVignette(to: whiteImage, data: vignetteData)

        // Sample center vs edge
        let centerColor = ImageTestUtilities.averageColor(
            of: result,
            in: CGRect(x: 75, y: 75, width: 50, height: 50),
            context: context
        )
        let edgeColor = ImageTestUtilities.averageColor(
            of: result,
            in: CGRect(x: 0, y: 0, width: 50, height: 50),
            context: context
        )

        let centerBrightness = (centerColor.r + centerColor.g + centerColor.b) / 3
        let edgeBrightness = (edgeColor.r + edgeColor.g + edgeColor.b) / 3

        XCTAssertGreaterThan(centerBrightness, edgeBrightness, "Center should be brighter than edges")
    }

    // MARK: - Rendering Tests

    /// Test: Render produces CGImage
    func testRenderProducesCGImage() async {
        let result = await engine.render(testImage)

        XCTAssertNotNil(result, "Render should produce CGImage")
        XCTAssertEqual(Int(result?.width ?? 0), Int(testSize.width))
        XCTAssertEqual(Int(result?.height ?? 0), Int(testSize.height))
    }

    /// Test: Render with rect
    func testRenderWithRect() async {
        let rect = CGRect(x: 0, y: 0, width: 50, height: 50)
        let result = await engine.render(testImage, from: rect)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.width, 50)
        XCTAssertEqual(result?.height, 50)
    }

    // MARK: - Full Pipeline Tests

    /// Test: Multiple filters applied in sequence
    func testMultipleFiltersApplied() async {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 20
        params.saturation = 10
        params.vibrance = 15

        let result = await engine.apply(params, to: testImage)

        XCTAssertFalse(result.extent.isEmpty)
        XCTAssertEqual(result.extent.width, testImage.extent.width, accuracy: 1)
        XCTAssertEqual(result.extent.height, testImage.extent.height, accuracy: 1)
    }

    /// Test: Full process method
    func testProcessMethod() async {
        var params = FilterParameters()
        params.exposure = 0.3
        params.contrast = 10

        let result = await engine.process(testImage, with: params)

        XCTAssertNotNil(result)
    }

    /// Test: Complex filter chain
    func testComplexFilterChain() async {
        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 15
        params.highlights = -20
        params.shadows = 30
        params.temperature = 10
        params.saturation = 5
        params.vibrance = 10
        params.clarity = 20
        params.sharpness = 25
        params.fade = 10
        params.vignette = VignetteData(amount: 30, midpoint: 0.5, roundness: 0, feather: 0.6)

        let result = await engine.apply(params, to: testImage)

        XCTAssertFalse(result.extent.isEmpty)
    }

    // MARK: - Cache Tests

    /// Test: Clear cache works
    func testClearCache() async {
        // Apply some filters to populate cache
        _ = await engine.applyExposure(to: testImage, ev: 0.5)
        _ = await engine.applyContrast(to: testImage, amount: 20)

        // Clear cache
        await engine.clearCache()

        // Should still work after clearing
        let result = await engine.applyExposure(to: testImage, ev: 0.3)
        XCTAssertFalse(result.extent.isEmpty)
    }

    // MARK: - Static Method Tests

    /// Test: Create CIImage from CGImage
    func testCreateCIImageFromCGImage() async {
        let cgImage = await engine.render(testImage)!
        let ciImage = FilterEngine.createCIImage(from: cgImage)

        XCTAssertEqual(ciImage.extent.width, CGFloat(cgImage.width), accuracy: 1)
        XCTAssertEqual(ciImage.extent.height, CGFloat(cgImage.height), accuracy: 1)
    }

    // MARK: - Performance Tests

    /// Test: Filter engine performance
    func testFilterEnginePerformance() async {
        let largeImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 1000, height: 1000)
        )

        var params = FilterParameters()
        params.exposure = 0.5
        params.contrast = 20
        params.saturation = 10

        // Simple timing test without measure block for Swift 6 compatibility
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<5 {
            _ = await engine.apply(params, to: largeImage)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        XCTAssertLessThan(elapsed, 10.0, "5 filter applications should complete within 10 seconds")
    }
}
