# FilmBox Development Session History

## Date: 2024-12-31

## Overview
This session focused on implementing missing filter effects and UI controls for the FilmBox iOS photo editor app.

---

## Tasks Completed

### 1. Filter Implementation Analysis
Analyzed the codebase to identify what was implemented vs missing:

**Already Implemented:**
- Exposure (CIExposureAdjust)
- Contrast (CIColorControls)
- Saturation (CIColorControls)
- Temperature (CITemperatureAndTint)
- Vignette (CIVignette)
- Sharpness (CISharpenLuminance)

**Missing (identified for implementation):**
- Highlights & Shadows
- Whites & Blacks
- Tint
- Vibrance
- Clarity (local contrast)
- Fade
- Grain
- Bloom
- Halation
- Sharpen Radius parameter

---

### 2. EditorViewModel Filter Implementations

Added comprehensive filter implementations to `EditorViewModel.swift`:

#### Whites & Blacks (using CIToneCurve)
```swift
private func applyWhites(_ amount: Float, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIToneCurve") else { return image }
    filter.setValue(image, forKey: kCIInputImageKey)

    let adjustment = amount / 100.0 * 0.15

    filter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
    filter.setValue(CIVector(x: 0.25, y: 0.25), forKey: "inputPoint1")
    filter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
    filter.setValue(CIVector(x: 0.75, y: 0.75 + CGFloat(adjustment * 0.5)), forKey: "inputPoint3")
    filter.setValue(CIVector(x: 1.0, y: min(1.0, max(0.5, 1.0 + CGFloat(adjustment)))), forKey: "inputPoint4")

    return filter.outputImage ?? image
}

private func applyBlacks(_ amount: Float, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIToneCurve") else { return image }
    filter.setValue(image, forKey: kCIInputImageKey)

    let adjustment = amount / 100.0 * 0.15

    filter.setValue(CIVector(x: 0.0, y: max(0.0, min(0.5, CGFloat(adjustment)))), forKey: "inputPoint0")
    filter.setValue(CIVector(x: 0.25, y: 0.25 + CGFloat(adjustment * 0.5)), forKey: "inputPoint1")
    filter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
    filter.setValue(CIVector(x: 0.75, y: 0.75), forKey: "inputPoint3")
    filter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")

    return filter.outputImage ?? image
}
```

#### Clarity (Local Contrast using CIUnsharpMask)
```swift
private func applyClarity(_ amount: Float, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }

    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(20.0, forKey: kCIInputRadiusKey)  // Large radius for local contrast
    filter.setValue(amount / 100.0 * 0.8, forKey: kCIInputIntensityKey)

    return filter.outputImage ?? image
}
```

#### Fade (Matte Film Look using CIColorMatrix)
```swift
private func applyFade(_ amount: Float, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIColorMatrix") else { return image }

    filter.setValue(image, forKey: kCIInputImageKey)
    let fadeAmount = amount / 100.0 * 0.15

    filter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
    filter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
    filter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
    filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    filter.setValue(CIVector(x: CGFloat(fadeAmount), y: CGFloat(fadeAmount), z: CGFloat(fadeAmount), w: 0), forKey: "inputBiasVector")

    return filter.outputImage ?? image
}
```

#### Sharpness with Radius (CIUnsharpMask)
```swift
private func applySharpness(amount: Float, radius: Float, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }

    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(amount / 100.0 * 2.5, forKey: kCIInputIntensityKey)
    filter.setValue(CGFloat(radius), forKey: kCIInputRadiusKey)

    return filter.outputImage ?? image
}
```

#### Vignette (CIVignetteEffect with feather)
```swift
private func applyVignette(_ vignette: VignetteData, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIVignetteEffect") else { return image }

    filter.setValue(image, forKey: kCIInputImageKey)
    let center = CIVector(x: image.extent.midX, y: image.extent.midY)
    filter.setValue(center, forKey: kCIInputCenterKey)
    filter.setValue(vignette.amount / 100.0 * 1.5, forKey: kCIInputIntensityKey)
    let maxRadius = min(image.extent.width, image.extent.height) / 2
    filter.setValue(maxRadius * CGFloat(vignette.midpoint), forKey: kCIInputRadiusKey)
    filter.setValue(CGFloat(vignette.feather), forKey: "inputFalloff")

    return filter.outputImage ?? image
}
```

