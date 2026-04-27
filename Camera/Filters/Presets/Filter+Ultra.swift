extension CameraFilter {
    /// Ultra — Agfa Ultra Color 100, vivid punchy consumer
    static let ultra = CameraFilter(
        id: "ultra", name: "Ultra", shortName: "ULT",
        tagline: "Vivid, punchy, oversaturated",
        temperature: 5, tint: -3, saturation: 25, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 350, shadowTintStrength: 0.04,
        highlightHue: 45, highlightTintStrength: 0.04,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.17, midtones: 0.53, lights: 0.83, highlights: 1.0),
            g: ToneCurve(shadows: 0.0, darks: 0.18, midtones: 0.52, lights: 0.82, highlights: 1.0),
            b: ToneCurve(shadows: 0.0, darks: 0.19, midtones: 0.50, lights: 0.81, highlights: 0.99)
        )
    )
}
