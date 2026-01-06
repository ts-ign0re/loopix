# Filter Addition Algorithm

## Overview

This document describes the complete process for adding new film emulation filters to FilmBox. There are three methods for creating filters:

1. **Scientific Method** - Based on densitometry measurements
2. **Calibration Method** - Using ColorChecker reference shots
3. **Manual Method** - Parameter tuning by visual comparison

---

## Method 1: Scientific (Densitometry-Based)

### Prerequisites

- Sensitometric data for target film stock
- Characteristic curves (H&D curves) for RGB channels
- Spectral sensitivity data (optional, improves accuracy)

### Process Flow

```
┌─────────────────────────────────────────────────────────────┐
│              SCIENTIFIC FILTER CREATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. ACQUIRE DATA                                            │
│     │                                                        │
│     ├─ Source: Film manufacturer datasheets                 │
│     ├─ Source: Published densitometry studies               │
│     └─ Source: Lab measurements (IT8/ColorChecker)          │
│     │                                                        │
│     ▼                                                        │
│  2. EXTRACT CHARACTERISTIC CURVES                           │
│     │                                                        │
│     ├─ Parse H&D curve data points                          │
│     ├─ Normalize to 0-1 range                               │
│     └─ Fit cubic spline for smooth interpolation            │
│     │                                                        │
│     ▼                                                        │
│  3. DERIVE COLOR MATRIX                                     │
│     │                                                        │
│     ├─ Calculate RGB cross-talk from spectral data          │
│     ├─ Build 3x3 color transformation matrix                │
│     └─ Validate with known color patches                    │
│     │                                                        │
│     ▼                                                        │
│  4. EXTRACT SECONDARY CHARACTERISTICS                       │
│     │                                                        │
│     ├─ Base fog density → blacks/shadows offset             │
│     ├─ Highlight rolloff → highlight compression            │
│     ├─ Grain structure → grain parameters                   │
│     └─ Color cast → split tone values                       │
│     │                                                        │
│     ▼                                                        │
│  5. ASSEMBLE FilterParameters                               │
│     │                                                        │
│     └─ Map extracted values to parameter ranges             │
│     │                                                        │
│     ▼                                                        │
│  6. VALIDATE                                                │
│     │                                                        │
│     ├─ Process test images                                  │
│     ├─ Compare to real film scans                           │
│     └─ Calculate ΔE color difference (target: <3)           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Characteristic Curve Extraction

```swift
/// Converts H&D curve data to ToneCurveData
func extractCharacteristicCurve(from hdCurve: [(logE: Double, density: Double)]) -> ToneCurveData {
    // 1. Find dynamic range boundaries
    let dMin = hdCurve.min(by: { $0.density < $1.density })!.density
    let dMax = hdCurve.max(by: { $0.density < $1.density })!.density

    // 2. Normalize to 0-1 range
    let normalized = hdCurve.map { point in
        let x = (point.logE - hdCurve.first!.logE) / (hdCurve.last!.logE - hdCurve.first!.logE)
        let y = (point.density - dMin) / (dMax - dMin)
        return CurvePoint(x: Float(x), y: Float(y))
    }

    // 3. Resample to 5 control points for CIToneCurve
    let resampled = resampleToControlPoints(normalized, count: 5)

    return ToneCurveData(
        composite: resampled,
        red: [],   // Use composite for all channels initially
        green: [],
        blue: []
    )
}