#### Grain (Film Grain using CIRandomGenerator + Overlay Blend)
```swift
private func applyGrain(_ grain: GrainData, to image: CIImage) -> CIImage {
    let extent = image.extent

    guard let noiseFilter = CIFilter(name: "CIRandomGenerator"),
          let noiseImage = noiseFilter.outputImage else { return image }

    let grainScale = CGFloat(3.0 + (grain.size * 7.0))
    var grainNoise = noiseImage.transformed(by: CGAffineTransform(scaleX: grainScale, y: grainScale))
    grainNoise = grainNoise.cropped(to: extent)

    // Convert to grayscale
    guard let grayscaleFilter = CIFilter(name: "CIColorMatrix") else { return image }
    grayscaleFilter.setValue(grainNoise, forKey: kCIInputImageKey)
    grayscaleFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputRVector")
    grayscaleFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputGVector")
    grayscaleFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputBVector")
    grayscaleFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    grayscaleFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

    guard var grayNoise = grayscaleFilter.outputImage else { return image }

    // Blur for organic feel
    let blurRadius = 0.5 + (grain.size * 1.0)
    if let blurFilter = CIFilter(name: "CIGaussianBlur") {
        blurFilter.setValue(grayNoise, forKey: kCIInputImageKey)
        blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
        if let blurred = blurFilter.outputImage {
            grayNoise = blurred.cropped(to: extent)
        }
    }

    let intensity = grain.amount / 100.0

    // Adjust contrast and center around middle gray
    guard let adjustFilter = CIFilter(name: "CIColorMatrix") else { return image }
    adjustFilter.setValue(grayNoise, forKey: kCIInputImageKey)

    let grainStrength = CGFloat(intensity * 0.4)
    adjustFilter.setValue(CIVector(x: grainStrength, y: 0, z: 0, w: 0), forKey: "inputRVector")
    adjustFilter.setValue(CIVector(x: 0, y: grainStrength, z: 0, w: 0), forKey: "inputGVector")
    adjustFilter.setValue(CIVector(x: 0, y: 0, z: grainStrength, w: 0), forKey: "inputBVector")
    adjustFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    let bias = CGFloat(0.5 - (grainStrength * 0.5))
    adjustFilter.setValue(CIVector(x: bias, y: bias, z: bias, w: 0), forKey: "inputBiasVector")

    guard let adjustedNoise = adjustFilter.outputImage else { return image }

    // Overlay blend for film-like grain
    guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else { return image }
    blendFilter.setValue(adjustedNoise, forKey: kCIInputImageKey)
    blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

    return blendFilter.outputImage ?? image
}
```

#### Bloom (CIBloom)
```swift
private func applyBloom(_ bloom: BloomData, to image: CIImage) -> CIImage {
    guard let filter = CIFilter(name: "CIBloom") else { return image }

    filter.setValue(image, forKey: kCIInputImageKey)
    filter.setValue(bloom.intensity / 100.0 * 2.0, forKey: kCIInputIntensityKey)
    filter.setValue(CGFloat(bloom.radius * 50.0), forKey: kCIInputRadiusKey)

    return filter.outputImage ?? image
}
```

