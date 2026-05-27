extension CameraFilter {
    /// Tri-X — Kodak Tri-X 400, gritty street legend, deep blacks, punchy
    static let triX = CameraFilter(
        id: "trix", name: "Tri-X", shortName: "TRX",
        tagline: "Gritty street, deep blacks",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0, isMonochrome: true, fade: 0,
        shadowHue: 35, shadowTintStrength: 0.02,
        highlightHue: 40, highlightTintStrength: 0.01,
        blackFloor: 0.025, whiteCeiling: 0.96,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.155, midtones: 0.55, lights: 0.83, highlights: 0.99),
            g: ToneCurve(shadows: 0.0, darks: 0.155, midtones: 0.55, lights: 0.83, highlights: 0.99),
            b: ToneCurve(shadows: 0.0, darks: 0.155, midtones: 0.55, lights: 0.83, highlights: 0.99)
        )
    )
}
