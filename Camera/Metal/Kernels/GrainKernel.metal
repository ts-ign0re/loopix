//
//  GrainKernel.metal
//  Camera
//
//  Physically-based film grain emulation.
//  Models silver halide crystal development in optical density domain.
//  Band-limited noise spectrum, density-dependent response, per-layer dye clouds.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// ── Hashing ────────────────────────────────────────────────

float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Box-Muller Gaussian (mean 0, σ ≈ 1)
float gaussianNoise(float2 p, float seed) {
    float3 p3 = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33 + seed);
    float2 u = fract((p3.xx + p3.yz) * p3.zy);
    float r = sqrt(-2.0 * log(max(u.x, 0.0001)));
    float theta = 6.28318530718 * u.y;
    return r * cos(theta);
}

// ── Simplex 2D noise ───────────────────────────────────────

float3 permute(float3 x) { return fmod(((x * 34.0) + 1.0) * x, 289.0); }

float simplex2D(float2 v) {
    const float4 C = float4(0.211324865405187, 0.366025403784439,
                           -0.577350269189626, 0.024390243902439);
    float2 i  = floor(v + dot(v, C.yy));
    float2 x0 = v - i + dot(i, C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = fmod(i, 289.0);
    float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
                                     + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy),
                                  dot(x12.zw, x12.zw)), 0.0);
    m = m * m; m = m * m;
    float3 x = 2.0 * fract(p * C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    float3 g;
    g.x  = a0.x * x0.x  + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float2 hash2(float2 p) {
    return float2(
        hash(p + float2(127.1, 311.7)),
        hash(p + float2(269.5, 183.3))
    );
}

float2 worley2D(float2 p) {
    float2 cell = floor(p);
    float2 local = fract(p);

    float d1 = 1e10;
    float d2 = 1e10;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2(float(x), float(y));
            float2 point = hash2(cell + neighbor);
            float2 diff = neighbor + point - local;
            float dist = dot(diff, diff);

            if (dist < d1) {
                d2 = d1;
                d1 = dist;
            } else if (dist < d2) {
                d2 = dist;
            }
        }
    }

    return sqrt(float2(d1, d2));
}

float2 domainWarp(float2 p) {
    float2 q = float2(
        simplex2D(p * 0.37 + float2(19.2, 7.1)),
        simplex2D(p * 0.34 + float2(-11.7, 23.6))
    );

    float2 r = float2(
        simplex2D((p + q * 1.4) * 0.71 + float2(33.5, -9.4)),
        simplex2D((p + q * 1.4) * 0.67 + float2(-5.8, 41.3))
    );

    return p + q * 0.85 + r * 0.45;
}

// ── Band-limited grain noise ─────────────────────────────
// Film grain has a specific power spectrum: energy in mid frequencies,
// rolloff at low and high ends. We approximate this with weighted octaves.

float bandLimitedGrain(float2 coord, float2 structCoord, float seed) {
    float2 warped = domainWarp(structCoord);

    // Gaussian base — uniform random crystal distribution
    float g = gaussianNoise(coord, seed) * 0.42;

    // Mid-frequency organic structure — band-limited core
    // These frequencies carry most energy in real film grain NPS
    g += simplex2D(warped * 1.05) * 0.32;
    g += simplex2D(warped * 2.1 + float2(173.0, 0.0)) * 0.20;
    g += simplex2D(warped * 0.55 + float2(41.0, 91.0)) * 0.10;

    // High-frequency micro-texture — slight rolloff
    g += gaussianNoise(coord * 1.25 + warped * 0.17, seed + 7.7) * 0.12;

    return g;
}

// ── Kernel ─────────────────────────────────────────────────

