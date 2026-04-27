extension CameraFilter {
    /// Provia — Fuji Provia 100F, clean accurate slide
    static let provia = CameraFilter(
        id: "provia", name: "Provia", shortName: "PRV",
        tagline: "Clean, accurate slide film",
        temperature: 0, tint: 0, saturation: 6, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 225, shadowTintStrength: 0.02,
        highlightHue: 35, highlightTintStrength: 0.01,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.22, midtones: 0.51, lights: 0.78, highlights: 1.0),
            g: ToneCurve(shadows: 0.0, darks: 0.22, midtones: 0.51, lights: 0.78, highlights: 1.0),
            b: ToneCurve(shadows: 0.0, darks: 0.23, midtones: 0.50, lights: 0.77, highlights: 0.99)
        )
    )
}
