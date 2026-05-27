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
    private var kernelCache: [String: CIKernel] = [:]
    private let cacheQueue = DispatchQueue(label: "com.camera.metalfilterloader.cache", attributes: .concurrent)

    struct KernelName {
        static let grain = "grainKernel"
    }

    // MARK: - Initialization

    private init() {
        self.device = MTLCreateSystemDefaultDevice()
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
        let imageSize = Float(min(image.extent.width, image.extent.height))
        return try applyKernel(
            named: KernelName.grain,
            to: image,
            parameters: [amount, size, roughness, monochromatic ? 1.0 : 0.0, time, imageSize, clumpStrength]
        )
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
