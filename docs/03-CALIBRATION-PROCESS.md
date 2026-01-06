# Calibration Process

## Overview

The calibration system allows users to create scientifically-accurate film emulation filters using a ColorChecker Passport or X-Rite ColorChecker Classic. This process measures how a specific film stock transforms colors and derives a matching filter.

---

## Calibration Theory

### Why ColorChecker?

The X-Rite ColorChecker provides:
- **24 precisely manufactured color patches** with known Lab values
- **6 grayscale patches** for tone curve derivation
- **Neutral patches** for white balance assessment
- **Skin tone patches** for critical color accuracy
- **Saturated primaries/secondaries** for HSL mapping

### The Transformation Model

```
┌─────────────────────────────────────────────────────────────┐
│                CALIBRATION MODEL                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   KNOWN INPUT               FILM PROCESS            OUTPUT   │
│   (ColorChecker)                                    (Scan)   │
│                                                              │
│   ┌─────────────┐                               ┌──────────┐│
│   │ Lab(65.71,  │    ┌───────────────────┐     │ Lab(63.2,││
│   │     18.13,  │───▶│   Film Transform  │────▶│     22.5, ││
│   │     17.81)  │    │   T(Lab) = Lab'   │     │     15.3) ││
│   └─────────────┘    └───────────────────┘     └──────────┘│
│   Light Skin Patch        Black Box              Measured   │
│                                                              │
│   Our Goal: Derive T() such that:                           │
│   T(digital_input) ≈ film_output                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

The calibration process reverse-engineers the transformation function T() by measuring how the film altered each known color patch.

---

## User Workflow

### Prerequisites

1. **ColorChecker chart** (Classic 24-patch recommended)
2. **Film shot of ColorChecker** (same roll/process as reference images)
3. **Scanned film image** in high quality (no post-processing)

### Step-by-Step Process

```
┌─────────────────────────────────────────────────────────────┐
│                  CALIBRATION WORKFLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  STEP 1: SELECT REFERENCE IMAGE                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                                                          ││
│  │  "Select a photo that shows the look you want           ││
│  │   to recreate. This could be:"                          ││
│  │                                                          ││
│  │   • A film scan with your desired aesthetic             ││
│  │   • A screenshot from a movie                           ││
│  │   • Any image with the target color grade               ││
│  │                                                          ││
│  │          [Choose from Photos]                           ││
│  │          [Import from Files]                            ││
│  │                                                          ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                  │
│                           ▼                                  │
│  STEP 2: CAPTURE/IMPORT COLORCHECKER                        │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                                                          ││
│  │  "For best results, include a ColorChecker in a        ││
│  │   shot with the same film and processing."              ││
│  │                                                          ││
│  │   Option A: [Import ColorChecker Scan]                  ││
│  │   Option B: [Skip - Use AI Estimation]                  ││
│  │                                                          ││
│  │  ┌────────────────────────────────────────────────┐    ││
│  │  │  ■ ■ ■ ■ ■ ■                                   │    ││
│  │  │  ■ ■ ■ ■ ■ ■    ← Detected chart outline      │    ││
│  │  │  ■ ■ ■ ■ ■ ■                                   │    ││
│  │  │  ■ ■ ■ ■ ■ ■                                   │    ││
│  │  └────────────────────────────────────────────────┘    ││
│  │                                                          ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                  │
│                           ▼                                  │
│  STEP 3: AUTOMATIC ANALYSIS                                 │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                                                          ││
│  │  "Analyzing film characteristics..."                    ││
│  │                                                          ││
│  │  ✓ Detecting ColorChecker patches                       ││
│  │  ✓ Measuring color values                               ││
│  │  ████████████░░░░░░░░ Deriving tone curve              ││
│  │  ○ Calculating color matrix                             ││
│  │  ○ Extracting grain pattern                             ││
│  │  ○ Generating filter                                    ││
│  │                                                          ││
│  └─────────────────────────────────────────────────────────┘│
│                           │                                  │
│                           ▼                                  │
│  STEP 4: REFINEMENT                                         │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                                                          ││
│  │  ┌──────────────┐  ┌──────────────┐                    ││
│  │  │  Reference   │  │  Your Filter │                    ││
│  │  │    Image     │  │   Applied    │                    ││
│  │  │              │  │              │                    ││
│  │  └──────────────┘  └──────────────┘                    ││
│  │                                                          ││
│  │  Fine-tune:                                             ││
│  │  Shadow warmth     ═══════●═══════     +12             ││
│  │  Highlight hue     ═══●═══════════     -25             ││
│  │  Grain amount      ═●═════════════      8              ││
│  │  Fade              ═══════●═══════     +15             ││
│  │                                                          ││
│  │                    [Save Filter]                        ││
│  │                                                          ││
│  └─────────────────────────────────────────────────────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Implementation

