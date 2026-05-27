extension CameraFilter {
    /// Chrome — Kodachrome 64, warm slide, rich magenta
    static let chrome = CameraFilter(
        id: "kodachrome", name: "Chrome", shortName: "KCM",
        tagline: "Warm slide film, rich colors",
        temperature: 5, tint: -4, saturation: 10, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 290, shadowTintStrength: 0.04,
        highlightHue: 280, highlightTintStrength: 0.03,
        blackFloor: 0.015, whiteCeiling: 0.98,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.19, midtones: 0.53, lights: 0.81, highlights: 0.99),
            g: ToneCurve(shadows: 0.0, darks: 0.21, midtones: 0.50, lights: 0.79, highlights: 0.98),
            b: ToneCurve(shadows: 0.01, darks: 0.22, midtones: 0.49, lights: 0.77, highlights: 0.97)
        )
    )
}
