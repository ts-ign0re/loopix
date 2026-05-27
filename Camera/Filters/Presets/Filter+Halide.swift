extension CameraFilter {
    /// Halide — green shadows + warm highlights, bold split tone
    static let halide = CameraFilter(
        id: "emulsion", name: "Halide", shortName: "HLD",
        tagline: "Green shadows, warm lights",
        temperature: 2, tint: -2, saturation: 3, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 155, shadowTintStrength: 0.09,
        highlightHue: 32, highlightTintStrength: 0.04,
        blackFloor: 0.02, whiteCeiling: 0.96,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.22, midtones: 0.52, lights: 0.78, highlights: 0.98),
            g: ToneCurve(shadows: 0.0, darks: 0.23, midtones: 0.51, lights: 0.77, highlights: 0.98),
            b: ToneCurve(shadows: 0.01, darks: 0.24, midtones: 0.50, lights: 0.76, highlights: 0.97)
        )
    )
}
