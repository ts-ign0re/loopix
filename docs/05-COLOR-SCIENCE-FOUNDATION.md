# Color Science Foundation

## Executive Summary

FilmBox's color processing is grounded in colorimetry and imaging science. This document explains the theoretical foundations and why specific implementation choices were made.

---

## Color Space Architecture

### Why Linear Color Space?

All image processing in FilmBox occurs in **Linear sRGB** color space, with final output in **sRGB**.

```
┌─────────────────────────────────────────────────────────────┐
│              COLOR SPACE PIPELINE                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   INPUT                 PROCESSING              OUTPUT       │
│   (sRGB)                (Linear sRGB)           (sRGB)       │
│                                                              │
│   ┌──────┐   gamma      ┌──────────────┐  gamma  ┌──────┐  │
│   │ JPEG │───removal───▶│   Filter     │──apply──▶│ HEIC │  │
│   │ HEIC │   (decode)   │   Pipeline   │  (encode)│ JPEG │  │
│   └──────┘              └──────────────┘          └──────┘  │
│                                                              │
│   Why Linear?                                               │
│   • Addition/subtraction are physically meaningful          │
│   • Blending operations are mathematically correct          │
│   • Matches how light actually combines in the real world   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### The Gamma Problem

**Problem**: sRGB images encode pixel values with a gamma curve (~2.2) to match human perception and optimize bit allocation. Performing operations directly on gamma-encoded values produces incorrect results.

**Example - Blending Two Colors**:

```
Gamma-encoded (WRONG):         Linear (CORRECT):

  50% gray + 50% gray           50% gray + 50% gray
  = 0.5 + 0.5 = 1.0             = 0.214 + 0.214 = 0.428
  = WHITE ❌                     = 50% gray ✓
                                  (after gamma encoding = 0.73)
```

**Solution**: Always decode to linear before processing, encode back to gamma after.

```swift
let context = CIContext(options: [
    .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
])
```

### Color Space Reference

| Color Space | Use Case | Characteristics |
|-------------|----------|-----------------|
| **Linear sRGB** | Internal processing | Physically accurate blending |
| **sRGB** | Display output, JPEG/PNG | Perceptually uniform, standard |
| **Display P3** | Wide-color devices | Larger gamut than sRGB |
| **ACES** | Professional workflows | Scene-referred, wide dynamic range |
| **CIE Lab** | Color difference calculation | Perceptually uniform distance |

---

## The CIE Color Model

### CIE 1931 XYZ

The foundation of colorimetry. XYZ values represent how a color stimulus affects the three cone types in human vision.

```
                         CIE 1931 xy Chromaticity Diagram

                         520nm (Green)
                              ╱╲
                             ╱  ╲
                            ╱    ╲
                           ╱      ╲
                          ╱   sRGB ╲
                         ╱   Gamut  ╲
            500nm ──────╱     ┌─────┐╲────── 560nm
                       ╱      │     │ ╲
                      ╱       │  D65│  ╲
                     ╱        │  •  │   ╲
                    ╱         │     │    ╲
                   ╱          └─────┘     ╲
                  ╱                        ╲
    480nm ───────╱                          ╲───── 600nm
                 │                           │
                 │                           │
    Blue ────────│                           │──────── Red
                 └───────────────────────────┘
                           700nm
