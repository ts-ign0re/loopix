# Film Emulation Science

## Overview

This document explains the scientific basis for our film emulation algorithms, covering how real photographic film works and how we replicate its characteristics digitally.

---

## How Film Works

### The Three-Layer Emulsion

Color negative film consists of three light-sensitive layers, each responding to different wavelengths:

```
┌─────────────────────────────────────────────────────────────┐
│              COLOR NEGATIVE FILM STRUCTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Light →                                                    │
│   ↓                                                          │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ Blue-sensitive layer (Yellow dye forming)            │   │
│   ├─────────────────────────────────────────────────────┤   │
│   │ Yellow filter (blocks blue from lower layers)        │   │
│   ├─────────────────────────────────────────────────────┤   │
│   │ Green-sensitive layer (Magenta dye forming)          │   │
│   ├─────────────────────────────────────────────────────┤   │
│   │ Red-sensitive layer (Cyan dye forming)               │   │
│   ├─────────────────────────────────────────────────────┤   │
│   │ Film base (cellulose acetate or polyester)           │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   After Development:                                        │
│   • Silver halide crystals → metallic silver → removed     │
│   • Dye couplers remain in proportion to exposure          │
│   • Result: complementary color negative image             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Spectral Sensitivity Overlap

Film layers don't have perfect spectral separation—they overlap:

```
     Sensitivity
         │
     100%├────╮      ╭────╮      ╭────╮
         │    │      │    │      │    │
         │    │      │    │      │    │
      50%├────┼──╮╭──┼────┼──╮╭──┼────┤
         │    │  ││  │    │  ││  │    │
         │    │  ││  │    │  ││  │    │
         │    │  ╰╯  │    │  ╰╯  │    │
       0%└────┴──────┴────┴──────┴────┴────
         400   450   500   550   600   650   700 nm
              BLUE        GREEN       RED

         │←Blue→│ │←─Green─→│ │←──Red──→│
           Layer     Layer      Layer

     Overlap regions create:
     • Blue-green (cyan colors) cross-talk
     • Green-red (yellow colors) cross-talk
     • This is what gives film its "look"
```

### Why This Matters for Emulation

The overlap means:
1. **Pure colors in reality affect multiple layers** → Film never captures "pure" colors
2. **Different films have different overlap amounts** → Unique color signatures
3. **This is NOT a defect** → It's the character we're trying to emulate

---

## Film Characteristics We Emulate

### 1. Characteristic Curve (Tonal Response)

Each film stock has a unique response to light exposure:

```
┌─────────────────────────────────────────────────────────────┐
│         FILM STOCK CHARACTERISTIC CURVES                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Density                                                   │
│      │                                                       │
│   3.0├                      ╭──── Velvia (high contrast)    │
│      │                    ╱╱                                 │
│   2.5├                  ╱╱  ╭──── Portra (low contrast)     │
│      │                ╱╱  ╱╱                                 │
│   2.0├              ╱╱  ╱╱                                   │
│      │            ╱╱  ╱╱                                     │
│   1.5├          ╱╱  ╱╱                                       │
│      │        ╱╱  ╱╱                                         │
│   1.0├      ╱╱  ╱╱                                           │
│      │    ╱╱ ╱╱                                              │
│   0.5├  ╱╱╱╱                                                 │
│      │╱╱╱                                                    │
│   0.0└─────┴─────┴─────┴─────┴─────┴─────                   │
│          -2    -1     0     1     2    Log E                │
│                                                              │
│   Portra: Extended dynamic range, gentle rolloff            │
│   Velvia: Punchy contrast, quick saturation                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Implementation**: We use `CIToneCurve` with 5 control points derived from published H&D data.

### 2. Color Cross-Talk Matrix

The spectral overlap creates a characteristic color shift:

