extension CameraFilter {
    static let cinematic = CameraFilter(
        id: "cinematic", name: "Cinematic", shortName: "CIN",
        tagline: "Teal shadows, warm highlights",
        temperature: -6, tint: -4, saturation: 8, contrast: 10,
        exposure: -0.02, isMonochrome: false, fade: 2,
        shadowHue: 195, shadowTintStrength: 0.09,
        highlightHue: 28, highlightTintStrength: 0.05,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.01, darks: 0.22, midtones: 0.50, lights: 0.82, highlights: 0.98),
            g: ToneCurve(shadows: 0.00, darks: 0.20, midtones: 0.47, lights: 0.79, highlights: 0.97),
            b: ToneCurve(shadows: 0.02, darks: 0.24, midtones: 0.53, lights: 0.86, highlights: 0.99)
        )
    )

    static let black = CameraFilter(
        id: "black", name: "Black", shortName: "BLK",
        tagline: "Dense blacks, selective red",
        temperature: -2, tint: -2, saturation: -24, contrast: 22,
        exposure: -0.18, isMonochrome: false, fade: 0,
        shadowHue: 220, shadowTintStrength: 0.02,
        highlightHue: 30, highlightTintStrength: 0.01,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.00, darks: 0.14, midtones: 0.40, lights: 0.78, highlights: 0.97),
            g: ToneCurve(shadows: 0.00, darks: 0.12, midtones: 0.37, lights: 0.74, highlights: 0.95),
            b: ToneCurve(shadows: 0.00, darks: 0.15, midtones: 0.41, lights: 0.80, highlights: 0.98)
        )
    )

    static let dreamy = CameraFilter(
        id: "dreamy", name: "Dreamy", shortName: "DRM",
        tagline: "Warm haze, soft contrast",
        temperature: 10, tint: 6, saturation: -6, contrast: -14,
        exposure: 0.12, isMonochrome: false, fade: 18,
        shadowHue: 300, shadowTintStrength: 0.03,
        highlightHue: 40, highlightTintStrength: 0.09,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.06, darks: 0.30, midtones: 0.58, lights: 0.84, highlights: 0.99),
            g: ToneCurve(shadows: 0.05, darks: 0.28, midtones: 0.55, lights: 0.82, highlights: 0.98),
            b: ToneCurve(shadows: 0.04, darks: 0.26, midtones: 0.52, lights: 0.80, highlights: 0.97)
        )
    )

    static let skylight = CameraFilter(
        id: "skylight", name: "Sky Light", shortName: "SKY",
        tagline: "Cool daylight, clean whites",
        temperature: -10, tint: -6, saturation: 4, contrast: 6,
        exposure: 0.03, isMonochrome: false, fade: 2,
        shadowHue: 205, shadowTintStrength: 0.08,
        highlightHue: 42, highlightTintStrength: 0.02,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.01, darks: 0.20, midtones: 0.49, lights: 0.81, highlights: 0.98),
            g: ToneCurve(shadows: 0.01, darks: 0.22, midtones: 0.50, lights: 0.82, highlights: 0.99),
            b: ToneCurve(shadows: 0.02, darks: 0.25, midtones: 0.56, lights: 0.88, highlights: 1.00)
        )
    )

    static let darkOrange = CameraFilter(
        id: "darkorange", name: "Dark Orange", shortName: "DOR",
        tagline: "Warm density, orange glow",
        temperature: 20, tint: 8, saturation: 12, contrast: 10,
        exposure: -0.08, isMonochrome: false, fade: 4,
        shadowHue: 18, shadowTintStrength: 0.09,
        highlightHue: 35, highlightTintStrength: 0.10,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.02, darks: 0.25, midtones: 0.55, lights: 0.86, highlights: 0.99),
            g: ToneCurve(shadows: 0.01, darks: 0.20, midtones: 0.47, lights: 0.77, highlights: 0.96),
            b: ToneCurve(shadows: 0.00, darks: 0.15, midtones: 0.39, lights: 0.67, highlights: 0.90)
        )
    )

    static let orangeBlue = CameraFilter(
        id: "orangeblue", name: "Orange&Blue", shortName: "O&B",
        tagline: "Blockbuster teal-orange split",
        temperature: -2, tint: -8, saturation: 16, contrast: 12,
        exposure: 0.0, isMonochrome: false, fade: 0,
        shadowHue: 190, shadowTintStrength: 0.13,
        highlightHue: 30, highlightTintStrength: 0.11,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.00, darks: 0.21, midtones: 0.52, lights: 0.84, highlights: 0.99),
            g: ToneCurve(shadows: 0.01, darks: 0.24, midtones: 0.50, lights: 0.78, highlights: 0.96),
            b: ToneCurve(shadows: 0.02, darks: 0.22, midtones: 0.48, lights: 0.80, highlights: 0.98)
        )
    )

    static let darkMoody = CameraFilter(
        id: "darkmoody", name: "Dark Moody", shortName: "DMD",
        tagline: "Low key, subdued palette",
        temperature: -4, tint: -3, saturation: -18, contrast: 14,
        exposure: -0.15, isMonochrome: false, fade: 6,
        shadowHue: 210, shadowTintStrength: 0.05,
        highlightHue: 30, highlightTintStrength: 0.02,
        curves: RGBACurves(
            r: ToneCurve(shadows: 0.01, darks: 0.17, midtones: 0.43, lights: 0.76, highlights: 0.96),
            g: ToneCurve(shadows: 0.01, darks: 0.16, midtones: 0.40, lights: 0.72, highlights: 0.94),
            b: ToneCurve(shadows: 0.01, darks: 0.19, midtones: 0.44, lights: 0.78, highlights: 0.97)
        )
    )
}
