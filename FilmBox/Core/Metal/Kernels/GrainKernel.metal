//
//  GrainKernel.metal
//  FilmBox
//
//  Metal shader for realistic film grain effect
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// Hash function for pseudo-random number generation
float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D noise function
float noise2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Cubic Hermite interpolation for smoother results
    float2 u = f * f * (3.0 - 2.0 * f);

    // Four corners
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fractal Brownian Motion for more realistic grain texture
float fbm(float2 p, float roughness) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float lacunarity = 2.0;

    // Number of octaves based on roughness (1-4)
    int octaves = int(mix(1.0, 4.0, roughness));

    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise2D(p * frequency);
        amplitude *= 0.5;
        frequency *= lacunarity;
    }

    return value;
}

// Film grain kernel
// Parameters:
//   amount: Grain intensity (0.0 - 1.0)
//   size: Grain size multiplier (0.5 - 4.0)
//   roughness: Grain texture roughness (0.0 - 1.0)
//   monochromatic: 1.0 for B&W grain, 0.0 for color grain
//   time: Animation time for temporal variation
extern "C" float4 grainKernel(coreimage::sampler src,
                               float amount,
                               float size,
                               float roughness,
                               float monochromatic,
                               float time,
                               coreimage::destination dest) {
    // Sample source image
    float4 color = src.sample(src.coord());

    // Get destination coordinates for grain calculation
    float2 coord = dest.coord();

    // Calculate grain size factor (smaller size value = larger grain)
    float sizeScale = 1.0 / max(size, 0.5);

    // Add time variation for animated grain
    float2 grainCoord = coord * sizeScale + float2(time * 100.0, time * 73.0);

    // Generate grain using FBM
    float grain = fbm(grainCoord, roughness);

    // Normalize grain to [-1, 1] range
    grain = (grain - 0.5) * 2.0;

    // Calculate luminance for exposure-dependent grain intensity
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Grain is more visible in midtones, less in shadows and highlights
    float midtoneMask = 4.0 * luminance * (1.0 - luminance);
    midtoneMask = mix(0.5, midtoneMask, 0.5); // Reduce the effect

    // Apply amount with midtone consideration
    float grainAmount = amount * 0.3 * midtoneMask;

    float3 grainColor;
    if (monochromatic > 0.5) {
        // Monochromatic grain (same value for all channels)
        grainColor = float3(grain);
    } else {
        // Color grain (different noise per channel)
        float grainR = fbm(grainCoord + float2(127.1, 311.7), roughness);
        float grainG = fbm(grainCoord + float2(269.5, 183.3), roughness);
        float grainB = fbm(grainCoord + float2(419.2, 371.9), roughness);
        grainColor = (float3(grainR, grainG, grainB) - 0.5) * 2.0;
    }

    // Blend grain with source image
    float3 result = color.rgb + grainColor * grainAmount;

    // Clamp result
    result = clamp(result, 0.0, 1.0);

    return float4(result, color.a);
}