### Phase 1: ColorChecker Detection

```swift
actor ColorCheckerDetector {

    /// Detected patch information
    struct DetectedPatch {
        let index: Int           // 0-23 patch number
        let center: CGPoint      // Center in image coordinates
        let averageColor: CIColor // Sampled RGB
        let confidence: Float    // Detection confidence 0-1
    }

    /// Detect ColorChecker patches using Vision framework
    func detectPatches(in image: CIImage) async throws -> [DetectedPatch] {
        // 1. Convert to CGImage for Vision
        guard let cgImage = CIContext().createCGImage(image, from: image.extent) else {
            throw CalibrationError.imageConversionFailed
        }

        // 2. Use Vision rectangle detection
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.9
        request.maximumAspectRatio = 1.1
        request.minimumSize = 0.01
        request.maximumObservations = 30

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        guard let results = request.results, results.count >= 24 else {
            throw CalibrationError.insufficientPatchesDetected
        }

        // 3. Filter to grid pattern (4 rows × 6 columns)
        let gridPatches = filterToColorCheckerGrid(results)

        // 4. Sample colors from patch centers
        return gridPatches.enumerated().map { index, rect in
            let center = CGPoint(
                x: rect.boundingBox.midX * image.extent.width,
                y: rect.boundingBox.midY * image.extent.height
            )
            let color = sampleColor(at: center, in: image, radius: 10)

            return DetectedPatch(
                index: index,
                center: center,
                averageColor: color,
                confidence: rect.confidence
            )
        }
    }

    /// Sample average color in a circular region
    private func sampleColor(at center: CGPoint, in image: CIImage, radius: CGFloat) -> CIColor {
        let sampleRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        // Use CIAreaAverage filter for accurate sampling
        let areaAverage = CIFilter.areaAverage()
        areaAverage.inputImage = image
        areaAverage.extent = sampleRect

        guard let outputImage = areaAverage.outputImage else {
            return CIColor(red: 0.5, green: 0.5, blue: 0.5)
        }

        // Read single pixel result
        var bitmap = [Float](repeating: 0, count: 4)
        CIContext().render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 16,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBAf,
            colorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!
        )

        return CIColor(red: CGFloat(bitmap[0]),
                       green: CGFloat(bitmap[1]),
                       blue: CGFloat(bitmap[2]))
    }
}
```

### Phase 2: Color Delta Calculation

