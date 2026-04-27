extension CameraFilter {
    /// Pan F — ultra fine grain B&W, luminous
    static let panF = CameraFilter(
        id: "panf", name: "Pan F", shortName: "PNF",
        tagline: "Fine grain, soft light",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0.15, isMonochrome: true, fade: 0,
        shadowHue: 35, shadowTintStrength: 0.01,
        highlightHue: 40, highlightTintStrength: 0.01,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.02, darks: 0.26, midtones: 0.50, lights: 0.74, highlights: 0.97),
            g: ToneCurve(shadows: 0.02, darks: 0.26, midtones: 0.50, lights: 0.74, highlights: 0.97),
            b: ToneCurve(shadows: 0.02, darks: 0.26, midtones: 0.50, lights: 0.74, highlights: 0.97)
        )
    )
}
