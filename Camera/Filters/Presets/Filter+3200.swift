extension CameraFilter {
    /// 3200 — Kodak T-MAX 3200 pushed, extreme grain, moody, night
    static let tmax3200 = CameraFilter(
        id: "tmax3200", name: "3200", shortName: "32K",
        tagline: "Pushed, moody, extreme",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0.15, isMonochrome: true, fade: 0,
        shadowHue: 0, shadowTintStrength: 0,
        highlightHue: 0, highlightTintStrength: 0,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.0, darks: 0.11, midtones: 0.57, lights: 0.86, highlights: 0.98),
            g: ToneCurve(shadows: 0.0, darks: 0.11, midtones: 0.57, lights: 0.86, highlights: 0.98),
            b: ToneCurve(shadows: 0.0, darks: 0.11, midtones: 0.57, lights: 0.86, highlights: 0.98)
        )
    )
}
