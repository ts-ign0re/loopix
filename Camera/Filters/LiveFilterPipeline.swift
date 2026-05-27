import CoreImage

/// Applies CameraFilter presets as a CIFilter chain
enum LiveFilterPipeline {
    private enum VignetteTuning {
        static let intensity: Double = 0.18
        static let radiusFactor: CGFloat = 0.92
    }

    static func apply(_ filter: CameraFilter, to image: CIImage, intensity: Float = 1.0) -> CIImage {
        var result = image

        if filter.id != "clean" {
            // 1. Exposure
            if filter.exposure != 0 {
                result = applyExposure(filter.exposure, to: result)
            }

            // 2. Temperature & Tint
            if filter.temperature != 0 || filter.tint != 0 {
                result = applyTemperature(filter.temperature, tint: filter.tint, to: result)
            }

            // 3. Saturation (and legacy contrast if non-zero)
            if filter.saturation != 0 || filter.contrast != 0 || filter.isMonochrome {
                let sat = filter.isMonochrome ? 0.0 : 1.0 + Double(filter.saturation) / 100.0
                let con = 1.0 + Double(filter.contrast) / 100.0
                result = applyColorControls(saturation: sat, contrast: con, to: result)
            }

            // 4. Per-channel tone curves via CIColorPolynomial
            if !filter.curves.isIdentity {
                result = applyToneCurves(filter.curves, to: result)
            }

            // 5. Split tone (shadow/highlight color tint)
            if filter.hasSplitTone {
                result = applySplitTone(filter, to: result)
            }

            // 6. Fade (lift blacks) — legacy, prefer curves shadows point
            if filter.fade > 0 {
                let lift = Double(filter.fade) / 100.0 * 0.15
                result = applyFade(lift: lift, to: result)
            }

            // 7. Film clamp — per-stock tonal range compression
            result = applyFilmClamp(to: result, blackFloor: filter.blackFloor, whiteCeiling: filter.whiteCeiling)

            // 8. Blend filtered with original based on intensity
            if intensity < 1.0 {
                result = applyDissolve(from: image, to: result, intensity: intensity)
            }
        }

        // 9. Subtle global vignette for center-focused composition.
        result = applySubtleVignette(to: result)

        return result
    }

    // MARK: - Pipeline Stages

    /// Pixel-wise lerp between original and filtered image via CIDissolveTransition
    private static func applyDissolve(from original: CIImage, to filtered: CIImage, intensity: Float) -> CIImage {
        let dissolve = CIFilter(name: "CIDissolveTransition")!
        dissolve.setValue(original, forKey: kCIInputImageKey)
        dissolve.setValue(filtered, forKey: kCIInputTargetImageKey)
        dissolve.setValue(intensity, forKey: kCIInputTimeKey)
        return dissolve.outputImage ?? filtered
    }

    private static func applyExposure(_ exposure: Float, to image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIExposureAdjust")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(exposure, forKey: kCIInputEVKey)
        return filter.outputImage ?? image
    }

    private static func applyTemperature(_ temperature: Float, tint: Float, to image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CITemperatureAndTint")!
        filter.setValue(image, forKey: kCIInputImageKey)
        let targetTemp = 6500.0 + Double(temperature) * 40.0
        filter.setValue(CIVector(x: targetTemp, y: CGFloat(tint)), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        return filter.outputImage ?? image
    }

    private static func applyColorControls(saturation: Double, contrast: Double, to image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }

    private static func applyToneCurves(_ curves: RGBACurves, to image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIColorPolynomial")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(curves.r.ciVector, forKey: "inputRedCoefficients")
        filter.setValue(curves.g.ciVector, forKey: "inputGreenCoefficients")
        filter.setValue(curves.b.ciVector, forKey: "inputBlueCoefficients")
        filter.setValue(curves.a.ciVector, forKey: "inputAlphaCoefficients")
        return filter.outputImage ?? image
    }

    private static func applySplitTone(_ preset: CameraFilter, to image: CIImage) -> CIImage {
        let shadow = CameraFilter.hueToRGB(hue: preset.shadowHue, strength: preset.shadowTintStrength)
        let highlight = CameraFilter.hueToRGB(hue: preset.highlightHue, strength: preset.highlightTintStrength)

        // Per channel: output = shadowColor + (1 - shadowColor)*input + highlightColor*input²
        let rCoeffs = CIVector(x: CGFloat(shadow.r), y: CGFloat(1.0 - shadow.r), z: CGFloat(highlight.r), w: 0)
        let gCoeffs = CIVector(x: CGFloat(shadow.g), y: CGFloat(1.0 - shadow.g), z: CGFloat(highlight.g), w: 0)
        let bCoeffs = CIVector(x: CGFloat(shadow.b), y: CGFloat(1.0 - shadow.b), z: CGFloat(highlight.b), w: 0)
        let aCoeffs = CIVector(x: 0, y: 1, z: 0, w: 0)

        let filter = CIFilter(name: "CIColorPolynomial")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(rCoeffs, forKey: "inputRedCoefficients")
        filter.setValue(gCoeffs, forKey: "inputGreenCoefficients")
        filter.setValue(bCoeffs, forKey: "inputBlueCoefficients")
        filter.setValue(aCoeffs, forKey: "inputAlphaCoefficients")
        return filter.outputImage ?? image
    }

    private static func applyFade(lift: Double, to image: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIColorMatrix")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: lift, y: lift, z: lift, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }

    /// Film clamp — per-stock tonal range compression
    private static func applyFilmClamp(to image: CIImage, blackFloor: Float, whiteCeiling: Float) -> CIImage {
        let floor = CGFloat(blackFloor)
        let ceil = CGFloat(whiteCeiling)
        let scale = ceil - floor

        let filter = CIFilter(name: "CIColorMatrix")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: scale, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: scale, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: scale, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        filter.setValue(CIVector(x: floor, y: floor, z: floor, w: 0), forKey: "inputBiasVector")
        return filter.outputImage ?? image
    }

    /// Mild edge darkening to keep attention near frame center without looking "processed".
    private static func applySubtleVignette(to image: CIImage) -> CIImage {
        let extent = image.extent
        guard extent.width > 1, extent.height > 1 else { return image }

        let filter = CIFilter(name: "CIVignetteEffect")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: extent.midX, y: extent.midY), forKey: kCIInputCenterKey)
        filter.setValue(VignetteTuning.intensity, forKey: kCIInputIntensityKey)
        filter.setValue(min(extent.width, extent.height) * VignetteTuning.radiusFactor, forKey: kCIInputRadiusKey)

        return filter.outputImage ?? image
    }
}