```

### CIE Lab (L\*a\*b\*)

Perceptually uniform color space used for calculating color differences.

- **L\*** = Lightness (0 = black, 100 = white)
- **a\*** = Green-Red axis (-128 = green, +128 = red)
- **b\*** = Blue-Yellow axis (-128 = blue, +128 = yellow)

```swift
/// Convert linear RGB to CIE Lab
func rgbToLab(r: Float, g: Float, b: Float) -> (L: Float, a: Float, b: Float) {
    // Step 1: Linear RGB to XYZ (D65 illuminant)
    let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
    let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
    let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

    // Step 2: XYZ to Lab
    let xn: Float = 0.95047  // D65 white point
    let yn: Float = 1.00000
    let zn: Float = 1.08883

    func f(_ t: Float) -> Float {
        let delta: Float = 6.0 / 29.0
        return t > pow(delta, 3) ? pow(t, 1.0/3.0) : t / (3 * delta * delta) + 4.0/29.0
    }

    let L = 116 * f(y / yn) - 16
    let a = 500 * (f(x / xn) - f(y / yn))
    let b = 200 * (f(y / yn) - f(z / zn))

    return (L, a, b)
}
```

### CIEDE2000 Color Difference

The industry standard for measuring perceptual color difference.

**ΔE Interpretation**:
| ΔE Value | Perception |
|----------|------------|
| 0 - 1 | Not perceptible to human eye |
| 1 - 2 | Perceptible through close observation |
| 2 - 10 | Perceptible at a glance |
| 11 - 49 | Colors are more similar than opposite |
| 100 | Colors are exact opposite |

**FilmBox Quality Targets**:
- Average ΔE across filter: **< 5** (Good)
- Skin tone ΔE: **< 3** (Critical)
- Grayscale ΔE: **< 2** (Important for tone curve accuracy)

---

## Film Response Characteristics

### The H&D Curve (Characteristic Curve)

The Hurter-Driffield curve describes how film density responds to exposure.

```
        Density (D)
           │
       3.0 ─┤                              ╭───── Shoulder (highlight compression)
           │                             ╱
       2.5 ─┤                           ╱
           │                          ╱
       2.0 ─┤                        ╱
           │                       ╱
       1.5 ─┤                     ╱ ← Straight-line region (linear response)
           │                   ╱
       1.0 ─┤                 ╱
           │               ╱
       0.5 ─┤            ╱
           │          ╱
       D₀ ─┼────────╱ ← Toe (shadow compression)
           │      │
           └──────┴───────────────────────────
              -3  -2  -1   0   1   2   3
                    Log Exposure (log E)

        Key Parameters:
        • D₀ (D-min): Base + fog density
        • Gamma (γ): Slope of straight-line region
        • Dynamic Range: log E from toe to shoulder
        • Shoulder/Toe shape: Curve roll-off characteristics
```

### Mapping H&D to Digital

```swift
/// Film characteristic curve model
struct CharacteristicCurve {
    let dMin: Float          // Base fog density (typically 0.1-0.3)
    let dMax: Float          // Maximum density (typically 2.5-3.5)
    let gamma: Float         // Contrast (slope), typically 0.5-0.9
    let toeLength: Float     // Shadow region extent
    let shoulderLength: Float // Highlight region extent

    /// Convert exposure to density using curve model
    func density(at logExposure: Float) -> Float {
        // Simplified model - real implementation uses measured data points
        let normalized = (logExposure + 3) / 6  // Normalize to 0-1

        // Toe region (shadows)
        if normalized < toeLength {
            let t = normalized / toeLength
            return dMin + (t * t) * (gamma * toeLength)
        }

        // Shoulder region (highlights)
        if normalized > (1 - shoulderLength) {
            let t = (normalized - (1 - shoulderLength)) / shoulderLength
            let shoulderStart = dMin + gamma * (1 - shoulderLength - toeLength)
            return shoulderStart + (1 - (1 - t) * (1 - t)) * (dMax - shoulderStart)
        }

        // Straight-line region (midtones)
        return dMin + gamma * (normalized - toeLength)
    }

    /// Convert to CIToneCurve control points
    func toToneCurveData() -> ToneCurveData {
        let points = stride(from: 0.0, through: 1.0, by: 0.25).map { x -> ToneCurveData.CurvePoint in
            let logE = Float(x) * 6 - 3  // Map 0-1 to -3...+3 log exposure
            let d = density(at: logE)
            let y = (d - dMin) / (dMax - dMin)  // Normalize density to 0-1
            return ToneCurveData.CurvePoint(x: Float(x), y: y)
        }
        return ToneCurveData(composite: points, red: [], green: [], blue: [])
    }
}
```

---

## White Balance Theory

### Color Temperature

Color temperature describes the spectral characteristics of a light source, measured in Kelvin.

```
     ┌────────────────────────────────────────────────────────┐
     │                COLOR TEMPERATURE SCALE                  │
     ├────────────────────────────────────────────────────────┤
     │                                                         │
     │   1900K        3200K        5500K        6500K   10000K│
     │     │           │            │            │         │  │
     │  ───┼───────────┼────────────┼────────────┼─────────┼──│
     │     │           │            │            │         │  │
     │  Candle    Tungsten     Daylight       D65     Shade  │
     │  (warm)    (indoor)     (sun)      (standard)  (cool) │
     │                                                         │
     │   WARM ◄─────────────────────────────────────────► COOL │
     │   (orange/yellow)                           (blue)     │
     │                                                         │
     └────────────────────────────────────────────────────────┘