```swift
/// Example: Kodak Portra 400 color matrix
/// Derived from spectral sensitivity data
let portra400Matrix: [[Float]] = [
    [1.02,  0.03, -0.02],  // Red channel: warm bias
    [0.02,  0.97,  0.02],  // Green: slight warmth
    [0.01,  0.04,  0.94]   // Blue: absorbs into shadows → warm shadows
]

/// Example: Fuji Velvia 50 color matrix
/// Known for saturated colors and cool shadows
let velvia50Matrix: [[Float]] = [
    [1.08, -0.02,  0.00],  // Red: boosted
    [0.00,  1.05,  0.00],  // Green: boosted
    [-0.02, 0.00,  1.02]   // Blue: slightly boosted, cool bias
]
```

### 3. Dye Cloud Formation (Grain)

Film grain is not random noise—it's the result of silver halide crystal development:

```
┌─────────────────────────────────────────────────────────────┐
│                  FILM GRAIN CHARACTERISTICS                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ISO 100 (Fine Grain)          ISO 800 (Coarse Grain)      │
│   ┌────────────────────┐        ┌────────────────────┐      │
│   │ · · · · · · · · ·  │        │ ○  ·  ○ ·  ○  ·   │      │
│   │  · · · · · · · · · │        │   ○ ·  ○  ·  ○ ·  │      │
│   │ · · · · · · · · ·  │        │ ○ ·  ○  ·  ○  · ○ │      │
│   │  · · · · · · · · · │        │  · ○ ·  ○ ·  ○ ·  │      │
│   └────────────────────┘        └────────────────────┘      │
│                                                              │
│   Properties:                                               │
│   • Size: Larger crystals = higher sensitivity = more grain │
│   • Distribution: Clustered, not uniform                    │
│   • Correlation: Grain is correlated between RGB layers    │
│   • Density-dependent: More visible in midtones            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Why Random Noise is Wrong**:
- Digital noise is uncorrelated between pixels
- Film grain has spatial correlation (clusters)
- Film grain is exposure-dependent (less in shadows/highlights)
- Film grain has characteristic size distribution

**Our Implementation**: Custom Metal kernel with:
1. Perlin noise base for natural clustering
2. Exposure-weighted application (less in shadows)
3. Size distribution matching target film stock
4. Optional color grain for C-41 films

### 4. Halation (Light Bloom)

When bright light hits film, it can reflect off the film base back into the emulsion:

```
┌─────────────────────────────────────────────────────────────┐
│                    HALATION EFFECT                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Incident Light                                            │
│        ↓                                                     │
│   ┌─────────────────────────────────────┐                   │
│   │  Emulsion Layers                    │                   │
│   ├─────────────────────────────────────┤                   │
│   │  Anti-halation layer (absorbs)      │ ← Modern film    │
│   ├─────────────────────────────────────┤                   │
│   │  Film Base                          │                   │
│   └─────────────────────────────────────┘                   │
│        ↑                                                     │
│   Light reflects back (halation)                            │
│                                                              │
│   Result: Red/orange glow around bright areas              │
│   • Red because anti-halation dye absorbs blue/green       │
│   • More pronounced on older/cheaper film stocks           │
│   • Artistic effect popular with CineStill 800T            │
│                                                              │
│   Visual Example:                                           │
│   ┌──────────────────┐                                      │
│   │       ┌──┐       │   Before: Sharp bright light        │
│   │       │░░│       │                                      │
│   │       └──┘       │                                      │
│   └──────────────────┘                                      │
│                                                              │
│   ┌──────────────────┐                                      │
│   │     ╭────╮       │   After: Red halo around light      │
│   │   ╭─┤░░░░├─╮     │                                      │
│   │     ╰────╯       │                                      │
│   └──────────────────┘                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Implementation**:
```swift
/// Halation effect using Metal kernel
/// 1. Extract bright regions (threshold)
/// 2. Apply gaussian blur
/// 3. Tint with halation color (red-orange)
/// 4. Blend additively with original

func applyHalation(_ params: HalationData, to image: CIImage) -> CIImage {
    guard params.intensity > 0 else { return image }

    // 1. Create luminance mask for highlights
    let luminance = image.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0),
        "inputGVector": CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0),
        "inputBVector": CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
    ])

    // 2. Threshold to extract highlights
    let threshold: Float = 0.8
    // ... threshold operation ...

    // 3. Blur the highlights
    let blurred = highlights.applyingGaussianBlur(sigma: Double(params.spread * 50))

    // 4. Tint with halation color
    let hue = params.hue / 360.0
    let tintColor = CIColor(hue: CGFloat(hue), saturation: 0.8, brightness: 1.0)
    let tinted = blurred.applyingFilter("CIColorMonochrome", parameters: [
        "inputColor": tintColor
    ])

    // 5. Blend additively
    let intensity = params.intensity / 100.0
    return image.applyingFilter("CIAdditionCompositing", parameters: [
        "inputBackgroundImage": tinted.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity))
        ])
    ])
}
```

