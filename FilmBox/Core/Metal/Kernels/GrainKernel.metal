//
//  GrainKernel.metal
//  FilmBox
//
//  Metal shader for realistic film grain effect
//  Simulates silver halide crystal response in photographic film
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// Box-Muller transform for Gaussian-distributed random numbers
// More realistic for film grain than uniform distribution
float2 gaussianRandom(float2 p, float seed) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33 + seed);
    float2 uniform = fract((p3.xx + p3.yz) * p3.zy);

    // Box-Muller transform
    float r = sqrt(-2.0 * log(max(uniform.x, 0.0001)));
    float theta = 6.28318530718 * uniform.y;
    return float2(r * cos(theta), r * sin(theta));
}

// Hash function for pseudo-random number generation
float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Simplex 2D noise for organic grain structure (like film crystals)
float3 permute(float3 x) { return fmod(((x*34.0)+1.0)*x, 289.0); }

float simplex2D(float2 v) {
    const float4 C = float4(0.211324865405187, 0.366025403784439,
                           -0.577350269189626, 0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = fmod(i, 289.0);
    float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m; m = m*m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    float3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// Voronoi-based grain clustering (simulates silver halide crystal clumping)
float voronoiGrain(float2 p, float roughness) {
    float2 i = floor(p);
    float2 f = fract(p);

    float minDist = 1.0;
    float secondDist = 1.0;

    // Search neighboring cells
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(x, y);
            float2 point = hash(i + neighbor) * roughness + neighbor;
            float dist = length(f - point);

            if (dist < minDist) {
                secondDist = minDist;
                minDist = dist;
            } else if (dist < secondDist) {
                secondDist = dist;
            }
        }
    }

    // Edge detection creates grain texture
    return secondDist - minDist;
}

// Per-pixel Gaussian film noise - uniform distribution without visible patterns
float filmNoise(float2 p, float roughness, float seed) {
    // Primary per-pixel Gaussian noise - each pixel is independent
    float2 gaussian = gaussianRandom(p, seed);
    float noise = gaussian.x;

    // Add subtle second octave for texture variation (controlled by roughness)
    if (roughness > 0.2) {
        float2 detail = gaussianRandom(p * 2.0 + 50.0, seed + 7.3);
        // Mix in detail proportional to roughness
        noise = noise + detail.x * 0.25 * roughness;
    }

    // Optional third octave for very rough grain
    if (roughness > 0.6) {
        float2 fine = gaussianRandom(p * 3.5 + 100.0, seed + 13.7);
        noise = noise + fine.x * 0.15 * (roughness - 0.6);
    }

    return noise;
}