#### Halation (Film Halation Effect)
```swift
private func applyHalation(_ halation: HalationData, to image: CIImage) -> CIImage {
    let extent = image.extent

    // Extract bright areas
    guard let colorClampFilter = CIFilter(name: "CIColorClamp") else { return image }
    colorClampFilter.setValue(image, forKey: kCIInputImageKey)
    colorClampFilter.setValue(CIVector(x: 0.7, y: 0.7, z: 0.7, w: 0), forKey: "inputMinComponents")
    colorClampFilter.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")

    guard let brightAreas = colorClampFilter.outputImage else { return image }

    // Tint bright areas with halation color
    guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else { return image }
    colorMatrixFilter.setValue(brightAreas, forKey: kCIInputImageKey)

    let hue = halation.hue / 360.0
    let r: CGFloat = max(0, min(1, 1.0 - abs(CGFloat(hue) * 6.0 - 3.0) + 1.0))
    let g: CGFloat = max(0, min(1, 2.0 - abs(CGFloat(hue) * 6.0 - 2.0)))
    let b: CGFloat = max(0, min(1, 2.0 - abs(CGFloat(hue) * 6.0 - 4.0)))

    colorMatrixFilter.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
    colorMatrixFilter.setValue(CIVector(x: 0, y: g * 0.3, z: 0, w: 0), forKey: "inputGVector")
    colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: b * 0.1, w: 0), forKey: "inputBVector")
    colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

    guard let tintedBright = colorMatrixFilter.outputImage else { return image }

    // Blur the tinted highlights
    guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
    blurFilter.setValue(tintedBright, forKey: kCIInputImageKey)
    let blurRadius = 5.0 + halation.spread * 45.0
    blurFilter.setValue(CGFloat(blurRadius), forKey: kCIInputRadiusKey)

    guard let blurredHalation = blurFilter.outputImage?.cropped(to: extent) else { return image }

    // Adjust intensity
    guard let opacityFilter = CIFilter(name: "CIColorMatrix") else { return image }
    opacityFilter.setValue(blurredHalation, forKey: kCIInputImageKey)
    let opacity = halation.intensity / 100.0 * 0.7
    opacityFilter.setValue(CIVector(x: CGFloat(opacity), y: 0, z: 0, w: 0), forKey: "inputRVector")
    opacityFilter.setValue(CIVector(x: 0, y: CGFloat(opacity), z: 0, w: 0), forKey: "inputGVector")
    opacityFilter.setValue(CIVector(x: 0, y: 0, z: CGFloat(opacity), w: 0), forKey: "inputBVector")
    opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
    opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

    guard let adjustedHalation = opacityFilter.outputImage else { return image }

    // Blend with original using screen blend
    guard let blendFilter = CIFilter(name: "CIScreenBlendMode") else { return image }
    blendFilter.setValue(adjustedHalation, forKey: kCIInputImageKey)
    blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

    return blendFilter.outputImage ?? image
}
```

#### Updated applyFilters Method
```swift
private func applyFilters(to image: CIImage, parameters: FilterParameters) async -> CIImage {
    var output = image

    // === LIGHT ADJUSTMENTS ===
    if parameters.exposure != 0 { /* CIExposureAdjust */ }
    if parameters.contrast != 0 { /* CIColorControls */ }
    if parameters.highlights != 0 || parameters.shadows != 0 { /* CIHighlightShadowAdjust */ }
    if parameters.whites != 0 { output = applyWhites(parameters.whites, to: output) }
    if parameters.blacks != 0 { output = applyBlacks(parameters.blacks, to: output) }

    // === COLOR ADJUSTMENTS ===
    if parameters.temperature != 0 || parameters.tint != 0 { /* CITemperatureAndTint */ }
    if parameters.saturation != 0 { /* CIColorControls */ }
    if parameters.vibrance != 0 { /* CIVibrance */ }

    // === EFFECTS ===
    if parameters.clarity != 0 { output = applyClarity(parameters.clarity, to: output) }
    if parameters.fade > 0 { output = applyFade(parameters.fade, to: output) }
    if parameters.sharpness > 0 { output = applySharpness(...) }
    if parameters.vignette.isActive { output = applyVignette(...) }
    if parameters.grain.isActive { output = applyGrain(...) }
    if parameters.bloom.isActive { output = applyBloom(...) }
    if parameters.halation.isActive { output = applyHalation(...) }

    return output
}
```

---

### 3. EditorView UI Updates

Updated `EditorView.swift` Adjust panel to include more sliders:

**Light Section:**
- Exposure (-2 to +2 EV)
- Contrast (-100 to +100)
- Highlights (-100 to +100)
- Shadows (-100 to +100)
- Whites (-100 to +100)
- Blacks (-100 to +100)

**Color Section:**
- Temperature (-100 to +100)
- Tint (-100 to +100)
- Saturation (-100 to +100)
- Vibrance (-100 to +100)

**Effects Panel (planned):**
- Detail: Clarity, Sharpness
- Film Effects: Grain, Fade, Vignette, Bloom, Halation

---

## Issues Encountered

1. **Files Deleted**: During the session, the FilmBox source directory was accidentally deleted. Had to restore using `git restore FilmBox/`

2. **Glob Tool Issues**: The Glob tool sometimes failed to find files that existed, requiring fallback to `find` command

---

## Files Modified

1. `FilmBox/Features/Editor/EditorViewModel.swift` - Added all filter implementations
2. `FilmBox/Features/Editor/EditorView.swift` - Added more sliders to Adjust panel

---

## Pending Work

