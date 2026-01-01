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

// Multi-octave noise with proper falloff
float filmNoise(float2 p, float roughness, float seed) {
    float value = 0.0;
    float amplitude = 1.0;
    float totalAmp = 0.0;
    float frequency = 1.0;

    // More octaves for rougher grain
    int octaves = int(mix(2.0, 5.0, roughness));

    for (int i = 0; i < octaves; i++) {
        float2 gaussian = gaussianRandom(p * frequency, seed + float(i) * 7.3);
        value += amplitude * gaussian.x;
        totalAmp += amplitude;
        amplitude *= 0.5;
        frequency *= 2.1;
    }

    return value / totalAmp;
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

    // Calculate grain size factor
    float sizeScale = 1.0 / max(size, 0.5);

    // Grain coordinates with optional temporal variation
    float2 grainCoord = coord * sizeScale;
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

    // Add grain clustering using Voronoi for more organic look
    float clusterNoise = voronoiGrain(grainCoord * 0.3, 0.8);
    float clusterFactor = mix(0.7, 1.3, clusterNoise);

    // Generate main grain noise with Gaussian distribution
    float grain = filmNoise(grainCoord, roughness, seed);

    // Add fine detail layer for high-ISO look
    float fineGrain = filmNoise(grainCoord * 2.5, roughness * 0.7, seed + 11.7) * 0.3;
    grain = grain + fineGrain;

    // Apply clustering
    grain *= clusterFactor;

    // Scale grain by exposure response and amount
    float grainIntensity = amount * 0.35 * exposureResponse;

    float3 grainColor;
    if (monochromatic > 0.5) {
        // Monochromatic grain (traditional B&W film look)
        grainColor = float3(grain);
    } else {
        // Chromatic grain - color film has different grain per layer
        // Red-sensitive layer is usually coarsest, blue is finest
        float grainR = filmNoise(grainCoord * 0.9, roughness, seed);
        float grainG = filmNoise(grainCoord * 1.0, roughness * 0.9, seed + 5.7);
        float grainB = filmNoise(grainCoord * 1.1, roughness * 0.8, seed + 11.3);

        // Subtle color shifts in chromatic grain
        grainColor = float3(grainR, grainG, grainB);

        // Reduce chromatic intensity relative to luminance grain
        grainColor *= 0.85;
    }

    // Apply grain with proper blending
    // Use overlay-style blending for more natural look in midtones
    float3 grainEffect = grainColor * grainIntensity;
    float3 result = color.rgb + grainEffect;

    // Soft clamp to avoid harsh clipping
    result = clamp(result, 0.0, 1.0);

    return float4(result, color.a);
}