extern "C" float4 grainKernel(coreimage::sampler src,
                               float amount,
                               float size,
                               float roughness,
                               float monochromatic,
                               float time,
                               float imageSize,
                               float clumpStrength,
                               coreimage::destination dest) {
    float4 color = src.sample(src.coord());
    float2 coord = dest.coord();

    // Per-frame spatial offset — slower temporal refresh, less digital flicker
    float frameSeed = floor(time * 12.0);
    float2 grainDrift = float2(
        sin(time * 0.9),
        cos(time * 0.7)
    ) * 64.0;
    float2 grainOffset = float2(
        hash(float2(frameSeed, 7.31)),
        hash(float2(13.17, frameSeed))
    ) * 4096.0 + grainDrift;

    // Resolution scaling
    float refSize = 1080.0;
    float resRatio = max(imageSize / refSize, 0.5);

    // Grain coordinate space
    float sizeScale = 2.4 / clamp(size, 0.5, 4.0);
    float2 grainCoord = coord * sizeScale / resRatio + grainOffset;
    float2 structCoord = grainCoord;

    // Per-pixel seed
    float posSeed = hash(grainCoord * 0.037);

    // ── Density-domain exposure response ──
    // Real grain: RMS granularity ∝ sqrt(density), where density = -log10(luminance)
    // Peak in midtones, sparse in shadows, overlapping in highlights
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    float density = -log10(max(luminance, 0.001));
    float densityNorm = clamp(density / 2.2, 0.0, 1.0);
    float densityResponse = pow(densityNorm, 0.62);
    // Suppress in deep highlights where grains overlap into continuous silver
    float highlightSuppress = smoothstep(0.02, 0.22, density);
    // Slight taper in deep shadows to avoid crunchy mush
    float shadowTaper = 1.0 - 0.25 * smoothstep(1.9, 3.0, density);
    float exposureResponse = clamp(densityResponse * highlightSuppress * shadowTaper + 0.20, 0.20, 1.0);

    // ── Grain generation — band-limited spectrum ──
    float grain = bandLimitedGrain(grainCoord, structCoord, posSeed);

    // Roughness — adds high-frequency micro-texture
    if (roughness > 0.0) {
        float detail = gaussianNoise(grainCoord * 2.2, posSeed + 17.3);
        grain += detail * 0.24 * roughness;
    }

    // ── Intensity ──
    float resBoost = pow(clamp(resRatio, 0.7, 4.0), 0.35);
    float monoBoost = monochromatic > 0.5 ? 1.45 : 1.0;
    float grainIntensity = amount * 0.58 * exposureResponse * resBoost * monoBoost;

    // ── Crystal clumping (Worley/Voronoi mask) ──
    // Strongest on high-ISO presets; subtle elsewhere.
    float clump = clamp(clumpStrength, 0.0, 1.0);
    float clumpSizeDamp = mix(1.0, 0.65, smoothstep(2.8, 4.0, size));
    clump *= clumpSizeDamp;
    if (clump > 0.001) {
        float2 cellA = worley2D(structCoord * 0.14);
        float2 cellB = worley2D(structCoord * 0.23 + float2(17.0, -9.0));

        float nucleiA = 1.0 - smoothstep(0.16, 0.48, cellA.x);
        float nucleiB = 1.0 - smoothstep(0.12, 0.36, cellB.x);
        float edgesA = smoothstep(0.02, 0.09, cellA.y - cellA.x);
        float edgesB = smoothstep(0.03, 0.12, cellB.y - cellB.x);

        float clusterMask = 0.92
            + nucleiA * 0.28
            + nucleiB * 0.14
            + edgesA * 0.12
            + edgesB * 0.07;
        clusterMask = clamp(clusterMask, 0.82, 1.32);
        grainIntensity *= mix(1.0, clusterMask, clump);
    }

    // ── Color film: independent dye layers with different grain sizes ──
    // Blue-sensitive layer (yellow dye) = coarsest grain (~1.4x)
    // Green-sensitive layer (magenta dye) = finest grain
    // Red-sensitive layer (cyan dye) = medium grain (~1.15x)
    float3 grainColor;
    if (monochromatic > 0.5) {
        grainColor = float3(grain);
    } else {
        // Red/cyan layer — slightly coarser than green
        float rGrain = bandLimitedGrain(
            grainCoord * 0.88, structCoord * 0.82 + float2(50.0, 0.0), posSeed + 3.1);

        // Green/magenta layer — finest grain (reference)
        // Already computed as 'grain'

        // Blue/yellow layer — coarsest grain
        float bGrain = bandLimitedGrain(
            grainCoord * 0.62, structCoord * 0.58 + float2(0.0, 50.0), posSeed + 9.3);

        grainColor = float3(rGrain, grain, bGrain);
    }

    // ── Density-domain blend ──
    // Convert to density, add grain, convert back — physically correct
    float3 grainEffect = grainColor * grainIntensity;
    float3 result;
    for (int c = 0; c < 3; c++) {
        float base = max(color[c], 0.001);
        float baseDensity = -log10(base);
        // Add grain as density fluctuation
        float grainedDensity = baseDensity + grainEffect[c] * 0.75;
        grainedDensity = max(grainedDensity, 0.0);
        result[c] = pow(10.0, -grainedDensity);
    }

    return float4(clamp(result, 0.0, 1.0), color.a);
}