```

### Tint (Green-Magenta Axis)

Orthogonal to temperature, tint corrects for non-Planckian light sources (like fluorescent).

```swift
/// Apply white balance correction
func applyWhiteBalance(temperature: Float, tint: Float, to image: CIImage) -> CIImage {
    // CITemperatureAndTint uses a different parameterization:
    // - neutral: target white point (Kelvin, tint)
    // - targetNeutral: destination white point (typically D65)

    let filter = CIFilter.temperatureAndTint()
    filter.inputImage = image

    // Map our -100...+100 range to Kelvin/tint
    // temperature: -100 = 3200K (warm), 0 = 6500K (D65), +100 = 10000K (cool)
    let kelvin = 6500 + temperature * 35  // Approximate mapping
    filter.neutral = CIVector(x: CGFloat(kelvin), y: CGFloat(tint))
    filter.targetNeutral = CIVector(x: 6500, y: 0)  // D65, no tint

    return filter.outputImage ?? image
}
```

---

## HSL vs HSV vs HSB

### Why We Use HSL-Based Adjustments

```
┌─────────────────────────────────────────────────────────────┐
│           HSL vs HSV/HSB COMPARISON                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   HSL (Hue, Saturation, Lightness)                         │
│   • L=0 is black, L=100 is white                           │
│   • S=0 is gray (at any L)                                 │
│   • More intuitive for photographers                       │
│   • "Saturation" matches photographic terminology          │
│                                                              │
│   HSV/HSB (Hue, Saturation, Value/Brightness)              │
│   • V=0 is black, V=100 is the "brightest" color           │
│   • S=0 + V=100 is WHITE (not intuitive)                   │
│   • Common in graphics software                            │
│   • Less suitable for photo editing                        │
│                                                              │
│   OUR CHOICE: HSL                                          │
│   • Aligns with Lightroom/Capture One terminology          │
│   • More predictable behavior for users                    │
│   • Better separation of luminance and chroma              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Per-Channel HSL Implementation

```swift
/// Apply HSL adjustments per color channel
func applyHSL(_ adjustments: HSLAdjustments, to image: CIImage) -> CIImage {
    // We implement per-channel HSL using a combination of:
    // 1. Color isolation (select pixels by hue)
    // 2. Hue rotation (shift hue by delta)
    // 3. Saturation scaling (multiply saturation)
    // 4. Luminance adjustment (exposure per channel)

    var result = image

    let channels: [(adj: HSLAdjustments.HSLChannel, hueCenter: Float, hueWidth: Float)] = [
        (adjustments.red,     0,   30),
        (adjustments.orange,  30,  30),
        (adjustments.yellow,  60,  30),
        (adjustments.green,   120, 30),
        (adjustments.aqua,    180, 30),
        (adjustments.blue,    240, 30),
        (adjustments.purple,  270, 30),
        (adjustments.magenta, 300, 30)
    ]

    for (channel, hueCenter, hueWidth) in channels {
        guard channel != .identity else { continue }
        result = applyChannelHSL(
            channel,
            hueCenter: hueCenter,
            hueWidth: hueWidth,
            to: result
        )
    }

    return result
}

/// Apply HSL adjustment to a specific hue range
private func applyChannelHSL(
    _ channel: HSLAdjustments.HSLChannel,
    hueCenter: Float,
    hueWidth: Float,
    to image: CIImage
) -> CIImage {
    // Create a mask for pixels in this hue range
    // Apply hue shift, saturation change, and luminance change
    // Blend back using the mask

    // Implementation uses CIColorMatrix for saturation
    // and CIHueAdjust for hue shifts
    // Luminance via CIExposureAdjust with masking

    // ...detailed implementation...
    return image
}
```

---

## Vibrance vs Saturation

### The Perceptual Difference