- [ ] Re-apply all filter implementations (files were restored to original state)
- [ ] Complete Effects panel UI with all sliders
- [ ] Build and test all filters work correctly
- [ ] Add Tone Curve editor
- [ ] Add HSL adjustments
- [ ] Add Split Tone
- [ ] Add Skin Tone controls

---

## CHANGES TO RE-APPLY

### File 1: `FilmBox/Features/Editor/EditorViewModel.swift`

**REPLACE the entire `applyFilters` method (around line 320-382) with this:**

```swift
    /// Apply filter parameters to an image
    private func applyFilters(to image: CIImage, parameters: FilterParameters) async -> CIImage {
        var output = image

        // === LIGHT ADJUSTMENTS ===

        // Apply exposure adjustment
        if parameters.exposure != 0 {
            if let filter = CIFilter(name: "CIExposureAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(parameters.exposure, forKey: kCIInputEVKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply contrast adjustment
        if parameters.contrast != 0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(1.0 + (parameters.contrast / 100.0), forKey: kCIInputContrastKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply highlights and shadows adjustment
        if parameters.highlights != 0 || parameters.shadows != 0 {
            if let filter = CIFilter(name: "CIHighlightShadowAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                let highlightAmount = 1.0 - (parameters.highlights / 100.0)
                filter.setValue(highlightAmount, forKey: "inputHighlightAmount")
                let shadowAmount = parameters.shadows / 100.0
                filter.setValue(shadowAmount, forKey: "inputShadowAmount")
                output = filter.outputImage ?? output
            }
        }

        // Apply whites adjustment
        if parameters.whites != 0 {
            output = applyWhites(parameters.whites, to: output)
        }

        // Apply blacks adjustment
        if parameters.blacks != 0 {
            output = applyBlacks(parameters.blacks, to: output)
        }

        // === COLOR ADJUSTMENTS ===

        // Apply temperature and tint adjustment
        if parameters.temperature != 0 || parameters.tint != 0 {
            if let filter = CIFilter(name: "CITemperatureAndTint") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
                let targetTemp = 6500 + (parameters.temperature * 30)
                filter.setValue(CIVector(x: CGFloat(targetTemp), y: CGFloat(parameters.tint)), forKey: "inputTargetNeutral")
                output = filter.outputImage ?? output
            }
        }

        // Apply saturation adjustment
        if parameters.saturation != 0 {
            if let filter = CIFilter(name: "CIColorControls") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(1.0 + (parameters.saturation / 100.0), forKey: kCIInputSaturationKey)
                output = filter.outputImage ?? output
            }
        }

        // Apply vibrance adjustment
        if parameters.vibrance != 0 {
            if let filter = CIFilter(name: "CIVibrance") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(parameters.vibrance / 100.0, forKey: "inputAmount")
                output = filter.outputImage ?? output
            }
        }

        // === EFFECTS ===

        // Apply clarity (local contrast)
        if parameters.clarity != 0 {
            output = applyClarity(parameters.clarity, to: output)
        }

        // Apply fade (lifts blacks for matte film look)
        if parameters.fade > 0 {
            output = applyFade(parameters.fade, to: output)
        }

        // Apply sharpness with radius
        if parameters.sharpness > 0 {
            output = applySharpness(amount: parameters.sharpness, radius: parameters.sharpenRadius, to: output)
        }

        // Apply vignette
        if parameters.vignette.isActive {
            output = applyVignette(parameters.vignette, to: output)
        }

        // Apply grain
        if parameters.grain.isActive {
            output = applyGrain(parameters.grain, to: output)
        }

        // Apply bloom
        if parameters.bloom.isActive {
            output = applyBloom(parameters.bloom, to: output)
        }

        // Apply halation
        if parameters.halation.isActive {
            output = applyHalation(parameters.halation, to: output)
        }

        return output
    }
```

**ADD these helper methods BEFORE the `// MARK: - Save` section:**

