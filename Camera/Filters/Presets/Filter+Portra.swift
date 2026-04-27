extension CameraFilter {
    /// Portra — Kodak Portra 400, warm highlights, cool shadows, natural skin
    static let portra = CameraFilter(
        id: "portra", name: "Portra", shortName: "PRA",
        tagline: "Natural skin, soft depth",
        temperature: 3, tint: 1, saturation: -4, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 220, shadowTintStrength: 0.03,
        highlightHue: 38, highlightTintStrength: 0.02,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.02, darks: 0.26, midtones: 0.52, lights: 0.76, highlights: 0.97),
            g: ToneCurve(shadows: 0.01, darks: 0.25, midtones: 0.50, lights: 0.75, highlights: 0.97),
            b: ToneCurve(shadows: 0.03, darks: 0.27, midtones: 0.50, lights: 0.74, highlights: 0.96)
        )
    )
}
