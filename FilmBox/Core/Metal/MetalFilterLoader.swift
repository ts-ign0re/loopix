//
//  MetalFilterLoader.swift
//  FilmBox
//
//  Swift class to load and manage Metal kernels for Core Image
//

import Foundation
import CoreImage
import Metal

/// Error types for Metal kernel operations
enum MetalFilterError: Error, LocalizedError {
    case metalDeviceNotAvailable
    case libraryNotFound
    case kernelNotFound(String)
    case kernelCompilationFailed(String)
    case invalidParameters(String)

    var errorDescription: String? {
        switch self {
        case .metalDeviceNotAvailable:
            return "Metal device is not available on this device"
        case .libraryNotFound:
            return "Metal library could not be loaded"
        case .kernelNotFound(let name):
            return "Kernel '\(name)' not found in Metal library"
        case .kernelCompilationFailed(let reason):
            return "Kernel compilation failed: \(reason)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        }
    }
}

/// Manages loading, caching, and applying Metal kernels for image processing
/// Uses DispatchQueue for thread-safe cache access, marked @unchecked Sendable
final class MetalFilterLoader: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared instance for app-wide kernel management
    static let shared = MetalFilterLoader()

    // MARK: - Properties

    /// Metal device reference
    private let device: MTLDevice?

    /// Core Image context with Metal support
    private let ciContext: CIContext

    /// Cache for compiled CIKernel instances
    private var kernelCache: [String: CIKernel] = [:]

    /// Cache for CIColorKernel instances (single pixel operations)
    private var colorKernelCache: [String: CIColorKernel] = [:]

    /// Thread-safe access to caches
    private let cacheQueue = DispatchQueue(label: "com.filmbox.metalfilterloader.cache", attributes: .concurrent)

    /// Metal library containing compiled shaders
    private var metalLibrary: MTLLibrary?

    // MARK: - Kernel Names

    /// Available kernel function names
    struct KernelName {
        // Grain kernels
        static let grain = "grainKernel"

        // Halation kernels
        static let halation = "halationKernel"
        static let halationExtractHighlights = "halationExtractHighlights"
        static let halationBlend = "halationBlend"

        // Bloom kernels
        static let bloom = "bloomKernel"
        static let bloomThreshold = "bloomThresholdKernel"
        static let bloomBlurHorizontal = "bloomBlurHorizontal"
        static let bloomBlurVertical = "bloomBlurVertical"
        static let bloomCombine = "bloomCombine"

        // Vignette kernels
        static let vignette = "vignetteKernel"
        static let vignetteExposure = "vignetteExposureKernel"
        static let vignetteColored = "vignetteColoredKernel"
        static let vignetteOptical = "vignetteOpticalKernel"
    }

    // MARK: - Initialization

    private init() {
        // Initialize Metal device
        self.device = MTLCreateSystemDefaultDevice()

        // Create Core Image context with Metal
        if let device = device {
            self.ciContext = CIContext(mtlDevice: device, options: [
                .cacheIntermediates: true,
                .priorityRequestLow: false
            ])
        } else {
            self.ciContext = CIContext(options: [
                .useSoftwareRenderer: true
            ])
        }

        // Load Metal library
        loadMetalLibrary()
    }

    /// Initialize with a custom Metal device
    init(device: MTLDevice) {
        self.device = device
        self.ciContext = CIContext(mtlDevice: device, options: [
            .cacheIntermediates: true
        ])
        loadMetalLibrary()
    }

    // MARK: - Library Loading

    /// Loads the default Metal library from the app bundle
    private func loadMetalLibrary() {
        guard let device = device else { return }

        // Try to load the default library
        if let library = device.makeDefaultLibrary() {
            metalLibrary = library
            return
        }

        // Try to load from a specific metallib file
        if let libraryURL = Bundle.main.url(forResource: "FilmBoxKernels", withExtension: "metallib") {
            do {
                metalLibrary = try device.makeLibrary(URL: libraryURL)
            } catch {
                print("MetalFilterLoader: Failed to load Metal library: \(error)")
            }
        }
    }

    // MARK: - Kernel Loading

    /// Loads a CIKernel from the Metal library
    /// - Parameter name: The kernel function name
    /// - Returns: Compiled CIKernel instance
    func loadKernel(named name: String) throws -> CIKernel {
        // Check cache first
        if let cached = cacheQueue.sync(execute: { kernelCache[name] }) {
            return cached
        }

        guard device != nil else {
            throw MetalFilterError.metalDeviceNotAvailable
        }

        // Load kernel from Metal library
        let kernel: CIKernel

        do {
            // For Core Image kernels, load from CIKernels.metallib (compiled with -fcikernel)
            guard let libraryURL = Bundle.main.url(forResource: "CIKernels", withExtension: "metallib"),
                  let data = try? Data(contentsOf: libraryURL) else {
                // Fallback: try default.metallib
                if let defaultURL = Bundle.main.url(forResource: "default", withExtension: "metallib"),
                   let defaultData = try? Data(contentsOf: defaultURL) {
                    kernel = try CIKernel(functionName: name, fromMetalLibraryData: defaultData)
                    cacheKernel(kernel, forName: name)
                    return kernel
                }
                throw MetalFilterError.libraryNotFound
            }

            kernel = try CIKernel(functionName: name, fromMetalLibraryData: data)
        } catch {
            throw MetalFilterError.kernelNotFound(name)
        }

        // Cache the kernel
        cacheKernel(kernel, forName: name)

        return kernel
    }