```
┌─────────────────────────────────────────────────────────────┐
│           SATURATION VS VIBRANCE                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   SATURATION (Linear Scaling)                               │
│   • Affects all colors equally                              │
│   • Can clip already-saturated colors                       │
│   • Skin tones can become orange/unnatural                  │
│                                                              │
│   Before:  [Low sat color] [Med sat] [High sat skin]       │
│   +50 Sat: [Medium]        [High]    [CLIPPED/Orange] ❌   │
│                                                              │
│   ────────────────────────────────────────────────────────  │
│                                                              │
│   VIBRANCE (Intelligent Saturation)                         │
│   • Affects low-saturation colors more                      │
│   • Protects already-saturated colors from clipping         │
│   • Specifically protects skin tones (orange/red hues)      │
│                                                              │
│   Before:   [Low sat color] [Med sat] [High sat skin]      │
│   +50 Vibr: [Medium]        [Medium+] [Slightly higher] ✓  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
/// Apply vibrance (saturation-aware saturation boost)
func applyVibrance(_ amount: Float, to image: CIImage) -> CIImage {
    guard amount != 0 else { return image }

    // CIVibrance is available on iOS and handles this automatically
    let filter = CIFilter.vibrance()
    filter.inputImage = image
    filter.amount = amount / 100  // -1 to +1

    return filter.outputImage ?? image
}

/// How CIVibrance works (conceptually):
/// 1. Calculate current saturation of each pixel
/// 2. Calculate adjustment factor: higher for low-sat pixels
/// 3. Reduce adjustment for skin tone hues (orange-red range)
/// 4. Apply scaled saturation boost
```

---

## Color Matrix Operations

### 3x3 Color Transformation

Many film characteristics can be expressed as a 3x3 matrix transformation:

```
┌───────────────────────────────────────────────────────────────┐
│  ┌     ┐   ┌               ┐   ┌     ┐                       │
│  │ R'  │   │ a₁₁  a₁₂  a₁₃│   │  R  │                       │
│  │ G'  │ = │ a₂₁  a₂₂  a₂₃│ × │  G  │                       │
│  │ B'  │   │ a₃₁  a₃₂  a₃₃│   │  B  │                       │
│  └     ┘   └               ┘   └     ┘                       │
│                                                               │
│  Identity Matrix:                                            │
│  ┌           ┐                                               │
│  │ 1  0  0   │  No change                                   │
│  │ 0  1  0   │                                              │
│  │ 0  0  1   │                                              │
│  └           ┘                                               │
│                                                               │
│  Warm Film Example (Portra-like):                           │
│  ┌                 ┐                                         │
│  │ 1.05  0.02 -0.01│  Red: slight boost, tiny green leak    │
│  │ 0.03  0.98  0.01│  Green: slight red leak                │
│  │ 0.01  0.05  0.96│  Blue: green leak (warm shadows)       │
│  └                 ┘                                         │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### CIColorMatrix Usage

```swift
/// Apply 3x3 color matrix transformation
func applyColorMatrix(_ matrix: [[Float]], to image: CIImage) -> CIImage {
    let filter = CIFilter.colorMatrix()
    filter.inputImage = image

    // CIColorMatrix uses 4-component vectors (including alpha)
    filter.rVector = CIVector(x: CGFloat(matrix[0][0]),
                              y: CGFloat(matrix[0][1]),
                              z: CGFloat(matrix[0][2]),
                              w: 0)
    filter.gVector = CIVector(x: CGFloat(matrix[1][0]),
                              y: CGFloat(matrix[1][1]),
                              z: CGFloat(matrix[1][2]),
                              w: 0)
    filter.bVector = CIVector(x: CGFloat(matrix[2][0]),
                              y: CGFloat(matrix[2][1]),
                              z: CGFloat(matrix[2][2]),
                              w: 0)
    filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
    filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)

    return filter.outputImage ?? image
}
```

---

## References

### Academic Papers
1. Hunt, R.W.G. (2004). *The Reproduction of Colour* (6th ed.). Wiley.
2. Sharma, G., Wu, W., & Dalal, E.N. (2005). "The CIEDE2000 Color-Difference Formula". *Color Research & Application*, 30(1), 21-30.
3. Poynton, C. (2012). *Digital Video and HD: Algorithms and Interfaces* (2nd ed.). Morgan Kaufmann.

### Industry Standards
- **ICC Profile Specification** (v4.4): Color management framework
- **sRGB Standard** (IEC 61966-2-1): Standard RGB color space
- **ACES** (Academy Color Encoding System): Film industry standard

### Online Resources
- Bruce Lindbloom's Color Calculator: http://brucelindbloom.com
- Color FAQ by Charles Poynton: http://poynton.ca/ColorFAQ.html
- ICC Color Management: https://color.org

---

*Last updated: January 2026*
