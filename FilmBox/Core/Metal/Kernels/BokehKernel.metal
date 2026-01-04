//
//  BokehKernel.metal
//  FilmBox
//
//  Metal shader for realistic optical bokeh depth-of-field effect
//  Based on ring-sampling gather algorithm used in video game rendering
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

// Constants for bokeh sampling
constant int MAX_RINGS = 6;
constant int SAMPLES_PER_RING = 8;

// Helper: Calculate luminance for highlight detection
inline float luminance(float3 color) {
    return dot(color, float3(0.2126, 0.7152, 0.0722));
}

// Helper: Smooth circle aperture shape
inline float circleWeight(float2 offset, float radius) {
    float dist = length(offset);
    return smoothstep(radius + 0.5, radius - 0.5, dist);
}

// Helper: Hexagonal aperture shape (6 blades)
inline float hexagonWeight(float2 offset, float radius) {
    float2 absOffset = abs(offset);
    // Hexagon distance function
    float hex = max(absOffset.x * 0.866025 + absOffset.y * 0.5, absOffset.y);
    return smoothstep(radius + 0.5, radius - 0.5, hex);
}

// Main bokeh kernel - applies optical depth of field with bokeh highlights
// Parameters:
//   src: Source image sampler
//   mask: Blur mask (0 = sharp, 1 = fully blurred)
//   maxRadius: Maximum blur radius in pixels
//   highlightThreshold: Brightness threshold for bokeh highlight boost (0.0 - 1.0)
//   highlightBoost: Amount to boost bright highlights (1.0 - 3.0)
//   apertureBlades: 0 = circle, 6 = hexagon, 5 = pentagon
//   dest: Destination
extern "C" float4 bokehKernel(coreimage::sampler src,
                               coreimage::sampler mask,
                               float maxRadius,
                               float highlightThreshold,
                               float highlightBoost,
                               float apertureBlades,
                               coreimage::destination dest) {
    float2 coord = src.coord();
    float2 texelSize = 1.0 / src.size();

    // Sample mask at same relative position as source pixel
    // coord is in source pixel space, normalize to 0-1 then sample mask
    float2 normalizedCoord = coord / src.size();
    float2 maskCoord = normalizedCoord * mask.size();
    // Mask: black (0) = sharp center, white (1) = blur edges
    float blurAmount = mask.sample(maskCoord).r;

    // If no blur needed, return original
    if (blurAmount < 0.001) {
        return src.sample(coord);
    }

    // Calculate actual blur radius for this pixel
    float radius = blurAmount * maxRadius;

    // Early exit for very small blur
    if (radius < 0.5) {
        return src.sample(coord);
    }

    // Determine number of rings based on blur radius
    int numRings = clamp(int(radius / 2.0) + 1, 2, MAX_RINGS);

    // Accumulator for weighted color
    float4 colorSum = float4(0.0);
    float weightSum = 0.0;

    // Sample center pixel
    float4 centerColor = src.sample(coord);
    float centerLum = luminance(centerColor.rgb);

    // Apply highlight boost to center if bright
    float centerHighlight = 1.0;
    if (centerLum > highlightThreshold) {
        centerHighlight = 1.0 + (centerLum - highlightThreshold) * highlightBoost;
    }

    colorSum += centerColor * centerHighlight;
    weightSum += centerHighlight;

    // Ring-based sampling for bokeh effect
    for (int ring = 1; ring <= numRings; ring++) {
        // Radius for this ring (proportional distribution)
        float ringRadius = (float(ring) / float(numRings)) * radius;

        // Number of samples increases with ring radius for uniform density
        int samplesThisRing = SAMPLES_PER_RING * ring;

        // Random rotation offset for each ring to reduce banding
        float ringRotation = float(ring) * 0.618033988749 * 2.0 * M_PI_F; // Golden ratio rotation

        for (int s = 0; s < samplesThisRing; s++) {
            // Calculate angle for this sample
            float angle = ringRotation + float(s) * 2.0 * M_PI_F / float(samplesThisRing);

            // Calculate offset
            float2 offset = ringRadius * float2(cos(angle), sin(angle));

            // Apply aperture shape weighting
            float apertureWeight = 1.0;
            if (apertureBlades <= 0.5) {
                // Circular aperture - disc-shaped bokeh
                apertureWeight = circleWeight(offset, ringRadius);
            } else if (apertureBlades > 5.5) {
                // Hexagonal aperture (6 blades)
                apertureWeight = hexagonWeight(offset, ringRadius);
            }

            // Skip if outside aperture shape
            if (apertureWeight < 0.01) continue;

            // Sample at offset position
            float2 sampleCoord = coord + offset * texelSize;
            float4 sampleColor = src.sample(sampleCoord);
            float sampleLum = luminance(sampleColor.rgb);

            // Highlight boost for bright areas (creates bokeh balls)
            float highlightWeight = 1.0;
            if (sampleLum > highlightThreshold) {
                // Quadratic boost for bright areas
                float excess = (sampleLum - highlightThreshold) / (1.0 - highlightThreshold + 0.001);
                highlightWeight = 1.0 + excess * excess * highlightBoost;
            }

            // Combined weight: aperture shape * highlight boost
            float weight = apertureWeight * highlightWeight;

            // Accumulate
            colorSum += sampleColor * weight;
            weightSum += weight;
        }
    }

    // Normalize
    if (weightSum > 0.0) {
        colorSum /= weightSum;
    }

    return float4(colorSum.rgb, centerColor.a);
}

