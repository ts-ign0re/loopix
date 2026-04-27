extension CameraFilter {
    /// Delta — modern T-grain B&W, smooth tonal range
    static let delta = CameraFilter(
        id: "delta", name: "Delta", shortName: "DLT",
        tagline: "Modern grain, smooth tones",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0, isMonochrome: true, fade: 0,
        shadowHue: 220, shadowTintStrength: 0.01,
        highlightHue: 0, highlightTintStrength: 0,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.01, darks: 0.23, midtones: 0.51, lights: 0.77, highlights: 0.99),
            g: ToneCurve(shadows: 0.01, darks: 0.23, midtones: 0.51, lights: 0.77, highlights: 0.99),
            b: ToneCurve(shadows: 0.01, darks: 0.23, midtones: 0.51, lights: 0.77, highlights: 0.99)
        )
    )
}
