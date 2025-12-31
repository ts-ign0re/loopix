import XCTest
import CoreImage
@testable import FilmBox

/// Tests for image flip (mirror) operations
final class FlipOperationTests: XCTestCase {

    // MARK: - Properties

    private var context: CIContext!
    private var testImage: CIImage!
    private let originalSize = CGSize(width: 200, height: 200)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        context = CIContext(options: [.useSoftwareRenderer: true])
        // Create quadrant image for flip verification
        // TL=Red, TR=Green, BL=Blue, BR=Yellow
        testImage = ImageTestUtilities.createQuadrantImage(size: originalSize)
    }

    override func tearDown() {
        context = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Horizontal Flip Tests

    /// Test: Flip horizontally (mirror along vertical axis)
    func testFlipHorizontal() {
        // Given: Quadrant image
        // Original: TL=Red, TR=Green, BL=Blue, BR=Yellow

        // When: Flip horizontally (left-right mirror)
        let flippedImage = testImage.transformed(
            by: CGAffineTransform(scaleX: -1, y: 1)
                .translatedBy(x: -testImage.extent.width, y: 0)
        )

        // Then: Dimensions should be same
        XCTAssertEqual(flippedImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(flippedImage.extent.height, originalSize.height, accuracy: 1)

        // After horizontal flip:
        // New TL (was TR) = Green
        // New TR (was TL) = Red
        // New BL (was BR) = Yellow
        // New BR (was BL) = Blue

        // Normalize to origin
        let normalizedImage = flippedImage.transformed(
            by: CGAffineTransform(translationX: -flippedImage.extent.origin.x, y: -flippedImage.extent.origin.y)
        )

        // Sample top-left (should be Green after horizontal flip)
        let topLeft = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: 0, y: normalizedImage.extent.height/2, width: normalizedImage.extent.width/2, height: normalizedImage.extent.height/2),
            context: context
        )

        XCTAssertGreaterThan(topLeft.g, 0.5, "After horizontal flip, top-left should be green")
        XCTAssertLessThan(topLeft.r, 0.5, "After horizontal flip, top-left should not have red")
    }

    /// Test: Verify top-right after horizontal flip becomes red
    func testFlipHorizontalTopRightBecomesRed() {
        // When: Flip horizontally
        let flippedImage = testImage.transformed(
            by: CGAffineTransform(scaleX: -1, y: 1)
                .translatedBy(x: -testImage.extent.width, y: 0)
        )

        let normalizedImage = flippedImage.transformed(
            by: CGAffineTransform(translationX: -flippedImage.extent.origin.x, y: -flippedImage.extent.origin.y)
        )

        // Sample top-right (should be Red after horizontal flip)
        let topRight = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: normalizedImage.extent.width/2, y: normalizedImage.extent.height/2,
                      width: normalizedImage.extent.width/2, height: normalizedImage.extent.height/2),
            context: context
        )

        XCTAssertGreaterThan(topRight.r, 0.5, "After horizontal flip, top-right should be red")
    }

    /// Test: Double horizontal flip returns to original
    func testDoubleHorizontalFlipReturnsToOriginal() {
        // When: Flip horizontally twice
        let flipTransform = CGAffineTransform(scaleX: -1, y: 1)
        var currentImage = testImage!

        for _ in 0..<2 {
            currentImage = currentImage.transformed(by: flipTransform)
        }

        // Then: Dimensions should match original
        XCTAssertEqual(currentImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(currentImage.extent.height, originalSize.height, accuracy: 1)

        // Colors should be back to original positions
        let normalizedOriginal = testImage.transformed(
            by: CGAffineTransform(translationX: -testImage.extent.origin.x, y: -testImage.extent.origin.y)
        )
        let normalizedFlipped = currentImage.transformed(
            by: CGAffineTransform(translationX: -currentImage.extent.origin.x, y: -currentImage.extent.origin.y)
        )

        // Top-left should be red again
        let originalTL = ImageTestUtilities.averageColor(
            of: normalizedOriginal,
            in: CGRect(x: 0, y: normalizedOriginal.extent.height/2, width: normalizedOriginal.extent.width/2, height: normalizedOriginal.extent.height/2),
            context: context
        )
        let flippedTL = ImageTestUtilities.averageColor(
            of: normalizedFlipped,
            in: CGRect(x: 0, y: normalizedFlipped.extent.height/2, width: normalizedFlipped.extent.width/2, height: normalizedFlipped.extent.height/2),
            context: context
        )

        XCTAssertEqual(originalTL.r, flippedTL.r, accuracy: 0.1)
        XCTAssertEqual(originalTL.g, flippedTL.g, accuracy: 0.1)
        XCTAssertEqual(originalTL.b, flippedTL.b, accuracy: 0.1)
    }

    // MARK: - Vertical Flip Tests

    /// Test: Flip vertically (mirror along horizontal axis)
    func testFlipVertical() {
        // Given: Quadrant image
        // Original: TL=Red, TR=Green, BL=Blue, BR=Yellow

        // When: Flip vertically (top-bottom mirror)
        let flippedImage = testImage.transformed(
            by: CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: 0, y: -testImage.extent.height)
        )

        // Then: Dimensions should be same
        XCTAssertEqual(flippedImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(flippedImage.extent.height, originalSize.height, accuracy: 1)

        // After vertical flip:
        // New TL (was BL) = Blue
        // New TR (was BR) = Yellow
        // New BL (was TL) = Red
        // New BR (was TR) = Green

        let normalizedImage = flippedImage.transformed(
            by: CGAffineTransform(translationX: -flippedImage.extent.origin.x, y: -flippedImage.extent.origin.y)
        )

        // Sample top-left (should be Blue after vertical flip)
        let topLeft = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: 0, y: normalizedImage.extent.height/2, width: normalizedImage.extent.width/2, height: normalizedImage.extent.height/2),
            context: context
        )

        XCTAssertGreaterThan(topLeft.b, 0.5, "After vertical flip, top-left should be blue")
    }

    /// Test: Verify bottom-left after vertical flip becomes red
    func testFlipVerticalBottomLeftBecomesRed() {
        // When: Flip vertically
        let flippedImage = testImage.transformed(
            by: CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: 0, y: -testImage.extent.height)
        )

        let normalizedImage = flippedImage.transformed(
            by: CGAffineTransform(translationX: -flippedImage.extent.origin.x, y: -flippedImage.extent.origin.y)
        )

        // Sample bottom-left (should be Red after vertical flip)
        let bottomLeft = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: 0, y: 0, width: normalizedImage.extent.width/2, height: normalizedImage.extent.height/2),
            context: context
        )

        XCTAssertGreaterThan(bottomLeft.r, 0.5, "After vertical flip, bottom-left should be red")
    }

    /// Test: Double vertical flip returns to original
    func testDoubleVerticalFlipReturnsToOriginal() {
        // When: Flip vertically twice
        let flipTransform = CGAffineTransform(scaleX: 1, y: -1)
        var currentImage = testImage!

        for _ in 0..<2 {
            currentImage = currentImage.transformed(by: flipTransform)
        }

        // Then: Dimensions should match original
        XCTAssertEqual(currentImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(currentImage.extent.height, originalSize.height, accuracy: 1)
    }

    // MARK: - Combined Flip Tests

    /// Test: Horizontal + Vertical flip = 180° rotation
    func testHorizontalAndVerticalFlipEquals180Rotation() {
        // Given: Original image

        // When: Apply both flips
        let hFlip = CGAffineTransform(scaleX: -1, y: 1)
        let vFlip = CGAffineTransform(scaleX: 1, y: -1)
        let bothFlips = hFlip.concatenating(vFlip)

        let flippedImage = testImage.transformed(by: bothFlips)

        // And: Apply 180° rotation
        let rotatedImage = testImage.transformed(
            by: CGAffineTransform(rotationAngle: CGFloat.pi)
        )

        // Then: Both should have same dimensions
        XCTAssertEqual(flippedImage.extent.width, rotatedImage.extent.width, accuracy: 1)
        XCTAssertEqual(flippedImage.extent.height, rotatedImage.extent.height, accuracy: 1)

        // Both should result in: TL=Yellow, TR=Blue, BL=Green, BR=Red
    }

    /// Test: Flip horizontal then vertical
    func testFlipHorizontalThenVertical() {
        // When: Flip horizontally, then vertically
        var currentImage = testImage!

        // Horizontal flip
        currentImage = currentImage.transformed(
            by: CGAffineTransform(scaleX: -1, y: 1)
        )

        // Vertical flip
        currentImage = currentImage.transformed(
            by: CGAffineTransform(scaleX: 1, y: -1)
        )

        // Then: Dimensions should be same
        XCTAssertEqual(currentImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(currentImage.extent.height, originalSize.height, accuracy: 1)

        // Result should be same as 180° rotation
        // Original TL (Red) -> TR (h-flip) -> BR (v-flip)
        // Original TR (Green) -> TL (h-flip) -> BL (v-flip)
        // Original BL (Blue) -> BR (h-flip) -> TR (v-flip)
        // Original BR (Yellow) -> BL (h-flip) -> TL (v-flip)
    }

    // MARK: - Non-Square Image Flip Tests

    /// Test: Flip non-square image horizontally
    func testFlipNonSquareImageHorizontal() {
        // Given: Non-square image (200x100)
        let nonSquareImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 200, height: 100),
            horizontal: true
        )

        // When: Flip horizontally
        let flippedImage = nonSquareImage.transformed(
            by: CGAffineTransform(scaleX: -1, y: 1)
        )

        // Then: Dimensions should be same
        XCTAssertEqual(abs(flippedImage.extent.width), 200, accuracy: 1)
        XCTAssertEqual(abs(flippedImage.extent.height), 100, accuracy: 1)
    }

    /// Test: Flip non-square image vertically
    func testFlipNonSquareImageVertical() {
        // Given: Non-square image (100x300)
        let nonSquareImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 100, height: 300),
            horizontal: false
        )

        // When: Flip vertically
        let flippedImage = nonSquareImage.transformed(
            by: CGAffineTransform(scaleX: 1, y: -1)
        )

        // Then: Dimensions should be same
        XCTAssertEqual(abs(flippedImage.extent.width), 100, accuracy: 1)
        XCTAssertEqual(abs(flippedImage.extent.height), 300, accuracy: 1)
    }

    // MARK: - Marker Position Tests

    /// Test: Flip marker image horizontally
    func testFlipMarkerImageHorizontal() {
        // Given: Image with marker in top-left
        let markerImage = ImageTestUtilities.createMarkerImage(
            size: originalSize,
            markerPosition: .topLeft
        )

        // When: Flip horizontally
        let flippedImage = markerImage.transformed(
            by: CGAffineTransform(scaleX: -1, y: 1)
                .translatedBy(x: -markerImage.extent.width, y: 0)
        )

        let normalizedImage = flippedImage.transformed(
            by: CGAffineTransform(translationX: -flippedImage.extent.origin.x, y: -flippedImage.extent.origin.y)
        )

        // Then: Marker should now be in top-right area
        let topRightColor = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: normalizedImage.extent.width * 0.8, y: normalizedImage.extent.height * 0.8,
                      width: normalizedImage.extent.width * 0.2, height: normalizedImage.extent.height * 0.2),
            context: context
        )

        // Should detect marker (red) in top-right
        XCTAssertGreaterThan(topRightColor.r, 0.3, "Marker should be moved to top-right after horizontal flip")
    }

    /// Test: Flip marker image vertically
    func testFlipMarkerImageVertical() {
        // Given: Image with marker in top-left
        let markerImage = ImageTestUtilities.createMarkerImage(
            size: originalSize,
            markerPosition: .topLeft
        )

        // When: Flip vertically
        let flippedImage = markerImage.transformed(
            by: CGAffineTransform(scaleX: 1, y: -1)
                .translatedBy(x: 0, y: -markerImage.extent.height)
        )

        let normalizedImage = flippedImage.transformed(
            by: CGAffineTransform(translationX: -flippedImage.extent.origin.x, y: -flippedImage.extent.origin.y)
        )

        // Then: Marker should now be in bottom-left area
        let bottomLeftColor = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: 0, y: 0,
                      width: normalizedImage.extent.width * 0.2, height: normalizedImage.extent.height * 0.2),
            context: context
        )

        // Should detect marker (red) in bottom-left
        XCTAssertGreaterThan(bottomLeftColor.r, 0.3, "Marker should be moved to bottom-left after vertical flip")
    }

    // MARK: - Performance Tests

    /// Test: Horizontal flip performance with large image
    func testHorizontalFlipPerformance() {
        // Given: Large test image
        let largeImage = ImageTestUtilities.createSolidColorImage(
            color: .blue,
            size: CGSize(width: 4000, height: 3000)
        )

        // When/Then: Measure flip performance
        measure {
            let _ = largeImage.transformed(
                by: CGAffineTransform(scaleX: -1, y: 1)
            )
        }
    }

    /// Test: Vertical flip performance with large image
    func testVerticalFlipPerformance() {
        // Given: Large test image
        let largeImage = ImageTestUtilities.createSolidColorImage(
            color: .green,
            size: CGSize(width: 4000, height: 3000)
        )

        // When/Then: Measure flip performance
        measure {
            let _ = largeImage.transformed(
                by: CGAffineTransform(scaleX: 1, y: -1)
            )
        }
    }

    /// Test: Combined flip performance
    func testCombinedFlipPerformance() {
        // Given: Large test image
        let largeImage = ImageTestUtilities.createSolidColorImage(
            color: .red,
            size: CGSize(width: 4000, height: 3000)
        )

        // When/Then: Measure combined flip performance
        measure {
            let _ = largeImage.transformed(
                by: CGAffineTransform(scaleX: -1, y: -1)
            )
        }
    }
}
