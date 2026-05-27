extension CameraFilter {
    /// PX-100UV+ Warm — warm instant chemistry with soft contrast
    static let flare = CameraFilter(
        id: "uvwarm", name: "UV Warm", shortName: "UVW",
        tagline: "Warm instant chemistry",
        temperature: 8, tint: 14, saturation: 4, contrast: -10,
        exposure: 0.08, isMonochrome: false, fade: 14,
        shadowHue: 320, shadowTintStrength: 0.04,
        highlightHue: 34, highlightTintStrength: 0.07,
        blackFloor: 0.06, whiteCeiling: 0.93,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.06, darks: 0.28, midtones: 0.54, lights: 0.77, highlights: 0.95),
            g: ToneCurve(shadows: 0.05, darks: 0.27, midtones: 0.52, lights: 0.76, highlights: 0.95),
            b: ToneCurve(shadows: 0.06, darks: 0.26, midtones: 0.50, lights: 0.73, highlights: 0.93)
        )
    )
}
