//
//  ToneCurveKernel.metal
//  Camera
//
//  Per-channel RGBA tone curve via 1D LUT lookup.
//  The LUT is a 256x1 texture where each pixel's RGBA channels
//  contain the output values for that input level.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" float4 toneCurveKernel(coreimage::sampler src,
                                   coreimage::sampler lut,
                                   coreimage::destination dest) {
    float4 color = src.sample(src.coord());

    // LUT is 256 pixels wide — map input value to LUT coordinate
    // sampler coord is in pixel space, offset by 0.5 for pixel center
    float r = lut.sample(float2(color.r * 255.0 + 0.5, 0.5)).r;
    float g = lut.sample(float2(color.g * 255.0 + 0.5, 0.5)).g;
    float b = lut.sample(float2(color.b * 255.0 + 0.5, 0.5)).b;
    float a = lut.sample(float2(color.a * 255.0 + 0.5, 0.5)).a;

    return float4(r, g, b, a);
}
