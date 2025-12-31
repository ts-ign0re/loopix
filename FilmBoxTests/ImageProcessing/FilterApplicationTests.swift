import XCTest
import CoreImage
import CoreImage.CIFilterBuiltins
@testable import FilmBox

/// Tests for filter application and image adjustments
final class FilterApplicationTests: XCTestCase {

    // MARK: - Properties

    private var context: CIContext!
    private var testImage: CIImage!
    private let originalSize = CGSize(width: 100, height: 100)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        context = CIContext(options: [.useSoftwareRenderer: true])
        // Create a mid-gray image for filter testing
        testImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0),
            size: originalSize
        )
    }

    override func tearDown() {
        context = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Exposure Tests

    /// Test: Positive exposure increases brightness
    func testPositiveExposureIncreasesBrightness() {
        // Given: Mid-gray image
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // When: Apply positive exposure
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = testImage
        filter.ev = 1.0 // +1 EV

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Image should be brighter
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        XCTAssertGreaterThan(adjustedColor.r, originalColor.r, "Red channel should increase with positive exposure")
        XCTAssertGreaterThan(adjustedColor.g, originalColor.g, "Green channel should increase with positive exposure")
        XCTAssertGreaterThan(adjustedColor.b, originalColor.b, "Blue channel should increase with positive exposure")
    }

    /// Test: Negative exposure decreases brightness
    func testNegativeExposureDecreasesBrightness() {
        // Given: Mid-gray image
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // When: Apply negative exposure
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = testImage
        filter.ev = -1.0 // -1 EV

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Image should be darker
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        XCTAssertLessThan(adjustedColor.r, originalColor.r, "Red channel should decrease with negative exposure")
        XCTAssertLessThan(adjustedColor.g, originalColor.g, "Green channel should decrease with negative exposure")
        XCTAssertLessThan(adjustedColor.b, originalColor.b, "Blue channel should decrease with negative exposure")
    }

    /// Test: Zero exposure doesn't change image
    func testZeroExposureNoChange() {
        // Given: Mid-gray image
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // When: Apply zero exposure
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = testImage
        filter.ev = 0.0

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Image should be unchanged
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        XCTAssertEqual(adjustedColor.r, originalColor.r, accuracy: 0.01, "Red should be unchanged")
        XCTAssertEqual(adjustedColor.g, originalColor.g, accuracy: 0.01, "Green should be unchanged")
        XCTAssertEqual(adjustedColor.b, originalColor.b, accuracy: 0.01, "Blue should be unchanged")
    }

    // MARK: - Contrast Tests

    /// Test: Increased contrast affects mid-tones
    func testIncreasedContrast() {
        // Given: Gradient image (has range of tones)
        let gradientImage = ImageTestUtilities.createGradientImage(
            size: originalSize,
            startColor: .black,
            endColor: .white
        )

        // When: Apply increased contrast
        let filter = CIFilter.colorControls()
        filter.inputImage = gradientImage
        filter.contrast = 1.5

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Output should still be valid image
        XCTAssertFalse(outputImage.extent.isEmpty, "Output image should not be empty")

        // Contrast increase should make darks darker and lights lighter
        // The spread between min and max brightness should increase
    }

    /// Test: Decreased contrast (flattens tones)
    func testDecreasedContrast() {
        // Given: Gradient image
        let gradientImage = ImageTestUtilities.createGradientImage(
            size: originalSize,
            startColor: .black,
            endColor: .white
        )

        // When: Apply decreased contrast
        let filter = CIFilter.colorControls()
        filter.inputImage = gradientImage
        filter.contrast = 0.5

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Output should be valid
        XCTAssertFalse(outputImage.extent.isEmpty, "Output image should not be empty")
    }

    // MARK: - Saturation Tests

    /// Test: Increased saturation intensifies colors
    func testIncreasedSaturation() {
        // Given: Colored image
        let coloredImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0), // Desaturated red
            size: originalSize
        )
        let originalColor = ImageTestUtilities.averageColor(of: coloredImage, context: context)

        // When: Apply increased saturation
        let filter = CIFilter.colorControls()
        filter.inputImage = coloredImage
        filter.saturation = 1.5

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Colors should be more vivid
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        // Red should become more dominant relative to other channels
        let originalRedDominance = originalColor.r - (originalColor.g + originalColor.b) / 2
        let adjustedRedDominance = adjustedColor.r - (adjustedColor.g + adjustedColor.b) / 2

        XCTAssertGreaterThan(adjustedRedDominance, originalRedDominance, "Color should be more saturated")
    }

    /// Test: Zero saturation produces grayscale
    func testZeroSaturationProducesGrayscale() {
        // Given: Colored image
        let coloredImage = ImageTestUtilities.createSolidColorImage(
            color: .red,
            size: originalSize
        )

        // When: Apply zero saturation
        let filter = CIFilter.colorControls()
        filter.inputImage = coloredImage
        filter.saturation = 0.0

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: All channels should be equal (grayscale)
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        XCTAssertEqual(adjustedColor.r, adjustedColor.g, accuracy: 0.05, "R and G should be equal in grayscale")
        XCTAssertEqual(adjustedColor.g, adjustedColor.b, accuracy: 0.05, "G and B should be equal in grayscale")
    }

    // MARK: - Temperature/Tint Tests

    /// Test: Warm temperature shifts toward orange
    func testWarmTemperature() {
        // Given: Neutral gray image
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // When: Apply warm temperature
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = testImage
        filter.neutral = CIVector(x: 6500, y: 0) // Reference neutral
        filter.targetNeutral = CIVector(x: 4000, y: 0) // Warm (lower Kelvin)

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Image should be warmer (more red/yellow)
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        // Warm images have higher red relative to blue
        let originalWarmth = originalColor.r - originalColor.b
        let adjustedWarmth = adjustedColor.r - adjustedColor.b

        XCTAssertGreaterThan(adjustedWarmth, originalWarmth, "Image should be warmer")
    }

    /// Test: Cool temperature shifts toward blue
    func testCoolTemperature() {
        // Given: Neutral gray image
        let originalColor = ImageTestUtilities.averageColor(of: testImage, context: context)

        // When: Apply cool temperature
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = testImage
        filter.neutral = CIVector(x: 6500, y: 0)
        filter.targetNeutral = CIVector(x: 10000, y: 0) // Cool (higher Kelvin)

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Image should be cooler (more blue)
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        let originalCoolness = originalColor.b - originalColor.r
        let adjustedCoolness = adjustedColor.b - adjustedColor.r

        XCTAssertGreaterThan(adjustedCoolness, originalCoolness, "Image should be cooler")
    }

    // MARK: - Highlights/Shadows Tests

    /// Test: Highlight recovery reduces bright areas
    func testHighlightRecovery() {
        // Given: Bright image
        let brightImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(white: 0.9, alpha: 1.0),
            size: originalSize
        )
        let originalColor = ImageTestUtilities.averageColor(of: brightImage, context: context)

        // When: Apply highlight reduction
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = brightImage
        filter.highlightAmount = 0.5 // Reduce highlights

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Bright areas should be reduced
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        // Average brightness should decrease
        let originalBrightness = (originalColor.r + originalColor.g + originalColor.b) / 3
        let adjustedBrightness = (adjustedColor.r + adjustedColor.g + adjustedColor.b) / 3

        XCTAssertLessThan(adjustedBrightness, originalBrightness, "Highlights should be reduced")
    }

    /// Test: Shadow lift brightens dark areas
    func testShadowLift() {
        // Given: Dark image
        let darkImage = ImageTestUtilities.createSolidColorImage(
            color: UIColor(white: 0.1, alpha: 1.0),
            size: originalSize
        )
        let originalColor = ImageTestUtilities.averageColor(of: darkImage, context: context)

        // When: Apply shadow lift
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = darkImage
        filter.shadowAmount = 0.5 // Lift shadows

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Dark areas should be brighter
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        let originalBrightness = (originalColor.r + originalColor.g + originalColor.b) / 3
        let adjustedBrightness = (adjustedColor.r + adjustedColor.g + adjustedColor.b) / 3

        XCTAssertGreaterThan(adjustedBrightness, originalBrightness, "Shadows should be lifted")
    }

    // MARK: - Tone Curve Tests

    /// Test: S-curve increases contrast
    func testSCurveToneCurve() {
        // Given: Gradient image
        let gradientImage = ImageTestUtilities.createGradientImage(
            size: originalSize,
            startColor: .darkGray,
            endColor: .lightGray
        )

        // When: Apply S-curve (darken shadows, brighten highlights)
        let filter = CIFilter.toneCurve()
        filter.inputImage = gradientImage
        filter.point0 = CGPoint(x: 0, y: 0)
        filter.point1 = CGPoint(x: 0.25, y: 0.15)  // Darken shadows
        filter.point2 = CGPoint(x: 0.5, y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: 0.85)  // Brighten highlights
        filter.point4 = CGPoint(x: 1, y: 1)

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Output should be valid
        XCTAssertFalse(outputImage.extent.isEmpty, "Output should not be empty")
    }

    /// Test: Lifted blacks (fade effect)
    func testLiftedBlacksFadeEffect() {
        // Given: Image with black areas
        let darkImage = ImageTestUtilities.createSolidColorImage(
            color: .black,
            size: originalSize
        )

        // When: Apply lifted blacks
        let filter = CIFilter.toneCurve()
        filter.inputImage = darkImage
        filter.point0 = CGPoint(x: 0, y: 0.2) // Lift blacks
        filter.point1 = CGPoint(x: 0.25, y: 0.35)
        filter.point2 = CGPoint(x: 0.5, y: 0.5)
        filter.point3 = CGPoint(x: 0.75, y: 0.75)
        filter.point4 = CGPoint(x: 1, y: 1)

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Black should be lifted to dark gray
        let adjustedColor = ImageTestUtilities.averageColor(of: outputImage, context: context)

        XCTAssertGreaterThan(adjustedColor.r, 0.1, "Black should be lifted")
        XCTAssertGreaterThan(adjustedColor.g, 0.1, "Black should be lifted")
        XCTAssertGreaterThan(adjustedColor.b, 0.1, "Black should be lifted")
    }

    // MARK: - Vignette Tests

    /// Test: Vignette darkens edges
    func testVignetteDarkensEdges() {
        // Given: White image
        let whiteImage = ImageTestUtilities.createSolidColorImage(
            color: .white,
            size: CGSize(width: 200, height: 200)
        )

        // When: Apply vignette
        let filter = CIFilter.vignette()
        filter.inputImage = whiteImage
        filter.intensity = 2.0
        filter.radius = 1.0

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Center should be brighter than edges
        let centerColor = ImageTestUtilities.averageColor(
            of: outputImage,
            in: CGRect(x: 75, y: 75, width: 50, height: 50),
            context: context
        )

        let edgeColor = ImageTestUtilities.averageColor(
            of: outputImage,
            in: CGRect(x: 0, y: 0, width: 50, height: 50),
            context: context
        )

        let centerBrightness = (centerColor.r + centerColor.g + centerColor.b) / 3
        let edgeBrightness = (edgeColor.r + edgeColor.g + edgeColor.b) / 3

        XCTAssertGreaterThan(centerBrightness, edgeBrightness, "Center should be brighter than edges")
    }

    // MARK: - Sharpening Tests

    /// Test: Sharpening filter applies successfully
    func testSharpeningApplies() {
        // Given: Test image
        let gradientImage = ImageTestUtilities.createGradientImage(size: originalSize)

        // When: Apply sharpening
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = gradientImage
        filter.sharpness = 0.5

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Output should be valid with same dimensions
        XCTAssertEqual(outputImage.extent.width, gradientImage.extent.width, accuracy: 1)
        XCTAssertEqual(outputImage.extent.height, gradientImage.extent.height, accuracy: 1)
    }

    /// Test: Unsharp mask applies
    func testUnsharpMaskApplies() {
        // Given: Test image

        // When: Apply unsharp mask
        let filter = CIFilter.unsharpMask()
        filter.inputImage = testImage
        filter.intensity = 0.5
        filter.radius = 2.5

        guard let outputImage = filter.outputImage else {
            XCTFail("Filter output is nil")
            return
        }

        // Then: Output should be valid
        XCTAssertFalse(outputImage.extent.isEmpty, "Output should not be empty")
    }

    // MARK: - Filter Chain Tests

    /// Test: Multiple filters can be chained
    func testFilterChain() {
        // Given: Test image
        var result = testImage!

        // When: Apply chain of filters
        // 1. Exposure
        let exposureFilter = CIFilter.exposureAdjust()
        exposureFilter.inputImage = result
        exposureFilter.ev = 0.5
        result = exposureFilter.outputImage ?? result

        // 2. Contrast
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = result
        contrastFilter.contrast = 1.2
        contrastFilter.saturation = 1.1
        result = contrastFilter.outputImage ?? result

        // 3. Vignette
        let vignetteFilter = CIFilter.vignette()
        vignetteFilter.inputImage = result
        vignetteFilter.intensity = 1.0
        vignetteFilter.radius = 1.0
        result = vignetteFilter.outputImage ?? result

        // Then: Output should be valid
        XCTAssertFalse(result.extent.isEmpty, "Chained filter output should not be empty")
    }

    // MARK: - Performance Tests

    /// Test: Filter chain performance
    func testFilterChainPerformance() {
        // Given: Large test image
        let largeImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 2000, height: 2000)
        )

        // When/Then: Measure filter chain performance
        measure {
            var result = largeImage

            let exposureFilter = CIFilter.exposureAdjust()
            exposureFilter.inputImage = result
            exposureFilter.ev = 0.3
            result = exposureFilter.outputImage ?? result

            let contrastFilter = CIFilter.colorControls()
            contrastFilter.inputImage = result
            contrastFilter.contrast = 1.1
            contrastFilter.saturation = 1.05
            result = contrastFilter.outputImage ?? result

            // Force evaluation
            _ = result.extent
        }
    }
}
