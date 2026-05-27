extension CameraFilter {
    /// Classic Chrome — Fuji, desaturated vintage, muted
    static let classicChrome = CameraFilter(
        id: "classicc", name: "Classic C", shortName: "CLC",
        tagline: "Muted, desaturated, vintage",
        temperature: 2, tint: 0, saturation: -12, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 210, shadowTintStrength: 0.05,
        highlightHue: 35, highlightTintStrength: 0.03,
        blackFloor: 0.02, whiteCeiling: 0.96,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.02, darks: 0.22, midtones: 0.52, lights: 0.78, highlights: 0.97),
            g: ToneCurve(shadows: 0.02, darks: 0.22, midtones: 0.50, lights: 0.77, highlights: 0.97),
            b: ToneCurve(shadows: 0.03, darks: 0.24, midtones: 0.50, lights: 0.76, highlights: 0.96)
        )
    )
}
