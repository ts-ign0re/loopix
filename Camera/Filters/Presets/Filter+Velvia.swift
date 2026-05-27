extension CameraFilter {
    /// Velvia — Fuji Velvia 50, vivid saturated slide film
    static let velvia = CameraFilter(
        id: "velvia", name: "Velvia", shortName: "VLV",
        tagline: "Vivid slide film, rich contrast",
        temperature: 5, tint: 3, saturation: 22, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 240, shadowTintStrength: 0.04,
        highlightHue: 40, highlightTintStrength: 0.02,
        blackFloor: 0.01, whiteCeiling: 0.99,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.18, midtones: 0.52, lights: 0.82, highlights: 1.0),
            g: ToneCurve(shadows: 0.0, darks: 0.19, midtones: 0.52, lights: 0.81, highlights: 1.0),
            b: ToneCurve(shadows: 0.0, darks: 0.20, midtones: 0.50, lights: 0.80, highlights: 0.99)
        )
    )
}
