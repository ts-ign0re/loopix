import Foundation
import CoreImage
import Metal

enum MetalFilterError: Error, LocalizedError {
    case metalDeviceNotAvailable
    case libraryNotFound
    case kernelNotFound(String)
    case kernelCompilationFailed(String)

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
        }
    }
}

/// Manages loading, caching, and applying Metal kernels for grain processing.
/// Simplified from FilmBox — grain only.
final class MetalFilterLoader: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = MetalFilterLoader()

    // MARK: - Properties

    private let device: MTLDevice?
    private let ciContext: CIContext
    private let grainNoiseTile: CIImage?
    private var kernelCache: [String: CIKernel] = [:]
    private let cacheQueue = DispatchQueue(label: "com.camera.metalfilterloader.cache", attributes: .concurrent)

    struct KernelName {
        static let grain = "grainKernel"
    }

    // MARK: - Initialization

    private init() {
        self.device = MTLCreateSystemDefaultDevice()
        let context: CIContext
        if let device = device {
            context = CIContext(mtlDevice: device, options: [
                .cacheIntermediates: true,
                .priorityRequestLow: false
            ])
        } else {
            context = CIContext(options: [
                .useSoftwareRenderer: true
            ])
        }
        self.ciContext = context
        self.grainNoiseTile = CIFilter(name: "CIRandomGenerator")?
            .outputImage?
            .cropped(to: CGRect(x: 0, y: 0, width: 512, height: 512))
    }

    // MARK: - Kernel Loading

    func loadKernel(named name: String) throws -> CIKernel {
        if let cached = cacheQueue.sync(execute: { kernelCache[name] }) {
            return cached
        }

        guard device != nil else {
            throw MetalFilterError.metalDeviceNotAvailable
        }

        let kernel: CIKernel

        do {
            // Load from CIKernels.metallib (compiled with -fcikernel)
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
        } catch let error as MetalFilterError {
            throw error
        } catch {
            throw MetalFilterError.kernelNotFound(name)
        }

        cacheKernel(kernel, forName: name)
        return kernel
    }

    private func cacheKernel(_ kernel: CIKernel, forName name: String) {
        cacheQueue.async(flags: .barrier) {
            self.kernelCache[name] = kernel
        }
    }

    // MARK: - Kernel Application

    func applyKernel(named kernelName: String, to image: CIImage, parameters: [Any]) throws -> CIImage {
        let kernel = try loadKernel(named: kernelName)
        let extent = image.extent
        let sampler = CISampler(image: image)

        var allParameters: [Any] = [sampler]
        allParameters.append(contentsOf: parameters)

        guard let output = kernel.apply(
            extent: extent,
            roiCallback: { _, rect in rect },
            arguments: allParameters
        ) else {
            throw MetalFilterError.kernelCompilationFailed("Kernel application returned nil")
        }

        return output
    }

    // MARK: - Grain

    func applyGrain(to image: CIImage,
                    amount: Float = 0.3,
                    size: Float = 1.0,
                    roughness: Float = 0.5,
                    monochromatic: Bool = true,
                    time: Float = 0.0,
                    clumpStrength: Float = 0.0) throws -> CIImage {
        // ponytail: built-in CI noise is stable across iOS GPU drivers.
        guard var noise = grainNoiseTile else {
            return image
        }

        let scale = CGFloat(max(0.55, min(size * 0.42, 1.6)))
        let phase = CGFloat(floor(time * 12))
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        transform = transform.translatedBy(
            x: phase.truncatingRemainder(dividingBy: 37) * 13,
            y: phase.truncatingRemainder(dividingBy: 53) * 17
        )
        noise = noise
            .applyingFilter("CIAffineTile", parameters: [
                kCIInputTransformKey: NSValue(cgAffineTransform: transform)
            ])
            .cropped(to: image.extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: monochromatic ? 0 : 0.55,
                kCIInputContrastKey: 1.05 + roughness * 0.8 + clumpStrength * 0.2
            ])

        let opacity = CGFloat(min(0.24, amount * (0.20 + roughness * 0.10 + clumpStrength * 0.04)))
        noise = noise.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: opacity)
        ])

        return noise
            .applyingFilter("CISoftLightBlendMode", parameters: [
                kCIInputBackgroundImageKey: image
            ])
            .cropped(to: image.extent)
    }

    /// Apply grain using GrainData with proper UI→Metal parameter mapping
    func applyGrain(to image: CIImage,
                    grainData: GrainData,
                    time: Float,
                    clumpStrength: Float = 0.0) throws -> CIImage {
        guard grainData.isActive else { return image }
        return try applyGrain(
            to: image,
            amount: grainData.metalAmount,
            size: grainData.metalSize,
            roughness: grainData.roughness,
            monochromatic: grainData.monochromatic,
            time: time,
            clumpStrength: clumpStrength
        )
    }

    // MARK: - Rendering

    func render(_ image: CIImage) -> CGImage? {
        return ciContext.createCGImage(image, from: image.extent)
    }

    // MARK: - Cache

    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.kernelCache.removeAll()
        }
    }

    func preloadKernels() {
        DispatchQueue.global(qos: .utility).async {
            _ = try? self.loadKernel(named: KernelName.grain)
        }
    }
}
