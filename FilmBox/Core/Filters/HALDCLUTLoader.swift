@preconcurrency import CoreImage
import CoreGraphics
import Foundation
import Accelerate

// MARK: - HALD CLUT Loader

/// Actor responsible for loading and parsing HALD CLUT (Color Lookup Table) files
/// HALD CLUT is an industry standard format used in DaVinci Resolve, Capture One, RawTherapee
/// for professional film simulation and color grading.
@available(iOS 17.0, *)
actor HALDCLUTLoader {

    // MARK: - Types

    /// Errors that can occur during CLUT loading
    enum CLUTError: Error, LocalizedError {
        case fileNotFound(URL)
        case invalidImage
        case unsupportedFormat(String)
        case invalidDimensions(width: Int, height: Int)
        case processingFailed
        case colorCubeCreationFailed

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let url):
                return "CLUT file not found: \(url.lastPathComponent)"
            case .invalidImage:
                return "Could not load image data"
            case .unsupportedFormat(let format):
                return "Unsupported CLUT format: \(format)"
            case .invalidDimensions(let width, let height):
                return "Invalid HALD CLUT dimensions: \(width)x\(height)"
            case .processingFailed:
                return "Failed to process CLUT data"
            case .colorCubeCreationFailed:
                return "Failed to create CIColorCube filter"
            }
        }
    }

    /// Metadata about a loaded CLUT
    struct CLUTInfo: Sendable {
        let url: URL
        let originalLevel: Int      // Original HALD level (e.g., 144 for 1728x1728)
        let effectiveLevel: Int     // Level used for CIColorCube (max 64)
        let wasDownsampled: Bool
    }

    // MARK: - Properties

    /// Cache for loaded color cube data to avoid re-parsing
    private var dataCache: [URL: (data: Data, info: CLUTInfo)] = [:]

    /// Maximum LUT size supported by CIColorCube on iOS
    private let maxCubeSize: Int = 64

    // MARK: - Public API

    /// Load a HALD CLUT from a URL and create a CIColorCube filter
    /// - Parameter url: URL to the HALD CLUT PNG file
    /// - Returns: Configured CIFilter ready to apply, along with metadata
    func loadCLUT(from url: URL) async throws -> (filter: CIFilter, info: CLUTInfo) {
        // Check cache first
        if let cached = dataCache[url] {
            guard let filter = createColorCubeFilter(from: cached.data, size: cached.info.effectiveLevel) else {
                throw CLUTError.colorCubeCreationFailed
            }
            return (filter, cached.info)
        }

        // Load and parse the CLUT
        let (cubeData, info) = try await parseCLUT(from: url)

        // Cache the data
        dataCache[url] = (cubeData, info)

        // Create the filter
        guard let filter = createColorCubeFilter(from: cubeData, size: info.effectiveLevel) else {
            throw CLUTError.colorCubeCreationFailed
        }

        return (filter, info)
    }

    /// Load only the color cube data without creating a filter
    /// Useful for batch processing or custom rendering pipelines
    func loadCLUTData(from url: URL) async throws -> (data: Data, info: CLUTInfo) {
        if let cached = dataCache[url] {
            return cached
        }

        let result = try await parseCLUT(from: url)
        dataCache[url] = result
        return result
    }

    /// Create a CIColorCube filter from pre-loaded cube data
    func createFilter(from data: Data, size: Int) -> CIFilter? {
        return createColorCubeFilter(from: data, size: size)
    }

    /// Clear the data cache
    func clearCache() {
        dataCache.removeAll()
    }

    /// Remove a specific URL from cache
    func removeFromCache(url: URL) {
        dataCache.removeValue(forKey: url)
    }

    // MARK: - Parsing

    /// Parse a HALD CLUT PNG file into color cube data
    private func parseCLUT(from url: URL) async throws -> (data: Data, info: CLUTInfo) {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CLUTError.fileNotFound(url)
        }

        // Load image data
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw CLUTError.invalidImage
        }

        let width = cgImage.width
        let height = cgImage.height

        // HALD CLUT must be square
        guard width == height else {
            throw CLUTError.invalidDimensions(width: width, height: height)
        }

        // Calculate HALD level
        // HALD level N has dimensions N^1.5 x N^1.5 = N^3 total pixels
        // So level = cubeRoot(width * height) = cubeRoot(width^2) = width^(2/3)
        let totalPixels = width * width
        let level = Int(round(pow(Double(totalPixels), 1.0/3.0)))

        // Verify dimensions match expected HALD format
        let expectedDimension = Int(pow(Double(level), 1.5))
        guard abs(expectedDimension - width) <= 1 else {
            throw CLUTError.invalidDimensions(width: width, height: height)
        }

        // Determine effective level (max 64 for CIColorCube)
        let effectiveLevel = min(level, maxCubeSize)
        let needsDownsampling = level > maxCubeSize

        // Extract pixel data
        guard let pixelData = extractPixelData(from: cgImage) else {
            throw CLUTError.processingFailed
        }

        // Convert to color cube format
        let cubeData: Data
        if needsDownsampling {
            cubeData = try downsampleCLUT(
                pixelData: pixelData,
                originalLevel: level,
                targetLevel: effectiveLevel,
                imageWidth: width
            )
        } else {
            cubeData = try convertToCubeData(
                pixelData: pixelData,
                level: level,
                imageWidth: width
            )
        }

        let info = CLUTInfo(
            url: url,
            originalLevel: level,
            effectiveLevel: effectiveLevel,
            wasDownsampled: needsDownsampling
        )

        return (cubeData, info)
    }

    /// Extract raw RGBA pixel data from a CGImage
    /// Uses noneSkipLast for proper handling of images without alpha channel
    private func extractPixelData(from image: CGImage) -> [UInt8]? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow

        var pixelData = [UInt8](repeating: 0, count: totalBytes)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB) else {
            return nil
        }

        // Use noneSkipLast for RGBX format - proper handling of images without alpha
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData
    }

    /// Convert HALD CLUT pixel data to CIColorCube format
    /// CIColorCube expects float RGBA values in [0,1] range, arranged as [R,G,B,A, R,G,B,A, ...]
    /// with B varying fastest, then G, then R
    private func convertToCubeData(
        pixelData: [UInt8],
        level: Int,
        imageWidth: Int
    ) throws -> Data {
        let cubeSize = level * level * level
        var floatData = [Float](repeating: 0, count: cubeSize * 4)

        // HALD CLUT layout:
        // The image is sqrt(level) x sqrt(level) blocks, each block is level x level pixels
        // Each block row contains level B values spread across sqrt(level) blocks
        // Each pixel row within a block contains level G values
        // The position within a row encodes R
        let sqrtLevel = Int(sqrt(Double(level)))

        for r in 0..<level {
            for g in 0..<level {
                for b in 0..<level {
                    // Calculate position in HALD image
                    let blockX = b % sqrtLevel
                    let blockY = b / sqrtLevel
                    let pixelX = blockX * level + r
                    let pixelY = blockY * level + g

                    // Read from pixel data (RGBA format)
                    let pixelIndex = (pixelY * imageWidth + pixelX) * 4

                    guard pixelIndex + 3 < pixelData.count else {
                        throw CLUTError.processingFailed
                    }

                    // Calculate output index (B varies fastest, then G, then R)
                    let outIndex = (r * level * level + g * level + b) * 4

                    floatData[outIndex + 0] = Float(pixelData[pixelIndex + 0]) / 255.0
                    floatData[outIndex + 1] = Float(pixelData[pixelIndex + 1]) / 255.0
                    floatData[outIndex + 2] = Float(pixelData[pixelIndex + 2]) / 255.0
                    floatData[outIndex + 3] = 1.0  // Alpha always 1
                }
            }
        }

        return Data(bytes: floatData, count: floatData.count * MemoryLayout<Float>.size)
    }

    /// Downsample a high-resolution CLUT to fit within CIColorCube limits
    /// Uses trilinear interpolation for smooth results
    private func downsampleCLUT(
        pixelData: [UInt8],
        originalLevel: Int,
        targetLevel: Int,
        imageWidth: Int
    ) throws -> Data {
        let cubeSize = targetLevel * targetLevel * targetLevel
        var floatData = [Float](repeating: 0, count: cubeSize * 4)

        let scale = Float(originalLevel - 1) / Float(targetLevel - 1)

        for r in 0..<targetLevel {
            for g in 0..<targetLevel {
                for b in 0..<targetLevel {
                    // Map to original CLUT coordinates
                    let origR = Float(r) * scale
                    let origG = Float(g) * scale
                    let origB = Float(b) * scale

                    // Trilinear interpolation
                    let color = trilinearSample(
                        pixelData: pixelData,
                        r: origR, g: origG, b: origB,
                        level: originalLevel,
                        imageWidth: imageWidth
                    )

                    let outIndex = (r * targetLevel * targetLevel + g * targetLevel + b) * 4
                    floatData[outIndex + 0] = color.0
                    floatData[outIndex + 1] = color.1
                    floatData[outIndex + 2] = color.2
                    floatData[outIndex + 3] = 1.0
                }
            }
        }

        return Data(bytes: floatData, count: floatData.count * MemoryLayout<Float>.size)
    }

    /// Sample a color from the HALD CLUT using trilinear interpolation
    private func trilinearSample(
        pixelData: [UInt8],
        r: Float, g: Float, b: Float,
        level: Int,
        imageWidth: Int
    ) -> (Float, Float, Float) {
        // Get integer and fractional parts
        let r0 = Int(r), r1 = min(r0 + 1, level - 1)
        let g0 = Int(g), g1 = min(g0 + 1, level - 1)
        let b0 = Int(b), b1 = min(b0 + 1, level - 1)

        let rFrac = r - Float(r0)
        let gFrac = g - Float(g0)
        let bFrac = b - Float(b0)

        // Sample 8 corners of the cube
        let c000 = sampleHALD(pixelData: pixelData, r: r0, g: g0, b: b0, level: level, width: imageWidth)
        let c001 = sampleHALD(pixelData: pixelData, r: r0, g: g0, b: b1, level: level, width: imageWidth)
        let c010 = sampleHALD(pixelData: pixelData, r: r0, g: g1, b: b0, level: level, width: imageWidth)
        let c011 = sampleHALD(pixelData: pixelData, r: r0, g: g1, b: b1, level: level, width: imageWidth)
        let c100 = sampleHALD(pixelData: pixelData, r: r1, g: g0, b: b0, level: level, width: imageWidth)
        let c101 = sampleHALD(pixelData: pixelData, r: r1, g: g0, b: b1, level: level, width: imageWidth)
        let c110 = sampleHALD(pixelData: pixelData, r: r1, g: g1, b: b0, level: level, width: imageWidth)
        let c111 = sampleHALD(pixelData: pixelData, r: r1, g: g1, b: b1, level: level, width: imageWidth)

        // Trilinear interpolation
        func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
            return a + (b - a) * t
        }

        func lerpColor(_ a: (Float, Float, Float), _ b: (Float, Float, Float), _ t: Float) -> (Float, Float, Float) {
            return (lerp(a.0, b.0, t), lerp(a.1, b.1, t), lerp(a.2, b.2, t))
        }

        // Interpolate along B axis
        let c00 = lerpColor(c000, c001, bFrac)
        let c01 = lerpColor(c010, c011, bFrac)
        let c10 = lerpColor(c100, c101, bFrac)
        let c11 = lerpColor(c110, c111, bFrac)

        // Interpolate along G axis
        let c0 = lerpColor(c00, c01, gFrac)
        let c1 = lerpColor(c10, c11, gFrac)

        // Interpolate along R axis
        return lerpColor(c0, c1, rFrac)
    }

    /// Sample a single color from HALD CLUT at integer coordinates
    private func sampleHALD(
        pixelData: [UInt8],
        r: Int, g: Int, b: Int,
        level: Int,
        width: Int
    ) -> (Float, Float, Float) {
        // Calculate position in HALD image
        // HALD uses sqrt(level) x sqrt(level) blocks
        let sqrtLevel = Int(sqrt(Double(level)))
        let blockX = b % sqrtLevel
        let blockY = b / sqrtLevel
        let pixelX = blockX * level + r
        let pixelY = blockY * level + g

        let pixelIndex = (pixelY * width + pixelX) * 4

        guard pixelIndex + 2 < pixelData.count else {
            return (0, 0, 0)
        }

        return (
            Float(pixelData[pixelIndex + 0]) / 255.0,
            Float(pixelData[pixelIndex + 1]) / 255.0,
            Float(pixelData[pixelIndex + 2]) / 255.0
        )
    }

    // MARK: - Filter Creation

    /// Create a CIColorCube filter from cube data
    /// Uses CIColorCubeWithColorSpace to ensure proper color management with FilterEngine's linearSRGB working space
    private func createColorCubeFilter(from data: Data, size: Int) -> CIFilter? {
        // Prefer CIColorCubeWithColorSpace for proper color management
        // This ensures the LUT is applied correctly when FilterEngine works in linearSRGB
        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            // Fallback to basic CIColorCube if CIColorCubeWithColorSpace unavailable
            guard let basicFilter = CIFilter(name: "CIColorCube") else {
                return nil
            }
            basicFilter.setValue(size, forKey: "inputCubeDimension")
            basicFilter.setValue(data, forKey: "inputCubeData")
            return basicFilter
        }

        // Use linearSRGB to match FilterEngine's working color space
        guard let linearColorSpace = CGColorSpace(name: CGColorSpace.linearSRGB) else {
            return nil
        }

        filter.setValue(size, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        filter.setValue(linearColorSpace, forKey: "inputColorSpace")

        return filter
    }
}

// MARK: - Convenience Extensions

@available(iOS 17.0, *)
extension HALDCLUTLoader {

    /// Load multiple CLUTs sequentially (CIFilter is not Sendable, so parallel loading is not supported)
    func loadCLUTs(from urls: [URL]) async -> [(url: URL, result: Result<(filter: CIFilter, info: CLUTInfo), Error>)] {
        var results: [(url: URL, result: Result<(filter: CIFilter, info: CLUTInfo), Error>)] = []
        for url in urls {
            do {
                let result = try await loadCLUT(from: url)
                results.append((url: url, result: .success((filter: result.filter, info: result.info))))
            } catch {
                results.append((url: url, result: .failure(error)))
            }
        }
        return results
    }
}
