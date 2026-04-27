extension CameraFilter {
    /// 400H — Fuji Pro 400H, overexposed pastel, cool green shadows
    static let pro400H = CameraFilter(
        id: "400h", name: "400H", shortName: "40H",
        tagline: "Pastel, cool greens, airy",
        temperature: -3, tint: -4, saturation: -8, contrast: 0,
        exposure: 0.2, isMonochrome: false, fade: 0,
        shadowHue: 165, shadowTintStrength: 0.06,
        highlightHue: 45, highlightTintStrength: 0.03,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.04, darks: 0.28, midtones: 0.51, lights: 0.74, highlights: 0.96),
            g: ToneCurve(shadows: 0.04, darks: 0.28, midtones: 0.52, lights: 0.75, highlights: 0.97),
            b: ToneCurve(shadows: 0.05, darks: 0.29, midtones: 0.52, lights: 0.74, highlights: 0.95)
        )
    )
}