### 5. Base + Fog (Lifted Blacks)

Unexposed film has a minimum density called "base + fog":

```
┌─────────────────────────────────────────────────────────────┐
│                   BASE + FOG EFFECT                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Digital (no base fog)         Film (with base fog)        │
│                                                              │
│   ┌────────────────────┐        ┌────────────────────┐      │
│   │████████████████████│        │████████████████████│      │
│   │████████████████████│        │████████████████████│      │
│   │████████████████████│        │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│      │
│   │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│        │░░░░░░░░░░░░░░░░░░░░│      │
│   │░░░░░░░░░░░░░░░░░░░░│        │░░░░░░░░░░░░░░░░░░░░│      │
│   │                    │        │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│ ← Lifted
│   └────────────────────┘        └────────────────────┘      │
│   Black = 0                     Black = 0.05-0.15           │
│                                 (depends on film stock)     │
│                                                              │
│   Visual Result:                                            │
│   • Shadows appear softer, less harsh                       │
│   • Creates "filmic" rather than "digital" look             │
│   • Often has color tint (orange mask in C-41)             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Implementation**: Tone curve point 0 starts at y > 0

### 6. Shoulder Compression (Highlight Rolloff)

Film has natural highlight protection—it compresses rather than clips:

```
     Digital Clipping          Film Shoulder Rolloff
     (harsh, sudden)           (gentle, gradual)

     Output                    Output
        │                         │
     1.0├──────┬───────        1.0├────────╮
        │      │                  │        │
     0.8├      │               0.8├       ╱│
        │      │                  │      ╱ │
     0.6├      │               0.6├    ╱   │
        │      │                  │   ╱    │
     0.4├      │               0.4├  ╱     │
        │      │                  │ ╱      │
     0.2├    ╱ │               0.2├╱       │
        │  ╱   │                  │        │
     0.0└─╱────┴───────        0.0└────────┴───────
        0.0   1.0   1.5+       0.0   1.0   1.5   2.0+
           Input                  Input

     • Blown highlights           • Smooth rolloff
     • Lost detail               • Retained detail
     • Harsh look                • Pleasing look
```

**Implementation**: Tone curve point 4 at y < 1.0

---

## Film Stock Profiles

### Kodak Portra 400 Profile

```swift
struct Portra400Profile {
    // Characteristic curve: gentle S-curve
    static let toneCurve = ToneCurveData(
        composite: [
            CurvePoint(x: 0.00, y: 0.03),   // Lifted blacks (base fog)
            CurvePoint(x: 0.25, y: 0.22),   // Gentle toe
            CurvePoint(x: 0.50, y: 0.52),   // Neutral midtones
            CurvePoint(x: 0.75, y: 0.78),   // Gentle shoulder
            CurvePoint(x: 1.00, y: 0.97)    // Soft highlights
        ],
        red: [], green: [], blue: []
    )

    // Color characteristics: warm, natural skin tones
    static let colorMatrix: [[Float]] = [
        [1.02, 0.03, -0.02],
        [0.02, 0.97, 0.02],
        [0.01, 0.04, 0.94]
    ]

