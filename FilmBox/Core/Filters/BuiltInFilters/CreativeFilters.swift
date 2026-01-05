import Foundation

/// Creative filter presets organized by mood and style
enum CreativeFilters {

    // MARK: - COOL Category

    /// Arctic - Cold, blue-tinted, high clarity
    static let arctic = FilterPreset(
        id: UUID(uuidString: "20000000-0001-0000-0000-000000000001")!,
        name: "Arctic",
        category: .cool,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 10,
            highlights: -15,
            shadows: 10,
            whites: 5,
            blacks: -5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.98)
                ],
                red: [],
                green: [],
                blue: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ]
            ),
            temperature: -25,
            tint: 5,
            saturation: -10,
            vibrance: 15,
            hsl: HSLAdjustments(
                red: .init(hue: -10, saturation: -20, luminance: 0),
                orange: .init(hue: -5, saturation: -15, luminance: 0),
                yellow: .init(hue: -10, saturation: -10, luminance: 0),
                green: .init(hue: 0, saturation: -5, luminance: 0),
                aqua: .init(hue: 5, saturation: 15, luminance: 5),
                blue: .init(hue: 0, saturation: 20, luminance: 0),
                purple: .init(hue: 5, saturation: 10, luminance: 0),
                magenta: .init(hue: 0, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 210,
                highlightSaturation: 15,
                shadowHue: 230,
                shadowSaturation: 20,
                balance: -10
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 20,
            grain: GrainData(amount: 15, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 12, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 5,
            bloom: .none,
            halation: .none,
            sharpness: 10,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["cold tones", "blue shadows", "crisp", "winter mood"],
            author: "FilmBox"
        )
    )

    /// Ocean Breeze - Teal and aqua tones, fresh feeling
    static let oceanBreeze = FilterPreset(
        id: UUID(uuidString: "20000000-0001-0000-0000-000000000002")!,
        name: "Ocean Breeze",
        category: .cool,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: 5,
            highlights: -10,
            shadows: 15,
            whites: 0,
            blacks: 5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.27),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.97)
                ],
                red: [],
                green: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.27),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.98)
                ],
                blue: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ]
            ),
            temperature: -15,
            tint: -8,
            saturation: 5,
            vibrance: 20,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: -10, luminance: 0),
                orange: .init(hue: -5, saturation: 0, luminance: 5),
                yellow: .init(hue: -15, saturation: -5, luminance: 5),
                green: .init(hue: 20, saturation: 10, luminance: 0),
                aqua: .init(hue: 0, saturation: 25, luminance: 5),
                blue: .init(hue: -10, saturation: 15, luminance: 0),
                purple: .init(hue: 0, saturation: 5, luminance: 0),
                magenta: .init(hue: 0, saturation: -5, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 180,
                highlightSaturation: 12,
                shadowHue: 200,
                shadowSaturation: 15,
                balance: 0
            ),
            skinToneHue: 5,
            skinToneSaturation: 3,
            clarity: 12,
            grain: GrainData(amount: 17, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 8, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 8,
            bloom: BloomData(intensity: 10, radius: 0.45, threshold: 0.8),
            halation: .none,
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["teal tones", "aqua", "fresh", "coastal vibes"],
            author: "FilmBox"
        )
    )

    /// Moonlight - Dark blue tones, nighttime mood
    static let moonlight = FilterPreset(
        id: UUID(uuidString: "20000000-0001-0000-0000-000000000003")!,
        name: "Moonlight",
        category: .cool,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: -0.1,
            contrast: 15,
            highlights: -20,
            shadows: 5,
            whites: -10,
            blacks: -15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.48),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.94)
                ],
                red: [],
                green: [],
                blue: [
                    .init(x: 0, y: 0.08),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.95)
                ]
            ),
            temperature: -30,
            tint: 10,
            saturation: -20,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: -15, saturation: -30, luminance: -10),
                orange: .init(hue: -10, saturation: -25, luminance: -5),
                yellow: .init(hue: -20, saturation: -30, luminance: -5),
                green: .init(hue: 0, saturation: -20, luminance: -5),
                aqua: .init(hue: 10, saturation: 5, luminance: 5),
                blue: .init(hue: 0, saturation: 20, luminance: 5),
                purple: .init(hue: 10, saturation: 15, luminance: 0),
                magenta: .init(hue: 5, saturation: -5, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 220,
                highlightSaturation: 18,
                shadowHue: 240,
                shadowSaturation: 25,
                balance: -20
            ),
            skinToneHue: 0,
            skinToneSaturation: -5,
            clarity: 10,
            grain: GrainData(amount: 18, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 25, midpoint: 0.45, roundness: 0, feather: 0.55),
            fade: 10,
            bloom: BloomData(intensity: 5, radius: 0.3, threshold: 0.85),
            halation: .none,
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["dark blue", "nighttime", "moody", "cinematic"],
            author: "FilmBox"
        )
    )

    // MARK: - WARM Category

    /// Golden Hour - Warm orange glow, soft highlights
    static let goldenHour = FilterPreset(
        id: UUID(uuidString: "20000000-0002-0000-0000-000000000001")!,
        name: "Golden Hour",
        category: .warm,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.15,
            contrast: -5,
            highlights: -20,
            shadows: 20,
            whites: -5,
            blacks: 10,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ],
                red: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.79),
                    .init(x: 1, y: 0.98)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.48),
                    .init(x: 0.75, y: 0.73),
                    .init(x: 1, y: 0.94)
                ]
            ),
            temperature: 30,
            tint: 5,
            saturation: 10,
            vibrance: 15,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: 10, luminance: 5),
                orange: .init(hue: 0, saturation: 20, luminance: 10),
                yellow: .init(hue: 5, saturation: 15, luminance: 10),
                green: .init(hue: 15, saturation: -10, luminance: 0),
                aqua: .init(hue: 20, saturation: -15, luminance: 0),
                blue: .init(hue: 10, saturation: -20, luminance: -5),
                purple: .init(hue: 5, saturation: -10, luminance: 0),
                magenta: .init(hue: 0, saturation: 5, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 20,
                shadowHue: 30,
                shadowSaturation: 15,
                balance: 10
            ),
            skinToneHue: 5,
            skinToneSaturation: 10,
            clarity: 5,
            grain: GrainData(amount: 17, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 15, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 10,
            bloom: BloomData(intensity: 15, radius: 0.5, threshold: 0.75),
            halation: HalationData(intensity: 20, hue: 25, spread: 0.5),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["warm glow", "orange tones", "soft light", "sunset mood"],
            author: "FilmBox"
        )
    )

    /// Sunset Blaze - Intense warm colors, dramatic
    static let sunsetBlaze = FilterPreset(
        id: UUID(uuidString: "20000000-0002-0000-0000-000000000002")!,
        name: "Sunset Blaze",
        category: .warm,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: 15,
            highlights: -15,
            shadows: 15,
            whites: 5,
            blacks: -5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.99)
                ],
                red: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.58),
                    .init(x: 0.75, y: 0.82),
                    .init(x: 1, y: 1)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.20),
                    .init(x: 0.5, y: 0.42),
                    .init(x: 0.75, y: 0.68),
                    .init(x: 1, y: 0.90)
                ]
            ),
            temperature: 40,
            tint: 10,
            saturation: 20,
            vibrance: 20,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 25, luminance: 5),
                orange: .init(hue: -5, saturation: 30, luminance: 10),
                yellow: .init(hue: 0, saturation: 25, luminance: 8),
                green: .init(hue: 20, saturation: -15, luminance: -5),
                aqua: .init(hue: 25, saturation: -25, luminance: -5),
                blue: .init(hue: 15, saturation: -30, luminance: -10),
                purple: .init(hue: 10, saturation: 10, luminance: 0),
                magenta: .init(hue: 5, saturation: 15, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 35,
                highlightSaturation: 25,
                shadowHue: 15,
                shadowSaturation: 20,
                balance: 5
            ),
            skinToneHue: 0,
            skinToneSaturation: 5,
            clarity: 15,
            grain: GrainData(amount: 17, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 20, midpoint: 0.5, roundness: 0, feather: 0.6),
            fade: 5,
            bloom: BloomData(intensity: 20, radius: 0.55, threshold: 0.7),
            halation: HalationData(intensity: 25, hue: 15, spread: 0.55),
            sharpness: 8,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["intense warmth", "dramatic colors", "sunset", "vibrant"],
            author: "FilmBox"
        )
    )

    /// Candlelight - Soft warm tones, intimate
    static let candlelight = FilterPreset(
        id: UUID(uuidString: "20000000-0002-0000-0000-000000000003")!,
        name: "Candlelight",
        category: .warm,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: -10,
            highlights: -25,
            shadows: 25,
            whites: -10,
            blacks: 15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.95)
                ],
                red: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.96)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.06),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.72),
                    .init(x: 1, y: 0.92)
                ]
            ),
            temperature: 25,
            tint: 8,
            saturation: -5,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: 8, saturation: 5, luminance: 5),
                orange: .init(hue: 5, saturation: 15, luminance: 10),
                yellow: .init(hue: 0, saturation: 10, luminance: 8),
                green: .init(hue: 10, saturation: -20, luminance: -5),
                aqua: .init(hue: 15, saturation: -25, luminance: -5),
                blue: .init(hue: 10, saturation: -30, luminance: -10),
                purple: .init(hue: 5, saturation: -15, luminance: -5),
                magenta: .init(hue: 0, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 40,
                highlightSaturation: 15,
                shadowHue: 25,
                shadowSaturation: 18,
                balance: -15
            ),
            skinToneHue: 8,
            skinToneSaturation: 8,
            clarity: 0,
            grain: GrainData(amount: 18, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 25, midpoint: 0.45, roundness: 0, feather: 0.55),
            fade: 15,
            bloom: BloomData(intensity: 12, radius: 0.45, threshold: 0.78),
            halation: HalationData(intensity: 15, hue: 20, spread: 0.45),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["soft warmth", "intimate", "low light", "cozy"],
            author: "FilmBox"
        )
    )

    // MARK: - PRO Category

    /// Clean Pro - Neutral, balanced, professional look
    static let cleanPro = FilterPreset(
        id: UUID(uuidString: "20000000-0003-0000-0000-000000000001")!,
        name: "Clean Pro",
        category: .pro,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 8,
            highlights: -10,
            shadows: 10,
            whites: 5,
            blacks: -5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.01),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.51),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.99)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 0,
            tint: 0,
            saturation: 5,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 5, luminance: 0),
                orange: .init(hue: 0, saturation: 8, luminance: 3),
                yellow: .init(hue: 0, saturation: 5, luminance: 3),
                green: .init(hue: 0, saturation: 5, luminance: 0),
                aqua: .init(hue: 0, saturation: 5, luminance: 0),
                blue: .init(hue: 0, saturation: 8, luminance: 0),
                purple: .init(hue: 0, saturation: 5, luminance: 0),
                magenta: .init(hue: 0, saturation: 5, luminance: 0)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 15,
            grain: .none,
            vignette: VignetteData(amount: 5, midpoint: 0.7, roundness: 0, feather: 0.8),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 15,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["neutral", "balanced", "professional", "clean"],
            author: "FilmBox"
        )
    )

    /// Studio Light - Bright, airy, commercial look
    static let studioLight = FilterPreset(
        id: UUID(uuidString: "20000000-0003-0000-0000-000000000002")!,
        name: "Studio Light",
        category: .pro,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.2,
            contrast: -5,
            highlights: -30,
            shadows: 30,
            whites: 10,
            blacks: 15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 3,
            tint: 0,
            saturation: -5,
            vibrance: 15,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: -5, luminance: 5),
                orange: .init(hue: 0, saturation: 5, luminance: 8),
                yellow: .init(hue: 0, saturation: 0, luminance: 5),
                green: .init(hue: 0, saturation: 0, luminance: 3),
                aqua: .init(hue: 0, saturation: 0, luminance: 3),
                blue: .init(hue: 0, saturation: 0, luminance: 0),
                purple: .init(hue: 0, saturation: 0, luminance: 0),
                magenta: .init(hue: 0, saturation: 0, luminance: 0)
            ),
            splitTone: .identity,
            skinToneHue: 3,
            skinToneSaturation: 5,
            clarity: 10,
            grain: .none,
            vignette: .none,
            fade: 5,
            bloom: BloomData(intensity: 8, radius: 0.4, threshold: 0.82),
            halation: .none,
            sharpness: 12,
            sharpenRadius: 0.9,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["bright", "airy", "commercial", "studio quality"],
            author: "FilmBox"
        )
    )

    /// Editorial - Magazine-ready, polished contrast
    static let editorial = FilterPreset(
        id: UUID(uuidString: "20000000-0003-0000-0000-000000000003")!,
        name: "Editorial",
        category: .pro,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 18,
            highlights: -15,
            shadows: 5,
            whites: 8,
            blacks: -10,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.80),
                    .init(x: 1, y: 1)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: -3,
            tint: 0,
            saturation: 0,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 5, luminance: 0),
                orange: .init(hue: -3, saturation: 10, luminance: 0),
                yellow: .init(hue: 0, saturation: 5, luminance: 0),
                green: .init(hue: 5, saturation: 0, luminance: 0),
                aqua: .init(hue: 0, saturation: 5, luminance: 0),
                blue: .init(hue: 0, saturation: 10, luminance: 0),
                purple: .init(hue: 0, saturation: 5, luminance: 0),
                magenta: .init(hue: 0, saturation: 5, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 5,
                shadowHue: 220,
                shadowSaturation: 5,
                balance: 0
            ),
            skinToneHue: -2,
            skinToneSaturation: 3,
            clarity: 20,
            grain: .none,
            vignette: VignetteData(amount: 10, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 18,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["magazine quality", "polished", "high contrast", "editorial"],
            author: "FilmBox"
        )
    )

    // MARK: - PORTRAIT Category

    /// Soft Glow - Flattering light, soft skin
    static let softGlow = FilterPreset(
        id: UUID(uuidString: "20000000-0004-0000-0000-000000000001")!,
        name: "Soft Glow",
        category: .portrait,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: -15,
            highlights: -25,
            shadows: 25,
            whites: -5,
            blacks: 10,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.96)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 8,
            tint: 3,
            saturation: -8,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 3, saturation: -10, luminance: 3),
                orange: .init(hue: 0, saturation: 8, luminance: 8),
                yellow: .init(hue: -5, saturation: -10, luminance: 5),
                green: .init(hue: 10, saturation: -15, luminance: 0),
                aqua: .init(hue: 5, saturation: -10, luminance: 0),
                blue: .init(hue: 0, saturation: -15, luminance: 0),
                purple: .init(hue: 0, saturation: -10, luminance: 0),
                magenta: .init(hue: 0, saturation: -8, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 40,
                highlightSaturation: 8,
                shadowHue: 30,
                shadowSaturation: 10,
                balance: -5
            ),
            skinToneHue: 5,
            skinToneSaturation: 12,
            clarity: -10,
            grain: GrainData(amount: 15, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 15, midpoint: 0.55, roundness: 0, feather: 0.7),
            fade: 12,
            bloom: BloomData(intensity: 18, radius: 0.5, threshold: 0.75),
            halation: HalationData(intensity: 8, hue: 20, spread: 0.4),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["soft skin", "flattering", "glowing", "dreamy"],
            author: "FilmBox"
        )
    )

    /// Natural Beauty - Clean skin tones, subtle enhancement
    static let naturalBeauty = FilterPreset(
        id: UUID(uuidString: "20000000-0004-0000-0000-000000000002")!,
        name: "Natural Beauty",
        category: .portrait,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: -5,
            highlights: -15,
            shadows: 15,
            whites: 0,
            blacks: 5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.27),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.98)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 5,
            tint: 2,
            saturation: -3,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: 2, saturation: -5, luminance: 2),
                orange: .init(hue: 0, saturation: 10, luminance: 5),
                yellow: .init(hue: -3, saturation: -5, luminance: 3),
                green: .init(hue: 5, saturation: -10, luminance: 0),
                aqua: .init(hue: 0, saturation: -5, luminance: 0),
                blue: .init(hue: 0, saturation: -8, luminance: 0),
                purple: .init(hue: 0, saturation: -5, luminance: 0),
                magenta: .init(hue: 0, saturation: -3, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 5,
                shadowHue: 35,
                shadowSaturation: 5,
                balance: 0
            ),
            skinToneHue: 3,
            skinToneSaturation: 10,
            clarity: 5,
            grain: .none,
            vignette: VignetteData(amount: 10, midpoint: 0.6, roundness: 0, feather: 0.75),
            fade: 5,
            bloom: BloomData(intensity: 5, radius: 0.35, threshold: 0.82),
            halation: .none,
            sharpness: 8,
            sharpenRadius: 0.9,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["natural", "clean skin", "subtle", "fresh"],
            author: "FilmBox"
        )
    )

    /// Warm Portrait - Classic warm portrait tones
    static let warmPortrait = FilterPreset(
        id: UUID(uuidString: "20000000-0004-0000-0000-000000000003")!,
        name: "Warm Portrait",
        category: .portrait,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: -8,
            highlights: -20,
            shadows: 20,
            whites: -5,
            blacks: 8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ],
                red: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.25),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.95)
                ]
            ),
            temperature: 15,
            tint: 5,
            saturation: -5,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: -3, luminance: 3),
                orange: .init(hue: 3, saturation: 15, luminance: 8),
                yellow: .init(hue: -5, saturation: -8, luminance: 5),
                green: .init(hue: 10, saturation: -18, luminance: 0),
                aqua: .init(hue: 8, saturation: -15, luminance: 0),
                blue: .init(hue: 0, saturation: -20, luminance: -5),
                purple: .init(hue: 5, saturation: -12, luminance: 0),
                magenta: .init(hue: 5, saturation: -8, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 40,
                highlightSaturation: 12,
                shadowHue: 28,
                shadowSaturation: 15,
                balance: -10
            ),
            skinToneHue: 8,
            skinToneSaturation: 15,
            clarity: 0,
            grain: GrainData(amount: 17, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 15, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 8,
            bloom: BloomData(intensity: 10, radius: 0.4, threshold: 0.8),
            halation: HalationData(intensity: 10, hue: 18, spread: 0.4),
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["warm tones", "classic portrait", "flattering", "golden skin"],
            author: "FilmBox"
        )
    )

    // MARK: - URBAN Category

    /// Street Grit - High contrast, desaturated, raw
    static let streetGrit = FilterPreset(
        id: UUID(uuidString: "20000000-0005-0000-0000-000000000001")!,
        name: "Street Grit",
        category: .urban,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: -0.05,
            contrast: 25,
            highlights: -15,
            shadows: -10,
            whites: 10,
            blacks: -20,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.20),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.82),
                    .init(x: 1, y: 0.99)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: -5,
            tint: 0,
            saturation: -25,
            vibrance: 5,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: -15, luminance: 0),
                orange: .init(hue: 0, saturation: -10, luminance: -3),
                yellow: .init(hue: 0, saturation: -15, luminance: -5),
                green: .init(hue: 0, saturation: -20, luminance: -5),
                aqua: .init(hue: 0, saturation: -15, luminance: -3),
                blue: .init(hue: 0, saturation: -10, luminance: -5),
                purple: .init(hue: 0, saturation: -10, luminance: 0),
                magenta: .init(hue: 0, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 5,
                shadowHue: 220,
                shadowSaturation: 8,
                balance: -10
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 30,
            grain: GrainData(amount: 19, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 22, midpoint: 0.45, roundness: 0, feather: 0.5),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 20,
            sharpenRadius: 1.2,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["high contrast", "gritty", "raw", "street photography"],
            author: "FilmBox"
        )
    )

    /// Neon City - Saturated blues and magentas, night vibes
    static let neonCity = FilterPreset(
        id: UUID(uuidString: "20000000-0005-0000-0000-000000000002")!,
        name: "Neon City",
        category: .urban,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 20,
            highlights: -10,
            shadows: 5,
            whites: 5,
            blacks: -10,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ],
                red: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.96)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ]
            ),
            temperature: -20,
            tint: 15,
            saturation: 25,
            vibrance: 20,
            hsl: HSLAdjustments(
                red: .init(hue: 10, saturation: 15, luminance: 0),
                orange: .init(hue: -10, saturation: -20, luminance: -5),
                yellow: .init(hue: -15, saturation: -25, luminance: -10),
                green: .init(hue: 30, saturation: -10, luminance: -5),
                aqua: .init(hue: -10, saturation: 25, luminance: 5),
                blue: .init(hue: 0, saturation: 30, luminance: 5),
                purple: .init(hue: -10, saturation: 25, luminance: 5),
                magenta: .init(hue: 5, saturation: 30, luminance: 5)
            ),
            splitTone: SplitToneData(
                highlightHue: 290,
                highlightSaturation: 20,
                shadowHue: 220,
                shadowSaturation: 25,
                balance: 0
            ),
            skinToneHue: 0,
            skinToneSaturation: -5,
            clarity: 18,
            grain: GrainData(amount: 20, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 18, midpoint: 0.5, roundness: 0, feather: 0.55),
            fade: 5,
            bloom: BloomData(intensity: 15, radius: 0.45, threshold: 0.75),
            halation: HalationData(intensity: 10, hue: 280, spread: 0.4),
            sharpness: 15,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["neon lights", "cyberpunk", "night city", "saturated"],
            author: "FilmBox"
        )
    )

    /// Concrete Jungle - Muted greens, urban tones
    static let concreteJungle = FilterPreset(
        id: UUID(uuidString: "20000000-0005-0000-0000-000000000003")!,
        name: "Concrete Jungle",
        category: .urban,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 12,
            highlights: -12,
            shadows: 8,
            whites: 5,
            blacks: -8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.51),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ],
                red: [],
                green: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ],
                blue: []
            ),
            temperature: -8,
            tint: -5,
            saturation: -15,
            vibrance: 8,
            hsl: HSLAdjustments(
                red: .init(hue: -5, saturation: -15, luminance: 0),
                orange: .init(hue: -5, saturation: -10, luminance: 0),
                yellow: .init(hue: 10, saturation: -15, luminance: 0),
                green: .init(hue: 20, saturation: -5, luminance: 5),
                aqua: .init(hue: 10, saturation: 5, luminance: 3),
                blue: .init(hue: -5, saturation: -5, luminance: 0),
                purple: .init(hue: 0, saturation: -10, luminance: 0),
                magenta: .init(hue: 0, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 55,
                highlightSaturation: 8,
                shadowHue: 170,
                shadowSaturation: 10,
                balance: -5
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 22,
            grain: GrainData(amount: 21, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 15, midpoint: 0.5, roundness: 0, feather: 0.6),
            fade: 5,
            bloom: .none,
            halation: .none,
            sharpness: 15,
            sharpenRadius: 1.1,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            characteristics: ["urban tones", "muted colors", "architectural", "modern"],
            author: "FilmBox"
        )
    )

    // MARK: - VINTAGE Category

    /// Faded Memory - Lifted blacks, muted colors, nostalgic
    static let fadedMemory = FilterPreset(
        id: UUID(uuidString: "20000000-0006-0000-0000-000000000001")!,
        name: "Faded Memory",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: -15,
            highlights: -20,
            shadows: 30,
            whites: -10,
            blacks: 25,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.10),
                    .init(x: 0.25, y: 0.32),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.75),
                    .init(x: 1, y: 0.92)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 10,
            tint: 0,
            saturation: -30,
            vibrance: 5,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: -20, luminance: 0),
                orange: .init(hue: 0, saturation: -15, luminance: 5),
                yellow: .init(hue: -10, saturation: -20, luminance: 5),
                green: .init(hue: 15, saturation: -25, luminance: 0),
                aqua: .init(hue: 10, saturation: -20, luminance: 0),
                blue: .init(hue: 0, saturation: -25, luminance: 0),
                purple: .init(hue: 5, saturation: -20, luminance: 0),
                magenta: .init(hue: 5, saturation: -15, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 12,
                shadowHue: 35,
                shadowSaturation: 15,
                balance: -15
            ),
            skinToneHue: 5,
            skinToneSaturation: 5,
            clarity: -5,
            grain: GrainData(amount: 22, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 25, midpoint: 0.45, roundness: 0, feather: 0.55),
            fade: 25,
            bloom: BloomData(intensity: 8, radius: 0.4, threshold: 0.8),
            halation: HalationData(intensity: 12, hue: 25, spread: 0.45),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            era: "1970s",
            characteristics: ["faded", "nostalgic", "lifted blacks", "vintage"],
            author: "FilmBox"
        )
    )

    /// Retro Chrome - Cross-processed look, shifted colors
    static let retroChrome = FilterPreset(
        id: UUID(uuidString: "20000000-0006-0000-0000-000000000002")!,
        name: "Retro Chrome",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 20,
            highlights: -10,
            shadows: -5,
            whites: 10,
            blacks: -15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.80),
                    .init(x: 1, y: 0.98)
                ],
                red: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.25),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.97)
                ],
                green: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ],
                blue: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.75),
                    .init(x: 1, y: 0.94)
                ]
            ),
            temperature: 5,
            tint: 10,
            saturation: 15,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: 10, saturation: 15, luminance: 0),
                orange: .init(hue: 5, saturation: 20, luminance: 5),
                yellow: .init(hue: 15, saturation: 10, luminance: 5),
                green: .init(hue: 25, saturation: -10, luminance: -5),
                aqua: .init(hue: 20, saturation: 15, luminance: 5),
                blue: .init(hue: -15, saturation: 10, luminance: 0),
                purple: .init(hue: -10, saturation: 15, luminance: 0),
                magenta: .init(hue: 10, saturation: 10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 55,
                highlightSaturation: 15,
                shadowHue: 200,
                shadowSaturation: 12,
                balance: 5
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 15,
            grain: GrainData(amount: 15, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 18, midpoint: 0.5, roundness: 0, feather: 0.6),
            fade: 8,
            bloom: BloomData(intensity: 5, radius: 0.35, threshold: 0.82),
            halation: HalationData(intensity: 15, hue: 20, spread: 0.45),
            sharpness: 10,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            era: "1980s",
            characteristics: ["cross-processed", "color shift", "retro", "vibrant"],
            author: "FilmBox"
        )
    )

    /// Aged Paper - Sepia-toned, warm fade, antique look
    static let agedPaper = FilterPreset(
        id: UUID(uuidString: "20000000-0006-0000-0000-000000000003")!,
        name: "Aged Paper",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: -10,
            highlights: -15,
            shadows: 20,
            whites: -8,
            blacks: 20,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.08),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.94)
                ],
                red: [
                    .init(x: 0, y: 0.08),
                    .init(x: 0.25, y: 0.32),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.95)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.10),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.72),
                    .init(x: 1, y: 0.90)
                ]
            ),
            temperature: 25,
            tint: 5,
            saturation: -40,
            vibrance: 0,
            hsl: HSLAdjustments(
                red: .init(hue: 10, saturation: -10, luminance: 5),
                orange: .init(hue: 8, saturation: 5, luminance: 8),
                yellow: .init(hue: 5, saturation: 0, luminance: 5),
                green: .init(hue: 15, saturation: -30, luminance: -5),
                aqua: .init(hue: 20, saturation: -35, luminance: -5),
                blue: .init(hue: 15, saturation: -40, luminance: -10),
                purple: .init(hue: 10, saturation: -30, luminance: -5),
                magenta: .init(hue: 10, saturation: -25, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 42,
                highlightSaturation: 25,
                shadowHue: 32,
                shadowSaturation: 30,
                balance: -10
            ),
            skinToneHue: 8,
            skinToneSaturation: 8,
            clarity: -8,
            grain: GrainData(amount: 26, size: 0.6, roughness: 0.6, monochromatic: true),
            vignette: VignetteData(amount: 30, midpoint: 0.4, roundness: 0, feather: 0.5),
            fade: 20,
            bloom: BloomData(intensity: 5, radius: 0.35, threshold: 0.82),
            halation: HalationData(intensity: 8, hue: 30, spread: 0.4),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            era: "Early 1900s",
            characteristics: ["sepia", "antique", "aged", "warm fade"],
            author: "FilmBox"
        )
    )

    // MARK: - All Creative Presets by Category

    /// All COOL category presets
    static let cool: [FilterPreset] = [
        arctic,
        oceanBreeze,
        moonlight
    ]

    /// All WARM category presets
    static let warm: [FilterPreset] = [
        goldenHour,
        sunsetBlaze,
        candlelight
    ]

    /// All PRO category presets
    static let pro: [FilterPreset] = [
        cleanPro,
        studioLight,
        editorial
    ]

    /// All PORTRAIT category presets
    static let portrait: [FilterPreset] = [
        softGlow,
        naturalBeauty,
        warmPortrait
    ]

    /// All URBAN category presets
    static let urban: [FilterPreset] = [
        streetGrit,
        neonCity,
        concreteJungle
    ]

    /// All VINTAGE category presets
    static let vintage: [FilterPreset] = [
        fadedMemory,
        retroChrome,
        agedPaper
    ]

    /// All creative filter presets
    static let all: [FilterPreset] = cool + warm + pro + portrait + urban + vintage
}
