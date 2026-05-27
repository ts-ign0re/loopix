extension CameraFilter {
    /// Fern — green lights + warm shadows, botanical
    static let fern = CameraFilter(
        id: "dew", name: "Fern", shortName: "FRN",
        tagline: "Green lights, warm shadows",
        temperature: -5, tint: -3, saturation: 5, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 35, shadowTintStrength: 0.04,
        highlightHue: 155, highlightTintStrength: 0.06,
        blackFloor: 0.02, whiteCeiling: 0.96,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.23, midtones: 0.50, lights: 0.77, highlights: 0.98),
            g: ToneCurve(shadows: 0.01, darks: 0.24, midtones: 0.52, lights: 0.78, highlights: 0.98),
            b: ToneCurve(shadows: 0.0, darks: 0.23, midtones: 0.49, lights: 0.76, highlights: 0.97)
        )
    )
}
