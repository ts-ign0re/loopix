extension CameraFilter {
    /// Superia — Fuji Superia 400, nostalgic consumer negative
    static let superia = CameraFilter(
        id: "superia", name: "Superia", shortName: "SPR",
        tagline: "Nostalgic greens, everyday film",
        temperature: 4, tint: 2, saturation: 0, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 145, shadowTintStrength: 0.06,
        highlightHue: 45, highlightTintStrength: 0.02,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.02, darks: 0.25, midtones: 0.52, lights: 0.76, highlights: 0.97),
            g: ToneCurve(shadows: 0.01, darks: 0.25, midtones: 0.51, lights: 0.76, highlights: 0.97),
            b: ToneCurve(shadows: 0.02, darks: 0.26, midtones: 0.50, lights: 0.75, highlights: 0.96)
        )
    )
}
