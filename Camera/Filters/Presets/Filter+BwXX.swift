extension CameraFilter {
    /// Kodak BW 400 CN — chromogenic monochrome with soft highlights
    static let bwXX = CameraFilter(
        id: "bw400cn", name: "BW 400 CN", shortName: "CN4",
        tagline: "Chromogenic, soft highlights",
        temperature: 0, tint: 0, saturation: 0, contrast: -4,
        exposure: 0, isMonochrome: true, fade: 10,
        shadowHue: 210, shadowTintStrength: 0.02,
        highlightHue: 42, highlightTintStrength: 0.03,
        blackFloor: 0.04, whiteCeiling: 0.94,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.03, darks: 0.24, midtones: 0.50, lights: 0.76, highlights: 0.95),
            g: ToneCurve(shadows: 0.03, darks: 0.24, midtones: 0.50, lights: 0.76, highlights: 0.95),
            b: ToneCurve(shadows: 0.03, darks: 0.24, midtones: 0.50, lights: 0.76, highlights: 0.95)
        )
    )
}
