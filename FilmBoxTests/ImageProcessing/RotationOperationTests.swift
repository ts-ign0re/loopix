import XCTest
import CoreImage
@testable import FilmBox

/// Tests for image rotation operations
final class RotationOperationTests: XCTestCase {

    // MARK: - Properties

    private var context: CIContext!
    private var testImage: CIImage!
    private let originalSize = CGSize(width: 200, height: 200)

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        context = CIContext(options: [.useSoftwareRenderer: true])
        // Create quadrant image for rotation verification
        // TL=Red, TR=Green, BL=Blue, BR=Yellow
        testImage = ImageTestUtilities.createQuadrantImage(size: originalSize)
    }

    override func tearDown() {
        context = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - 90 Degree Rotation Tests

    /// Test: Rotate 90 degrees clockwise (right)
    func testRotate90DegreesClockwise() {
        // Given: Quadrant image
        // Original: TL=Red, TR=Green, BL=Blue, BR=Yellow

        // When: Rotate 90° clockwise (-90° in radians, or 270° counter-clockwise)
        let angle = -CGFloat.pi / 2 // -90 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Dimensions should be same (square image)
        XCTAssertEqual(rotatedImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.height, originalSize.height, accuracy: 1)

        // After 90° CW rotation:
        // New TL (was BL) = Blue
        // New TR (was TL) = Red
        // New BL (was BR) = Yellow
        // New BR (was TR) = Green

        // Verify by sampling corners (accounting for CIImage coordinate system)
        let normalizedImage = rotatedImage.transformed(
            by: CGAffineTransform(translationX: -rotatedImage.extent.origin.x, y: -rotatedImage.extent.origin.y)
        )

        // Sample top-left (should be Blue after 90° CW)
        let topLeft = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: 0, y: normalizedImage.extent.height/2, width: normalizedImage.extent.width/2, height: normalizedImage.extent.height/2),
            context: context
        )

        // Blue should dominate in the new top-left
        XCTAssertGreaterThan(topLeft.b, 0.5, "After 90° CW, top-left should have blue")
    }

    /// Test: Rotate 90 degrees counter-clockwise (left)
    func testRotate90DegreesCounterClockwise() {
        // Given: Quadrant image

        // When: Rotate 90° counter-clockwise
        let angle = CGFloat.pi / 2 // +90 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Dimensions should be same (square image)
        XCTAssertEqual(rotatedImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.height, originalSize.height, accuracy: 1)

        // After 90° CCW rotation:
        // New TL (was TR) = Green
        // New TR (was BR) = Yellow
        // New BL (was TL) = Red
        // New BR (was BL) = Blue
    }

    /// Test: Rotate 180 degrees
    func testRotate180Degrees() {
        // Given: Quadrant image

        // When: Rotate 180°
        let angle = CGFloat.pi // 180 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Dimensions should be same
        XCTAssertEqual(rotatedImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.height, originalSize.height, accuracy: 1)

        // After 180° rotation:
        // New TL (was BR) = Yellow
        // New TR (was BL) = Blue
        // New BL (was TR) = Green
        // New BR (was TL) = Red

        // Normalize to origin
        let normalizedImage = rotatedImage.transformed(
            by: CGAffineTransform(translationX: -rotatedImage.extent.origin.x, y: -rotatedImage.extent.origin.y)
        )

        // Sample bottom-right (should be Red after 180°)
        let bottomRight = ImageTestUtilities.averageColor(
            of: normalizedImage,
            in: CGRect(x: normalizedImage.extent.width/2, y: 0, width: normalizedImage.extent.width/2, height: normalizedImage.extent.height/2),
            context: context
        )

        XCTAssertGreaterThan(bottomRight.r, 0.5, "After 180°, bottom-right should have red")
    }

    /// Test: Rotate 270 degrees (same as 90° CCW)
    func testRotate270Degrees() {
        // Given: Quadrant image

        // When: Rotate 270° CW (same as 90° CCW)
        let angle = -3 * CGFloat.pi / 2 // -270 degrees = +90 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Should match 90° CCW rotation
        let ccwImage = testImage.transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 2))

        // Both should have same dimensions
        XCTAssertEqual(rotatedImage.extent.size.width, ccwImage.extent.size.width, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.size.height, ccwImage.extent.size.height, accuracy: 1)
    }

    // MARK: - Arbitrary Angle Tests

    /// Test: Rotate 45 degrees
    func testRotate45Degrees() {
        // Given: Square image

        // When: Rotate 45°
        let angle = CGFloat.pi / 4 // 45 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Dimensions should be larger (rotated square inscribed in larger square)
        // For 45°, the new bounding box is sqrt(2) times the original
        let expectedSize = originalSize.width * sqrt(2)
        XCTAssertEqual(rotatedImage.extent.width, expectedSize, accuracy: 2)
        XCTAssertEqual(rotatedImage.extent.height, expectedSize, accuracy: 2)
    }

    /// Test: Rotate 30 degrees
    func testRotate30Degrees() {
        // Given: Square image

        // When: Rotate 30°
        let angle = CGFloat.pi / 6 // 30 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Image should be rotated (dimensions will be larger)
        XCTAssertGreaterThan(rotatedImage.extent.width, originalSize.width)
        XCTAssertGreaterThan(rotatedImage.extent.height, originalSize.height)
    }

    /// Test: Rotate small angle (straighten adjustment)
    func testStraightenRotation() {
        // Given: Image that needs slight straightening

        // When: Rotate by small angle (typical straighten range is ±10°)
        let angle = CGFloat.pi / 36 // 5 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Image should be slightly larger
        XCTAssertGreaterThan(rotatedImage.extent.width, originalSize.width)

        // Aspect ratio should be preserved (for small angles)
        let originalAspect = originalSize.width / originalSize.height
        let rotatedAspect = rotatedImage.extent.width / rotatedImage.extent.height
        XCTAssertEqual(originalAspect, rotatedAspect, accuracy: 0.1)
    }

    // MARK: - Full Rotation Tests

    /// Test: Rotate 360 degrees (should be same as original)
    func testRotate360Degrees() {
        // Given: Original image

        // When: Rotate 360°
        let angle = 2 * CGFloat.pi
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Then: Should be same size as original
        XCTAssertEqual(rotatedImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.height, originalSize.height, accuracy: 1)
    }

    /// Test: Multiple 90° rotations return to original
    func testFour90DegreeRotationsReturnToOriginal() {
        // Given: Original image

        // When: Rotate 90° four times
        var currentImage = testImage!
        for _ in 0..<4 {
            currentImage = currentImage.transformed(
                by: CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            )
        }

        // Then: Dimensions should match original
        XCTAssertEqual(currentImage.extent.width, originalSize.width, accuracy: 1)
        XCTAssertEqual(currentImage.extent.height, originalSize.height, accuracy: 1)
    }

    // MARK: - Non-Square Image Tests

    /// Test: Rotate non-square image 90 degrees
    func testRotateNonSquareImage90Degrees() {
        // Given: Non-square image (200x100)
        let nonSquareImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 200, height: 100)
        )

        // When: Rotate 90°
        let rotatedImage = nonSquareImage.transformed(
            by: CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        )

        // Then: Width and height should swap
        XCTAssertEqual(rotatedImage.extent.width, 100, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.height, 200, accuracy: 1)
    }

    /// Test: Rotate non-square image 180 degrees
    func testRotateNonSquareImage180Degrees() {
        // Given: Non-square image (300x200)
        let nonSquareImage = ImageTestUtilities.createGradientImage(
            size: CGSize(width: 300, height: 200)
        )

        // When: Rotate 180°
        let rotatedImage = nonSquareImage.transformed(
            by: CGAffineTransform(rotationAngle: CGFloat.pi)
        )

        // Then: Dimensions should be same
        XCTAssertEqual(rotatedImage.extent.width, 300, accuracy: 1)
        XCTAssertEqual(rotatedImage.extent.height, 200, accuracy: 1)
    }

    // MARK: - Rotation with Crop (Auto-crop after rotation)

    /// Test: Rotate and crop to remove empty corners
    func testRotateAndAutoCrop() {
        // Given: Image rotated by arbitrary angle
        let angle = CGFloat.pi / 12 // 15 degrees
        let rotatedImage = testImage.transformed(by: CGAffineTransform(rotationAngle: angle))

        // Calculate the inscribed rectangle (largest rectangle that fits inside rotated square)
        // For a square rotated by θ, the inscribed square has side = original_side * cos(θ) - sin(θ) for small angles
        let cosAngle = cos(abs(angle))
        let sinAngle = sin(abs(angle))

        // For a square, the maximum inscribed rectangle while maintaining aspect ratio
        let inscribedWidth = originalSize.width * cosAngle - originalSize.height * sinAngle
        let inscribedHeight = originalSize.height * cosAngle - originalSize.width * sinAngle

        // Verify that an inscribed crop would be smaller than rotated image
        XCTAssertLessThan(inscribedWidth, rotatedImage.extent.width)
        XCTAssertLessThan(inscribedHeight, rotatedImage.extent.height)
    }

    // MARK: - Performance Tests

    /// Test: Rotation performance with large image
    func testRotationPerformance() {
        // Given: Large test image
        let largeImage = ImageTestUtilities.createSolidColorImage(
            color: .blue,
            size: CGSize(width: 4000, height: 3000)
        )

        // When/Then: Measure rotation performance
        measure {
            let _ = largeImage.transformed(by: CGAffineTransform(rotationAngle: CGFloat.pi / 4))
        }
    }

    /// Test: Multiple small rotations performance
    func testIncrementalRotationPerformance() {
        // Given: Test image
        let smallAngle = CGFloat.pi / 180 // 1 degree

        // When/Then: Measure many small rotations
        measure {
            var currentImage = self.testImage!
            for _ in 0..<10 {
                currentImage = currentImage.transformed(
                    by: CGAffineTransform(rotationAngle: smallAngle)
                )
            }
        }
    }
}