```swift
struct ColorDelta {
    let patchIndex: Int
    let patchName: String
    let referencelab: (L: Float, a: Float, b: Float)
    let measuredLab: (L: Float, a: Float, b: Float)
    let deltaE: Float       // CIEDE2000 color difference
    let deltaL: Float       // Luminance shift
    let deltaC: Float       // Chroma shift
    let deltaH: Float       // Hue shift (degrees)
}

extension CalibrationEngine {

    func calculateColorDeltas(
        measured: [DetectedPatch]
    ) -> [ColorDelta] {
        return measured.compactMap { patch in
            guard let reference = Self.colorCheckerReference[patchName(for: patch.index)] else {
                return nil
            }

            // Convert measured RGB to Lab
            let measuredLab = rgbToLab(
                r: Float(patch.averageColor.red),
                g: Float(patch.averageColor.green),
                b: Float(patch.averageColor.blue)
            )

            // Calculate CIEDE2000 color difference
            let deltaE = ciede2000(
                lab1: reference,
                lab2: measuredLab
            )

            // Calculate component shifts
            let deltaL = measuredLab.L - reference.L
            let (refC, refH) = labToLCH(reference)
            let (measC, measH) = labToLCH(measuredLab)
            let deltaC = measC - refC
            let deltaH = angularDifference(measH, refH)

            return ColorDelta(
                patchIndex: patch.index,
                patchName: patchName(for: patch.index),
                referencelab: reference,
                measuredLab: measuredLab,
                deltaE: deltaE,
                deltaL: deltaL,
                deltaC: deltaC,
                deltaH: deltaH
            )
        }
    }

    /// CIEDE2000 color difference formula
    private func ciede2000(
        lab1: (L: Float, a: Float, b: Float),
        lab2: (L: Float, a: Float, b: Float)
    ) -> Float {
        // Full CIEDE2000 implementation
        // Reference: "The CIEDE2000 Color-Difference Formula" by Sharma, Wu, Dalal
        // ...implementation details...

        // Simplified version for documentation:
        let dL = lab2.L - lab1.L
        let da = lab2.a - lab1.a
        let db = lab2.b - lab1.b
        return sqrt(dL*dL + da*da + db*db)  // CIE76 approximation
    }
}
```

### Phase 3: Parameter Derivation

```swift
extension CalibrationEngine {

    /// Derive tone curve from grayscale patches (19-24)
    func deriveToneCurve(from deltas: [ColorDelta]) -> ToneCurveData {
        // Grayscale patches: white(19), neutral8(20), neutral6.5(21),
        //                    neutral5(22), neutral3.5(23), black(24)

        let grayscaleDeltas = deltas.filter { (19...24).contains($0.patchIndex) }
            .sorted { $0.referencelab.L > $1.referencelab.L }

        // Map reference L values to normalized 0-1 range
        let points: [ToneCurveData.CurvePoint] = grayscaleDeltas.map { delta in
            let inputX = delta.referencelab.L / 100.0  // Reference luminance
            let outputY = delta.measuredLab.L / 100.0  // Film response

            return ToneCurveData.CurvePoint(x: inputX, y: outputY)
        }

        // Ensure we have 5 points for CIToneCurve (resample if needed)
        let resampled = resampleCurve(points, targetCount: 5)

        return ToneCurveData(
            composite: resampled,
            red: [],
            green: [],
            blue: []
        )
    }

    /// Derive white balance from neutral patches
    func deriveWhiteBalance(from deltas: [ColorDelta]) -> (temperature: Float, tint: Float) {
        // Use neutral patches for white balance
        let neutralDeltas = deltas.filter { (19...24).contains($0.patchIndex) }

        // Average a* shift indicates green-magenta (tint)
        // Average b* shift indicates blue-yellow (temperature)
        let avgA = neutralDeltas.map { $0.measuredLab.a - $0.referencelab.a }.reduce(0, +)
            / Float(neutralDeltas.count)
        let avgB = neutralDeltas.map { $0.measuredLab.b - $0.referencelab.b }.reduce(0, +)
            / Float(neutralDeltas.count)

        // Map Lab shifts to temperature/tint ranges (-100 to +100)
        let temperature = clamp(avgB * 5, min: -100, max: 100)  // b* → temp
        let tint = clamp(-avgA * 5, min: -100, max: 100)        // -a* → tint

        return (temperature, tint)
    }

    /// Derive HSL adjustments from color patches
    func deriveHSLAdjustments(from deltas: [ColorDelta]) -> HSLAdjustments {
        var hsl = HSLAdjustments()

        // Map patches to HSL channels
        let patchToChannel: [String: WritableKeyPath<HSLAdjustments, HSLAdjustments.HSLChannel>] = [
            "red": \.red,
            "orange": \.orange,
            "orange_yellow": \.yellow,
            "yellow": \.yellow,
            "yellow_green": \.green,
            "green": \.green,
            "bluish_green": \.aqua,
            "cyan": \.aqua,
            "blue": \.blue,
            "blue_sky": \.blue,
            "purplish_blue": \.blue,
            "purple": \.purple,
            "magenta": \.magenta,
            "moderate_red": \.red
        ]

        for delta in deltas {
            guard let keyPath = patchToChannel[delta.patchName] else { continue }

            var channel = hsl[keyPath: keyPath]
            channel.hue = clamp(delta.deltaH, min: -180, max: 180)
            channel.saturation = clamp(delta.deltaC * 2, min: -100, max: 100)
            channel.luminance = clamp(delta.deltaL, min: -100, max: 100)
            hsl[keyPath: keyPath] = channel
        }

        return hsl
    }

    /// Derive split tone from overall color cast
    func deriveSplitTone(from deltas: [ColorDelta]) -> SplitToneData {
        // Analyze shadows (dark patches) and highlights (bright patches)
        let shadowPatches = deltas.filter { $0.referencelab.L < 40 }
        let highlightPatches = deltas.filter { $0.referencelab.L > 60 }

        // Average hue shift in shadows
        let shadowHueShift = averageHueShift(shadowPatches)
        let shadowChromaShift = averageChromaShift(shadowPatches)

        // Average hue shift in highlights
        let highlightHueShift = averageHueShift(highlightPatches)
        let highlightChromaShift = averageChromaShift(highlightPatches)

        return SplitToneData(
            highlightHue: normalizeHue(highlightHueShift),
            highlightSaturation: min(abs(highlightChromaShift) * 3, 100),
            shadowHue: normalizeHue(shadowHueShift),
            shadowSaturation: min(abs(shadowChromaShift) * 3, 100),
            balance: 0  // Neutral balance by default
        )
    }
}
```

