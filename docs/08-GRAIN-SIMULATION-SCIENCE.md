# Grain Simulation Science

## Overview

Film grain is one of the most distinctive characteristics of analog photography. This document explains the physics of real film grain and our approach to scientifically-accurate digital simulation.

---

## The Physics of Film Grain

### Silver Halide Crystal Formation

Film grain originates from silver halide crystals in the emulsion:

```
┌─────────────────────────────────────────────────────────────┐
│              SILVER HALIDE CRYSTAL STRUCTURE                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Emulsion Composition:                                     │
│   ┌─────────────────────────────────────────────────────┐   │
│   │  ╭─╮  ╭──╮     ╭─╮    ╭──╮                         │   │
│   │  │●│  │●●│     │●│    │●●│   ● = Silver halide    │   │
│   │  ╰─╯  ╰──╯ ╭─╮ ╰─╯╭─╮ ╰──╯       crystal           │   │
│   │            │●│    │●│                               │   │
│   │  ╭──╮  ╭─╮ ╰─╯ ╭──╯╰╮      Suspended in gelatin   │   │
│   │  │●●│  │●│     │●●●●│      matrix                  │   │
│   │  ╰──╯  ╰─╯     ╰────╯                               │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   Crystal Properties:                                       │
│   • Size: 0.2 - 2.0 micrometers                            │
│   • Shape: Varies by film type (cubic, tabular, etc.)      │
│   • Distribution: Random but statistically predictable      │
│   • Sensitivity: Larger crystals = higher ISO = more grain │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Exposure and Development

When light hits the crystals, a latent image forms:

```
┌─────────────────────────────────────────────────────────────┐
│              GRAIN FORMATION PROCESS                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   STEP 1: Exposure                                          │
│   ┌─────────────────────────────────────────────────────┐   │
│   │     Light (photons)                                 │   │
│   │         ↓ ↓ ↓                                       │   │
│   │     ╭───────╮                                       │   │
│   │     │ AgBr  │  →  Ag+ + e- (latent image center)   │   │
│   │     ╰───────╯                                       │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   STEP 2: Development                                       │
│   ┌─────────────────────────────────────────────────────┐   │
│   │     Exposed crystal → Metallic silver (opaque)      │   │
│   │     ╭───╮            ╭███╮                          │   │
│   │     │ ● │    →      │███│  Developed grain         │   │
│   │     ╰───╯            ╰███╯                          │   │
│   │                                                      │   │
│   │     Unexposed crystal → Washed away (transparent)   │   │
│   │     ╭───╮            (nothing)                      │   │
│   │     │   │    →                                      │   │
│   │     ╰───╯                                           │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   Result: Random pattern of opaque silver clusters         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Grain Size vs ISO

The fundamental trade-off in film design:

```
     ISO 50                 ISO 400                ISO 3200
     (Fine grain)           (Medium grain)         (Coarse grain)

     ┌─────────────┐        ┌─────────────┐       ┌─────────────┐
     │·············│        │·  ·  ·  ·  ·│       │○   ○   ○   │
     │·············│        │  ·  ·  ·  · │       │  ○   ○   ○ │
     │·············│        │·  ·  ·  ·  ·│       │○   ○   ○   │
     │·············│        │  ·  ·  ·  · │       │  ○   ○   ○ │
     │·············│        │·  ·  ·  ·  ·│       │○   ○   ○   │
     └─────────────┘        └─────────────┘       └─────────────┘

     Crystal size:          Crystal size:         Crystal size:
     ~0.2-0.5 μm            ~0.5-1.0 μm           ~1.0-2.0 μm

     Characteristics:       Characteristics:       Characteristics:
     • Very fine            • Visible grain        • Prominent grain
     • High resolution      • Good versatility     • High sensitivity
     • Less sensitive       • Balanced             • Lower resolution
```

---

## What Makes Film Grain Unique

### 1. Spatial Correlation (Clustering)

Film grain is NOT random pixel noise. It has spatial structure:

```
┌─────────────────────────────────────────────────────────────┐
│       RANDOM NOISE vs FILM GRAIN                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Random (Digital) Noise:       Film Grain:                │
│                                                              │
│   ┌─────────────────────┐      ┌─────────────────────┐     │
│   │▪ ▫ ▪ ▫ ▫ ▪ ▫ ▪ ▫ ▪│      │  ▪▪   ▪▪▪    ▪▪   │     │
│   │▫ ▪ ▫ ▪ ▫ ▪ ▫ ▪ ▫ ▪│      │ ▪▪▪   ▪▪   ▪▪▪▪   │     │
│   │▪ ▫ ▪ ▫ ▪ ▫ ▪ ▫ ▪ ▫│      │  ▪    ▪▪▪   ▪▪    │     │
│   │▫ ▪ ▫ ▪ ▫ ▪ ▫ ▪ ▫ ▪│      │   ▪▪▪    ▪▪     ▪▪│     │
│   │▪ ▫ ▫ ▪ ▫ ▪ ▫ ▪ ▫ ▪│      │ ▪▪      ▪▪▪   ▪▪▪│     │
│   └─────────────────────┘      └─────────────────────┘     │
│                                                              │
│   • Uncorrelated pixels        • Clusters of similar values │
│   • Uniform distribution       • Organic, natural texture   │
│   • Harsh, unpleasant         • Pleasing, "filmic"          │
│   • Same at all frequencies    • Has characteristic size    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2. Density Dependence

Film grain visibility varies with exposure:

```
     Grain Visibility by Exposure Zone:

     ┌─────────────────────────────────────────────────────────┐
     │                                                         │
     │   Shadows         Midtones        Highlights           │
     │   (Zone 0-III)    (Zone IV-VI)    (Zone VII-X)        │
     │                                                         │
     │   ┌───────┐       ┌───────┐       ┌───────┐            │
     │   │███████│       │▒▒▒▒▒▒▒│       │░░░░░░░│            │
     │   │███████│       │▒▒▒▒▒▒▒│       │░░░░░░░│            │
     │   │███████│       │▒▒▒▒▒▒▒│       │░░░░░░░│            │
     │   └───────┘       └───────┘       └───────┘            │
     │                                                         │
     │   Low grain       Maximum grain   Lower grain          │
     │   (few developed  (mix of        (mostly developed     │
     │    crystals)      both)          crystals)             │
     │                                                         │
     │   Grain Visibility                                     │
     │        │                                                │
     │    100%├          ╭───────╮                            │
     │        │        ╱           ╲                           │
     │     50%├      ╱               ╲                         │
     │        │    ╱                   ╲                       │
     │      0%├───╱─────────────────────╲───                  │
     │        └───┴───────┴───────┴───────┴───                │
     │         Shadows   Midtones  Highlights                 │
     │                                                         │
     └─────────────────────────────────────────────────────────┘
```

### 3. Color vs Monochrome Grain

Color negative film has different grain in each layer:

```
┌─────────────────────────────────────────────────────────────┐
│              COLOR FILM GRAIN STRUCTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   CHROMOGENIC (C-41 Color) FILM:                           │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ Yellow layer grain  (Blue-sensitive)                │   │
│   │   ·    ·   ·  ·   ·   ·   ·  ·   ·   ·             │   │
│   ├─────────────────────────────────────────────────────┤   │
│   │ Magenta layer grain (Green-sensitive)               │   │
│   │  ·  ·   ·   ·  ·   ·   ·  ·   ·   ·   ·            │   │
│   ├─────────────────────────────────────────────────────┤   │
│   │ Cyan layer grain    (Red-sensitive)                 │   │
│   │ ·   ·  ·   ·   · ·    ·  ·   ·  ·   ·              │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   Key insight: Layers have DIFFERENT grain patterns!       │
│   • Not perfectly aligned                                   │
│   • Creates subtle color variations                        │
│   • More complex than grayscale grain                      │
│                                                              │
│   BLACK & WHITE FILM:                                       │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ Single emulsion layer                               │   │
│   │  ·  ·  ·   ·  ·  ·   ·  ·  ·   ·  ·  ·            │   │
│   │   ·  ·  ·   ·  ·  ·   ·  ·  ·   ·  ·              │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   • Same grain pattern affects all tones equally           │
│   • No color noise, only luminance variation               │
│   • Generally more prominent, graphic quality              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Our Implementation

### Grain Model Parameters

```swift
struct GrainData: Codable, Hashable, Sendable {
    var amount: Float = 0        // 0...100 (overall intensity)
    var size: Float = 0.5        // 0...1 (crystal size simulation)
    var roughness: Float = 0.5   // 0...1 (texture character)
    var monochromatic: Bool = true // true = B&W style grain

    static let none = GrainData()
}
```