```swift
    // MARK: - Whites & Blacks

    private func applyWhites(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIToneCurve") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)

        let adjustment = amount / 100.0 * 0.15

        filter.setValue(CIVector(x: 0.0, y: 0.0), forKey: "inputPoint0")
        filter.setValue(CIVector(x: 0.25, y: 0.25), forKey: "inputPoint1")
        filter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        filter.setValue(CIVector(x: 0.75, y: 0.75 + CGFloat(adjustment * 0.5)), forKey: "inputPoint3")
        filter.setValue(CIVector(x: 1.0, y: min(1.0, max(0.5, 1.0 + CGFloat(adjustment)))), forKey: "inputPoint4")

        return filter.outputImage ?? image
    }

    private func applyBlacks(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIToneCurve") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)

        let adjustment = amount / 100.0 * 0.15

        filter.setValue(CIVector(x: 0.0, y: max(0.0, min(0.5, CGFloat(adjustment)))), forKey: "inputPoint0")
        filter.setValue(CIVector(x: 0.25, y: 0.25 + CGFloat(adjustment * 0.5)), forKey: "inputPoint1")
        filter.setValue(CIVector(x: 0.5, y: 0.5), forKey: "inputPoint2")
        filter.setValue(CIVector(x: 0.75, y: 0.75), forKey: "inputPoint3")
        filter.setValue(CIVector(x: 1.0, y: 1.0), forKey: "inputPoint4")

        return filter.outputImage ?? image
    }

    // MARK: - Clarity

    private func applyClarity(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(20.0, forKey: kCIInputRadiusKey)
        filter.setValue(amount / 100.0 * 0.8, forKey: kCIInputIntensityKey)

        return filter.outputImage ?? image
    }

    // MARK: - Fade

    private func applyFade(_ amount: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        let fadeAmount = amount / 100.0 * 0.15

        filter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: CGFloat(fadeAmount), y: CGFloat(fadeAmount), z: CGFloat(fadeAmount), w: 0), forKey: "inputBiasVector")

        return filter.outputImage ?? image
    }

    // MARK: - Sharpness

    private func applySharpness(amount: Float, radius: Float, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(amount / 100.0 * 2.5, forKey: kCIInputIntensityKey)
        filter.setValue(CGFloat(radius), forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    // MARK: - Vignette

    private func applyVignette(_ vignette: VignetteData, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIVignetteEffect") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        let center = CIVector(x: image.extent.midX, y: image.extent.midY)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(vignette.amount / 100.0 * 1.5, forKey: kCIInputIntensityKey)
        let maxRadius = min(image.extent.width, image.extent.height) / 2
        filter.setValue(maxRadius * CGFloat(vignette.midpoint), forKey: kCIInputRadiusKey)
        filter.setValue(CGFloat(vignette.feather), forKey: "inputFalloff")

        return filter.outputImage ?? image
    }

    // MARK: - Grain

    private func applyGrain(_ grain: GrainData, to image: CIImage) -> CIImage {
        let extent = image.extent

        guard let noiseFilter = CIFilter(name: "CIRandomGenerator"),
              let noiseImage = noiseFilter.outputImage else { return image }

        let grainScale = CGFloat(3.0 + (grain.size * 7.0))
        var grainNoise = noiseImage.transformed(by: CGAffineTransform(scaleX: grainScale, y: grainScale))
        grainNoise = grainNoise.cropped(to: extent)

        guard let grayscaleFilter = CIFilter(name: "CIColorMatrix") else { return image }
        grayscaleFilter.setValue(grainNoise, forKey: kCIInputImageKey)
        grayscaleFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputRVector")
        grayscaleFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputGVector")
        grayscaleFilter.setValue(CIVector(x: 0.33, y: 0.33, z: 0.33, w: 0), forKey: "inputBVector")
        grayscaleFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        grayscaleFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard var grayNoise = grayscaleFilter.outputImage else { return image }

        let blurRadius = 0.5 + (grain.size * 1.0)
        if let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(grayNoise, forKey: kCIInputImageKey)
            blurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
            if let blurred = blurFilter.outputImage {
                grayNoise = blurred.cropped(to: extent)
            }
        }

        let intensity = grain.amount / 100.0

        guard let adjustFilter = CIFilter(name: "CIColorMatrix") else { return image }
        adjustFilter.setValue(grayNoise, forKey: kCIInputImageKey)

        let grainStrength = CGFloat(intensity * 0.4)
        adjustFilter.setValue(CIVector(x: grainStrength, y: 0, z: 0, w: 0), forKey: "inputRVector")
        adjustFilter.setValue(CIVector(x: 0, y: grainStrength, z: 0, w: 0), forKey: "inputGVector")
        adjustFilter.setValue(CIVector(x: 0, y: 0, z: grainStrength, w: 0), forKey: "inputBVector")
        adjustFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        let bias = CGFloat(0.5 - (grainStrength * 0.5))
        adjustFilter.setValue(CIVector(x: bias, y: bias, z: bias, w: 0), forKey: "inputBiasVector")

        guard let adjustedNoise = adjustFilter.outputImage else { return image }

        guard let blendFilter = CIFilter(name: "CIOverlayBlendMode") else { return image }
        blendFilter.setValue(adjustedNoise, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }

    // MARK: - Bloom

    private func applyBloom(_ bloom: BloomData, to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIBloom") else { return image }

        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(bloom.intensity / 100.0 * 2.0, forKey: kCIInputIntensityKey)
        filter.setValue(CGFloat(bloom.radius * 50.0), forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }

    // MARK: - Halation

    private func applyHalation(_ halation: HalationData, to image: CIImage) -> CIImage {
        let extent = image.extent

        // Extract bright areas
        guard let colorClampFilter = CIFilter(name: "CIColorClamp") else { return image }
        colorClampFilter.setValue(image, forKey: kCIInputImageKey)
        colorClampFilter.setValue(CIVector(x: 0.7, y: 0.7, z: 0.7, w: 0), forKey: "inputMinComponents")
        colorClampFilter.setValue(CIVector(x: 1, y: 1, z: 1, w: 1), forKey: "inputMaxComponents")

        guard let brightAreas = colorClampFilter.outputImage else { return image }

        // Tint bright areas with halation color
        guard let colorMatrixFilter = CIFilter(name: "CIColorMatrix") else { return image }
        colorMatrixFilter.setValue(brightAreas, forKey: kCIInputImageKey)

        let hue = halation.hue / 360.0
        let r: CGFloat = max(0, min(1, 1.0 - abs(CGFloat(hue) * 6.0 - 3.0) + 1.0))
        let g: CGFloat = max(0, min(1, 2.0 - abs(CGFloat(hue) * 6.0 - 2.0)))
        let b: CGFloat = max(0, min(1, 2.0 - abs(CGFloat(hue) * 6.0 - 4.0)))

        colorMatrixFilter.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: g * 0.3, z: 0, w: 0), forKey: "inputGVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: b * 0.1, w: 0), forKey: "inputBVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        colorMatrixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard let tintedBright = colorMatrixFilter.outputImage else { return image }

        // Blur the tinted highlights
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        blurFilter.setValue(tintedBright, forKey: kCIInputImageKey)
        let blurRadius = 5.0 + halation.spread * 45.0
        blurFilter.setValue(CGFloat(blurRadius), forKey: kCIInputRadiusKey)

        guard let blurredHalation = blurFilter.outputImage?.cropped(to: extent) else { return image }

        // Adjust intensity
        guard let opacityFilter = CIFilter(name: "CIColorMatrix") else { return image }
        opacityFilter.setValue(blurredHalation, forKey: kCIInputImageKey)
        let opacity = halation.intensity / 100.0 * 0.7
        opacityFilter.setValue(CIVector(x: CGFloat(opacity), y: 0, z: 0, w: 0), forKey: "inputRVector")
        opacityFilter.setValue(CIVector(x: 0, y: CGFloat(opacity), z: 0, w: 0), forKey: "inputGVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: CGFloat(opacity), w: 0), forKey: "inputBVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        opacityFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBiasVector")

        guard let adjustedHalation = opacityFilter.outputImage else { return image }

        // Blend with original using screen blend
        guard let blendFilter = CIFilter(name: "CIScreenBlendMode") else { return image }
        blendFilter.setValue(adjustedHalation, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)

        return blendFilter.outputImage ?? image
    }
```