/// Film characteristic curves are typically S-shaped
/// Key points: toe (shadows), straight-line (midtones), shoulder (highlights)
func identifyZones(in curve: [CurvePoint]) -> (toe: Float, shoulder: Float) {
    // Find inflection points using second derivative
    // toe: where curve transitions from concave to linear
    // shoulder: where curve transitions from linear to convex
    // ...implementation details...
}
```

### Color Matrix Derivation

Film has inherent color cross-talk due to dye layer spectral overlap:

```swift
/// Derives 3x3 color matrix from spectral sensitivity data
func deriveColorMatrix(
    redSensitivity: [Float],    // 380-780nm, 10nm intervals
    greenSensitivity: [Float],
    blueSensitivity: [Float]
) -> [[Float]] {
    // Matrix transforms linear RGB to film-response RGB
    // Based on spectral overlap between dye layers

    // Example: Kodak Portra has warm shadows due to:
    // - Blue layer sensitivity extending into green
    // - Red layer sensitivity starting earlier than pure red

    return [
        [1.05, 0.02, -0.01],  // Red output
        [0.03, 0.98, 0.01],   // Green output
        [0.01, 0.05, 0.96]    // Blue output
    ]
}
```

---

## Method 2: Calibration-Based (ColorChecker)

### Prerequisites

- Reference image shot on target film
- Same scene shot with ColorChecker chart
- OR: ColorChecker shot with same film/processing

### Process Flow

```
┌─────────────────────────────────────────────────────────────┐
│            CALIBRATION-BASED FILTER CREATION                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  USER INPUT                                                  │
│  ├─ Reference image (target look)                           │
│  └─ ColorChecker image (same film/process)                  │
│                                                              │
│  STEP 1: DETECT COLORCHECKER                                │
│  │                                                           │
│  │  ┌────────────────────────────────┐                      │
│  │  │ ■ ■ ■ ■ ■ ■   24-patch chart   │                      │
│  │  │ ■ ■ ■ ■ ■ ■   detected via     │                      │
│  │  │ ■ ■ ■ ■ ■ ■   Vision framework │                      │
│  │  │ ■ ■ ■ ■ ■ ■   or manual pick   │                      │
│  │  └────────────────────────────────┘                      │
│  │                                                           │
│  ▼                                                           │
│  STEP 2: EXTRACT MEASURED VALUES                            │
│  │                                                           │
│  │  For each patch:                                         │
│  │  ├─ Sample average RGB from center region                │
│  │  ├─ Convert to Lab color space                           │
│  │  └─ Store as measured[i]                                 │
│  │                                                           │
│  ▼                                                           │
│  STEP 3: COMPARE TO REFERENCE VALUES                        │
│  │                                                           │
│  │  ColorChecker reference values (D50 illuminant):         │
│  │  ├─ Patch 1 (dark skin): Lab(37.99, 13.56, 14.06)       │
│  │  ├─ Patch 2 (light skin): Lab(65.71, 18.13, 17.81)      │
│  │  ├─ ...                                                  │
│  │  └─ Patch 24 (white): Lab(96.54, -0.43, 1.19)           │
│  │                                                           │
│  │  Calculate: delta[i] = measured[i] - reference[i]        │
│  │                                                           │
│  ▼                                                           │
│  STEP 4: DERIVE TRANSFORMATION                              │
│  │                                                           │
│  │  ├─ Grayscale patches → tone curve                       │
│  │  │   (patches 19-24: white to black)                     │
│  │  │                                                        │
│  │  ├─ Color patches → hue shifts                           │
│  │  │   (patches 13-18: primaries + secondaries)            │
│  │  │                                                        │
│  │  ├─ Skin patches → skin tone adjustment                  │
│  │  │   (patches 1-2: dark/light skin)                      │
│  │  │                                                        │
│  │  └─ Overall cast → white balance + split tone            │
│  │                                                           │
│  ▼                                                           │
│  STEP 5: GENERATE FilterParameters                          │
│  │                                                           │
│  │  Map derived values to parameter ranges                  │
│  │                                                           │
│  ▼                                                           │
│  STEP 6: REFINEMENT                                         │
│  │                                                           │
│  │  ├─ Apply to test images                                 │
│  │  ├─ Manual fine-tuning of grain, vignette               │
│  │  └─ A/B comparison with reference                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
actor CalibrationEngine {

    /// Reference ColorChecker values (Lab, D50 illuminant)
    static let colorCheckerReference: [String: (L: Float, a: Float, b: Float)] = [
        "dark_skin":      (37.99, 13.56, 14.06),
        "light_skin":     (65.71, 18.13, 17.81),
        "blue_sky":       (49.93, -4.88, -21.93),
        "foliage":        (43.14, -13.10, 21.91),
        "blue_flower":    (55.11, 8.84, -25.40),
        "bluish_green":   (70.72, -33.40, -0.20),
        "orange":         (62.66, 36.07, 57.10),
        "purplish_blue":  (40.02, 10.41, -45.96),
        "moderate_red":   (51.12, 48.24, 16.25),
        "purple":         (30.33, 22.98, -21.59),
        "yellow_green":   (72.53, -23.71, 57.26),
        "orange_yellow":  (71.94, 19.36, 67.86),
        "blue":           (28.78, 14.18, -50.30),
        "green":          (55.26, -38.34, 31.37),
        "red":            (42.10, 53.38, 28.19),
        "yellow":         (81.73, 4.04, 79.82),
        "magenta":        (51.94, 49.99, -14.57),
        "cyan":           (51.04, -28.63, -28.64),
        "white":          (96.54, -0.43, 1.19),
        "neutral_8":      (81.26, -0.64, -0.34),
        "neutral_6.5":    (66.77, -0.73, -0.50),
        "neutral_5":      (50.87, -0.15, -0.27),
        "neutral_3.5":    (35.66, -0.42, -1.23),
        "black":          (20.46, -0.08, -0.97)
    ]

    func calibrate(
        colorCheckerImage: CIImage,
        referenceImage: CIImage
    ) async throws -> FilterParameters {
        // 1. Detect patches
        let patches = try await detectColorCheckerPatches(in: colorCheckerImage)

        // 2. Sample measured values
        let measured = samplePatchColors(patches, in: colorCheckerImage)

        // 3. Calculate deltas
        let deltas = calculateColorDeltas(measured: measured)

        // 4. Derive parameters
        var params = FilterParameters()

        // Tone curve from grayscale patches
        params.toneCurve = deriveToneCurve(from: deltas.grayscale)

        // White balance from neutral patches
        let (temp, tint) = deriveWhiteBalance(from: deltas.neutrals)
        params.temperature = temp
        params.tint = tint

        // HSL from color patches
        params.hsl = deriveHSLAdjustments(from: deltas.colors)

        // Skin tone from skin patches
        params.skinToneHue = deltas.skinHueShift
        params.skinToneSaturation = deltas.skinSatShift

        // Split tone from overall cast analysis
        params.splitTone = deriveSplitTone(from: deltas)

        return params
    }
}
```

---

## Method 3: Manual (Visual Comparison)

### When to Use

- No densitometry data available
- No ColorChecker reference shot
- Creating artistic interpretations
- Quick prototyping

### Process Flow

```
┌─────────────────────────────────────────────────────────────┐
│              MANUAL FILTER CREATION                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. GATHER REFERENCE MATERIAL                               │
│     ├─ Real film scans (Flickr, Reddit, personal)           │
│     ├─ Film stock characteristics (online resources)        │
│     └─ Example images with target look                      │
│                                                              │
│  2. IDENTIFY KEY CHARACTERISTICS                            │
│     ├─ Overall color cast (warm/cool)                       │
│     ├─ Contrast profile (lifted blacks, compressed highs)   │
│     ├─ Saturation behavior (muted, vivid, selective)        │
│     ├─ Grain presence and character                         │
│     └─ Special effects (halation, vignette)                 │
│                                                              │
│  3. ESTABLISH BASELINE                                      │
│     ├─ Start with identity parameters                       │
│     └─ Process test image with diverse content              │
│                                                              │
│  4. ITERATIVE REFINEMENT                                    │
│     │                                                        │
│     │  ┌──────────────┐                                     │
│     │  │   Adjust     │                                     │
│     │  │  Parameter   │                                     │
│     │  └──────┬───────┘                                     │
│     │         │                                              │
│     │         ▼                                              │
│     │  ┌──────────────┐      ┌──────────────┐              │
│     │  │   Compare    │──No──│    Close     │              │
│     │  │  to Target   │      │   Enough?    │              │
│     │  └──────────────┘      └──────┬───────┘              │
│     │         │                     │                       │
│     │        Yes                   Loop                     │
│     │         │                     │                       │
│     │         ▼                     │                       │
│     │  ┌──────────────┐            │                       │
│     │  │    Save      │◄───────────┘                       │
│     │  │   Preset     │                                     │
│     │  └──────────────┘                                     │
│                                                              │
│  5. VALIDATION                                              │
│     ├─ Test on 10+ diverse images                           │
│     ├─ Check skin tones specifically                        │
│     ├─ Verify shadows and highlights behavior               │
│     └─ Community feedback (beta testers)                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Parameter Tuning Guide