// Film grain kernel - simulates photographic film grain
// Parameters:
//   amount: Grain intensity (0.0 - 1.0)
//   size: Grain size multiplier (0.5 - 4.0, larger = finer grain)
//   roughness: Grain texture roughness (0.0 - 1.0)
//   monochromatic: 1.0 for B&W grain, 0.0 for chromatic grain
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

    // Get destination coordinates
    float2 coord = dest.coord();

    // Calculate grain size factor - controls grain cell size
    // Larger size = smaller sizeScale = larger grain cells
    float sizeScale = 2.0 / max(size, 0.5);

    // Grain coordinates - quantize to create discrete grain cells
    // This ensures adjacent pixels within the same cell share the same noise value,
    // producing consistent grain appearance across different image resolutions
    float2 scaledCoord = coord * sizeScale;
    float2 grainCoord = floor(scaledCoord);

    // Use fractional part for smooth blending at cell edges
    float2 cellFract = fract(scaledCoord);
    float seed = time * 17.3;

    // Calculate luminance for exposure-dependent response
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // === FILM-LIKE GRAIN RESPONSE ===
    // Real film grain is caused by silver halide crystals
    // More exposed areas (highlights) have more developed crystals = more grain
    // Shadows have fewer developed crystals = less visible grain
    // But the relationship is not linear - it follows a characteristic curve

    // Negative film characteristic: grain peaks in upper midtones
    // This simulates the density response curve of silver halide emulsion
    float exposureResponse = pow(luminance, 0.7) * (1.0 - pow(luminance, 2.5));
    exposureResponse = max(exposureResponse, 0.15); // Minimum grain in deep shadows

    // Generate grain with bilinear interpolation between cells for smooth appearance
    // Sample four corners of the current cell
    float grain00 = filmNoise(grainCoord, roughness, seed);
    float grain10 = filmNoise(grainCoord + float2(1.0, 0.0), roughness, seed);
    float grain01 = filmNoise(grainCoord + float2(0.0, 1.0), roughness, seed);
    float grain11 = filmNoise(grainCoord + float2(1.0, 1.0), roughness, seed);

    // Smooth interpolation weights using smoothstep for organic edges
    float2 blend = smoothstep(0.0, 1.0, cellFract);

    // Bilinear interpolation for smooth grain transitions
    float grain = mix(mix(grain00, grain10, blend.x),
                      mix(grain01, grain11, blend.x), blend.y);

    // Scale grain by exposure response and amount
    // Increased intensity for strong, visible film-like grain
    float grainIntensity = amount * 0.6 * exposureResponse;

    float3 grainColor;
    if (monochromatic > 0.5) {
        // Monochromatic grain (traditional B&W film look)
        grainColor = float3(grain);
    } else {
        // Chromatic grain - color film has different grain per layer
        // Red-sensitive layer is usually coarsest, blue is finest
        // Use scaled grain coordinates with different offsets per channel

        // Red channel (slightly coarser)
        float2 coordR = grainCoord * 0.9;
        float grainR00 = filmNoise(coordR, roughness, seed);
        float grainR10 = filmNoise(coordR + float2(1.0, 0.0), roughness, seed);
        float grainR01 = filmNoise(coordR + float2(0.0, 1.0), roughness, seed);
        float grainR11 = filmNoise(coordR + float2(1.0, 1.0), roughness, seed);
        float grainR = mix(mix(grainR00, grainR10, blend.x),
                          mix(grainR01, grainR11, blend.x), blend.y);

        // Green channel
        float2 coordG = grainCoord * 1.0;
        float grainG00 = filmNoise(coordG, roughness * 0.9, seed + 5.7);
        float grainG10 = filmNoise(coordG + float2(1.0, 0.0), roughness * 0.9, seed + 5.7);
        float grainG01 = filmNoise(coordG + float2(0.0, 1.0), roughness * 0.9, seed + 5.7);
        float grainG11 = filmNoise(coordG + float2(1.0, 1.0), roughness * 0.9, seed + 5.7);
        float grainG = mix(mix(grainG00, grainG10, blend.x),
                          mix(grainG01, grainG11, blend.x), blend.y);

        // Blue channel (finest)
        float2 coordB = grainCoord * 1.1;
        float grainB00 = filmNoise(coordB, roughness * 0.8, seed + 11.3);
        float grainB10 = filmNoise(coordB + float2(1.0, 0.0), roughness * 0.8, seed + 11.3);
        float grainB01 = filmNoise(coordB + float2(0.0, 1.0), roughness * 0.8, seed + 11.3);
        float grainB11 = filmNoise(coordB + float2(1.0, 1.0), roughness * 0.8, seed + 11.3);
        float grainB = mix(mix(grainB00, grainB10, blend.x),
                          mix(grainB01, grainB11, blend.x), blend.y);

        // Subtle color shifts in chromatic grain
        grainColor = float3(grainR, grainG, grainB);

        // Reduce chromatic intensity relative to luminance grain
        grainColor *= 0.85;
    }

    // Apply grain with soft-light blending for film-like response
    // Soft-light preserves shadows and highlights better than additive
    float3 grainEffect = grainColor * grainIntensity;
    float3 result;

    // Soft-light blend: grain modulates the image like film density
    for (int c = 0; c < 3; c++) {
        float base = color[c];
        float grain = grainEffect[c];

        if (grain < 0.0) {
            // Darken: multiply-like for negative grain
            result[c] = base * (1.0 + grain * 1.5);
        } else {
            // Lighten: screen-like for positive grain
            result[c] = base + grain * (1.0 - base) * 1.5;
        }
    }

    // Soft clamp to avoid harsh clipping
    result = clamp(result, 0.0, 1.0);

    return float4(result, color.a);
}
