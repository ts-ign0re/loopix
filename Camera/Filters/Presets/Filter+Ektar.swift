extension CameraFilter {
    /// Ektar — Kodak Ektar 100, vivid saturated landscape
    static let ektar = CameraFilter(
        id: "ektar", name: "Ektar", shortName: "EKT",
        tagline: "Vivid, punchy, saturated",
        temperature: 3, tint: -2, saturation: 18, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 210, shadowTintStrength: 0.04,
        highlightHue: 35, highlightTintStrength: 0.03,
        blackFloor: 0.02, whiteCeiling: 0.97,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.20, midtones: 0.52, lights: 0.80, highlights: 0.99),
            g: ToneCurve(shadows: 0.0, darks: 0.21, midtones: 0.51, lights: 0.79, highlights: 0.99),
            b: ToneCurve(shadows: 0.01, darks: 0.22, midtones: 0.49, lights: 0.77, highlights: 0.98)
        )
    )
}
