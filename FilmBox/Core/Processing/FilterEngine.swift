import CoreImage
import CoreGraphics
import Foundation
import Metal

// MARK: - FilterEngine

/// GPU-accelerated image processing engine using Core Image
/// Actor-based for thread-safe concurrent access
@available(iOS 17.0, *)
actor FilterEngine {

    // MARK: - Properties

    /// Shared Core Image context configured for GPU rendering
    private let context: CIContext

    /// Cached filters for performance
    private var filterCache: [String: CIFilter] = [:]

    /// HALD CLUT loader for film simulation presets
    private let clutLoader = HALDCLUTLoader()

    /// Cache for loaded CLUT filters by path
    private var clutFilterCache: [String: CIFilter] = [:]

    // MARK: - Initialization

    init() {
        // Configure CIContext for optimal GPU performance
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer: false,
            .cacheIntermediates: true
        ]

        self.context = CIContext(options: options)
    }

    /// Initialize with a custom Metal device
    init(device: MTLDevice?) {
        var options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .useSoftwareRenderer: false,
            .cacheIntermediates: true
        ]

        if let device = device {
            self.context = CIContext(mtlDevice: device, options: options)
        } else {
            self.context = CIContext(options: options)
        }
    }

    // MARK: - Main Processing

    /// Apply a full preset including CLUT (if any) and parameters
    /// - Parameters:
    ///   - preset: The filter preset to apply
    ///   - image: Source CIImage
    /// - Returns: Processed CIImage
    func apply(_ preset: FilterPreset, to image: CIImage) async -> CIImage {
        var result = image

        // 1. Apply base parameter adjustments (exposure, contrast, etc.)
        result = applyBaseAdjustments(preset.parameters, to: result)

        // 2. Apply CLUT if present (film simulation)
        if let clutPath = preset.clutPath {
            result = await applyCLUT(
                at: clutPath,
                to: result,
                intensity: preset.clutIntensity
            )
        }

        // 3. Apply effects (grain, vignette, etc.)
        result = applyEffects(preset.parameters, to: result)

        return result
    }

    /// Apply all filter parameters to an image in the correct order
    /// - Parameters:
    ///   - image: Source CIImage
    ///   - parameters: Filter parameters to apply
    /// - Returns: Processed CIImage
    func apply(_ parameters: FilterParameters, to image: CIImage) -> CIImage {
        var result = image

        // 1. Exposure & Contrast
        if parameters.exposure != 0 {
            result = applyExposure(to: result, ev: parameters.exposure)
        }
        if parameters.contrast != 0 {
            result = applyContrast(to: result, amount: parameters.contrast)
        }

        // 2. Tone Curve
        if !parameters.toneCurve.isIdentity {
            result = applyToneCurve(to: result, curve: parameters.toneCurve)
        }

        // 3. Highlights & Shadows
        if parameters.highlights != 0 || parameters.shadows != 0 {
            result = applyHighlightsShadows(
                to: result,
                highlights: parameters.highlights,
                shadows: parameters.shadows
            )
        }

        // 4. White Balance
        if parameters.temperature != 0 || parameters.tint != 0 {
            result = applyWhiteBalance(
                to: result,
                temperature: parameters.temperature,
                tint: parameters.tint
            )
        }

        // 5. HSL Adjustments (placeholder - requires custom Metal kernel)
        if !parameters.hsl.isIdentity {
            result = applyHSLAdjustments(to: result, hsl: parameters.hsl)
        }

        // 6. Saturation & Vibrance
        if parameters.saturation != 0 {
            result = applySaturation(to: result, amount: parameters.saturation)
        }
        if parameters.vibrance != 0 {
            result = applyVibrance(to: result, amount: parameters.vibrance)
        }

        // 7. Split Tone (placeholder)
        if !parameters.splitTone.isIdentity {
            result = applySplitTone(to: result, data: parameters.splitTone)
        }

        // 8. Clarity
        if parameters.clarity != 0 {
            result = applyClarity(to: result, amount: parameters.clarity)
        }

        // 9. Sharpening
        if parameters.sharpness > 0 {
            result = applySharpening(
                to: result,
                amount: parameters.sharpness,
                radius: parameters.sharpenRadius
            )
        }

        // 10. Fade
        if parameters.fade > 0 {
            result = applyFade(to: result, amount: parameters.fade)
        }

        // 11. Grain (placeholder)
        if parameters.grain.isActive {
            result = applyGrain(to: result, data: parameters.grain)
        }

        // 12. Bloom (placeholder)
        if parameters.bloom.isActive {
            result = applyBloom(to: result, data: parameters.bloom)
        }

        // 13. Halation (placeholder)
        if parameters.halation.isActive {
            result = applyHalation(to: result, data: parameters.halation)
        }

        // 14. Vignette
        if parameters.vignette.isActive {
            result = applyVignette(to: result, data: parameters.vignette)
        }

        return result
    }

    // MARK: - Rendering

    /// Render a CIImage to a CGImage
    /// - Parameter image: Source CIImage
    /// - Returns: Rendered CGImage, or nil if rendering fails
    func render(_ image: CIImage) -> CGImage? {
        return context.createCGImage(image, from: image.extent)
    }

    /// Render a CIImage to a CGImage with a specific size
    /// - Parameters:
    ///   - image: Source CIImage
    ///   - rect: The rect to render
    /// - Returns: Rendered CGImage, or nil if rendering fails
    func render(_ image: CIImage, from rect: CGRect) -> CGImage? {
        return context.createCGImage(image, from: rect)
    }

    // MARK: - CLUT Processing

    /// Apply a HALD CLUT filter to an image
    /// - Parameters:
    ///   - path: Path to the CLUT file (relative or absolute)
    ///   - image: Source image
    ///   - intensity: CLUT intensity (0-100)
    /// - Returns: Processed image
    func applyCLUT(at path: String, to image: CIImage, intensity: Float = 100) async -> CIImage {
        // Get the CLUT filter (from cache or load new)
        let filter: CIFilter
        if let cached = clutFilterCache[path] {
            filter = cached
        } else {
            // Resolve the path
            let url = resolveCLUTPath(path)

            do {
                let (loadedFilter, _) = try await clutLoader.loadCLUT(from: url)
                clutFilterCache[path] = loadedFilter
                filter = loadedFilter
            } catch {
                // Log error and return original image
                print("Failed to load CLUT at \(path): \(error)")
                return image
            }
        }

        // Apply the filter
        filter.setValue(image, forKey: kCIInputImageKey)

        guard let output = filter.outputImage else {
            return image
        }

        // Apply intensity blending if not 100%
        if intensity < 100 {
            return blendImages(base: image, overlay: output, amount: intensity / 100.0)
        }

        return output
    }

    /// Apply a pre-loaded CLUT filter directly
    /// - Parameters:
    ///   - filter: The CIColorCube filter to apply
    ///   - image: Source image
    ///   - intensity: CLUT intensity (0-100)
    /// - Returns: Processed image
    func applyCLUT(filter: CIFilter, to image: CIImage, intensity: Float = 100) -> CIImage {
        filter.setValue(image, forKey: kCIInputImageKey)

        guard let output = filter.outputImage else {
            return image
        }

        if intensity < 100 {
            return blendImages(base: image, overlay: output, amount: intensity / 100.0)
        }

        return output
    }

    /// Resolve a CLUT path to an absolute URL
    /// - Parameter path: Relative or absolute path
    /// - Returns: Absolute URL
    private func resolveCLUTPath(_ path: String) -> URL {
        // Check if it's already an absolute path
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }

        // Check in app bundle first
        if let bundleURL = Bundle.main.url(forResource: path, withExtension: nil) {
            return bundleURL
        }

        // Check in bundle's HaldCLUT directory
        let pathComponents = path.split(separator: "/")
        let filename = String(pathComponents.last ?? "")
        let directory = pathComponents.dropLast().joined(separator: "/")

        if let bundleURL = Bundle.main.url(
            forResource: filename.replacingOccurrences(of: ".png", with: ""),
            withExtension: "png",
            subdirectory: "HaldCLUT/\(directory)"
        ) {
            return bundleURL
        }

        // Fall back to documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(path)
    }

    /// Preload CLUT filters for faster access
    /// - Parameter paths: Array of CLUT paths to preload
    func preloadCLUTs(_ paths: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for path in paths {
                group.addTask {
                    let url = self.resolveCLUTPath(path)
                    do {
                        let (filter, _) = try await self.clutLoader.loadCLUT(from: url)
                        self.clutFilterCache[path] = filter
                    } catch {
                        print("Failed to preload CLUT at \(path): \(error)")
                    }
                }
            }
        }
    }

    /// Clear the CLUT filter cache
    func clearCLUTCache() async {
        clutFilterCache.removeAll()
        await clutLoader.clearCache()
    }

    // MARK: - Split Processing

    /// Apply base adjustments (before CLUT)
    /// These are color-accurate adjustments that should happen before the film look
    private func applyBaseAdjustments(_ params: FilterParameters, to image: CIImage) -> CIImage {
        var result = image

        // 1. Exposure & Contrast
        if params.exposure != 0 {
            result = applyExposure(to: result, ev: params.exposure)
        }
        if params.contrast != 0 {
            result = applyContrast(to: result, amount: params.contrast)
        }

        // 2. Highlights & Shadows
        if params.highlights != 0 || params.shadows != 0 {
            result = applyHighlightsShadows(
                to: result,
                highlights: params.highlights,
                shadows: params.shadows
            )
        }

        // 3. White Balance (before CLUT for accurate color)
        if params.temperature != 0 || params.tint != 0 {
            result = applyWhiteBalance(
                to: result,
                temperature: params.temperature,
                tint: params.tint
            )
        }

        return result
    }

    /// Apply effects (after CLUT)
    /// These are artistic effects that should happen after the film look
    private func applyEffects(_ params: FilterParameters, to image: CIImage) -> CIImage {
        var result = image

        // 1. Tone Curve (can be used for fine-tuning after CLUT)
        if !params.toneCurve.isIdentity {
            result = applyToneCurve(to: result, curve: params.toneCurve)
        }

        // 2. HSL Adjustments
        if !params.hsl.isIdentity {
            result = applyHSLAdjustments(to: result, hsl: params.hsl)
        }

        // 3. Saturation & Vibrance
        if params.saturation != 0 {
            result = applySaturation(to: result, amount: params.saturation)
        }
        if params.vibrance != 0 {
            result = applyVibrance(to: result, amount: params.vibrance)
        }

        // 4. Split Tone
        if !params.splitTone.isIdentity {
            result = applySplitTone(to: result, data: params.splitTone)
        }

        // 5. Clarity
        if params.clarity != 0 {
            result = applyClarity(to: result, amount: params.clarity)
        }

        // 6. Sharpening
        if params.sharpness > 0 {
            result = applySharpening(
                to: result,
                amount: params.sharpness,
                radius: params.sharpenRadius
            )
        }

        // 7. Fade
        if params.fade > 0 {
            result = applyFade(to: result, amount: params.fade)
        }

        // 8. Grain
        if params.grain.isActive {
            result = applyGrain(to: result, data: params.grain)
        }

        // 9. Bloom
        if params.bloom.isActive {
            result = applyBloom(to: result, data: params.bloom)
        }

        // 10. Halation
        if params.halation.isActive {
            result = applyHalation(to: result, data: params.halation)
        }

        // 11. Vignette (always last)
        if params.vignette.isActive {
            result = applyVignette(to: result, data: params.vignette)
        }

        return result
    }

    // MARK: - Individual Filters

    /// Apply exposure adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - ev: Exposure value in EV (-2 to +2)
    /// - Returns: Adjusted image
    func applyExposure(to image: CIImage, ev: Float) -> CIImage {
        guard let filter = getCachedFilter(name: "CIExposureAdjust") else {
            return image
        }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(ev, forKey: kCIInputEVKey)

        return filter.outputImage ?? image
    }

    /// Apply contrast adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Contrast amount (-100 to +100)
    /// - Returns: Adjusted image
    func applyContrast(to image: CIImage, amount: Float) -> CIImage {
        guard let filter = getCachedFilter(name: "CIColorControls") else {
            return image
        }

        // Convert -100...+100 to 0.25...1.75 (1.0 is neutral)
        let contrast = 1.0 + (amount / 100.0) * 0.75

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(1.0, forKey: kCIInputSaturationKey)
        filter.setValue(0.0, forKey: kCIInputBrightnessKey)

        return filter.outputImage ?? image
    }

    /// Apply highlights and shadows adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - highlights: Highlights adjustment (-100 to +100)
    ///   - shadows: Shadows adjustment (-100 to +100)
    /// - Returns: Adjusted image
    func applyHighlightsShadows(
        to image: CIImage,
        highlights: Float,
        shadows: Float
    ) -> CIImage {
        guard let filter = getCachedFilter(name: "CIHighlightShadowAdjust") else {
            return image
        }

        // CIHighlightShadowAdjust:
        // - inputHighlightAmount: 0.0 to 1.0 (default 1.0, lower = reduce highlights)
        // - inputShadowAmount: -1.0 to 1.0 (default 0.0, positive = lift shadows)

        // Convert -100...+100 to appropriate ranges
        // Highlights: -100 maps to 0.0 (reduce), 0 maps to 1.0 (neutral), +100 maps to 2.0 (boost)
        let highlightAmount = 1.0 - (highlights / 100.0)

        // Shadows: -100 maps to -1.0, 0 maps to 0.0, +100 maps to 1.0
        let shadowAmount = shadows / 100.0

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(highlightAmount, forKey: "inputHighlightAmount")
        filter.setValue(shadowAmount, forKey: "inputShadowAmount")

        return filter.outputImage ?? image
    }

    /// Apply white balance adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - temperature: Temperature shift (-100 to +100)
    ///   - tint: Tint shift (-100 to +100)
    /// - Returns: Adjusted image
    func applyWhiteBalance(
        to image: CIImage,
        temperature: Float,
        tint: Float
    ) -> CIImage {
        guard let filter = getCachedFilter(name: "CITemperatureAndTint") else {
            return image
        }

        // CITemperatureAndTint uses neutral as (6500, 0)
        // Temperature: -100 maps to ~4000K (warm), +100 maps to ~9000K (cool)
        // We adjust the target to shift the white balance
        let neutralTemp: Float = 6500.0
        let neutralTint: Float = 0.0

        // Convert -100...+100 to Kelvin shift
        // Negative = warmer (lower target K), Positive = cooler (higher target K)
        let tempShift = temperature * 25.0  // -2500 to +2500
        let tintShift = tint * 1.0          // -100 to +100

        let targetNeutral = CIVector(x: CGFloat(neutralTemp + tempShift), y: CGFloat(neutralTint + tintShift))

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        filter.setValue(targetNeutral, forKey: "inputTargetNeutral")

        return filter.outputImage ?? image
    }

    /// Apply saturation adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Saturation amount (-100 to +100)
    /// - Returns: Adjusted image
    func applySaturation(to image: CIImage, amount: Float) -> CIImage {
        guard let filter = getCachedFilter(name: "CIColorControls") else {
            return image
        }

        // Convert -100...+100 to 0...2 (1.0 is neutral)
        let saturation = 1.0 + (amount / 100.0)

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        filter.setValue(1.0, forKey: kCIInputContrastKey)
        filter.setValue(0.0, forKey: kCIInputBrightnessKey)

        return filter.outputImage ?? image
    }

    /// Apply vibrance adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Vibrance amount (-100 to +100)
    /// - Returns: Adjusted image
    func applyVibrance(to image: CIImage, amount: Float) -> CIImage {
        guard let filter = getCachedFilter(name: "CIVibrance") else {
            return image
        }

        // CIVibrance inputAmount: -1.0 to 1.0
        let vibrance = amount / 100.0

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(vibrance, forKey: "inputAmount")

        return filter.outputImage ?? image
    }

    /// Apply tone curve adjustment
    /// - Parameters:
    ///   - image: Source image
    ///   - curve: Tone curve data with control points
    /// - Returns: Adjusted image
    func applyToneCurve(to image: CIImage, curve: ToneCurveData) -> CIImage {
        guard let filter = getCachedFilter(name: "CIToneCurve") else {
            return image
        }

        // CIToneCurve requires exactly 5 points
        // Get the 5 points from composite curve or use defaults
        let points = getCurvePoints(from: curve.composite)

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: CGFloat(points[0].x), y: CGFloat(points[0].y)), forKey: "inputPoint0")
        filter.setValue(CIVector(x: CGFloat(points[1].x), y: CGFloat(points[1].y)), forKey: "inputPoint1")
        filter.setValue(CIVector(x: CGFloat(points[2].x), y: CGFloat(points[2].y)), forKey: "inputPoint2")
        filter.setValue(CIVector(x: CGFloat(points[3].x), y: CGFloat(points[3].y)), forKey: "inputPoint3")
        filter.setValue(CIVector(x: CGFloat(points[4].x), y: CGFloat(points[4].y)), forKey: "inputPoint4")

        return filter.outputImage ?? image
    }

    /// Apply clarity adjustment using unsharp mask with low radius
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Clarity amount (-100 to +100)
    /// - Returns: Adjusted image
    func applyClarity(to image: CIImage, amount: Float) -> CIImage {
        guard let filter = getCachedFilter(name: "CIUnsharpMask") else {
            return image
        }

        // Clarity uses a large radius (midtone contrast) with moderate intensity
        // Low radius for local contrast, high intensity for effect
        let radius: Float = 2.5  // Low radius for clarity effect
        let intensity = abs(amount) / 100.0 * 1.5  // Scale intensity

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)

        // For negative clarity, we need to blur instead
        if amount < 0 {
            guard let blurFilter = getCachedFilter(name: "CIGaussianBlur") else {
                return image
            }
            blurFilter.setValue(image, forKey: kCIInputImageKey)
            blurFilter.setValue(abs(amount) / 100.0 * 2.0, forKey: kCIInputRadiusKey)

            // Blend the blurred image with original
            if let blurred = blurFilter.outputImage {
                return blendImages(base: image, overlay: blurred, amount: abs(amount) / 100.0)
            }
        }

        return filter.outputImage ?? image
    }

    /// Apply sharpening
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Sharpening amount (0 to 100)
    ///   - radius: Sharpening radius (0.5 to 3.0)
    /// - Returns: Adjusted image
    func applySharpening(to image: CIImage, amount: Float, radius: Float) -> CIImage {
        guard let filter = getCachedFilter(name: "CISharpenLuminance") else {
            return image
        }

        // CISharpenLuminance:
        // - inputSharpness: 0.0 to 2.0 (default 0.4)
        // - inputRadius: pixel radius
        let sharpness = amount / 100.0 * 2.0

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(sharpness, forKey: kCIInputSharpnessKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    /// Apply fade effect by blending with gray
    /// - Parameters:
    ///   - image: Source image
    ///   - amount: Fade amount (0 to 100)
    /// - Returns: Adjusted image
    func applyFade(to image: CIImage, amount: Float) -> CIImage {
        // Create a gray color overlay
        let fadeIntensity = amount / 100.0
        let grayLevel = 0.5 + (fadeIntensity * 0.15)  // Slightly lighter gray for fade

        guard let colorFilter = getCachedFilter(name: "CIConstantColorGenerator") else {
            return image
        }

        let grayColor = CIColor(red: CGFloat(grayLevel), green: CGFloat(grayLevel), blue: CGFloat(grayLevel), alpha: 1.0)
        colorFilter.setValue(grayColor, forKey: kCIInputColorKey)

        guard let grayImage = colorFilter.outputImage?.cropped(to: image.extent) else {
            return image
        }

        // Blend with original using soft light or overlay
        // For fade, we lift the blacks by blending toward gray
        return blendImages(base: image, overlay: grayImage, amount: fadeIntensity * 0.3)
    }

    /// Apply vignette effect using Metal kernel
    /// - Parameters:
    ///   - image: Source image
    ///   - data: Vignette parameters
    /// - Returns: Adjusted image
    func applyVignette(to image: CIImage, data: VignetteData) -> CIImage {
        // Convert parameters from UI range to Metal kernel range
        // amount: -100...+100 → -1.0...1.0
        // midpoint: 0...1 → direct mapping
        // roundness: -100...+100 → 0...1 (negative = rectangular, positive = circular)
        // feather: 0...1 → direct mapping
        let amount = data.amount / 100.0
        let midpoint = data.midpoint
        let roundness = (data.roundness + 100.0) / 200.0  // Map -100...100 to 0...1
        let feather = data.feather

        do {
            return try MetalFilterLoader.shared.applyVignette(
                to: image,
                amount: amount,
                midpoint: midpoint,
                roundness: roundness,
                feather: feather
            )
        } catch {
            // Fallback to CIVignette if Metal fails
            print("FilterEngine: Metal vignette failed, using fallback: \(error)")
            guard let filter = getCachedFilter(name: "CIVignette") else {
                return image
            }
            filter.setValue(image, forKey: kCIInputImageKey)
            filter.setValue(amount, forKey: kCIInputIntensityKey)
            filter.setValue(1.0 + midpoint, forKey: kCIInputRadiusKey)
            return filter.outputImage ?? image
        }
    }

    // MARK: - HSL and Split Tone Filters

    /// Apply per-channel HSL adjustments using CIColorCubeWithColorSpace
    /// This creates a 3D LUT that maps input colors to adjusted colors
    private func applyHSLAdjustments(to image: CIImage, hsl: HSLAdjustments) -> CIImage {
        // Create color cube data for HSL adjustments
        let cubeSize = 32  // 32x32x32 LUT for good quality/performance balance
        let cubeData = generateHSLColorCube(size: cubeSize, adjustments: hsl)

        guard let filter = CIFilter(name: "CIColorCubeWithColorSpace") else {
            return image
        }

        filter.setValue(cubeSize, forKey: "inputCubeDimension")
        filter.setValue(cubeData, forKey: "inputCubeData")
        filter.setValue(CGColorSpace(name: CGColorSpace.sRGB), forKey: "inputColorSpace")
        filter.setValue(image, forKey: kCIInputImageKey)

        return filter.outputImage ?? image
    }

    /// Generate 3D color cube data for HSL adjustments
    private func generateHSLColorCube(size: Int, adjustments: HSLAdjustments) -> Data {
        var cubeData = [Float]()
        cubeData.reserveCapacity(size * size * size * 4)

        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    // Normalize to 0...1
                    let rf = Float(r) / Float(size - 1)
                    let gf = Float(g) / Float(size - 1)
                    let bf = Float(b) / Float(size - 1)

                    // Convert RGB to HSL
                    var (h, s, l) = rgbToHSL(r: rf, g: gf, b: bf)

                    // Determine which color channel this hue belongs to and get adjustments
                    let (hueShift, satShift, lumShift) = getChannelAdjustments(hue: h, adjustments: adjustments)

                    // Apply adjustments
                    h = fmod(h + hueShift / 360.0 + 1.0, 1.0)  // Hue shift in 0...1 range
                    s = max(0, min(1, s + satShift / 100.0))   // Saturation adjustment
                    l = max(0, min(1, l + lumShift / 100.0))   // Luminance adjustment

                    // Convert back to RGB
                    let (rOut, gOut, bOut) = hslToRGB(h: h, s: s, l: l)

                    cubeData.append(rOut)
                    cubeData.append(gOut)
                    cubeData.append(bOut)
                    cubeData.append(1.0)  // Alpha
                }
            }
        }

        return Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float>.size)
    }

    /// Get HSL adjustments for a specific hue based on which color channel it belongs to
    private func getChannelAdjustments(hue: Float, adjustments: HSLAdjustments) -> (Float, Float, Float) {
        // Define hue ranges for each channel (0-1 range, where 0 and 1 are both red)
        // Red: 0.0 (345°-15° = 0.958-0.042)
        // Orange: 0.083 (15°-45° = 0.042-0.125)
        // Yellow: 0.167 (45°-75° = 0.125-0.208)
        // Green: 0.333 (75°-165° = 0.208-0.458)
        // Aqua: 0.5 (165°-195° = 0.458-0.542)
        // Blue: 0.667 (195°-255° = 0.542-0.708)
        // Purple: 0.75 (255°-285° = 0.708-0.792)
        // Magenta: 0.833 (285°-345° = 0.792-0.958)

        let channels: [(center: Float, channel: HSLAdjustments.HSLChannel)] = [
            (0.0, adjustments.red),      // Red at 0°
            (0.083, adjustments.orange), // Orange at 30°
            (0.167, adjustments.yellow), // Yellow at 60°
            (0.333, adjustments.green),  // Green at 120°
            (0.5, adjustments.aqua),     // Aqua at 180°
            (0.667, adjustments.blue),   // Blue at 240°
            (0.75, adjustments.purple),  // Purple at 270°
            (0.833, adjustments.magenta), // Magenta at 300°
            (1.0, adjustments.red)       // Wrap around to red
        ]

        // Find the two closest channels and interpolate
        var lowerChannel = channels[0]
        var upperChannel = channels[0]

        for i in 0..<(channels.count - 1) {
            if hue >= channels[i].center && hue < channels[i + 1].center {
                lowerChannel = channels[i]
                upperChannel = channels[i + 1]
                break
            }
        }

        // Calculate interpolation factor
        let range = upperChannel.center - lowerChannel.center
        let t = range > 0 ? (hue - lowerChannel.center) / range : 0

        // Smooth interpolation using smoothstep for better transitions
        let smoothT = t * t * (3.0 - 2.0 * t)

        // Interpolate adjustments
        let hueShift = lowerChannel.channel.hue + smoothT * (upperChannel.channel.hue - lowerChannel.channel.hue)
        let satShift = lowerChannel.channel.saturation + smoothT * (upperChannel.channel.saturation - lowerChannel.channel.saturation)
        let lumShift = lowerChannel.channel.luminance + smoothT * (upperChannel.channel.luminance - lowerChannel.channel.luminance)

        return (hueShift, satShift, lumShift)
    }

    /// Convert RGB to HSL
    private func rgbToHSL(r: Float, g: Float, b: Float) -> (h: Float, s: Float, l: Float) {
        let maxC = max(r, max(g, b))
        let minC = min(r, min(g, b))
        let delta = maxC - minC

        var h: Float = 0
        var s: Float = 0
        let l = (maxC + minC) / 2.0

        if delta > 0.0001 {
            s = delta / (1.0 - abs(2.0 * l - 1.0))

            if maxC == r {
                h = fmod((g - b) / delta, 6.0)
            } else if maxC == g {
                h = (b - r) / delta + 2.0
            } else {
                h = (r - g) / delta + 4.0
            }
            h /= 6.0
            if h < 0 { h += 1.0 }
        }

        return (h, s, l)
    }

    /// Convert HSL to RGB
    private func hslToRGB(h: Float, s: Float, l: Float) -> (r: Float, g: Float, b: Float) {
        if s < 0.0001 {
            return (l, l, l)
        }

        let c = (1.0 - abs(2.0 * l - 1.0)) * s
        let x = c * (1.0 - abs(fmod(h * 6.0, 2.0) - 1.0))
        let m = l - c / 2.0

        var r: Float = 0, g: Float = 0, b: Float = 0

        let hue6 = h * 6.0
        if hue6 < 1.0 {
            r = c; g = x; b = 0
        } else if hue6 < 2.0 {
            r = x; g = c; b = 0
        } else if hue6 < 3.0 {
            r = 0; g = c; b = x
        } else if hue6 < 4.0 {
            r = 0; g = x; b = c
        } else if hue6 < 5.0 {
            r = x; g = 0; b = c
        } else {
            r = c; g = 0; b = x
        }

        return (r + m, g + m, b + m)
    }

    /// Apply split tone effect - colorize highlights and shadows separately
    private func applySplitTone(to image: CIImage, data: SplitToneData) -> CIImage {
        // Convert hue from degrees (0-360) to 0-1 range
        let highlightHue = data.highlightHue / 360.0
        let shadowHue = data.shadowHue / 360.0

        // Convert saturation from 0-100 to 0-1
        let highlightSat = data.highlightSaturation / 100.0
        let shadowSat = data.shadowSaturation / 100.0

        // Convert balance from -100...+100 to 0...1 (0.5 = neutral)
        let balance = (data.balance + 100.0) / 200.0

        // Create highlight tint color
        let (hR, hG, hB) = hslToRGB(h: highlightHue, s: highlightSat, l: 0.5)
        let highlightColor = CIColor(red: CGFloat(hR), green: CGFloat(hG), blue: CGFloat(hB))

        // Create shadow tint color
        let (sR, sG, sB) = hslToRGB(h: shadowHue, s: shadowSat, l: 0.5)
        let shadowColor = CIColor(red: CGFloat(sR), green: CGFloat(sG), blue: CGFloat(sB))

        // Create luminance mask from input image
        guard let grayscale = CIFilter(name: "CIPhotoEffectMono") else {
            return image
        }
        grayscale.setValue(image, forKey: kCIInputImageKey)

        guard let luminanceMask = grayscale.outputImage else {
            return image
        }

        // Create solid color images for tints
        guard let highlightColorGen = CIFilter(name: "CIConstantColorGenerator"),
              let shadowColorGen = CIFilter(name: "CIConstantColorGenerator") else {
            return image
        }

        highlightColorGen.setValue(highlightColor, forKey: kCIInputColorKey)
        shadowColorGen.setValue(shadowColor, forKey: kCIInputColorKey)

        guard let highlightTint = highlightColorGen.outputImage?.cropped(to: image.extent),
              let shadowTint = shadowColorGen.outputImage?.cropped(to: image.extent) else {
            return image
        }

        // Apply highlight tint using soft light blend, masked by luminance
        guard let highlightBlend = CIFilter(name: "CISoftLightBlendMode") else {
            return image
        }
        highlightBlend.setValue(highlightTint, forKey: kCIInputImageKey)
        highlightBlend.setValue(image, forKey: kCIInputBackgroundImageKey)

        guard let highlightResult = highlightBlend.outputImage else {
            return image
        }

        // Apply shadow tint
        guard let shadowBlend = CIFilter(name: "CISoftLightBlendMode") else {
            return image
        }
        shadowBlend.setValue(shadowTint, forKey: kCIInputImageKey)
        shadowBlend.setValue(image, forKey: kCIInputBackgroundImageKey)

        guard let shadowResult = shadowBlend.outputImage else {
            return image
        }

        // Use luminance to blend between shadow and highlight results
        // Brighter areas get highlight tint, darker areas get shadow tint
        guard let blendMask = CIFilter(name: "CIBlendWithMask") else {
            return image
        }

        // Adjust luminance mask based on balance
        var adjustedMask = luminanceMask
        if balance != 0.5 {
            // Shift the mask to favor highlights or shadows
            guard let levels = CIFilter(name: "CIColorControls") else {
                return image
            }
            let brightnessAdjust = (balance - 0.5) * 0.5  // -0.25 to +0.25
            levels.setValue(luminanceMask, forKey: kCIInputImageKey)
            levels.setValue(brightnessAdjust, forKey: kCIInputBrightnessKey)
            levels.setValue(1.5, forKey: kCIInputContrastKey)  // Increase contrast for sharper split
            adjustedMask = levels.outputImage ?? luminanceMask
        }

        blendMask.setValue(highlightResult, forKey: kCIInputImageKey)
        blendMask.setValue(shadowResult, forKey: kCIInputBackgroundImageKey)
        blendMask.setValue(adjustedMask, forKey: kCIInputMaskImageKey)

        guard let splitToned = blendMask.outputImage else {
            return image
        }

        // Final blend with original based on overall intensity
        // Use average of saturation values as intensity indicator
        let intensity = (highlightSat + shadowSat) / 2.0
        if intensity < 0.01 {
            return image
        }

        return blendImages(base: image, overlay: splitToned, amount: min(intensity * 2.0, 1.0))
    }

    /// Apply film grain effect using Metal kernel
    private func applyGrain(to image: CIImage, data: GrainData) -> CIImage {
        // Convert parameters from UI range to Metal kernel range
        // amount: 0...100 → 0...1
        // size: 0...1 → 0.5...4.0 (inverted - larger value = smaller grain)
        // roughness: 0...1 → 0...1 (direct mapping)
        let amount = data.amount / 100.0
        let size = 0.5 + (1.0 - data.size) * 3.5  // Invert: 0 → 4.0 (large grain), 1 → 0.5 (fine grain)
        let roughness = data.roughness
        let monochromatic = data.monochromatic

        do {
            return try MetalFilterLoader.shared.applyGrain(
                to: image,
                amount: amount,
                size: size,
                roughness: roughness,
                monochromatic: monochromatic,
                time: 0.0  // Static grain for photos
            )
        } catch {
            print("FilterEngine: Failed to apply grain: \(error)")
            return image
        }
    }

    /// Apply bloom/glow effect using Metal kernel
    private func applyBloom(to image: CIImage, data: BloomData) -> CIImage {
        // Convert parameters from UI range to Metal kernel range
        // intensity: 0...100 → 0...2.0
        // radius: 0...1 → 1.0...50.0
        // threshold: 0...1 → direct mapping
        let intensity = data.intensity / 100.0 * 2.0
        let radius = 1.0 + data.radius * 49.0  // Map 0...1 to 1...50
        let threshold = data.threshold

        do {
            return try MetalFilterLoader.shared.applyBloom(
                to: image,
                intensity: intensity,
                radius: radius,
                threshold: threshold
            )
        } catch {
            print("FilterEngine: Failed to apply bloom: \(error)")
            return image
        }
    }

    /// Apply halation effect (film red glow) using Metal kernel
    private func applyHalation(to image: CIImage, data: HalationData) -> CIImage {
        // Convert parameters from UI range to Metal kernel range
        // intensity: 0...100 → 0...1.0
        // hue: 0...360 → 0...1.0 (normalized hue)
        // spread: 0...1 → 1.0...50.0
        let intensity = data.intensity / 100.0
        let hue = data.hue / 360.0  // Normalize 0...360 to 0...1
        let spread = 1.0 + data.spread * 49.0  // Map 0...1 to 1...50

        do {
            return try MetalFilterLoader.shared.applyHalation(
                to: image,
                intensity: intensity,
                hue: hue,
                spread: spread
            )
        } catch {
            print("FilterEngine: Failed to apply halation: \(error)")
            return image
        }
    }

    // MARK: - Helper Methods

    /// Get or create a cached filter
    private func getCachedFilter(name: String) -> CIFilter? {
        if let cached = filterCache[name] {
            return cached
        }

        guard let filter = CIFilter(name: name) else {
            return nil
        }

        filterCache[name] = filter
        return filter
    }

    /// Extract exactly 5 points from a curve for CIToneCurve
    private func getCurvePoints(from points: [ToneCurveData.CurvePoint]) -> [(x: Float, y: Float)] {
        // CIToneCurve requires exactly 5 points at specific x positions
        let defaultPoints: [(x: Float, y: Float)] = [
            (0.0, 0.0),
            (0.25, 0.25),
            (0.5, 0.5),
            (0.75, 0.75),
            (1.0, 1.0)
        ]

        guard points.count >= 2 else {
            return defaultPoints
        }

        // If we have exactly 5 points, use them directly
        if points.count == 5 {
            return points.map { (x: $0.x, y: $0.y) }
        }

        // Otherwise, interpolate to get 5 points at standard positions
        var result: [(x: Float, y: Float)] = []
        let xPositions: [Float] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for x in xPositions {
            // Find surrounding points for interpolation
            var lowerIndex = 0
            for (index, point) in points.enumerated() {
                if point.x <= x {
                    lowerIndex = index
                } else {
                    break
                }
            }

            let upperIndex = min(lowerIndex + 1, points.count - 1)

            if lowerIndex == upperIndex {
                result.append((x: x, y: points[lowerIndex].y))
            } else {
                let lower = points[lowerIndex]
                let upper = points[upperIndex]
                let t = (x - lower.x) / (upper.x - lower.x)
                let y = lower.y + t * (upper.y - lower.y)
                result.append((x: x, y: y))
            }
        }

        return result
    }

    /// Blend two images together
    private func blendImages(base: CIImage, overlay: CIImage, amount: Float) -> CIImage {
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            return base
        }

        // Create a constant alpha mask
        guard let maskGenerator = CIFilter(name: "CIConstantColorGenerator") else {
            return base
        }

        let maskColor = CIColor(red: CGFloat(amount), green: CGFloat(amount), blue: CGFloat(amount), alpha: 1.0)
        maskGenerator.setValue(maskColor, forKey: kCIInputColorKey)

        guard let mask = maskGenerator.outputImage?.cropped(to: base.extent) else {
            return base
        }

        blendFilter.setValue(base, forKey: kCIInputImageKey)
        blendFilter.setValue(overlay, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)

        return blendFilter.outputImage ?? base
    }

    /// Clear the filter cache
    func clearCache() {
        filterCache.removeAll()
    }
}

// MARK: - Shared Instance

@available(iOS 17.0, *)
extension FilterEngine {
    /// Shared singleton instance for app-wide filter processing
    static let shared = FilterEngine()
}

// MARK: - Convenience Extensions

@available(iOS 17.0, *)
extension FilterEngine {

    /// Process an image with parameters and render to CGImage in one call
    func process(_ image: CIImage, with parameters: FilterParameters) -> CGImage? {
        let processed = apply(parameters, to: image)
        return render(processed)
    }

    /// Process a CGImage with a filter preset and return CGImage
    func process(cgImage: CGImage, with preset: FilterPreset) async -> CGImage? {
        let ciImage = CIImage(cgImage: cgImage)
        let processed = await apply(preset, to: ciImage)
        return render(processed)
    }

    /// Create a CIImage from a CGImage
    static func createCIImage(from cgImage: CGImage) -> CIImage {
        return CIImage(cgImage: cgImage)
    }

    /// Create a CIImage from image data
    static func createCIImage(from data: Data) -> CIImage? {
        return CIImage(data: data)
    }
}
