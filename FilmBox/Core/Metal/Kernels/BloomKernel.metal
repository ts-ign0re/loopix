//
//  BloomKernel.metal
//  FilmBox
//
//  Metal shader for highlight bloom/glow effect
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// Bloom kernel - extracts and blurs bright pixels, adds glow
// Parameters:
//   intensity: Bloom intensity (0.0 - 2.0)
//   radius: Blur radius for the bloom (1.0 - 50.0)
//   threshold: Brightness threshold for bloom extraction (0.0 - 1.0)
extern "C" float4 bloomKernel(coreimage::sampler src,
                               float intensity,
                               float radius,
                               float threshold,
                               coreimage::destination dest) {
    float2 coord = src.coord();
    float2 texelSize = 1.0 / src.size();

    // Sample original pixel
    float4 color = src.sample(coord);

    // Calculate luminance
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Extract bright areas with soft threshold
    float brightMask = smoothstep(threshold, threshold + 0.1, luminance);
    float3 brightPixels = color.rgb * brightMask;

    // Multi-sample gaussian blur for bloom
    float3 bloom = float3(0.0);
    float totalWeight = 0.0;

    // Gaussian kernel weights (pre-computed for 9 samples)
    constant float gaussianWeights[9] = {
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    };

    // Multi-pass blur simulation with larger radius
    int samples = 16;
    float sigma = radius / 3.0;

    // Sample in concentric rings for better quality
    for (int ring = 0; ring <= 3; ring++) {
        float ringRadius = float(ring) * radius / 3.0;
        int ringSamples = ring == 0 ? 1 : ring * 8;

        for (int s = 0; s < ringSamples; s++) {
            float angle = float(s) * 2.0 * M_PI_F / float(ringSamples);
            float2 offset = ringRadius * float2(cos(angle), sin(angle)) * texelSize;

            float4 sampleColor = src.sample(coord + offset);
            float sampleLum = dot(sampleColor.rgb, float3(0.2126, 0.7152, 0.0722));
            float sampleMask = smoothstep(threshold, threshold + 0.1, sampleLum);

            // Gaussian weight based on distance
            float weight = exp(-(ringRadius * ringRadius) / (2.0 * sigma * sigma));

            bloom += sampleColor.rgb * sampleMask * weight;
            totalWeight += weight;
        }
    }

    if (totalWeight > 0.0) {
        bloom /= totalWeight;
    }

    // Add bloom to original image
    // Using additive blending for glow effect
    float3 result = color.rgb + bloom * intensity;

    // Soft clamp to prevent harsh clipping
    result = result / (1.0 + result * 0.1);
    result = clamp(result, 0.0, 1.0);

    return float4(result, color.a);
}

// Threshold extraction kernel for multi-pass bloom pipeline
// Extracts pixels above threshold for subsequent blurring
extern "C" float4 bloomThresholdKernel(coreimage::sampler src,
                                        float threshold,
                                        float softness,
                                        coreimage::destination dest) {
    float4 color = src.sample(src.coord());
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Soft threshold with configurable knee
    float knee = softness * 0.5;
    float soft = luminance - threshold + knee;
    soft = clamp(soft * soft / (4.0 * knee + 0.0001), 0.0, 1.0);

    float contribution = max(soft, luminance - threshold) / max(luminance, 0.0001);
    contribution = max(contribution, 0.0);

    return float4(color.rgb * contribution, 1.0);
}

// Horizontal gaussian blur pass
extern "C" float4 bloomBlurHorizontal(coreimage::sampler src,
                                       float radius,
                                       coreimage::destination dest) {
    float2 coord = src.coord();
    float2 texelSize = 1.0 / src.size();

    float3 result = float3(0.0);
    float totalWeight = 0.0;

    float sigma = radius / 3.0;
    int kernelSize = int(ceil(radius));

    for (int i = -kernelSize; i <= kernelSize; i++) {
        float2 offset = float2(float(i) * texelSize.x, 0.0);
        float4 sampleColor = src.sample(coord + offset);

        float weight = exp(-(float(i * i)) / (2.0 * sigma * sigma));
        result += sampleColor.rgb * weight;
        totalWeight += weight;
    }

    result /= totalWeight;
    return float4(result, 1.0);
}

// Vertical gaussian blur pass
extern "C" float4 bloomBlurVertical(coreimage::sampler src,
                                     float radius,
                                     coreimage::destination dest) {
    float2 coord = src.coord();
    float2 texelSize = 1.0 / src.size();

    float3 result = float3(0.0);
    float totalWeight = 0.0;

    float sigma = radius / 3.0;
    int kernelSize = int(ceil(radius));

    for (int i = -kernelSize; i <= kernelSize; i++) {
        float2 offset = float2(0.0, float(i) * texelSize.y);
        float4 sampleColor = src.sample(coord + offset);

        float weight = exp(-(float(i * i)) / (2.0 * sigma * sigma));
        result += sampleColor.rgb * weight;
        totalWeight += weight;
    }

    result /= totalWeight;
    return float4(result, 1.0);
}

// Combine bloom with original image
extern "C" float4 bloomCombine(coreimage::sampler src,
                                coreimage::sampler bloomTex,
                                float intensity,
                                coreimage::destination dest) {
    float4 color = src.sample(src.coord());
    float4 bloom = bloomTex.sample(bloomTex.coord());

    // Additive blend with intensity control
    float3 result = color.rgb + bloom.rgb * intensity;

    // Tone mapping to prevent over-saturation
    result = result / (1.0 + result * 0.1);
    result = clamp(result, 0.0, 1.0);

    return float4(result, color.a);
}