### Phase 4: Validation

```swift
extension CalibrationEngine {

    struct CalibrationQuality {
        let averageDeltaE: Float
        let maxDeltaE: Float
        let skinToneDeltaE: Float
        let grayBalanceDeltaE: Float
        let overallScore: CalibrationScore

        enum CalibrationScore: String {
            case excellent = "Excellent"
            case good = "Good"
            case acceptable = "Acceptable"
            case poor = "Poor - Consider recapturing"
        }
    }

    func validateCalibration(
        original: [DetectedPatch],
        filter: FilterParameters,
        colorCheckerImage: CIImage
    ) async -> CalibrationQuality {
        // Apply derived filter to original ColorChecker image
        let filtered = await FilterEngine.shared.apply(filter, to: colorCheckerImage)

        // Re-sample patches from filtered image
        let filteredPatches = try? await ColorCheckerDetector().detectPatches(in: filtered)

        guard let filteredPatches else {
            return CalibrationQuality(
                averageDeltaE: 999,
                maxDeltaE: 999,
                skinToneDeltaE: 999,
                grayBalanceDeltaE: 999,
                overallScore: .poor
            )
        }

        // Calculate how close filtered result is to reference
        var deltaEs: [Float] = []
        var skinDeltaEs: [Float] = []
        var grayDeltaEs: [Float] = []

        for (original, filtered) in zip(original, filteredPatches) {
            let reference = Self.colorCheckerReference[patchName(for: original.index)]!
            let filteredLab = rgbToLab(/* filtered color */)
            let deltaE = ciede2000(lab1: reference, lab2: filteredLab)

            deltaEs.append(deltaE)

            if original.index <= 1 { // Skin patches
                skinDeltaEs.append(deltaE)
            }
            if original.index >= 19 { // Gray patches
                grayDeltaEs.append(deltaE)
            }
        }

        let avgDeltaE = deltaEs.reduce(0, +) / Float(deltaEs.count)
        let maxDeltaE = deltaEs.max() ?? 0
        let skinDeltaE = skinDeltaEs.reduce(0, +) / Float(max(skinDeltaEs.count, 1))
        let grayDeltaE = grayDeltaEs.reduce(0, +) / Float(max(grayDeltaEs.count, 1))

        let score: CalibrationQuality.CalibrationScore
        switch avgDeltaE {
        case 0..<3: score = .excellent
        case 3..<5: score = .good
        case 5..<7: score = .acceptable
        default: score = .poor
        }

        return CalibrationQuality(
            averageDeltaE: avgDeltaE,
            maxDeltaE: maxDeltaE,
            skinToneDeltaE: skinDeltaE,
            grayBalanceDeltaE: grayDeltaE,
            overallScore: score
        )
    }
}
```

