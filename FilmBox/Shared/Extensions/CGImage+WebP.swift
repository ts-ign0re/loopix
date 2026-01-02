//
//  CGImage+WebP.swift
//  FilmBox
//
//  Created for FilmBox iOS App
//

import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import UIKit

// MARK: - CGImage WebP Extension

/// Extension on CGImage for WebP support
/// Note: Full WebP encoding requires libwebp integration.
/// This implementation provides JPEG fallback for now.
///
/// To add full WebP support:
/// 1. Add libwebp via SPM or CocoaPods
/// 2. Import libwebp headers
/// 3. Implement WebP encoding/decoding using libwebp APIs
extension CGImage {

    // MARK: - WebP Support Status

    /// Indicates whether native WebP encoding is available
    /// Currently returns false as libwebp integration is pending
    static var isWebPEncodingAvailable: Bool {
        // TODO: Return true once libwebp is integrated
        return false
    }

    /// Indicates whether native WebP decoding is available
    /// iOS 14+ supports WebP decoding natively via ImageIO
    static var isWebPDecodingAvailable: Bool {
        return true // iOS 14+ supports WebP decoding
    }

    // MARK: - JPEG Encoding

    /// Converts the CGImage to JPEG data
    /// - Parameter quality: The compression quality (0.0 to 1.0, where 1.0 is highest quality)
    /// - Returns: JPEG data, or nil if encoding fails
    func toJPEGData(quality: CGFloat = 0.85) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0) else {
            return nil
        }

        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]

        CGImageDestinationAddImage(destination, self, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }

    /// Creates a CGImage from JPEG data
    /// - Parameter data: The JPEG data to decode
    /// - Returns: A CGImage, or nil if decoding fails
    static func fromJPEGData(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // MARK: - WebP Encoding (Placeholder)

    /// Converts the CGImage to WebP data
    /// Note: Currently falls back to JPEG as libwebp is not integrated
    /// - Parameter quality: The compression quality (0.0 to 1.0)
    /// - Returns: WebP data (or JPEG fallback), or nil if encoding fails
    func toWebPData(quality: CGFloat = 0.85) -> Data? {
        // TODO: Implement WebP encoding once libwebp is integrated
        // For now, fall back to JPEG
        #if DEBUG
        print("[CGImage+WebP] WebP encoding not available, using JPEG fallback")
        #endif
        return toJPEGData(quality: quality)
    }

    /// Creates a CGImage from WebP data
    /// Note: iOS 14+ supports WebP decoding natively
    /// - Parameter data: The WebP data to decode
    /// - Returns: A CGImage, or nil if decoding fails
    static func fromWebPData(_ data: Data) -> CGImage? {
        // iOS 14+ supports WebP decoding via ImageIO
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // MARK: - PNG Encoding

    /// Converts the CGImage to PNG data
    /// - Returns: PNG data, or nil if encoding fails
    func toPNGData() -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0) else {
            return nil
        }

        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, self, nil)

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }

    /// Creates a CGImage from PNG data
    /// - Parameter data: The PNG data to decode
    /// - Returns: A CGImage, or nil if decoding fails
    static func fromPNGData(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // MARK: - Generic Decoding

    /// Creates a CGImage from image data of any supported format
    /// - Parameter data: The image data to decode
    /// - Returns: A CGImage, or nil if decoding fails
    static func fromData(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    // MARK: - Image Properties

    /// Returns the image dimensions
    var size: CGSize {
        CGSize(width: width, height: height)
    }

    /// Returns the aspect ratio (width / height)
    var aspectRatio: CGFloat {
        guard height > 0 else { return 1.0 }
        return CGFloat(width) / CGFloat(height)
    }
}

// MARK: - Data Extension for Image Type Detection

extension Data {

    /// Detected image format
    enum ImageFormat {
        case jpeg
        case png
        case webp
        case heic
        case gif
        case unknown
    }

    /// Detects the image format from the data's magic bytes
    var detectedImageFormat: ImageFormat {
        guard count >= 12 else { return .unknown }

        let bytes = [UInt8](self.prefix(12))

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return .jpeg
        }

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return .png
        }

        // WebP: RIFF....WEBP
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
           bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 {
            return .webp
        }

        // HEIC: ....ftyp
        if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            return .heic
        }

        // GIF: GIF87a or GIF89a
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 {
            return .gif
        }

        return .unknown
    }
}
