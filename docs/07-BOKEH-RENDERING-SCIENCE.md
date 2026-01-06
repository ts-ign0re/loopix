# Bokeh Rendering Science

## Overview

Bokeh (from Japanese "暈け," meaning "blur" or "haze") refers to the aesthetic quality of out-of-focus areas in a photograph. This document explains the optical science behind bokeh and our approach to digital simulation.

---

## Optical Fundamentals

### How Lenses Create Blur

When a point of light is out of focus, it's projected onto the sensor not as a point, but as a disk called the **circle of confusion** (CoC):

```
┌─────────────────────────────────────────────────────────────┐
│              CIRCLE OF CONFUSION                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   In Focus:                    Out of Focus:                │
│                                                              │
│   Light rays      Sensor      Light rays      Sensor       │
│       │             │             │             │           │
│       │  ╲         │             │  ╲          │           │
│       │   ╲        │             │   ╲         │           │
│   ○───┼────╳───────┼         ○───┼────╳────────┼           │
│       │   ╱        │ ·           │   ╱         │ ●         │
│       │  ╱         │             │  ╱          │  (disk)   │
│       │             │             │             │           │
│                                                              │
│   Result: Sharp point         Result: Blurred disk         │
│                                                              │
│   CoC Diameter depends on:                                  │
│   • Distance from focus plane                               │
│   • Aperture size (f-number)                               │
│   • Focal length                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Aperture Shape Determines Bokeh Shape

The shape of the aperture blades directly affects bokeh appearance:

```
┌─────────────────────────────────────────────────────────────┐
│              APERTURE SHAPES AND BOKEH                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Aperture                    Bokeh Shape                   │
│                                                              │
│   ┌───────┐                  Perfect Circle                 │
│   │  ○    │  Circular        Smooth, "creamy"               │
│   │       │  (wide open)     Most desirable                 │
│   └───────┘                                                  │
│                                                              │
│   ┌───────┐                  Hexagonal                      │
│   │  ⬡    │  6-blade         Visible edges                 │
│   │       │  diaphragm       "Mechanical" look              │
│   └───────┘                                                  │
│                                                              │
│   ┌───────┐                  Octagonal                      │
│   │  ⯃    │  8-blade         Smoother edges                │
│   │       │  diaphragm       Modern lenses                 │
│   └───────┘                                                  │
│                                                              │
│   ┌───────┐                  Rounded Polygon               │
│   │ (○)   │  Rounded         Nearly circular                │
│   │       │  blades          Premium lenses                 │
│   └───────┘                                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Cat's Eye Effect (Mechanical Vignetting)

At frame edges, light rays are cut off by the lens barrel, creating elliptical bokeh:

```
┌─────────────────────────────────────────────────────────────┐
│              CAT'S EYE / MECHANICAL VIGNETTING               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Frame Position:           Bokeh Shape:                    │
│                                                              │
│   ┌─────────────────────┐                                   │
│   │ ◗               ◖   │   Edges: Elliptical/cat's eye   │
│   │                     │                                   │
│   │     ○       ○       │   Mid: Slightly oval             │
│   │                     │                                   │
│   │         ●           │   Center: Circular               │
│   │                     │                                   │
│   │     ○       ○       │                                   │
│   │                     │                                   │
│   │ ◖               ◗   │                                   │
│   └─────────────────────┘                                   │
│                                                              │
│   Cause: Off-axis light rays are partially blocked          │
│   Effect: More pronounced with longer focal lengths         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Bokeh Quality Characteristics

### "Good" vs "Bad" Bokeh

Bokeh quality is subjective but has measurable characteristics:

```
┌─────────────────────────────────────────────────────────────┐
│              BOKEH QUALITY COMPARISON                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   "GOOD" BOKEH (Smooth)           "BAD" BOKEH (Harsh)       │
│                                                              │
│   ┌─────────────────────┐        ┌─────────────────────┐   │
│   │   ╭───╮             │        │   ┌───┐             │   │
│   │  ╱░░░░░╲            │        │  ╱█████╲            │   │
│   │ │░░░░░░░│           │        │ │░░█░░░│            │   │
│   │  ╲░░░░░╱            │        │  ╲░░░░░╱            │   │
│   │   ╰───╯             │        │   └───┘             │   │
│   └─────────────────────┘        └─────────────────────┘   │
│                                                              │
│   • Even brightness              • Bright edge (outlining) │
│   • Soft edges                   • Hard edges              │
│   • Smooth gradients             • Visible onion rings     │
│   • Colors blend naturally       • Colors separate harshly │
│                                                              │
│   Caused by:                     Caused by:                │
│   • Apodization elements         • Spherical aberration    │
│   • Neutral density graduation   • Aspherical elements     │
│   • Careful optical design       • Budget lens design      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Spherical Aberration and Bokeh