| Film Characteristic | Primary Parameters | Secondary Parameters |
|--------------------|--------------------|---------------------|
| Warm shadows | Split tone (shadow hue ~40°) | Temperature +10-20 |
| Cool highlights | Split tone (highlight hue ~220°) | Tint -5-10 |
| Lifted blacks | Tone curve point 0 y: 0.05-0.15 | Blacks +10-30 |
| Compressed highlights | Tone curve point 4 y: 0.90-0.95 | Highlights -20-40 |
| Muted colors | Saturation -15-30 | Vibrance -10-20 |
| Cross-process look | Strong split tone | Contrast +20, Saturation +10 |
| Faded look | Fade +20-50 | Contrast -10-20 |
| Vintage | Fade +30, Vignette | Grain +30-50 |

---

## Adding Filter to App

### Step 1: Create FilterPreset

```swift
let newFilter = FilterPreset(
    id: UUID(),
    name: "Kodak Portra 400",
    category: .film,
    source: .builtIn,  // or .userCreated, .calibrated
    parameters: derivedParameters,
    metadata: FilterMetadata(
        filmStock: "Kodak Portra 400",
        era: "1998-present",
        characteristics: ["warm shadows", "natural skin tones", "fine grain"],
        author: "FilmBox Team"
    ),
    createdAt: Date(),
    modifiedAt: Date()
)
```