---

### File 2: `FilmBox/Features/Editor/EditorView.swift`

**REPLACE the `adjustToolPanel` property with this:**

```swift
    private var adjustToolPanel: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Light section
                Text("Light")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ToolSlider(
                    label: "Exposure",
                    value: Binding(
                        get: { viewModel.currentParameters.exposure },
                        set: { viewModel.updateExposure($0) }
                    ),
                    range: -2...2,
                    defaultValue: 0,
                    decimalPlaces: 1
                )

                ToolSlider(
                    label: "Contrast",
                    value: Binding(
                        get: { viewModel.currentParameters.contrast },
                        set: { viewModel.updateContrast($0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Highlights",
                    value: Binding(
                        get: { viewModel.currentParameters.highlights },
                        set: { viewModel.updateHighlights($0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Shadows",
                    value: Binding(
                        get: { viewModel.currentParameters.shadows },
                        set: { viewModel.updateShadows($0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Whites",
                    value: Binding(
                        get: { viewModel.currentParameters.whites },
                        set: { viewModel.updateParameter(\.whites, value: $0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Blacks",
                    value: Binding(
                        get: { viewModel.currentParameters.blacks },
                        set: { viewModel.updateParameter(\.blacks, value: $0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                Divider().background(Color.white.opacity(0.2))

                // Color section
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ToolSlider(
                    label: "Temperature",
                    value: Binding(
                        get: { viewModel.currentParameters.temperature },
                        set: { viewModel.updateTemperature($0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Tint",
                    value: Binding(
                        get: { viewModel.currentParameters.tint },
                        set: { viewModel.updateParameter(\.tint, value: $0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Saturation",
                    value: Binding(
                        get: { viewModel.currentParameters.saturation },
                        set: { viewModel.updateSaturation($0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Vibrance",
                    value: Binding(
                        get: { viewModel.currentParameters.vibrance },
                        set: { viewModel.updateParameter(\.vibrance, value: $0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
```

