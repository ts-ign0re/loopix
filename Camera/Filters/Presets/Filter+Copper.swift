extension CameraFilter {
    /// Redscale 100 — strong amber/red cast with suppressed blues
    static let copper = CameraFilter(
        id: "redscale", name: "Redscale", shortName: "RDS",
        tagline: "Amber burn, crushed cyans",
        temperature: 24, tint: 8, saturation: 10, contrast: 6,
        exposure: -0.05, isMonochrome: false, fade: 2,
        shadowHue: 18, shadowTintStrength: 0.10,
        highlightHue: 36, highlightTintStrength: 0.12,
        blackFloor: 0.05, whiteCeiling: 0.93,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.03, darks: 0.27, midtones: 0.56, lights: 0.80, highlights: 0.97),
            g: ToneCurve(shadows: 0.01, darks: 0.23, midtones: 0.50, lights: 0.75, highlights: 0.95),
            b: ToneCurve(shadows: 0.00, darks: 0.16, midtones: 0.41, lights: 0.67, highlights: 0.90)
        )
    )
}