### Step 2: Add to Built-In Filters JSON

```json
{
  "filters": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Kodak Portra 400",
      "category": "film",
      "source": "builtIn",
      "parameters": {
        "exposure": 0,
        "contrast": 5,
        "highlights": -10,
        "shadows": 15,
        "temperature": 8,
        "tint": 2,
        "saturation": -5,
        "vibrance": 10,
        "toneCurve": {
          "composite": [
            {"x": 0, "y": 0.03},
            {"x": 0.25, "y": 0.23},
            {"x": 0.5, "y": 0.52},
            {"x": 0.75, "y": 0.78},
            {"x": 1, "y": 0.97}
          ]
        },
        "splitTone": {
          "shadowHue": 35,
          "shadowSaturation": 15,
          "highlightHue": 45,
          "highlightSaturation": 8,
          "balance": -10
        },
        "grain": {
          "amount": 15,
          "size": 0.4,
          "roughness": 0.5,
          "monochromatic": false
        }
      },
      "metadata": {
        "filmStock": "Kodak Portra 400",
        "era": "1998-present",
        "characteristics": ["warm shadows", "natural skin tones", "fine grain"]
      }
    }
  ]
}
```

### Step 3: Generate Preview Thumbnail

Each filter needs a preview thumbnail shown in the filter strip:

```swift
func generateFilterPreview(for filter: FilterPreset) async -> CGImage? {
    // Use standardized test image (included in bundle)
    guard let testImage = CIImage(contentsOf: Bundle.main.url(
        forResource: "filter_preview_base",
        withExtension: "jpg"
    )!) else { return nil }

    let processed = await FilterEngine.shared.apply(filter, to: testImage)
    return await FilterEngine.shared.render(processed, to: CGSize(width: 120, height: 120))
}
```

### Step 4: Validation Checklist

Before releasing a new filter:

- [ ] Tested on 20+ diverse images (portraits, landscapes, urban, low-light)
- [ ] Skin tones look natural (not orange, green, or grey)
- [ ] Shadows retain detail (not crushed)
- [ ] Highlights retain detail (not blown)
- [ ] Works with both high and low saturation source images
- [ ] Grain looks natural at 100% zoom
- [ ] Processing time <200ms on iPhone 12
- [ ] Color accuracy ΔE <5 vs reference film scans
- [ ] Metadata is complete and accurate

---

## Quality Standards

### Color Accuracy Metrics

| Metric | Acceptable | Good | Excellent |
|--------|------------|------|-----------|
| ΔE (avg across patches) | <7 | <5 | <3 |
| ΔE (max single patch) | <12 | <8 | <5 |
| Skin tone ΔE | <5 | <3 | <2 |
| Gray balance ΔE | <3 | <2 | <1 |

### Performance Requirements

| Metric | Requirement |
|--------|-------------|
| Thumbnail generation | <100ms |
| Full-res preview | <200ms |
| Export processing | <2s per image |
| Memory overhead | <50MB per filter |

---

*Last updated: January 2026*