    /// Loads a CIColorKernel for per-pixel color operations
    func loadColorKernel(named name: String) throws -> CIColorKernel {
        if let cached = cacheQueue.sync(execute: { colorKernelCache[name] }) {
            return cached
        }

        // Try CIKernels.metallib first, then fall back to default.metallib
        let data: Data
        if let libraryURL = Bundle.main.url(forResource: "CIKernels", withExtension: "metallib"),
           let libData = try? Data(contentsOf: libraryURL) {
            data = libData
        } else if let defaultURL = Bundle.main.url(forResource: "default", withExtension: "metallib"),
                  let defaultData = try? Data(contentsOf: defaultURL) {
            data = defaultData
        } else {
            throw MetalFilterError.libraryNotFound
        }

        let kernel = try CIColorKernel(functionName: name, fromMetalLibraryData: data)

        cacheQueue.async(flags: .barrier) {
            self.colorKernelCache[name] = kernel
        }

        return kernel
    }

    /// Attempts to load kernel from Metal source code
    private func loadKernelFromSource(named name: String) throws -> CIKernel {
        // Find the Metal source file
        guard let sourceURL = Bundle.main.url(forResource: name, withExtension: "metal") ??
                              Bundle.main.url(forResource: kernelFileForFunction(name), withExtension: "metal") else {
            throw MetalFilterError.kernelNotFound(name)
        }

        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        guard let kernel = try? CIKernel(source: source) else {
            throw MetalFilterError.kernelCompilationFailed("Failed to compile \(name)")
        }

        return kernel
    }

    /// Maps function names to their source files
    private func kernelFileForFunction(_ functionName: String) -> String {
        switch functionName {
        case let name where name.contains("grain"):
            return "GrainKernel"
        case let name where name.contains("halation"):
            return "HalationKernel"
        case let name where name.contains("bloom"):
            return "BloomKernel"
        case let name where name.contains("vignette"):
            return "VignetteKernel"
        default:
            return functionName
        }
    }

    /// Thread-safe kernel caching
    private func cacheKernel(_ kernel: CIKernel, forName name: String) {
        cacheQueue.async(flags: .barrier) {
            self.kernelCache[name] = kernel
        }
    }

    // MARK: - Kernel Application

    /// Applies a kernel to an image with the given parameters
    /// - Parameters:
    ///   - kernelName: Name of the kernel to apply
    ///   - image: Source CIImage
    ///   - parameters: Kernel parameters as an array
    /// - Returns: Processed CIImage
    func applyKernel(named kernelName: String, to image: CIImage, parameters: [Any]) throws -> CIImage {
        let kernel = try loadKernel(named: kernelName)

        let extent = image.extent
        let sampler = CISampler(image: image)

        var allParameters: [Any] = [sampler]
        allParameters.append(contentsOf: parameters)

        guard let output = kernel.apply(extent: extent, roiCallback: { _, rect in rect }, arguments: allParameters) else {
            throw MetalFilterError.kernelCompilationFailed("Kernel application returned nil")
        }

        return output
    }

    // MARK: - Convenience Methods for Specific Effects

    /// Applies film grain effect
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Grain intensity (0.0 - 1.0)
    ///   - size: Grain size (0.5 - 4.0)
    ///   - roughness: Grain texture roughness (0.0 - 1.0)
    ///   - monochromatic: True for B&W grain
    ///   - time: Animation time for temporal variation
    func applyGrain(to image: CIImage,
                    amount: Float = 0.3,
                    size: Float = 1.0,
                    roughness: Float = 0.5,
                    monochromatic: Bool = true,
                    time: Float = 0.0) throws -> CIImage {
        return try applyKernel(
            named: KernelName.grain,
            to: image,
            parameters: [amount, size, roughness, monochromatic ? 1.0 : 0.0, time]
        )
    }

    /// Applies halation effect
    /// - Parameters:
    ///   - image: Source image
    ///   - intensity: Halation intensity (0.0 - 1.0)
    ///   - hue: Halation color hue (0.0 - 1.0)
    ///   - spread: Size of halation spread
    func applyHalation(to image: CIImage,
                       intensity: Float = 0.5,
                       hue: Float = 0.0,
                       spread: Float = 20.0) throws -> CIImage {
        return try applyKernel(
            named: KernelName.halation,
            to: image,
            parameters: [intensity, hue, spread]
        )
    }