### Why We Use Procedural Noise

Real film grain patterns are:
- **Resolution-independent** - Look correct at any zoom
- **Temporally stable** - Don't flicker in video
- **Computationally efficient** - Generate on-the-fly

We use **Perlin noise** (or similar) because:
- Natural-looking clusters (spatial correlation)
- Controllable frequency characteristics
- Efficient Metal/GPU implementation

### Metal Kernel Implementation

```metal
// GrainKernel.metal

#include <metal_stdlib>
using namespace metal;

// Perlin noise implementation for organic texture
float perlinNoise(float2 p, float scale) {
    // Hash function for pseudo-random gradients
    float2 i = floor(p * scale);
    float2 f = fract(p * scale);

    // Smoothstep for interpolation
    float2 u = f * f * (3.0 - 2.0 * f);

    // Four corner gradients
    float a = hash(i + float2(0, 0));
    float b = hash(i + float2(1, 0));
    float c = hash(i + float2(0, 1));
    float d = hash(i + float2(1, 1));

    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Multi-octave noise for realistic grain texture
float grainNoise(float2 uv, float size, float roughness) {
    float noise = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0 / size;
    float totalAmplitude = 0.0;

    // 4 octaves of noise
    for (int i = 0; i < 4; i++) {
        noise += amplitude * perlinNoise(uv, frequency);
        totalAmplitude += amplitude;
        amplitude *= roughness;
        frequency *= 2.0;
    }

    return noise / totalAmplitude;
}

kernel void grainKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float& amount [[buffer(0)]],
    constant float& size [[buffer(1)]],
    constant float& roughness [[buffer(2)]],
    constant int& monochromatic [[buffer(3)]],
    constant float2& seed [[buffer(4)]],  // Random offset for variation
    uint2 gid [[thread_position_in_grid]]
) {
    float4 color = inTexture.read(gid);

    // Normalized coordinates
    float2 uv = float2(gid) / float2(inTexture.get_width(), inTexture.get_height());
    uv += seed;  // Add randomness

    // Calculate grain scale based on size parameter
    // Larger size = bigger grain clusters
    float grainScale = mix(100.0, 20.0, size);

    if (monochromatic) {
        // Single channel grain (B&W style)
        float grain = grainNoise(uv, grainScale, roughness);
        grain = (grain - 0.5) * 2.0;  // Center around 0

        // Calculate luminance for density-dependent grain
        float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

        // Grain is most visible in midtones
        // Bell curve centered at 0.5
        float midtoneFactor = 1.0 - abs(luminance - 0.5) * 2.0;
        midtoneFactor = max(midtoneFactor, 0.2);  // Minimum visibility

        // Apply grain
        float grainAmount = amount / 100.0 * 0.15;  // Scale to reasonable range
        color.rgb += grain * grainAmount * midtoneFactor;
    } else {
        // Color grain (C-41 style)
        // Different noise patterns for each channel
        float grainR = grainNoise(uv + float2(0.0, 0.0), grainScale, roughness);
        float grainG = grainNoise(uv + float2(17.3, 31.7), grainScale, roughness);
        float grainB = grainNoise(uv + float2(43.1, 59.2), grainScale, roughness);

        float3 grainColor = float3(grainR, grainG, grainB);
        grainColor = (grainColor - 0.5) * 2.0;

        float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
        float midtoneFactor = 1.0 - abs(luminance - 0.5) * 2.0;
        midtoneFactor = max(midtoneFactor, 0.2);

        float grainAmount = amount / 100.0 * 0.12;
        color.rgb += grainColor * grainAmount * midtoneFactor;
    }

    // Clamp to valid range
    color.rgb = clamp(color.rgb, 0.0, 1.0);

    outTexture.write(color, gid);
}
```

### Fallback CIFilter Implementation

When Metal kernels aren't available:

