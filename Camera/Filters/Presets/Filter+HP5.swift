extension CameraFilter {
    /// HP5 — classic photojournalism B&W, rich S-curve
    static let hp5 = CameraFilter(
        id: "hp5", name: "HP5", shortName: "HP5",
        tagline: "Classic press, rich midtones",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0, isMonochrome: true, fade: 0,
        shadowHue: 35, shadowTintStrength: 0.03,
        highlightHue: 40, highlightTintStrength: 0.01,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.20, midtones: 0.53, lights: 0.80, highlights: 0.98),
            g: ToneCurve(shadows: 0.0, darks: 0.20, midtones: 0.53, lights: 0.80, highlights: 0.98),
            b: ToneCurve(shadows: 0.0, darks: 0.20, midtones: 0.53, lights: 0.80, highlights: 0.98)
        )
    )
}
