extension CameraFilter {
    /// Kodak HIE Infra — high-contrast infrared monochrome look
    static let slate = CameraFilter(
        id: "mono", name: "HIE Infra", shortName: "HIE",
        tagline: "Infrared glow, white foliage",
        temperature: 4, tint: 0, saturation: 0, contrast: 14,
        exposure: 0.15, isMonochrome: true, fade: 0,
        shadowHue: 200, shadowTintStrength: 0.03,
        highlightHue: 50, highlightTintStrength: 0.05,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.00, darks: 0.14, midtones: 0.58, lights: 0.87, highlights: 1.00),
            g: ToneCurve(shadows: 0.00, darks: 0.14, midtones: 0.58, lights: 0.87, highlights: 1.00),
            b: ToneCurve(shadows: 0.00, darks: 0.14, midtones: 0.58, lights: 0.87, highlights: 1.00)
        )
    )
}
