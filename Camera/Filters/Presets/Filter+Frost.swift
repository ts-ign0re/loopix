extension CameraFilter {
    /// Time Zero Expired Cold — faded instant stock with cold cast
    static let frost = CameraFilter(
        id: "expiredcold", name: "Expired Cold", shortName: "EXC",
        tagline: "Aged instant, cold cast",
        temperature: -18, tint: -4, saturation: -18, contrast: -6,
        exposure: 0.05, isMonochrome: false, fade: 12,
        shadowHue: 195, shadowTintStrength: 0.08,
        highlightHue: 210, highlightTintStrength: 0.03,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.04, darks: 0.27, midtones: 0.50, lights: 0.73, highlights: 0.93),
            g: ToneCurve(shadows: 0.04, darks: 0.28, midtones: 0.51, lights: 0.74, highlights: 0.94),
            b: ToneCurve(shadows: 0.05, darks: 0.30, midtones: 0.53, lights: 0.76, highlights: 0.95)
        )
    )
}