```swift
func applyGrain(_ grain: GrainData, to image: CIImage) -> CIImage {
    guard grain.amount > 0 else { return image }

    // 1. Generate noise texture
    let noiseGenerator = CIFilter.randomGenerator()
    guard var noise = noiseGenerator.outputImage else { return image }

    // 2. Scale noise based on size parameter
    let scale = 1.0 / (grain.size * 2 + 0.5)
    noise = noise.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

    // 3. Crop to image extent
    noise = noise.cropped(to: image.extent)

    // 4. Convert to monochrome if needed
    if grain.monochromatic {
        let mono = CIFilter.colorMonochrome()
        mono.inputImage = noise
        mono.color = CIColor.gray
        mono.intensity = 1.0
        noise = mono.outputImage ?? noise
    }

    // 5. Create luminance mask for density-dependent application
    let luminanceMask = createMidtoneMask(for: image)

    // 6. Blend noise with original
    let intensity = grain.amount / 100.0 * 0.2
    let blend = CIFilter.dissolveTransition()
    blend.inputImage = applyWithMask(noise: noise, mask: luminanceMask, intensity: intensity)
    blend.targetImage = image
    blend.time = Float(intensity)

    return blend.outputImage ?? image
}

/// Create mask that's brightest in midtones
func createMidtoneMask(for image: CIImage) -> CIImage {
    // Convert to luminance
    let luminance = image.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 0.2126, y: 0.2126, z: 0.2126, w: 0),
        "inputGVector": CIVector(x: 0.7152, y: 0.7152, z: 0.7152, w: 0),
        "inputBVector": CIVector(x: 0.0722, y: 0.0722, z: 0.0722, w: 0)
    ])

    // Apply curve that peaks at midtones
    // y = 1 - |2x - 1| approximates the bell curve
    let toneCurve = CIFilter.toneCurve()
    toneCurve.inputImage = luminance
    toneCurve.point0 = CGPoint(x: 0, y: 0.3)    // Some grain in shadows
    toneCurve.point1 = CGPoint(x: 0.25, y: 0.7)
    toneCurve.point2 = CGPoint(x: 0.5, y: 1.0)  // Maximum in midtones
    toneCurve.point3 = CGPoint(x: 0.75, y: 0.7)
    toneCurve.point4 = CGPoint(x: 1, y: 0.3)    // Some grain in highlights

    return toneCurve.outputImage ?? luminance
}
```

---

## Film Stock Grain Profiles

### Kodak Portra 400

```swift
static let portra400Grain = GrainData(
    amount: 15,        // Subtle, fine grain
    size: 0.4,         // Medium-small clusters
    roughness: 0.5,    // Balanced texture
    monochromatic: false  // Color grain (C-41)
)
```

### Kodak Tri-X 400

```swift
static let triX400Grain = GrainData(
    amount: 40,        // Prominent, classic grain
    size: 0.6,         // Medium-large clusters
    roughness: 0.6,    // More texture
    monochromatic: true   // B&W film
)
```

### Ilford Delta 3200

```swift
static let delta3200Grain = GrainData(
    amount: 65,        // Very prominent grain
    size: 0.8,         // Large clusters
    roughness: 0.7,    // Rough texture
    monochromatic: true   // B&W film
)
```

### Fuji Velvia 50

```swift
static let velvia50Grain = GrainData(
    amount: 8,         // Very fine grain (slide film)
    size: 0.2,         // Small clusters
    roughness: 0.3,    // Smooth texture
    monochromatic: false  // Color grain (E-6)
)
```

---

## Validation

### Visual Comparison Test

We validate grain against real film scans:

1. **Zoom to 100%** - Compare grain structure
2. **View at distance** - Compare overall texture impression
3. **Check midtones** - Verify density-dependent visibility
4. **Check color films** - Verify RGB channel independence

### Metrics

| Metric | Measurement Method | Target |
|--------|-------------------|--------|
| Cluster size | Autocorrelation analysis | Match reference film |
| Spatial frequency | FFT analysis | Match characteristic curve |
| Density response | Zone comparison | Peak in midtones |
| Color independence | Channel separation | Visible in color mode |

---

## Scientific References

### Academic Papers

1. Dainty, J. C., & Shaw, R. (1974). "Image Science: Principles, Analysis and Evaluation of Photographic-Type Imaging Processes." Academic Press.

2. Shaw, R. (1978). "The Application of Fourier Techniques and Information Theory to the Assessment of Photographic Image Quality." *Photographic Science and Engineering*, 6(6), 281-286.

3. Perlin, K. (1985). "An Image Synthesizer." *ACM SIGGRAPH Computer Graphics*, 19(3), 287-296.

### Technical Resources

- Kodak Publication H-1: "Kodak Black-and-White Photographic Papers"
- Fujifilm Technical Data Sheets
- Ilford Photo Technical Information

---

*Last updated: January 2026*
