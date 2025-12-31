//
//  VignetteKernel.metal
//  FilmBox
//
//  Metal shader for advanced vignette effect with feathering
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// Vignette kernel with advanced controls
// Parameters:
//   amount: Vignette intensity (-1.0 to 1.0, negative = lighten edges)
//   midpoint: Where the vignette starts (0.0 - 1.0, from center)
//   roundness: Shape of vignette (0.0 = rectangular, 1.0 = circular)
//   feather: Softness of the vignette transition (0.0 - 1.0)
extern "C" float4 vignetteKernel(coreimage::sampler src,
                                  float amount,
                                  float midpoint,
                                  float roundness,
                                  float feather,
                                  float2 center,
                                  float2 imageSize,
                                  coreimage::destination dest) {
    // Sample source image
    float4 color = src.sample(src.coord());

    // Get pixel position relative to center
    float2 coord = dest.coord();
    float2 normalizedCoord = (coord - center) / imageSize;

    // Adjust for aspect ratio
    float aspectRatio = imageSize.x / imageSize.y;
    normalizedCoord.x *= aspectRatio;

    // Calculate distance based on roundness
    // roundness = 1.0: circular (Euclidean distance)
    // roundness = 0.0: rectangular (Chebyshev distance)
    float2 absCoord = abs(normalizedCoord);

    // Blend between circular and rectangular distance
    float circularDist = length(normalizedCoord);
    float rectangularDist = max(absCoord.x, absCoord.y);
    float dist = mix(rectangularDist, circularDist, roundness);

    // Scale distance relative to aspect ratio
    dist *= 2.0; // Normalize so 1.0 reaches the edges

    // Apply midpoint (where vignette starts)
    // midpoint of 0.5 means vignette starts halfway to edge
    float start = midpoint;
    float end = start + max(feather, 0.01); // Prevent division by zero

    // Calculate vignette mask with smooth falloff
    float vignette = smoothstep(start, end, dist);

    // Apply amount (positive = darken, negative = lighten)
    float3 result;
    if (amount >= 0.0) {
        // Darken edges
        float darkenFactor = 1.0 - (vignette * amount);
        result = color.rgb * darkenFactor;
    } else {
        // Lighten edges
        float lightenAmount = vignette * (-amount);
        result = color.rgb + (1.0 - color.rgb) * lightenAmount;
    }

    return float4(clamp(result, 0.0, 1.0), color.a);
}

// Alternative vignette with exposure-based falloff
// More photographic look using exposure compensation
extern "C" float4 vignetteExposureKernel(coreimage::sampler src,
                                          float exposureStops,
                                          float midpoint,
                                          float roundness,
                                          float feather,
                                          float2 center,
                                          float2 imageSize,
                                          coreimage::destination dest) {
    float4 color = src.sample(src.coord());

    float2 coord = dest.coord();
    float2 normalizedCoord = (coord - center) / imageSize;

    float aspectRatio = imageSize.x / imageSize.y;
    normalizedCoord.x *= aspectRatio;

    float2 absCoord = abs(normalizedCoord);
    float circularDist = length(normalizedCoord);
    float rectangularDist = max(absCoord.x, absCoord.y);
    float dist = mix(rectangularDist, circularDist, roundness) * 2.0;

    float start = midpoint;
    float end = start + max(feather, 0.01);
    float vignette = smoothstep(start, end, dist);

    // Apply exposure adjustment in stops
    // Negative stops = darken, positive = brighten
    float exposureMultiplier = pow(2.0, -exposureStops * vignette);
    float3 result = color.rgb * exposureMultiplier;

    return float4(clamp(result, 0.0, 1.0), color.a);
}

// Colored vignette with customizable tint
extern "C" float4 vignetteColoredKernel(coreimage::sampler src,
                                         float amount,
                                         float midpoint,
                                         float roundness,
                                         float feather,
                                         float3 vignetteColor,
                                         float2 center,
                                         float2 imageSize,
                                         coreimage::destination dest) {
    float4 color = src.sample(src.coord());

    float2 coord = dest.coord();
    float2 normalizedCoord = (coord - center) / imageSize;

    float aspectRatio = imageSize.x / imageSize.y;
    normalizedCoord.x *= aspectRatio;

    float2 absCoord = abs(normalizedCoord);
    float circularDist = length(normalizedCoord);
    float rectangularDist = max(absCoord.x, absCoord.y);
    float dist = mix(rectangularDist, circularDist, roundness) * 2.0;

    float start = midpoint;
    float end = start + max(feather, 0.01);
    float vignette = smoothstep(start, end, dist);

    // Blend towards vignette color at edges
    float3 result = mix(color.rgb, vignetteColor * color.rgb, vignette * amount);

    return float4(clamp(result, 0.0, 1.0), color.a);
}

// Optical vignette simulation
// Simulates natural lens falloff (cos^4 law approximation)
extern "C" float4 vignetteOpticalKernel(coreimage::sampler src,
                                         float intensity,
                                         float2 center,
                                         float2 imageSize,
                                         coreimage::destination dest) {
    float4 color = src.sample(src.coord());

    float2 coord = dest.coord();
    float2 normalizedCoord = (coord - center) / (imageSize * 0.5);

    // Calculate angle from optical axis
    float dist = length(normalizedCoord);

    // Cos^4 falloff approximation (natural lens vignetting)
    // More physically accurate than simple radial falloff
    float cosAngle = 1.0 / sqrt(1.0 + dist * dist);
    float falloff = pow(cosAngle, 4.0);

    // Apply intensity control
    falloff = mix(1.0, falloff, intensity);

    float3 result = color.rgb * falloff;

    return float4(result, color.a);
}
