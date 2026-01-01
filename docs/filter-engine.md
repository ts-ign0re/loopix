# Filter Engine Architecture

## Overview

`FilterEngine` is an actor-based GPU image processing engine using Core Image. It handles all filter operations including exposure, color adjustments, film simulation (CLUT), and effects.

---

## Core Configuration

```swift
// CIContext optimized for GPU rendering
let context = CIContext(options: [
    .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,  // Linear for accurate math
    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,         // sRGB for display
    .useSoftwareRenderer: false,                                        // GPU only
    .cacheIntermediates: true                                           // Cache for performance
])
```

---

## Filter Parameters

All adjustments are stored in `FilterParameters`:

```swift
struct FilterParameters: Codable, Hashable, Sendable {
    // Light
    var exposure: Float = 0      // -2...+2 EV
    var contrast: Float = 0      // -100...+100
    var highlights: Float = 0    // -100...+100
    var shadows: Float = 0       // -100...+100
    var whites: Float = 0        // -100...+100
    var blacks: Float = 0        // -100...+100

    // Color
    var temperature: Float = 0   // -100...+100
    var tint: Float = 0          // -100...+100
    var saturation: Float = 0    // -100...+100
    var vibrance: Float = 0      // -100...+100

    // HSL (8 channels)
    var hsl: HSLAdjustments = .identity

    // Effects
    var clarity: Float = 0       // -100...+100
    var grain: GrainData = .none
    var vignette: VignetteData = .none
    var fade: Float = 0          // 0...100
    var bloom: BloomData = .none
    var halation: HalationData = .none

    // Sharpening
    var sharpness: Float = 0     // 0...100
    var sharpenRadius: Float = 1.0

    // Transform
    var rotation: Float = 0      // degrees
    var cropRect: CGRect?        // normalized or pixel coordinates
}
```

---

## Processing Pipeline

Filters are applied in a specific order for color accuracy:

```swift
func apply(_ params: FilterParameters, to image: CIImage) -> CIImage {
    var result = image
    let originalExtent = image.extent

    // 0. Crop (first, to reduce processing area)
    if let cropRect = params.cropRect {
        result = result.cropped(to: cropRect)
    }

    // 1. Exposure & Contrast
    result = applyExposure(params.exposure, to: result)
    result = applyContrast(params.contrast, to: result)

    // 2. Tone Curve
    if params.toneCurve != .identity {
        result = applyToneCurve(params.toneCurve, to: result)
    }

    // 3. Highlights & Shadows
    result = applyHighlightsShadows(highlights: params.highlights, shadows: params.shadows, to: result)

    // 4. Whites & Blacks
    result = applyWhitesBlacks(whites: params.whites, blacks: params.blacks, to: result)

    // 5. White Balance
    result = applyWhiteBalance(temperature: params.temperature, tint: params.tint, to: result)

    // 6. HSL Adjustments
    if params.hsl != .identity {
        result = applyHSL(params.hsl, to: result)
    }

    // 7. Saturation & Vibrance
    result = applySaturation(params.saturation, to: result)
    result = applyVibrance(params.vibrance, to: result)

    // 8. Split Tone
    if params.splitTone != .identity {
        result = applySplitTone(params.splitTone, to: result)
    }

    // 9. Clarity (local contrast)
    if params.clarity != 0 {
        result = applyClarity(params.clarity, to: result)
    }

    // 10. Sharpening
    if params.sharpness > 0 {
        result = applySharpening(amount: params.sharpness, radius: params.sharpenRadius, to: result)
    }

    // 11. Effects (artistic, applied last)
    if params.fade > 0 { result = applyFade(params.fade, to: result) }
    if params.grain != .none { result = applyGrain(params.grain, to: result) }
    if params.bloom != .none { result = applyBloom(params.bloom, to: result) }
    if params.halation != .none { result = applyHalation(params.halation, to: result) }
    if params.vignette != .none { result = applyVignette(params.vignette, to: result) }

    return result
}
```

---

## HALD CLUT (Film Simulation)

Film presets use HALD Color Lookup Tables for accurate color grading:

### Loading
```swift
// HALDCLUTLoader extracts 3D LUT data from HALD images
let (filter, dimension) = try await clutLoader.loadCLUT(from: url)
// Returns CIColorCubeWithColorSpace filter
```

### Application
```swift
func applyCLUT(at path: String, to image: CIImage, intensity: Float = 100) async -> CIImage {
    let originalExtent = image.extent

    // Load or get cached filter
    let filter = clutFilterCache[path] ?? loadFilter(path)

    // Apply
    filter.setValue(image, forKey: kCIInputImageKey)
    guard let output = filter.outputImage else { return image }

    // IMPORTANT: Crop to original extent (CLUT can change image size)
    let croppedOutput = output.cropped(to: originalExtent)

    // Blend with intensity
    if intensity < 100 {
        return blendImages(base: image, overlay: croppedOutput, amount: intensity / 100.0)
    }

    return croppedOutput
}
```

### HALD Format
- Square image where dimension³ = width
- Common sizes: 64x64 (4³), 512x512 (8³), 4096x4096 (16³)
- Each pixel maps input RGB to output RGB

---

## Core Image Filters Used

| Effect | CIFilter |
|--------|----------|
| Exposure | `CIExposureAdjust` |
| Contrast | `CIColorControls` |
| Highlights/Shadows | `CIHighlightShadowAdjust` |
| Temperature/Tint | `CITemperatureAndTint` |
| Saturation | `CIColorControls` |
| Vibrance | `CIVibrance` |
| Tone Curve | `CIToneCurve` |
| Sharpening | `CISharpenLuminance` + `CIUnsharpMask` |
| Vignette | `CIVignette` |
| Grain | `CIRandomGenerator` + blend |
| Bloom | `CIBloom` |
| CLUT | `CIColorCubeWithColorSpace` |

---

## Blending

Used for intensity control and compositing:

```swift
func blendImages(base: CIImage, overlay: CIImage, amount: Float) -> CIImage {
    // CIDissolveTransition for smooth blending
    let blend = CIFilter.dissolveTransition()
    blend.inputImage = base
    blend.targetImage = overlay
    blend.time = amount  // 0.0 = base, 1.0 = overlay
    return blend.outputImage ?? base
}
```

---

## Performance Considerations

1. **Actor isolation:** Thread-safe concurrent access
2. **Filter caching:** Reuse CIFilter instances
3. **CLUT caching:** Load once, apply many times
4. **Intermediate caching:** CIContext caches intermediate results
5. **Extent preservation:** Always crop output to original extent

---

## Metal Kernels

Custom Metal kernels for effects not available in Core Image:

```
FilmBox/Core/Metal/Kernels/
├── GrainKernel.metal      # Realistic film grain
├── HalationKernel.metal   # Film halation effect
├── BloomKernel.metal      # Soft glow
└── VignetteKernel.metal   # Custom vignette
```

Loaded via `MetalFilterLoader`:
```swift
let kernel = try CIColorKernel(source: metalSource)
```