---

## Quality Requirements

### Capture Guidelines for Users

```
┌─────────────────────────────────────────────────────────────┐
│            COLORCHECKER CAPTURE GUIDELINES                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✓ DO:                                                      │
│  ├─ Fill frame with chart (at least 50% of image)           │
│  ├─ Use even, diffuse lighting                              │
│  ├─ Ensure chart is flat and perpendicular to camera        │
│  ├─ Include same film stock and processing as target        │
│  ├─ Scan at high resolution (300+ DPI)                      │
│  └─ Avoid post-processing on scan                           │
│                                                              │
│  ✗ DON'T:                                                   │
│  ├─ Shoot at extreme angles                                 │
│  ├─ Use harsh directional lighting                          │
│  ├─ Allow patches to be in shadow                           │
│  ├─ Use faded or damaged charts                             │
│  └─ Apply any color correction before calibration           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Error Handling

| Error | Cause | User Message |
|-------|-------|--------------|
| `insufficientPatchesDetected` | <24 patches found | "Could not detect all color patches. Ensure the chart is fully visible and well-lit." |
| `poorPatchConfidence` | Low detection confidence | "Some patches were difficult to read. Try recapturing with better lighting." |
| `extremeColorShift` | Unrealistic color values | "The detected colors seem unusual. Check that the scan hasn't been pre-processed." |
| `invalidGrayscale` | Non-monotonic gray response | "The grayscale patches show unexpected values. The film may be damaged or improperly processed." |

---

## Calibration Without ColorChecker

For users who don't have a ColorChecker shot, we offer AI-assisted estimation:

### AI Estimation Mode

```
┌─────────────────────────────────────────────────────────────┐
│              AI-ASSISTED CALIBRATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  When no ColorChecker is available:                         │
│                                                              │
│  1. REFERENCE ANALYSIS                                      │
│     ├─ Detect known objects (sky, foliage, skin)            │
│     ├─ Estimate color shifts from expected values           │
│     └─ Analyze histogram for tone curve clues               │
│                                                              │
│  2. FILM STOCK MATCHING                                     │
│     ├─ Compare to database of known film signatures         │
│     ├─ Suggest closest match                                │
│     └─ Use as starting point for refinement                 │
│                                                              │
│  3. USER REFINEMENT                                         │
│     ├─ Provide A/B comparison tools                         │
│     ├─ Allow manual parameter adjustment                    │
│     └─ Save as "AI-estimated" filter type                   │
│                                                              │
│  ⚠️ Accuracy: ~80% vs ColorChecker method (~95%)            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Storage Format

Calibrated filters are stored with additional metadata:

```swift
extension FilterPreset.FilterSource {
    case calibrated(
        referenceImageHash: String,       // SHA256 of reference image
        colorCheckerImageHash: String?,   // SHA256 of ColorChecker image (if used)
        calibrationQuality: Float,        // Average ΔE achieved
        calibrationMethod: CalibrationMethod
    )

    enum CalibrationMethod: String, Codable {
        case colorChecker24      // Standard X-Rite ColorChecker
        case colorCheckerSG      // ColorChecker SG (140 patches)
        case aiEstimated         // No physical chart used
        case manual              // User manually tuned
    }
}
```

---

*Last updated: January 2026*