    /// Applies bloom effect
    /// - Parameters:
    ///   - image: Source image
    ///   - intensity: Bloom intensity (0.0 - 2.0)
    ///   - radius: Blur radius
    ///   - threshold: Brightness threshold
    func applyBloom(to image: CIImage,
                    intensity: Float = 0.5,
                    radius: Float = 10.0,
                    threshold: Float = 0.7) throws -> CIImage {
        return try applyKernel(
            named: KernelName.bloom,
            to: image,
            parameters: [intensity, radius, threshold]
        )
    }

    /// Applies vignette effect
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Vignette intensity (-1.0 to 1.0)
    ///   - midpoint: Where vignette starts (0.0 - 1.0)
    ///   - roundness: Shape (0.0 = rectangular, 1.0 = circular)
    ///   - feather: Transition softness
    func applyVignette(to image: CIImage,
                       amount: Float = 0.5,
                       midpoint: Float = 0.5,
                       roundness: Float = 1.0,
                       feather: Float = 0.3) throws -> CIImage {
        let extent = image.extent
        let center = CIVector(x: extent.midX, y: extent.midY)
        let size = CIVector(x: extent.width, y: extent.height)

        return try applyKernel(
            named: KernelName.vignette,
            to: image,
            parameters: [amount, midpoint, roundness, feather, center, size]
        )
    }

    // MARK: - Rendering

    /// Renders a CIImage to a CGImage
    func render(_ image: CIImage) -> CGImage? {
        return ciContext.createCGImage(image, from: image.extent)
    }

    /// Renders a CIImage to a pixel buffer
    func render(_ image: CIImage, to pixelBuffer: CVPixelBuffer) {
        ciContext.render(image, to: pixelBuffer)
    }

    // MARK: - Cache Management

    /// Clears the kernel cache
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.kernelCache.removeAll()
            self.colorKernelCache.removeAll()
        }
    }

    /// Preloads commonly used kernels
    func preloadKernels() {
        let kernelNames = [
            KernelName.grain,
            KernelName.halation,
            KernelName.bloom,
            KernelName.vignette
        ]

        DispatchQueue.global(qos: .utility).async {
            for name in kernelNames {
                _ = try? self.loadKernel(named: name)
            }
        }
    }
}

// MARK: - CIFilter Subclasses

/// Film grain filter using Metal kernel
final class GrainFilter: CIFilter, @unchecked Sendable {

    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputAmount: CGFloat = 0.3
    @objc dynamic var inputSize: CGFloat = 1.0
    @objc dynamic var inputRoughness: CGFloat = 0.5
    @objc dynamic var inputMonochromatic: CGFloat = 1.0
    @objc dynamic var inputTime: CGFloat = 0.0

    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }

        return try? MetalFilterLoader.shared.applyGrain(
            to: input,
            amount: Float(inputAmount),
            size: Float(inputSize),
            roughness: Float(inputRoughness),
            monochromatic: inputMonochromatic > 0.5,
            time: Float(inputTime)
        )
    }

    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: "Film Grain",
            kCIAttributeFilterCategories: [kCICategoryStylize, kCICategoryVideo, kCICategoryStillImage],
            "inputImage": [
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage
            ],
            "inputAmount": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.3,
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeSliderMin: 0.0,
                kCIAttributeSliderMax: 1.0,
                kCIAttributeDisplayName: "Amount",
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputSize": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1.0,
                kCIAttributeMin: 0.5,
                kCIAttributeMax: 4.0,
                kCIAttributeDisplayName: "Size",
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputRoughness": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.5,
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeDisplayName: "Roughness",
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputMonochromatic": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1.0,
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeDisplayName: "Monochromatic",
                kCIAttributeType: kCIAttributeTypeBoolean
            ]
        ]
    }
}

/// Vignette filter using Metal kernel
final class AdvancedVignetteFilter: CIFilter, @unchecked Sendable {

    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputAmount: CGFloat = 0.5
    @objc dynamic var inputMidpoint: CGFloat = 0.5
    @objc dynamic var inputRoundness: CGFloat = 1.0
    @objc dynamic var inputFeather: CGFloat = 0.3

    override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }

        return try? MetalFilterLoader.shared.applyVignette(
            to: input,
            amount: Float(inputAmount),
            midpoint: Float(inputMidpoint),
            roundness: Float(inputRoundness),
            feather: Float(inputFeather)
        )
    }

    override var attributes: [String: Any] {
        return [
            kCIAttributeFilterDisplayName: "Advanced Vignette",
            kCIAttributeFilterCategories: [kCICategoryColorEffect, kCICategoryVideo, kCICategoryStillImage],
            "inputImage": [
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage
            ],
            "inputAmount": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.5,
                kCIAttributeMin: -1.0,
                kCIAttributeMax: 1.0,
                kCIAttributeDisplayName: "Amount",
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputMidpoint": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.5,
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeDisplayName: "Midpoint",
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputRoundness": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1.0,
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeDisplayName: "Roundness",
                kCIAttributeType: kCIAttributeTypeScalar
            ],
            "inputFeather": [
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.3,
                kCIAttributeMin: 0.0,
                kCIAttributeMax: 1.0,
                kCIAttributeDisplayName: "Feather",
                kCIAttributeType: kCIAttributeTypeScalar
            ]
        ]
    }
}
