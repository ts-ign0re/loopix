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

// Film-like noise combining organic simplex structure with gaussian detail
float filmNoise(float2 p, float roughness, float seed) {
    // Organic base from simplex - creates crystal-like structure
    float organic = simplex2D(p * 0.8) * 0.5;

    // Add second layer of simplex at different scale for variation
    organic += simplex2D(p * 1.7 + 100.0) * 0.3;

    // Add gaussian detail for fine texture
    float value = 0.0;
    float amplitude = 1.0;
    float totalAmp = 0.0;
    float frequency = 1.0;
    int octaves = int(mix(2.0, 4.0, roughness));

    for (int i = 0; i < octaves; i++) {
        float2 gaussian = gaussianRandom(p * frequency, seed + float(i) * 7.3);
        value += amplitude * gaussian.x;
        totalAmp += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    float detail = value / totalAmp;

    // Mix: 55% organic structure, 45% gaussian detail
    // This gives film-like clumpy appearance rather than digital noise
    return mix(organic, detail, 0.45);
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

    // Calculate grain size factor - larger base size for visible film-like grain
    float sizeScale = 0.7 / max(size, 0.5);

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
    // Enhanced clustering for visible crystal clumps like real film
    float clusterNoise = voronoiGrain(grainCoord * 0.25, 0.9);
    float clusterFactor = mix(0.5, 1.5, smoothstep(0.0, 0.5, clusterNoise));

    // Generate main grain noise with Gaussian distribution
    float grain = filmNoise(grainCoord, roughness, seed);

    // Add fine detail layer for high-ISO look
    float fineGrain = filmNoise(grainCoord * 2.5, roughness * 0.7, seed + 11.7) * 0.3;
    grain = grain + fineGrain;

    // Apply clustering
    grain *= clusterFactor;

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
        float grainR = filmNoise(grainCoord * 0.9, roughness, seed);
        float grainG = filmNoise(grainCoord * 1.0, roughness * 0.9, seed + 5.7);
        float grainB = filmNoise(grainCoord * 1.1, roughness * 0.8, seed + 11.3);

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