// Fast preview bokeh - uses fewer samples for real-time dragging
// Uses a simplified 3-ring pattern for speed
extern "C" float4 bokehKernelFast(coreimage::sampler src,
                                   coreimage::sampler mask,
                                   float maxRadius,
                                   coreimage::destination dest) {
    float2 coord = src.coord();
    float2 texelSize = 1.0 / src.size();

    // Sample mask at same relative position as source pixel
    float2 normalizedCoord = coord / src.size();
    float2 maskCoord = normalizedCoord * mask.size();
    // Mask: black (0) = sharp, white (1) = blur
    float blurAmount = mask.sample(maskCoord).r;

    // If no blur needed, return original
    if (blurAmount < 0.001) {
        return src.sample(coord);
    }

    float radius = blurAmount * maxRadius;

    if (radius < 1.0) {
        return src.sample(coord);
    }

    // Simple 3-ring fast blur
    float4 colorSum = src.sample(coord);
    float weightSum = 1.0;

    // Fixed sample pattern: 3 rings with 8, 16, 24 samples
    int rings[3] = {1, 2, 3};
    int samples[3] = {8, 12, 16};

    for (int r = 0; r < 3; r++) {
        float ringRadius = (float(rings[r]) / 3.0) * radius;
        int numSamples = samples[r];

        for (int s = 0; s < numSamples; s++) {
            float angle = float(s) * 2.0 * M_PI_F / float(numSamples);
            float2 offset = ringRadius * float2(cos(angle), sin(angle)) * texelSize;

            float4 sampleColor = src.sample(coord + offset);
            colorSum += sampleColor;
            weightSum += 1.0;
        }
    }

    return float4(colorSum.rgb / weightSum, colorSum.a / weightSum);
}

// Radial blur mask generator - creates gradient from center point
// Parameters:
//   centerX, centerY: Focus center in normalized coordinates (0-1)
//   innerRadius: Radius of sharp focus area (0-1 of image diagonal)
//   outerRadius: Where blur reaches maximum (0-1)
//   falloff: Transition curve (1.0 = linear, 2.0 = quadratic, 0.5 = sqrt)
extern "C" float4 radialMaskKernel(coreimage::sampler src,
                                    float centerX,
                                    float centerY,
                                    float innerRadius,
                                    float outerRadius,
                                    float falloff,
                                    coreimage::destination dest) {
    float2 size = src.size();
    float2 coord = dest.coord();

    // Convert to normalized coordinates
    float2 normalizedCoord = coord / size;
    float2 center = float2(centerX, centerY);

    // Calculate distance from center, accounting for aspect ratio
    float aspectRatio = size.x / size.y;
    float2 delta = normalizedCoord - center;
    delta.x *= aspectRatio;
    float dist = length(delta);

    // Normalize distance by diagonal
    float diagonal = sqrt(1.0 + aspectRatio * aspectRatio);
    float normalizedDist = dist / diagonal;

    // Calculate blur amount based on distance
    float blurAmount = 0.0;
    if (normalizedDist > innerRadius) {
        // Map distance to blur amount with falloff curve
        float t = clamp((normalizedDist - innerRadius) / (outerRadius - innerRadius + 0.001), 0.0, 1.0);
        blurAmount = pow(t, falloff);
    }

    return float4(blurAmount, blurAmount, blurAmount, 1.0);
}

// Linear/tilt-shift blur mask generator
// Parameters:
//   position: Y position of focus band (0-1)
//   focusWidth: Width of in-focus band (0-1)
//   falloff: Transition softness
extern "C" float4 linearMaskKernel(coreimage::sampler src,
                                    float position,
                                    float focusWidth,
                                    float falloff,
                                    coreimage::destination dest) {
    float2 size = src.size();
    float2 coord = dest.coord();

    // Normalized Y position
    float normalizedY = coord.y / size.y;

    // Distance from focus band center
    float distFromCenter = abs(normalizedY - position);

    // Calculate blur based on distance from focus band
    float halfWidth = focusWidth * 0.5;
    float blurAmount = 0.0;

    if (distFromCenter > halfWidth) {
        float t = (distFromCenter - halfWidth) / (0.5 - halfWidth + 0.001);
        t = clamp(t, 0.0, 1.0);
        blurAmount = pow(t, falloff);
    }

    return float4(blurAmount, blurAmount, blurAmount, 1.0);
}

// Masked bokeh composite - blends sharp and blurred images using mask
extern "C" float4 bokehCompositeKernel(coreimage::sampler sharp,
                                        coreimage::sampler blurred,
                                        coreimage::sampler mask,
                                        coreimage::destination dest) {
    float4 sharpColor = sharp.sample(sharp.coord());
    float4 blurredColor = blurred.sample(blurred.coord());
    float blurAmount = mask.sample(mask.coord()).r;

    // Linear interpolation between sharp and blurred
    return mix(sharpColor, blurredColor, blurAmount);
}
