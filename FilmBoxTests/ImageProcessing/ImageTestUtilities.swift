import XCTest
import CoreImage
import UIKit
@testable import FilmBox

// MARK: - Image Test Utilities

/// Utilities for creating and comparing test images
enum ImageTestUtilities {

    // MARK: - Test Image Generation

    /// Create a solid color test image
    static func createSolidColorImage(
        color: UIColor,
        size: CGSize = CGSize(width: 100, height: 100)
    ) -> CIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        color.setFill()
        UIRectFill(rect)
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return CIImage(image: uiImage)!
    }

    /// Create a gradient test image (useful for rotation/flip verification)
    static func createGradientImage(
        size: CGSize = CGSize(width: 100, height: 100),
        startColor: UIColor = .red,
        endColor: UIColor = .blue,
        horizontal: Bool = true
    ) -> CIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        let context = UIGraphicsGetCurrentContext()!

        let colors = [startColor.cgColor, endColor.cgColor] as CFArray
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!

        let startPoint = CGPoint.zero
        let endPoint = horizontal ? CGPoint(x: size.width, y: 0) : CGPoint(x: 0, y: size.height)

        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: []
        )

        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return CIImage(image: uiImage)!
    }

    /// Create a test image with distinct quadrants (useful for rotation/flip tests)
    /// Top-left: Red, Top-right: Green, Bottom-left: Blue, Bottom-right: Yellow
    static func createQuadrantImage(size: CGSize = CGSize(width: 100, height: 100)) -> CIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)

        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        // Top-left: Red
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight))

        // Top-right: Green
        UIColor.green.setFill()
        UIRectFill(CGRect(x: halfWidth, y: 0, width: halfWidth, height: halfHeight))

        // Bottom-left: Blue
        UIColor.blue.setFill()
        UIRectFill(CGRect(x: 0, y: halfHeight, width: halfWidth, height: halfHeight))

        // Bottom-right: Yellow
        UIColor.yellow.setFill()
        UIRectFill(CGRect(x: halfWidth, y: halfHeight, width: halfWidth, height: halfHeight))

        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return CIImage(image: uiImage)!
    }

    /// Create a test image with a marker in one corner (useful for orientation tests)
    static func createMarkerImage(
        size: CGSize = CGSize(width: 100, height: 100),
        backgroundColor: UIColor = .white,
        markerColor: UIColor = .red,
        markerPosition: MarkerPosition = .topLeft
    ) -> CIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)

        // Background
        backgroundColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        // Marker (20% of image size)
        let markerSize = CGSize(width: size.width * 0.2, height: size.height * 0.2)
        let markerRect: CGRect

        switch markerPosition {
        case .topLeft:
            markerRect = CGRect(origin: .zero, size: markerSize)
        case .topRight:
            markerRect = CGRect(x: size.width - markerSize.width, y: 0, width: markerSize.width, height: markerSize.height)
        case .bottomLeft:
            markerRect = CGRect(x: 0, y: size.height - markerSize.height, width: markerSize.width, height: markerSize.height)
        case .bottomRight:
            markerRect = CGRect(x: size.width - markerSize.width, y: size.height - markerSize.height, width: markerSize.width, height: markerSize.height)
        }

        markerColor.setFill()
        UIRectFill(markerRect)

        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return CIImage(image: uiImage)!
    }

    enum MarkerPosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    // MARK: - Image Comparison

    /// Compare two images for equality within a tolerance
    static func imagesAreEqual(
        _ image1: CIImage,
        _ image2: CIImage,
        tolerance: Float = 0.01,
        context: CIContext? = nil
    ) -> Bool {
        let ctx = context ?? CIContext()

        // Check extents match
        guard image1.extent.size == image2.extent.size else {
            return false
        }

        let extent = image1.extent
        let width = Int(extent.width)
        let height = Int(extent.height)

        // Render both images to bitmaps
        var bitmap1 = [UInt8](repeating: 0, count: width * height * 4)
        var bitmap2 = [UInt8](repeating: 0, count: width * height * 4)

        ctx.render(image1, toBitmap: &bitmap1, rowBytes: width * 4, bounds: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        ctx.render(image2, toBitmap: &bitmap2, rowBytes: width * 4, bounds: extent, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        // Compare pixels
        var totalDiff: Float = 0
        let pixelCount = width * height

        for i in stride(from: 0, to: bitmap1.count, by: 4) {
            let diff = abs(Float(bitmap1[i]) - Float(bitmap2[i])) +
                       abs(Float(bitmap1[i+1]) - Float(bitmap2[i+1])) +
                       abs(Float(bitmap1[i+2]) - Float(bitmap2[i+2]))
            totalDiff += diff / (255.0 * 3.0)
        }

        let avgDiff = totalDiff / Float(pixelCount)
        return avgDiff <= tolerance
    }

    /// Get the average color of an image region
    static func averageColor(
        of image: CIImage,
        in region: CGRect? = nil,
        context: CIContext? = nil
    ) -> (r: Float, g: Float, b: Float, a: Float) {
        let ctx = context ?? CIContext()
        let rect = region ?? image.extent

        let width = Int(rect.width)
        let height = Int(rect.height)
        var bitmap = [UInt8](repeating: 0, count: width * height * 4)

        ctx.render(image, toBitmap: &bitmap, rowBytes: width * 4, bounds: rect, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        var r: Float = 0, g: Float = 0, b: Float = 0, a: Float = 0
        let pixelCount = Float(width * height)

        for i in stride(from: 0, to: bitmap.count, by: 4) {
            r += Float(bitmap[i]) / 255.0
            g += Float(bitmap[i+1]) / 255.0
            b += Float(bitmap[i+2]) / 255.0
            a += Float(bitmap[i+3]) / 255.0
        }

        return (r / pixelCount, g / pixelCount, b / pixelCount, a / pixelCount)
    }

    /// Get pixel color at specific coordinates
    static func pixelColor(
        of image: CIImage,
        at point: CGPoint,
        context: CIContext? = nil
    ) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let ctx = context ?? CIContext()

        // Sample a 1x1 region
        let sampleRect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
        var pixel = [UInt8](repeating: 0, count: 4)

        ctx.render(image, toBitmap: &pixel, rowBytes: 4, bounds: sampleRect, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        return (pixel[0], pixel[1], pixel[2], pixel[3])
    }

    /// Check if a specific region is approximately a given color
    static func regionHasColor(
        _ image: CIImage,
        region: CGRect,
        expectedColor: UIColor,
        tolerance: Float = 0.1,
        context: CIContext? = nil
    ) -> Bool {
        let avgColor = averageColor(of: image, in: region, context: context)

        var expectedR: CGFloat = 0, expectedG: CGFloat = 0, expectedB: CGFloat = 0, expectedA: CGFloat = 0
        expectedColor.getRed(&expectedR, green: &expectedG, blue: &expectedB, alpha: &expectedA)

        let diff = abs(avgColor.r - Float(expectedR)) +
                   abs(avgColor.g - Float(expectedG)) +
                   abs(avgColor.b - Float(expectedB))

        return (diff / 3.0) <= tolerance
    }

    // MARK: - Size Verification

    /// Verify image dimensions
    static func verifyDimensions(
        _ image: CIImage,
        expectedWidth: CGFloat,
        expectedHeight: CGFloat,
        tolerance: CGFloat = 0.5
    ) -> Bool {
        let actualWidth = image.extent.width
        let actualHeight = image.extent.height

        return abs(actualWidth - expectedWidth) <= tolerance &&
               abs(actualHeight - expectedHeight) <= tolerance
    }

    /// Verify aspect ratio
    static func verifyAspectRatio(
        _ image: CIImage,
        expectedRatio: CGFloat,
        tolerance: CGFloat = 0.01
    ) -> Bool {
        let actualRatio = image.extent.width / image.extent.height
        return abs(actualRatio - expectedRatio) <= tolerance
    }
}

// MARK: - XCTestCase Extension

extension XCTestCase {

    /// Assert two images are visually equal
    func assertImagesEqual(
        _ image1: CIImage,
        _ image2: CIImage,
        tolerance: Float = 0.01,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            ImageTestUtilities.imagesAreEqual(image1, image2, tolerance: tolerance),
            "Images are not equal within tolerance \(tolerance)",
            file: file,
            line: line
        )
    }

    /// Assert image has expected dimensions
    func assertImageDimensions(
        _ image: CIImage,
        width: CGFloat,
        height: CGFloat,
        tolerance: CGFloat = 0.5,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            ImageTestUtilities.verifyDimensions(image, expectedWidth: width, expectedHeight: height, tolerance: tolerance),
            "Image dimensions (\(image.extent.width)x\(image.extent.height)) don't match expected (\(width)x\(height))",
            file: file,
            line: line
        )
    }

    /// Assert image region has expected color
    func assertRegionColor(
        _ image: CIImage,
        region: CGRect,
        expectedColor: UIColor,
        tolerance: Float = 0.1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            ImageTestUtilities.regionHasColor(image, region: region, expectedColor: expectedColor, tolerance: tolerance),
            "Region \(region) does not have expected color",
            file: file,
            line: line
        )
    }
}