    // Grain: fine, subtle
    static let grain = GrainData(
        amount: 15,
        size: 0.4,
        roughness: 0.5,
        monochromatic: false
    )

    // Split tone: warm shadows, neutral highlights
    static let splitTone = SplitToneData(
        highlightHue: 45,
        highlightSaturation: 5,
        shadowHue: 35,
        shadowSaturation: 15,
        balance: -10
    )
}
```

### Fuji Velvia 50 Profile

```swift
struct Velvia50Profile {
    // Characteristic curve: high contrast, punchy
    static let toneCurve = ToneCurveData(
        composite: [
            CurvePoint(x: 0.00, y: 0.01),   // Deep blacks
            CurvePoint(x: 0.25, y: 0.18),   // Contrast toe
            CurvePoint(x: 0.50, y: 0.55),   // Pushed midtones
            CurvePoint(x: 0.75, y: 0.82),   // Contrast shoulder
            CurvePoint(x: 1.00, y: 0.99)    // Bright highlights
        ],
        red: [], green: [], blue: []
    )

    // Color characteristics: highly saturated
    static let colorMatrix: [[Float]] = [
        [1.08, -0.02, 0.00],
        [0.00, 1.06, 0.00],
        [-0.02, 0.00, 1.04]
    ]

    static let saturation: Float = 20   // +20% saturation boost
    static let vibrance: Float = 15     // Additional vibrance

    // Grain: very fine (slide film)
    static let grain = GrainData(
        amount: 8,
        size: 0.2,
        roughness: 0.3,
        monochromatic: false
    )
}
```

### CineStill 800T Profile

```swift
struct CineStill800TProfile {
    // Characteristic curve: cinema-style
    static let toneCurve = ToneCurveData(
        composite: [
            CurvePoint(x: 0.00, y: 0.05),   // Lifted blacks
            CurvePoint(x: 0.25, y: 0.24),
            CurvePoint(x: 0.50, y: 0.50),
            CurvePoint(x: 0.75, y: 0.76),
            CurvePoint(x: 1.00, y: 0.95)
        ],
        red: [], green: [], blue: []
    )

    // Tungsten balanced (3200K) - appears cool under daylight
    static let temperature: Float = -25  // Cool shift

    // Famous halation (no remjet layer)
    static let halation = HalationData(
        intensity: 40,
        hue: 15,        // Red-orange
        spread: 0.6
    )

    // Grain: noticeable, cinematic
    static let grain = GrainData(
        amount: 35,
        size: 0.6,
        roughness: 0.6,
        monochromatic: false
    )
}
```

---

## Validation Methodology

### Reference Material

We validate our emulations against:
1. **Lab-scanned film** - Professional scans with known settings
2. **Manufacturer data sheets** - Published H&D curves and spectral data
3. **Community comparisons** - A/B tests with real film users

### Metrics

| Metric | Target | Method |
|--------|--------|--------|
| Color accuracy (ΔE) | < 5 avg | ColorChecker comparison |
| Tone curve match | < 3% deviation | Grayscale ramp comparison |
| Grain realism | Subjective | Blind comparison test |
| Overall impression | >80% approval | Community survey |

---

## Limitations & Honest Disclosure

### What We CAN Emulate Well
- Characteristic curves (tone response)
- Color cross-talk (color signature)
- Grain appearance (with Metal kernels)
- Halation and bloom effects
- Base fog and lifted blacks

### What We CANNOT Perfectly Emulate
- **Light scattering within emulsion**: Physical phenomenon we approximate
- **Reciprocity failure**: Film responds differently to long exposures
- **Development variations**: Real film varies batch to batch
- **Print paper characteristics**: We emulate scan, not print

### Our Approach to Honesty
We do NOT claim to be "identical to film." We claim to be:
- **Scientifically informed** - Based on real film data
- **Perceptually similar** - Achieves the look and feel
- **Consistently reproducible** - Unlike real film

---

*Last updated: January 2026*
