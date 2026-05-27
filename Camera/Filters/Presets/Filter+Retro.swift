extension CameraFilter {
    /// Retro — Rollei-inspired vintage B&W, matte contrast
    static let retro = CameraFilter(
        id: "retro", name: "Retro", shortName: "RTR",
        tagline: "Vintage matte, bright whites",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0, isMonochrome: true, fade: 8,
        shadowHue: 40, shadowTintStrength: 0.04,
        highlightHue: 45, highlightTintStrength: 0.03,
        blackFloor: 0.06, whiteCeiling: 0.93,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.18, midtones: 0.52, lights: 0.82, highlights: 1.0),
            g: ToneCurve(shadows: 0.0, darks: 0.18, midtones: 0.52, lights: 0.82, highlights: 1.0),
            b: ToneCurve(shadows: 0.0, darks: 0.18, midtones: 0.52, lights: 0.82, highlights: 1.0)
        )
    )
}