**REPLACE the `effectsToolPanel` property with this:**

```swift
    private var effectsToolPanel: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Detail section
                Text("Detail")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ToolSlider(
                    label: "Clarity",
                    value: Binding(
                        get: { viewModel.currentParameters.clarity },
                        set: { viewModel.updateParameter(\.clarity, value: $0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Sharpness",
                    value: Binding(
                        get: { viewModel.currentParameters.sharpness },
                        set: { viewModel.updateParameter(\.sharpness, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                Divider().background(Color.white.opacity(0.2))

                // Film effects section
                Text("Film Effects")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)

                ToolSlider(
                    label: "Grain",
                    value: Binding(
                        get: { viewModel.currentParameters.grain.amount },
                        set: { viewModel.updateParameter(\.grain.amount, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Fade",
                    value: Binding(
                        get: { viewModel.currentParameters.fade },
                        set: { viewModel.updateParameter(\.fade, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Vignette",
                    value: Binding(
                        get: { viewModel.currentParameters.vignette.amount },
                        set: { viewModel.updateParameter(\.vignette.amount, value: $0) }
                    ),
                    range: -100...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Bloom",
                    value: Binding(
                        get: { viewModel.currentParameters.bloom.intensity },
                        set: { viewModel.updateParameter(\.bloom.intensity, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )

                ToolSlider(
                    label: "Halation",
                    value: Binding(
                        get: { viewModel.currentParameters.halation.intensity },
                        set: { viewModel.updateParameter(\.halation.intensity, value: $0) }
                    ),
                    range: 0...100,
                    defaultValue: 0
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
```

---

## Quick Command to Restore Files (if deleted again)

```bash
git restore FilmBox/
```

---

## Technical Notes

### CIFilter Names Used:
- `CIExposureAdjust` - Exposure
- `CIColorControls` - Contrast, Saturation
- `CIHighlightShadowAdjust` - Highlights, Shadows
- `CIToneCurve` - Whites, Blacks (5-point curve)
- `CITemperatureAndTint` - Temperature, Tint
- `CIVibrance` - Vibrance
- `CIUnsharpMask` - Clarity (large radius), Sharpness
- `CIVignetteEffect` - Vignette with center, radius, falloff
- `CIRandomGenerator` + `CIOverlayBlendMode` - Film Grain
- `CIBloom` - Bloom glow effect
- `CIColorClamp` + `CIGaussianBlur` + `CIScreenBlendMode` - Halation
- `CIColorMatrix` - Fade, color tinting

### Parameter Ranges (from FilterParameters.swift):
- Exposure: -2 to +2 EV
- Contrast, Highlights, Shadows, Whites, Blacks: -100 to +100
- Temperature, Tint: -100 to +100
- Saturation, Vibrance: -100 to +100
- Clarity: -100 to +100
- Sharpness: 0 to 100
- Sharpen Radius: 0.5 to 3.0
- Fade: 0 to 100
- Grain Amount: 0 to 100
- Grain Size, Roughness: 0 to 1
- Vignette Amount: -100 to +100
- Vignette Midpoint, Feather: 0 to 1
- Bloom Intensity: 0 to 100
- Bloom Radius, Threshold: 0 to 1
- Halation Intensity: 0 to 100
- Halation Hue: 0 to 360
- Halation Spread: 0 to 1
