import XCTest
import CoreImage
@testable import FilmBox

/// Tests for image crop operations
final class CropOperationTests: XCTestCase {

    // MARK: - Properties

    private var context: CIContext!
    private var testImage: CIImage!
    private let originalSize = CGSize(width: 200, height: 200)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        context = CIContext(options: [.useSoftwareRenderer: true])
        // Create quadrant image: TL=Red, TR=Green, BL=Blue, BR=Yellow
        testImage = ImageTestUtilities.createQuadrantImage(size: originalSize)
    }

    override func tearDown() {
        context = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Basic Crop Tests

    /// Test: Crop to center square
    func testCropToCenterSquare() {
        // Given: 200x200 image, crop to center 100x100
        let cropRect = CGRect(x: 50, y: 50, width: 100, height: 100)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Verify dimensions
        assertImageDimensions(croppedImage, width: 100, height: 100)

        // And: Should contain parts of all 4 quadrants
        // Center region should be mixed colors from all quadrants
    }

    /// Test: Crop to top-left quadrant (should be red)
    func testCropToTopLeftQuadrant() {
        // Given: Crop to top-left quarter
        let cropRect = CGRect(x: 0, y: 100, width: 100, height: 100) // CIImage has flipped Y

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Verify dimensions
        assertImageDimensions(croppedImage, width: 100, height: 100)

        // And: Should be entirely red
        let avgColor = ImageTestUtilities.averageColor(of: croppedImage, context: context)
        XCTAssertGreaterThan(avgColor.r, 0.8, "Red channel should be high")
        XCTAssertLessThan(avgColor.g, 0.2, "Green channel should be low")
        XCTAssertLessThan(avgColor.b, 0.2, "Blue channel should be low")
    }

    /// Test: Crop to top-right quadrant (should be green)
    func testCropToTopRightQuadrant() {
        // Given: Crop to top-right quarter
        let cropRect = CGRect(x: 100, y: 100, width: 100, height: 100)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Should be entirely green
        let avgColor = ImageTestUtilities.averageColor(of: croppedImage, context: context)
        XCTAssertLessThan(avgColor.r, 0.2, "Red channel should be low")
        XCTAssertGreaterThan(avgColor.g, 0.8, "Green channel should be high")
        XCTAssertLessThan(avgColor.b, 0.2, "Blue channel should be low")
    }

    /// Test: Crop to bottom-left quadrant (should be blue)
    func testCropToBottomLeftQuadrant() {
        // Given: Crop to bottom-left quarter
        let cropRect = CGRect(x: 0, y: 0, width: 100, height: 100)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Should be entirely blue
        let avgColor = ImageTestUtilities.averageColor(of: croppedImage, context: context)
        XCTAssertLessThan(avgColor.r, 0.2, "Red channel should be low")
        XCTAssertLessThan(avgColor.g, 0.2, "Green channel should be low")
        XCTAssertGreaterThan(avgColor.b, 0.8, "Blue channel should be high")
    }

    /// Test: Crop to bottom-right quadrant (should be yellow)
    func testCropToBottomRightQuadrant() {
        // Given: Crop to bottom-right quarter
        let cropRect = CGRect(x: 100, y: 0, width: 100, height: 100)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Should be yellow (R+G high, B low)
        let avgColor = ImageTestUtilities.averageColor(of: croppedImage, context: context)
        XCTAssertGreaterThan(avgColor.r, 0.8, "Red channel should be high")
        XCTAssertGreaterThan(avgColor.g, 0.8, "Green channel should be high")
        XCTAssertLessThan(avgColor.b, 0.2, "Blue channel should be low")
    }

    // MARK: - Aspect Ratio Crop Tests

    /// Test: Crop to 16:9 aspect ratio
    func testCropTo16x9AspectRatio() {
        // Given: 200x200 image
        // Target: 16:9 aspect ratio, maximum size that fits

        let targetAspect: CGFloat = 16.0 / 9.0
        let newWidth: CGFloat = 200
        let newHeight = newWidth / targetAspect
        let yOffset = (200 - newHeight) / 2

        let cropRect = CGRect(x: 0, y: yOffset, width: newWidth, height: newHeight)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Verify aspect ratio
        let actualAspect = croppedImage.extent.width / croppedImage.extent.height
        XCTAssertEqual(actualAspect, targetAspect, accuracy: 0.01, "Aspect ratio should be 16:9")
    }

    /// Test: Crop to 4:3 aspect ratio
    func testCropTo4x3AspectRatio() {
        let targetAspect: CGFloat = 4.0 / 3.0
        let newHeight: CGFloat = 200
        let newWidth = newHeight * targetAspect
        let xOffset = (200 - newWidth) / 2

        let cropRect = CGRect(x: max(0, xOffset), y: 0, width: min(newWidth, 200), height: newHeight)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Verify dimensions are valid
        XCTAssertGreaterThan(croppedImage.extent.width, 0)
        XCTAssertGreaterThan(croppedImage.extent.height, 0)
    }

    /// Test: Crop to 1:1 square aspect ratio
    func testCropTo1x1AspectRatio() {
        // Given: Already square image, crop to smaller square
        let cropRect = CGRect(x: 25, y: 25, width: 150, height: 150)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Should be square
        XCTAssertEqual(croppedImage.extent.width, croppedImage.extent.height, accuracy: 0.1)
        assertImageDimensions(croppedImage, width: 150, height: 150)
    }

    // MARK: - Edge Cases

    /// Test: Crop with rect larger than image (should clamp)
    func testCropWithOversizedRect() {
        // Given: Crop rect larger than image
        let cropRect = CGRect(x: -50, y: -50, width: 300, height: 300)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Result should be clamped to image bounds
        // The resulting image extent should be the intersection
        XCTAssertLessThanOrEqual(croppedImage.extent.width, originalSize.width)
        XCTAssertLessThanOrEqual(croppedImage.extent.height, originalSize.height)
    }

    /// Test: Crop with zero-size rect
    func testCropWithZeroSizeRect() {
        // Given: Zero-size crop rect
        let cropRect = CGRect(x: 50, y: 50, width: 0, height: 0)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Result should be empty
        XCTAssertTrue(croppedImage.extent.isEmpty)
    }

    /// Test: Crop with negative origin (partially outside)
    func testCropWithNegativeOrigin() {
        // Given: Crop rect starting outside image
        let cropRect = CGRect(x: -50, y: -50, width: 100, height: 100)

        // When: Apply crop
        let croppedImage = testImage.cropped(to: cropRect)

        // Then: Should only include the overlapping region
        let expectedWidth = min(cropRect.maxX, originalSize.width) - max(cropRect.minX, 0)
        let expectedHeight = min(cropRect.maxY, originalSize.height) - max(cropRect.minY, 0)

        XCTAssertEqual(croppedImage.extent.width, max(0, expectedWidth), accuracy: 1)
        XCTAssertEqual(croppedImage.extent.height, max(0, expectedHeight), accuracy: 1)
    }

    // MARK: - Normalized Crop Tests (0-1 range)

    /// Test: Crop using normalized coordinates (like CropOverlay uses)
    func testNormalizedCrop() {
        // Given: Normalized crop rect (0-1 range)
        let normalizedRect = CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)

        // Convert to pixel coordinates
        let pixelRect = CGRect(
            x: normalizedRect.origin.x * originalSize.width,
            y: normalizedRect.origin.y * originalSize.height,
            width: normalizedRect.width * originalSize.width,
            height: normalizedRect.height * originalSize.height
        )

        // When: Apply crop
        let croppedImage = testImage.cropped(to: pixelRect)

        // Then: Should be half the original size
        assertImageDimensions(croppedImage, width: 100, height: 100)
    }

    /// Test: Full image normalized crop (0,0,1,1)
    func testFullImageNormalizedCrop() {
        // Given: Full image crop rect
        let normalizedRect = CGRect(x: 0, y: 0, width: 1, height: 1)

        let pixelRect = CGRect(
            x: normalizedRect.origin.x * originalSize.width,
            y: normalizedRect.origin.y * originalSize.height,
            width: normalizedRect.width * originalSize.width,
            height: normalizedRect.height * originalSize.height
        )

        // When: Apply crop
        let croppedImage = testImage.cropped(to: pixelRect)

        // Then: Should be same size as original
        assertImageDimensions(croppedImage, width: originalSize.width, height: originalSize.height)
    }

    // MARK: - Performance Tests

    /// Test: Crop performance with large image
    func testCropPerformance() {
        // Given: Large test image
        let largeImage = ImageTestUtilities.createSolidColorImage(
            color: .blue,
            size: CGSize(width: 4000, height: 3000)
        )
        let cropRect = CGRect(x: 500, y: 500, width: 2000, height: 1500)

        // When/Then: Measure crop performance
        measure {
            let _ = largeImage.cropped(to: cropRect)
        }
    }
}
