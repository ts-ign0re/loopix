//
//  CIImage+Extensions.swift
//  FilmBox
//
//  Created for FilmBox iOS App
//

import CoreImage
import Photos
import UIKit

// MARK: - CIImage Extensions

extension CIImage {

    // MARK: - Convenience Initializer from PHAsset

    /// Creates a CIImage from a PHAsset asynchronously
    /// - Parameters:
    ///   - asset: The PHAsset to load the image from
    ///   - options: Optional PHImageRequestOptions for customizing the request
    /// - Returns: A CIImage if successful, nil otherwise
    static func image(from asset: PHAsset, options: PHImageRequestOptions? = nil) async -> CIImage? {
        await withCheckedContinuation { continuation in
            let requestOptions = options ?? {
                let opts = PHImageRequestOptions()
                opts.version = .current
                opts.deliveryMode = .highQualityFormat
                opts.isNetworkAccessAllowed = true
                opts.isSynchronous = false
                return opts
            }()

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: requestOptions
            ) { data, _, orientation, _ in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }

                var ciImage = CIImage(data: data)

                // Apply EXIF orientation
                if let image = ciImage {
                    ciImage = image.oriented(for: orientation)
                }

                continuation.resume(returning: ciImage)
            }
        }
    }

    // MARK: - Orientation

    /// Returns a new CIImage oriented according to the EXIF orientation
    /// - Parameter orientation: The CGImagePropertyOrientation to apply
    /// - Returns: A new CIImage with the orientation applied
    func oriented(for orientation: CGImagePropertyOrientation) -> CIImage {
        return self.oriented(orientation)
    }

    /// Returns a new CIImage oriented according to the UIImage orientation
    /// - Parameter orientation: The UIImage.Orientation to apply
    /// - Returns: A new CIImage with the orientation applied
    func oriented(for orientation: UIImage.Orientation) -> CIImage {
        let cgOrientation = CGImagePropertyOrientation(orientation)
        return self.oriented(cgOrientation)
    }

    // MARK: - Cropping

    /// Safely crops the image to the specified rectangle with bounds checking
    /// - Parameter rect: The rectangle to crop to, in image coordinates
    /// - Returns: A new cropped CIImage with origin at (0,0)
    func safeCropped(to rect: CGRect) -> CIImage {
        // Ensure the rect is within bounds
        let clampedRect = rect.intersection(self.extent)
        guard !clampedRect.isEmpty else {
            return self
        }

        // Use the original CIImage.cropped(to:) method
        return self.cropped(to: clampedRect)
            .transformed(by: CGAffineTransform(translationX: -clampedRect.origin.x, y: -clampedRect.origin.y))
    }

    /// Crops the image to the specified aspect ratio, centered
    /// - Parameter aspectRatio: The desired aspect ratio (width / height)
    /// - Returns: A new cropped CIImage centered with the given aspect ratio
    func cropped(toAspectRatio aspectRatio: CGFloat) -> CIImage {
        let currentAspect = extent.width / extent.height

        var cropRect: CGRect

        if currentAspect > aspectRatio {
            // Image is wider, crop horizontally
            let newWidth = extent.height * aspectRatio
            let xOffset = (extent.width - newWidth) / 2
            cropRect = CGRect(x: extent.origin.x + xOffset, y: extent.origin.y, width: newWidth, height: extent.height)
        } else {
            // Image is taller, crop vertically
            let newHeight = extent.width / aspectRatio
            let yOffset = (extent.height - newHeight) / 2
            cropRect = CGRect(x: extent.origin.x, y: extent.origin.y + yOffset, width: extent.width, height: newHeight)
        }

        return safeCropped(to: cropRect)
    }

    // MARK: - Scaling

    /// Scales the image to fit within the specified size while maintaining aspect ratio
    /// - Parameter targetSize: The maximum size to scale to
    /// - Returns: A new scaled CIImage
    func scaled(to targetSize: CGSize) -> CIImage {
        let currentSize = extent.size

        guard currentSize.width > 0 && currentSize.height > 0 else {
            return self
        }

        let widthRatio = targetSize.width / currentSize.width
        let heightRatio = targetSize.height / currentSize.height
        let scale = min(widthRatio, heightRatio)

        guard scale < 1.0 else {
            // No need to scale up
            return self
        }

        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return self.transformed(by: transform)
    }

    /// Scales the image by the specified factor
    /// - Parameter factor: The scale factor (1.0 = original size)
    /// - Returns: A new scaled CIImage
    func scaled(by factor: CGFloat) -> CIImage {
        guard factor > 0 else { return self }
        let transform = CGAffineTransform(scaleX: factor, y: factor)
        return self.transformed(by: transform)
    }

    // MARK: - Thumbnail

    /// Creates a thumbnail of the image with the specified maximum dimension
    /// - Parameter maxSize: The maximum width or height of the thumbnail
    /// - Returns: A new thumbnail CIImage
    func thumbnail(maxSize: CGFloat) -> CIImage {
        let currentSize = extent.size

        guard currentSize.width > 0 && currentSize.height > 0 else {
            return self
        }

        let maxDimension = max(currentSize.width, currentSize.height)

        guard maxDimension > maxSize else {
            // Already smaller than max size
            return self
        }

        let scale = maxSize / maxDimension
        return scaled(by: scale)
    }

    /// Creates a thumbnail that fits within the specified size
    /// - Parameter size: The maximum size for the thumbnail
    /// - Returns: A new thumbnail CIImage
    func thumbnail(fitting size: CGSize) -> CIImage {
        return scaled(to: size)
    }

    // MARK: - Rendering

    /// Renders the CIImage to a CGImage using the specified context
    /// - Parameter context: The CIContext to use for rendering (uses default if nil)
    /// - Returns: A rendered CGImage, or nil if rendering fails
    func rendered(using context: CIContext? = nil) -> CGImage? {
        let ciContext = context ?? CIContext(options: [.useSoftwareRenderer: false])
        return ciContext.createCGImage(self, from: extent)
    }

    /// Renders the CIImage to a UIImage
    /// - Parameter context: The CIContext to use for rendering (uses default if nil)
    /// - Returns: A UIImage, or nil if rendering fails
    func toUIImage(using context: CIContext? = nil) -> UIImage? {
        guard let cgImage = rendered(using: context) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - CGImagePropertyOrientation Extension

extension CGImagePropertyOrientation {

    /// Initializes from UIImage.Orientation
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
