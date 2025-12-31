//
//  HalationKernel.metal
//  FilmBox
//
//  Metal shader for film halation effect (red glow around highlights)
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// Convert RGB to HSL
float3 rgbToHsl(float3 rgb) {
    float maxC = max(max(rgb.r, rgb.g), rgb.b);
    float minC = min(min(rgb.r, rgb.g), rgb.b);
    float delta = maxC - minC;

    float l = (maxC + minC) * 0.5;
    float s = 0.0;
    float h = 0.0;

    if (delta > 0.0001) {
        s = delta / (1.0 - abs(2.0 * l - 1.0));

        if (maxC == rgb.r) {
            h = fmod((rgb.g - rgb.b) / delta, 6.0);
        } else if (maxC == rgb.g) {
            h = (rgb.b - rgb.r) / delta + 2.0;
        } else {
            h = (rgb.r - rgb.g) / delta + 4.0;
        }
        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }

    return float3(h, s, l);
}

// Convert HSL to RGB
float3 hslToRgb(float3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (s < 0.0001) {
        return float3(l);
    }

    float c = (1.0 - abs(2.0 * l - 1.0)) * s;
    float x = c * (1.0 - abs(fmod(h * 6.0, 2.0) - 1.0));
    float m = l - c * 0.5;

    float3 rgb;
    float hue6 = h * 6.0;

    if (hue6 < 1.0) {
        rgb = float3(c, x, 0.0);
    } else if (hue6 < 2.0) {
        rgb = float3(x, c, 0.0);
    } else if (hue6 < 3.0) {
        rgb = float3(0.0, c, x);
    } else if (hue6 < 4.0) {
        rgb = float3(0.0, x, c);
    } else if (hue6 < 5.0) {
        rgb = float3(x, 0.0, c);
    } else {
        rgb = float3(c, 0.0, x);
    }

    return rgb + m;
}

// Halation kernel - single pass for Core Image
// This creates a glow effect around bright areas
// Parameters:
//   intensity: Halation intensity (0.0 - 1.0)
//   hue: Halation color hue (0.0 - 1.0, where ~0.0 is red)
//   spread: Size of the halation spread (1.0 - 50.0)
extern "C" float4 halationKernel(coreimage::sampler src,
                                  float intensity,
                                  float hue,
                                  float spread,
                                  coreimage::destination dest) {
    // Sample source image at current position
    float4 color = src.sample(src.coord());

    // Calculate luminance to detect highlights
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Highlight threshold - areas above this will create halation
    float threshold = 0.7;
    float highlightMask = smoothstep(threshold, 1.0, luminance);

    // Sample surrounding pixels to create blur effect
    float2 coord = src.coord();
    float2 texelSize = 1.0 / src.size();

    // Gaussian-weighted sampling for soft glow
    float3 blurredHighlights = float3(0.0);
    float totalWeight = 0.0;

    // Sample in a circular pattern
    int samples = 16;
    float spreadRadius = spread;

    for (int i = 0; i < samples; i++) {
        float angle = float(i) * 2.0 * M_PI_F / float(samples);
        for (float r = 1.0; r <= spreadRadius; r += spreadRadius / 4.0) {
            float2 offset = float2(cos(angle), sin(angle)) * r * texelSize;
            float4 sampleColor = src.sample(coord + offset);

            float sampleLum = dot(sampleColor.rgb, float3(0.2126, 0.7152, 0.0722));
            float sampleMask = smoothstep(threshold, 1.0, sampleLum);

            // Gaussian falloff
            float weight = exp(-r * r / (2.0 * spreadRadius * spreadRadius / 4.0));
            weight *= sampleMask;

            blurredHighlights += sampleColor.rgb * weight;
            totalWeight += weight;
        }
    }

    if (totalWeight > 0.0) {
        blurredHighlights /= totalWeight;
    }

    // Apply halation color
    // Default hue of 0.0 gives red/orange halation typical of film
    float3 halationHsl = rgbToHsl(blurredHighlights);
    halationHsl.x = hue; // Override hue with halation color
    halationHsl.y = mix(halationHsl.y, 0.8, 0.5); // Boost saturation
    float3 halationColor = hslToRgb(halationHsl);

    // Calculate halation contribution
    float halationAmount = length(blurredHighlights) * intensity;
    halationAmount = clamp(halationAmount, 0.0, 1.0);

    // Blend halation with original image using screen blend mode
    float3 result = 1.0 - (1.0 - color.rgb) * (1.0 - halationColor * halationAmount);

    // Mix based on intensity
    result = mix(color.rgb, result, intensity);

    return float4(clamp(result, 0.0, 1.0), color.a);
}

// Separate highlight extraction kernel for multi-pass pipeline
extern "C" float4 halationExtractHighlights(coreimage::sampler src,
                                             float threshold,
                                             coreimage::destination dest) {
    float4 color = src.sample(src.coord());
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));

    // Soft threshold for highlight extraction
    float mask = smoothstep(threshold, threshold + 0.2, luminance);

    return float4(color.rgb * mask, mask);
}

// Blend halation kernel - combines blurred highlights with original
extern "C" float4 halationBlend(coreimage::sampler src,
                                 coreimage::sampler blurredHighlights,
                                 float intensity,
                                 float hue,
                                 coreimage::destination dest) {
    float4 color = src.sample(src.coord());
    float4 highlights = blurredHighlights.sample(blurredHighlights.coord());

    // Apply halation color tint
    float3 halationHsl = rgbToHsl(highlights.rgb);
    halationHsl.x = hue;
    halationHsl.y = mix(halationHsl.y, 0.8, 0.5);
    float3 halationColor = hslToRgb(halationHsl);

    // Screen blend mode for glow effect
    float3 result = 1.0 - (1.0 - color.rgb) * (1.0 - halationColor * intensity * highlights.a);

    return float4(clamp(result, 0.0, 1.0), color.a);
}
