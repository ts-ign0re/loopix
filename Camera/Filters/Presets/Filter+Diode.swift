extension CameraFilter {
    /// Kodak Elite 100 XPRO — cross-process look with green/cyan shadows
    static let diode = CameraFilter(
        id: "xpro100", name: "XPRO 100", shortName: "XPR",
        tagline: "Cross-process, acid greens",
        temperature: -4, tint: -10, saturation: 14, contrast: 8,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 160, shadowTintStrength: 0.10,
        highlightHue: 54, highlightTintStrength: 0.06,
        blackFloor: 0.02, whiteCeiling: 0.95,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.00, darks: 0.18, midtones: 0.52, lights: 0.82, highlights: 0.99),
            g: ToneCurve(shadows: 0.01, darks: 0.24, midtones: 0.53, lights: 0.79, highlights: 0.98),
            b: ToneCurve(shadows: 0.00, darks: 0.21, midtones: 0.46, lights: 0.74, highlights: 0.96)
        )
    )
}