Spherical aberration affects whether bokeh has edge emphasis:

```
     UNDER-CORRECTED                    OVER-CORRECTED
     (Soft foreground, busy bg)         (Busy foreground, soft bg)

     Foreground      Background         Foreground      Background
     (front blur)    (back blur)        (front blur)    (back blur)

     ┌─────┐         ┌─────┐            ┌─────┐         ┌─────┐
     │░░░░░│         │█░░░█│            │█░░░█│         │░░░░░│
     │░░░░░│         │░░█░░│            │░░█░░│         │░░░░░│
     │░░░░░│         │█░░░█│            │█░░░█│         │░░░░░│
     └─────┘         └─────┘            └─────┘         └─────┘
     Smooth edge     Bright edge        Bright edge     Smooth edge
```

---

## Our Implementation Approach

### Current Limitations

**Important**: True physically-accurate bokeh simulation requires depth information that we don't have from a 2D photograph. Our implementation provides **aesthetic approximation**, not optical simulation.

### What We Can Do (From 2D Image)

1. **Bloom effect** - Simulates light spreading from bright areas
2. **Soft glow** - Creates dreamy atmosphere around highlights
3. **Lens-like light spread** - Approximates how lenses spread point lights

### Implementation: Bloom as Bokeh Approximation

```swift
struct BloomData: Codable, Hashable, Sendable {
    var intensity: Float = 0     // 0...100
    var radius: Float = 0.5      // 0...1 (blur extent)
    var threshold: Float = 0.8   // 0...1 (brightness cutoff)

    static let none = BloomData()
}

/// Bloom implementation approximating lens behavior
func applyBloom(_ params: BloomData, to image: CIImage) -> CIImage {
    guard params.intensity > 0 else { return image }

    // 1. Extract highlights above threshold
    let highlights = extractHighlights(
        from: image,
        threshold: params.threshold
    )

    // 2. Apply multi-scale blur (simulates optical spread)
    // Real lenses have a specific point spread function (PSF)
    // We approximate with layered Gaussian blur
    let blur1 = highlights.applyingGaussianBlur(sigma: Double(params.radius * 20))
    let blur2 = highlights.applyingGaussianBlur(sigma: Double(params.radius * 50))
    let blur3 = highlights.applyingGaussianBlur(sigma: Double(params.radius * 100))

    // 3. Combine blur layers (mimics lens PSF)
    let combined = combineBlurLayers([
        (blur1, 0.5),   // Sharp core
        (blur2, 0.3),   // Medium spread
        (blur3, 0.2)    // Wide halo
    ])

    // 4. Add bloom to original with intensity control
    let intensity = params.intensity / 100.0
    return image.applyingFilter("CIAdditionCompositing", parameters: [
        "inputBackgroundImage": combined.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: CGFloat(intensity), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: CGFloat(intensity), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(intensity), w: 0)
        ])
    ])
}
```

### Metal Kernel for Advanced Bloom

For better performance and quality, we use a custom Metal kernel:

```metal
// BloomKernel.metal

#include <metal_stdlib>
using namespace metal;

// Physically-based bloom that approximates lens PSF
kernel void bloomKernel(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float& threshold [[buffer(0)]],
    constant float& intensity [[buffer(1)]],
    constant float& radius [[buffer(2)]],
    uint2 gid [[thread_position_in_grid]]
) {
    float4 color = inTexture.read(gid);

    // Calculate luminance
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Soft threshold (avoid hard cutoff)
    float bloomMask = smoothstep(threshold - 0.1, threshold + 0.1, luminance);

    // Sample surrounding pixels for blur
    // (Simplified - real implementation uses separable blur passes)
    float4 bloom = float4(0);
    float weightSum = 0;

    int sampleRadius = int(radius * 20);
    for (int y = -sampleRadius; y <= sampleRadius; y++) {
        for (int x = -sampleRadius; x <= sampleRadius; x++) {
            float dist = length(float2(x, y));
            if (dist > float(sampleRadius)) continue;

            // Gaussian weight with lens-like falloff
            float weight = exp(-dist * dist / (2 * radius * radius * 100));

            uint2 samplePos = uint2(
                clamp(int(gid.x) + x, 0, int(inTexture.get_width() - 1)),
                clamp(int(gid.y) + y, 0, int(inTexture.get_height() - 1))
            );

            float4 sample = inTexture.read(samplePos);
            float sampleLum = dot(sample.rgb, float3(0.2126, 0.7152, 0.0722));

            if (sampleLum > threshold) {
                bloom += sample * weight;
                weightSum += weight;
            }
        }
    }

    if (weightSum > 0) {
        bloom /= weightSum;
    }

    // Combine with original
    float4 result = color + bloom * intensity * bloomMask;
    outTexture.write(result, gid);
}
```

---

## Future: True Depth-Based Bokeh

### Requirements for Real Bokeh Simulation

To implement true optical bokeh, we would need:

1. **Depth map** - Per-pixel distance from camera
2. **Focus plane selection** - User-defined focus distance
3. **Aperture simulation** - Shape and f-number
4. **Point spread function** - Accurate lens model

### Potential Depth Sources

| Source | Quality | Availability |
|--------|---------|--------------|
| Portrait mode depth | Good | iPhone dual-camera photos |
| LiDAR depth | Excellent | iPhone Pro models |
| ML-estimated depth | Variable | Any photo (computed) |
| HEIF depth data | Good | When saved by iOS Camera |

### Future Implementation Concept

```swift
/// Future: Depth-aware bokeh rendering
func applyDepthAwareBokeh(
    image: CIImage,
    depthMap: CIImage,
    focusDistance: Float,
    aperture: Float,
    bladeCount: Int
) -> CIImage {
    // 1. Calculate CoC size for each pixel based on depth
    // CoC = |depth - focusDistance| * aperture_factor

    // 2. Generate aperture shape kernel
    // Polygonal for stopped-down, circular for wide-open

    // 3. Apply variable-radius blur based on CoC map
    // Larger CoC = more blur

    // 4. Handle edge cases:
    //    - Foreground/background separation
    //    - Cat's eye at frame edges
    //    - Specular highlight handling

    // This is computationally expensive and would use Metal compute
}
```

---

## Scientific References

### Academic Papers

1. Potmesil, M., & Chakravarty, I. (1981). "A Lens and Aperture Camera Model for Synthetic Image Generation." *ACM SIGGRAPH Computer Graphics*, 15(3), 297-305.

2. Kolb, C., Mitchell, D., & Hanrahan, P. (1995). "A Realistic Camera Model for Computer Graphics." *SIGGRAPH '95 Proceedings*, 317-324.

3. Wu, J., et al. (2010). "Realistic Rendering of Bokeh Effect Based on Optical Aberrations." *The Visual Computer*, 26(6-8), 555-563.

### Optical Science

- Smith, W. J. (2007). *Modern Optical Engineering* (4th ed.). McGraw-Hill.
- Kingslake, R. (1992). *Optics in Photography*. SPIE Press.

### Photography Resources

- Cicala, R. (2013). "Bokeh: The Evolution of a Word." LensRentals Blog.
- Nasse, H. H. (2010). "Depth of Field and Bokeh." Carl Zeiss White Paper.

---

## Honest Assessment

### What We Do Well
- Bloom effects that evoke the feeling of quality bokeh
- Pleasing light spread from highlights
- Halation effects (separate but related)

### What We Cannot Do (Yet)
- True depth-based blur without depth data
- Accurate aperture shape simulation
- Cat's eye effect (requires depth + position)
- Foreground blur vs background blur distinction

### Our Recommendation
For users wanting true bokeh control:
1. **Use camera settings** - Wide aperture during capture
2. **Portrait mode photos** - Use depth data when available
3. **Our bloom effects** - For post-capture artistic enhancement

We're honest that our "bokeh" effects are **aesthetic approximations**, not **optical simulations**. True bokeh is an optical phenomenon that occurs during image capture, not post-processing.

---

*Last updated: January 2026*
