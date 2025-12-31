import Foundation

/// Film emulation presets based on classic film stocks
enum FilmEmulations {

    // MARK: - Color Negative Film Stocks

    /// Kodak Portra 160 - Low contrast, warm skin tones, pastel colors
    /// Known for exceptional skin tone reproduction and fine grain
    static let kodakPortra160 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000001")!,
        name: "Portra 160",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: -15,
            highlights: -10,
            shadows: 15,
            whites: -5,
            blacks: 5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.27),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.98)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 8,
            tint: 3,
            saturation: -8,
            vibrance: 5,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: -5, luminance: 0),
                orange: .init(hue: 3, saturation: 8, luminance: 5),
                yellow: .init(hue: -5, saturation: -10, luminance: 3),
                green: .init(hue: 10, saturation: -15, luminance: 0),
                aqua: .init(hue: 5, saturation: -10, luminance: 0),
                blue: .init(hue: -5, saturation: -12, luminance: 0),
                purple: .init(hue: 0, saturation: -8, luminance: 0),
                magenta: .init(hue: 5, saturation: -5, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 8,
                shadowHue: 30,
                shadowSaturation: 10,
                balance: -10
            ),
            skinToneHue: 5,
            skinToneSaturation: 8,
            clarity: 5,
            grain: GrainData(amount: 8, size: 0.3, roughness: 0.4, monochromatic: false),
            vignette: VignetteData(amount: 10, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 5,
            bloom: .none,
            halation: HalationData(intensity: 8, hue: 15, spread: 0.4),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Portra 160",
            era: "1998-present",
            characteristics: ["low contrast", "warm skin tones", "pastel colors", "fine grain", "professional portrait film"],
            author: "FilmBox"
        )
    )

    /// Kodak Portra 400 - Slightly more contrast, orange shadows, muted highlights
    /// Versatile professional film with excellent exposure latitude
    static let kodakPortra400 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000002")!,
        name: "Portra 400",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: -8,
            highlights: -15,
            shadows: 20,
            whites: -8,
            blacks: 8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.96)
                ],
                red: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.97)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.49),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.96)
                ]
            ),
            temperature: 10,
            tint: 5,
            saturation: -5,
            vibrance: 8,
            hsl: HSLAdjustments(
                red: .init(hue: 8, saturation: -3, luminance: 0),
                orange: .init(hue: 5, saturation: 12, luminance: 8),
                yellow: .init(hue: -8, saturation: -8, luminance: 5),
                green: .init(hue: 15, saturation: -20, luminance: -3),
                aqua: .init(hue: 10, saturation: -15, luminance: 0),
                blue: .init(hue: -8, saturation: -15, luminance: -5),
                purple: .init(hue: 5, saturation: -10, luminance: 0),
                magenta: .init(hue: 8, saturation: -8, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 40,
                highlightSaturation: 10,
                shadowHue: 25,
                shadowSaturation: 15,
                balance: -15
            ),
            skinToneHue: 8,
            skinToneSaturation: 10,
            clarity: 8,
            grain: GrainData(amount: 15, size: 0.4, roughness: 0.5, monochromatic: false),
            vignette: VignetteData(amount: 12, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 8,
            bloom: .none,
            halation: HalationData(intensity: 12, hue: 12, spread: 0.45),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Portra 400",
            era: "1998-present",
            characteristics: ["orange shadows", "muted highlights", "excellent latitude", "warm tones", "versatile"],
            author: "FilmBox"
        )
    )

    /// Kodak Portra 800 - More grain, warmer, higher contrast
    /// High-speed film with distinctive warmth and noticeable grain
    static let kodakPortra800 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000003")!,
        name: "Portra 800",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: 5,
            highlights: -20,
            shadows: 25,
            whites: -10,
            blacks: 12,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.95)
                ],
                red: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.96)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.48),
                    .init(x: 0.75, y: 0.73),
                    .init(x: 1, y: 0.94)
                ]
            ),
            temperature: 15,
            tint: 8,
            saturation: -3,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: 10, saturation: 0, luminance: 3),
                orange: .init(hue: 8, saturation: 15, luminance: 10),
                yellow: .init(hue: -10, saturation: -5, luminance: 8),
                green: .init(hue: 20, saturation: -25, luminance: -5),
                aqua: .init(hue: 15, saturation: -20, luminance: -3),
                blue: .init(hue: -10, saturation: -18, luminance: -8),
                purple: .init(hue: 8, saturation: -12, luminance: 0),
                magenta: .init(hue: 10, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 38,
                highlightSaturation: 12,
                shadowHue: 22,
                shadowSaturation: 18,
                balance: -20
            ),
            skinToneHue: 10,
            skinToneSaturation: 12,
            clarity: 10,
            grain: GrainData(amount: 28, size: 0.55, roughness: 0.6, monochromatic: false),
            vignette: VignetteData(amount: 15, midpoint: 0.5, roundness: 0, feather: 0.6),
            fade: 10,
            bloom: BloomData(intensity: 5, radius: 0.3, threshold: 0.85),
            halation: HalationData(intensity: 18, hue: 10, spread: 0.5),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Portra 800",
            era: "1998-present",
            characteristics: ["visible grain", "warm", "higher contrast", "high-speed", "low-light capable"],
            author: "FilmBox"
        )
    )

    /// Kodak Gold 200 - Saturated, warm, yellow-green cast
    /// Consumer film with punchy, saturated colors and nostalgic feel
    static let kodakGold200 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000004")!,
        name: "Kodak Gold 200",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 12,
            highlights: -8,
            shadows: 10,
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
                red: [],
                green: [
                    .init(x: 0, y: 0.01),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.99)
                ],
                blue: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.46),
                    .init(x: 0.75, y: 0.72),
                    .init(x: 1, y: 0.95)
                ]
            ),
            temperature: 18,
            tint: -5,
            saturation: 15,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: 10, luminance: 0),
                orange: .init(hue: -3, saturation: 18, luminance: 5),
                yellow: .init(hue: 8, saturation: 20, luminance: 8),
                green: .init(hue: 15, saturation: 5, luminance: 5),
                aqua: .init(hue: 20, saturation: -10, luminance: 0),
                blue: .init(hue: -15, saturation: -5, luminance: -5),
                purple: .init(hue: 10, saturation: 5, luminance: 0),
                magenta: .init(hue: 5, saturation: 8, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 50,
                highlightSaturation: 15,
                shadowHue: 40,
                shadowSaturation: 12,
                balance: 5
            ),
            skinToneHue: -3,
            skinToneSaturation: 5,
            clarity: 15,
            grain: GrainData(amount: 18, size: 0.45, roughness: 0.55, monochromatic: false),
            vignette: VignetteData(amount: 18, midpoint: 0.5, roundness: 0, feather: 0.55),
            fade: 3,
            bloom: .none,
            halation: HalationData(intensity: 10, hue: 20, spread: 0.4),
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Gold 200",
            era: "1988-present",
            characteristics: ["saturated colors", "warm", "yellow-green cast", "consumer film", "nostalgic"],
            author: "FilmBox"
        )
    )

    /// Kodak Ektar 100 - High saturation, punchy, fine grain
    /// World's finest grain color negative film with vivid color reproduction
    static let kodakEktar100 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000005")!,
        name: "Ektar 100",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 20,
            highlights: -5,
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
                red: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 1)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.98)
                ]
            ),
            temperature: 5,
            tint: 0,
            saturation: 25,
            vibrance: 18,
            hsl: HSLAdjustments(
                red: .init(hue: 3, saturation: 20, luminance: 0),
                orange: .init(hue: 0, saturation: 15, luminance: 3),
                yellow: .init(hue: 0, saturation: 18, luminance: 5),
                green: .init(hue: -5, saturation: 22, luminance: 0),
                aqua: .init(hue: 0, saturation: 15, luminance: 0),
                blue: .init(hue: 5, saturation: 25, luminance: -5),
                purple: .init(hue: 0, saturation: 12, luminance: 0),
                magenta: .init(hue: 0, saturation: 15, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 5,
                shadowHue: 220,
                shadowSaturation: 5,
                balance: 0
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 20,
            grain: GrainData(amount: 5, size: 0.2, roughness: 0.3, monochromatic: false),
            vignette: VignetteData(amount: 8, midpoint: 0.65, roundness: 0, feather: 0.75),
            fade: 0,
            bloom: .none,
            halation: HalationData(intensity: 5, hue: 15, spread: 0.35),
            sharpness: 10,
            sharpenRadius: 0.8,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Ektar 100",
            era: "2008-present",
            characteristics: ["high saturation", "punchy colors", "ultra-fine grain", "vivid", "landscape film"],
            author: "FilmBox"
        )
    )

    /// Fuji Pro 400H - Pastel, slightly cyan shadows, soft
    /// Professional portrait film known for soft, flattering skin tones
    static let fujiPro400H = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000006")!,
        name: "Pro 400H",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: -12,
            highlights: -18,
            shadows: 22,
            whites: -10,
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
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.51),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.97)
                ],
                green: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ],
                blue: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.97)
                ]
            ),
            temperature: -5,
            tint: -3,
            saturation: -12,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: -5, saturation: -8, luminance: 3),
                orange: .init(hue: 0, saturation: 5, luminance: 8),
                yellow: .init(hue: -8, saturation: -15, luminance: 5),
                green: .init(hue: 25, saturation: -25, luminance: 0),
                aqua: .init(hue: 0, saturation: 5, luminance: 5),
                blue: .init(hue: 15, saturation: -5, luminance: 0),
                purple: .init(hue: 10, saturation: -12, luminance: 0),
                magenta: .init(hue: 15, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 55,
                highlightSaturation: 6,
                shadowHue: 190,
                shadowSaturation: 12,
                balance: -25
            ),
            skinToneHue: 3,
            skinToneSaturation: 5,
            clarity: 3,
            grain: GrainData(amount: 12, size: 0.35, roughness: 0.45, monochromatic: false),
            vignette: VignetteData(amount: 10, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 8,
            bloom: BloomData(intensity: 8, radius: 0.4, threshold: 0.82),
            halation: HalationData(intensity: 6, hue: 180, spread: 0.35),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm Pro 400H",
            era: "2004-2021",
            characteristics: ["pastel colors", "cyan shadows", "soft rendering", "flattering skin tones", "discontinued"],
            author: "FilmBox"
        )
    )

    /// Kodak ColorPlus 200 - Budget consumer film with warm, saturated colors
    /// Affordable film known for nostalgic, slightly warm tones
    static let kodakColorPlus200 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000007")!,
        name: "ColorPlus 200",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 15,
            highlights: -5,
            shadows: 12,
            whites: 5,
            blacks: -8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.98)
                ],
                red: [],
                green: [
                    .init(x: 0, y: 0.01),
                    .init(x: 0.25, y: 0.25),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.98)
                ],
                blue: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.48),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.96)
                ]
            ),
            temperature: 15,
            tint: -3,
            saturation: 18,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: 12, luminance: 0),
                orange: .init(hue: -3, saturation: 15, luminance: 5),
                yellow: .init(hue: 5, saturation: 18, luminance: 8),
                green: .init(hue: 10, saturation: 5, luminance: 3),
                aqua: .init(hue: 15, saturation: -5, luminance: 0),
                blue: .init(hue: -10, saturation: -8, luminance: -3),
                purple: .init(hue: 8, saturation: 5, luminance: 0),
                magenta: .init(hue: 5, saturation: 8, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 48,
                highlightSaturation: 12,
                shadowHue: 35,
                shadowSaturation: 10,
                balance: 0
            ),
            skinToneHue: -2,
            skinToneSaturation: 5,
            clarity: 12,
            grain: GrainData(amount: 20, size: 0.5, roughness: 0.55, monochromatic: false),
            vignette: VignetteData(amount: 15, midpoint: 0.5, roundness: 0, feather: 0.6),
            fade: 5,
            bloom: .none,
            halation: HalationData(intensity: 8, hue: 18, spread: 0.4),
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak ColorPlus 200",
            era: "1999-present",
            characteristics: ["budget film", "warm tones", "saturated", "nostalgic", "consumer"],
            author: "FilmBox"
        )
    )

    /// Fuji Superia 400 - Versatile consumer film with balanced colors
    /// Popular everyday film with good skin tones and natural colors
    static let fujiSuperia400 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000008")!,
        name: "Superia 400",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 10,
            highlights: -10,
            shadows: 15,
            whites: -3,
            blacks: 5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.97)
                ],
                red: [],
                green: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.27),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.98)
                ],
                blue: []
            ),
            temperature: 5,
            tint: -5,
            saturation: 8,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 5, luminance: 0),
                orange: .init(hue: 3, saturation: 10, luminance: 5),
                yellow: .init(hue: -5, saturation: 5, luminance: 5),
                green: .init(hue: 15, saturation: 8, luminance: 3),
                aqua: .init(hue: 5, saturation: 5, luminance: 0),
                blue: .init(hue: 0, saturation: -5, luminance: -3),
                purple: .init(hue: 5, saturation: 0, luminance: 0),
                magenta: .init(hue: 3, saturation: 5, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 52,
                highlightSaturation: 5,
                shadowHue: 200,
                shadowSaturation: 8,
                balance: -10
            ),
            skinToneHue: 3,
            skinToneSaturation: 5,
            clarity: 8,
            grain: GrainData(amount: 18, size: 0.45, roughness: 0.5, monochromatic: false),
            vignette: VignetteData(amount: 12, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 5,
            bloom: .none,
            halation: HalationData(intensity: 6, hue: 15, spread: 0.35),
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm Superia 400",
            era: "1998-present",
            characteristics: ["versatile", "balanced colors", "natural skin tones", "consumer film", "everyday"],
            author: "FilmBox"
        )
    )

    /// Fuji C200 - Budget consumer film with cooler tones
    /// Affordable film known for subtle colors and slight green cast
    static let fujiC200 = FilterPreset(
        id: UUID(uuidString: "10000000-0001-0000-0000-000000000009")!,
        name: "Fuji C200",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.03,
            contrast: 8,
            highlights: -8,
            shadows: 12,
            whites: 0,
            blacks: 3,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.97)
                ],
                red: [],
                green: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.27),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ],
                blue: []
            ),
            temperature: -5,
            tint: -8,
            saturation: 5,
            vibrance: 8,
            hsl: HSLAdjustments(
                red: .init(hue: -3, saturation: 0, luminance: 0),
                orange: .init(hue: 0, saturation: 5, luminance: 3),
                yellow: .init(hue: 5, saturation: 8, luminance: 5),
                green: .init(hue: 10, saturation: 12, luminance: 5),
                aqua: .init(hue: 5, saturation: 8, luminance: 3),
                blue: .init(hue: -5, saturation: 0, luminance: -3),
                purple: .init(hue: 3, saturation: 0, luminance: 0),
                magenta: .init(hue: 0, saturation: 3, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 55,
                highlightSaturation: 5,
                shadowHue: 180,
                shadowSaturation: 10,
                balance: -15
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 5,
            grain: GrainData(amount: 15, size: 0.4, roughness: 0.45, monochromatic: false),
            vignette: VignetteData(amount: 10, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 8,
            bloom: .none,
            halation: HalationData(intensity: 5, hue: 120, spread: 0.3),
            sharpness: 3,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm C200",
            era: "2007-present",
            characteristics: ["budget film", "cool tones", "green cast", "subtle colors", "consumer"],
            author: "FilmBox"
        )
    )

    // MARK: - Black & White Film Stocks

    /// Kodak Tri-X 400 - High contrast, visible grain, deep blacks
    /// Legendary photojournalism film with distinctive punchy look
    static let kodakTriX400 = FilterPreset(
        id: UUID(uuidString: "10000000-0002-0000-0000-000000000001")!,
        name: "Tri-X 400",
        category: .bw,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: 25,
            highlights: -10,
            shadows: -15,
            whites: 10,
            blacks: -20,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0),
                    .init(x: 0.15, y: 0.08),
                    .init(x: 0.25, y: 0.20),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.82),
                    .init(x: 0.9, y: 0.94),
                    .init(x: 1, y: 1)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 0,
            tint: 0,
            saturation: -100,
            vibrance: 0,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 0, luminance: -10),
                orange: .init(hue: 0, saturation: 0, luminance: 15),
                yellow: .init(hue: 0, saturation: 0, luminance: 20),
                green: .init(hue: 0, saturation: 0, luminance: -5),
                aqua: .init(hue: 0, saturation: 0, luminance: -15),
                blue: .init(hue: 0, saturation: 0, luminance: -25),
                purple: .init(hue: 0, saturation: 0, luminance: -15),
                magenta: .init(hue: 0, saturation: 0, luminance: -10)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 25,
            grain: GrainData(amount: 35, size: 0.6, roughness: 0.7, monochromatic: true),
            vignette: VignetteData(amount: 20, midpoint: 0.45, roundness: 0, feather: 0.5),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 15,
            sharpenRadius: 1.2,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Tri-X 400",
            era: "1954-present",
            characteristics: ["high contrast", "visible grain", "deep blacks", "photojournalism classic", "punchy"],
            author: "FilmBox"
        )
    )

    /// Ilford HP5 Plus - Medium contrast, classic grain
    /// Versatile B&W film with smooth tonal range and classic grain structure
    static let ilfordHP5Plus = FilterPreset(
        id: UUID(uuidString: "10000000-0002-0000-0000-000000000002")!,
        name: "HP5 Plus",
        category: .bw,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.03,
            contrast: 15,
            highlights: -5,
            shadows: 5,
            whites: 5,
            blacks: -10,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.99)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 0,
            tint: 0,
            saturation: -100,
            vibrance: 0,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 0, luminance: -5),
                orange: .init(hue: 0, saturation: 0, luminance: 10),
                yellow: .init(hue: 0, saturation: 0, luminance: 15),
                green: .init(hue: 0, saturation: 0, luminance: 5),
                aqua: .init(hue: 0, saturation: 0, luminance: -5),
                blue: .init(hue: 0, saturation: 0, luminance: -15),
                purple: .init(hue: 0, saturation: 0, luminance: -10),
                magenta: .init(hue: 0, saturation: 0, luminance: -5)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 18,
            grain: GrainData(amount: 25, size: 0.5, roughness: 0.55, monochromatic: true),
            vignette: VignetteData(amount: 15, midpoint: 0.5, roundness: 0, feather: 0.6),
            fade: 3,
            bloom: .none,
            halation: .none,
            sharpness: 10,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Ilford HP5 Plus",
            era: "1976-present",
            characteristics: ["medium contrast", "classic grain", "smooth tones", "versatile", "wide latitude"],
            author: "FilmBox"
        )
    )

    /// Kodak T-Max 400 - Modern tabular grain, smooth tones, fine detail
    /// Technical B&W film with ultra-fine grain for its speed
    static let kodakTMax400 = FilterPreset(
        id: UUID(uuidString: "10000000-0002-0000-0000-000000000003")!,
        name: "T-Max 400",
        category: .bw,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.03,
            contrast: 18,
            highlights: -8,
            shadows: 0,
            whites: 5,
            blacks: -12,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.01),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.51),
                    .init(x: 0.75, y: 0.79),
                    .init(x: 1, y: 0.99)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 0,
            tint: 0,
            saturation: -100,
            vibrance: 0,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 0, luminance: -8),
                orange: .init(hue: 0, saturation: 0, luminance: 12),
                yellow: .init(hue: 0, saturation: 0, luminance: 18),
                green: .init(hue: 0, saturation: 0, luminance: 0),
                aqua: .init(hue: 0, saturation: 0, luminance: -10),
                blue: .init(hue: 0, saturation: 0, luminance: -20),
                purple: .init(hue: 0, saturation: 0, luminance: -12),
                magenta: .init(hue: 0, saturation: 0, luminance: -8)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 20,
            grain: GrainData(amount: 18, size: 0.35, roughness: 0.45, monochromatic: true),
            vignette: VignetteData(amount: 12, midpoint: 0.55, roundness: 0, feather: 0.6),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 12,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak T-Max 400",
            era: "1986-present",
            characteristics: ["tabular grain", "smooth tones", "fine detail", "technical film", "modern B&W"],
            author: "FilmBox"
        )
    )

    /// Ilford Delta 3200 - High-speed, dramatic grain, low-light specialist
    /// Ultra-fast B&W film for extreme low-light conditions
    static let ilfordDelta3200 = FilterPreset(
        id: UUID(uuidString: "10000000-0002-0000-0000-000000000004")!,
        name: "Delta 3200",
        category: .bw,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: 30,
            highlights: -15,
            shadows: -20,
            whites: 12,
            blacks: -25,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0),
                    .init(x: 0.15, y: 0.05),
                    .init(x: 0.25, y: 0.18),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.85),
                    .init(x: 0.9, y: 0.96),
                    .init(x: 1, y: 1)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 0,
            tint: 0,
            saturation: -100,
            vibrance: 0,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 0, luminance: -12),
                orange: .init(hue: 0, saturation: 0, luminance: 18),
                yellow: .init(hue: 0, saturation: 0, luminance: 22),
                green: .init(hue: 0, saturation: 0, luminance: -8),
                aqua: .init(hue: 0, saturation: 0, luminance: -18),
                blue: .init(hue: 0, saturation: 0, luminance: -28),
                purple: .init(hue: 0, saturation: 0, luminance: -18),
                magenta: .init(hue: 0, saturation: 0, luminance: -12)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 28,
            grain: GrainData(amount: 45, size: 0.7, roughness: 0.75, monochromatic: true),
            vignette: VignetteData(amount: 22, midpoint: 0.42, roundness: 0, feather: 0.48),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 18,
            sharpenRadius: 1.3,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Ilford Delta 3200",
            era: "1998-present",
            characteristics: ["ultra-fast", "dramatic grain", "low-light", "high contrast", "available darkness"],
            author: "FilmBox"
        )
    )

    /// Fuji Neopan Acros 100 - Ultra-fine grain, smooth tones, excellent detail
    /// Legendary Japanese B&W film known for exceptional sharpness
    static let fujiAcros100 = FilterPreset(
        id: UUID(uuidString: "10000000-0002-0000-0000-000000000005")!,
        name: "Acros 100",
        category: .bw,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 12,
            highlights: -5,
            shadows: 5,
            whites: 3,
            blacks: -8,
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
            saturation: -100,
            vibrance: 0,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 0, luminance: -5),
                orange: .init(hue: 0, saturation: 0, luminance: 8),
                yellow: .init(hue: 0, saturation: 0, luminance: 12),
                green: .init(hue: 0, saturation: 0, luminance: 5),
                aqua: .init(hue: 0, saturation: 0, luminance: -3),
                blue: .init(hue: 0, saturation: 0, luminance: -12),
                purple: .init(hue: 0, saturation: 0, luminance: -8),
                magenta: .init(hue: 0, saturation: 0, luminance: -5)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 15,
            grain: GrainData(amount: 8, size: 0.2, roughness: 0.3, monochromatic: true),
            vignette: VignetteData(amount: 8, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 2,
            bloom: .none,
            halation: .none,
            sharpness: 15,
            sharpenRadius: 0.8,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm Neopan Acros 100",
            era: "1997-2018, 2019-present (II)",
            characteristics: ["ultra-fine grain", "smooth tones", "exceptional sharpness", "legendary", "studio quality"],
            author: "FilmBox"
        )
    )

    // MARK: - Cinema Film Stocks

    /// CineStill 800T - Tungsten-balanced, cyan shadows, red halation
    /// Motion picture film (Kodak Vision3 500T) with remjet removed
    static let cineStill800T = FilterPreset(
        id: UUID(uuidString: "10000000-0003-0000-0000-000000000001")!,
        name: "CineStill 800T",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: 10,
            highlights: -15,
            shadows: 18,
            whites: -5,
            blacks: 5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.03),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ],
                red: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.96)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0.06),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.97)
                ]
            ),
            temperature: -25,
            tint: 8,
            saturation: 5,
            vibrance: 15,
            hsl: HSLAdjustments(
                red: .init(hue: 10, saturation: 15, luminance: 5),
                orange: .init(hue: 0, saturation: 5, luminance: 5),
                yellow: .init(hue: -10, saturation: -8, luminance: 3),
                green: .init(hue: 25, saturation: -15, luminance: 0),
                aqua: .init(hue: 0, saturation: 20, luminance: 8),
                blue: .init(hue: 10, saturation: 15, luminance: 0),
                purple: .init(hue: -5, saturation: 10, luminance: 0),
                magenta: .init(hue: 10, saturation: 12, luminance: 5)
            ),
            splitTone: SplitToneData(
                highlightHue: 40,
                highlightSaturation: 8,
                shadowHue: 190,
                shadowSaturation: 20,
                balance: -20
            ),
            skinToneHue: 5,
            skinToneSaturation: 5,
            clarity: 12,
            grain: GrainData(amount: 25, size: 0.55, roughness: 0.6, monochromatic: false),
            vignette: VignetteData(amount: 18, midpoint: 0.5, roundness: 0, feather: 0.55),
            fade: 5,
            bloom: BloomData(intensity: 12, radius: 0.45, threshold: 0.78),
            halation: HalationData(intensity: 35, hue: 5, spread: 0.6),
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "CineStill 800T",
            era: "2015-present",
            characteristics: ["tungsten balanced", "cyan shadows", "red halation", "cinematic", "night photography"],
            author: "FilmBox"
        )
    )

    /// CineStill 50D - Daylight-balanced, fine grain, rich colors
    /// Motion picture film (Kodak Vision3 50D) with remjet removed
    static let cineStill50D = FilterPreset(
        id: UUID(uuidString: "10000000-0003-0000-0000-000000000002")!,
        name: "CineStill 50D",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 15,
            highlights: -8,
            shadows: 10,
            whites: 5,
            blacks: -8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.01),
                    .init(x: 0.25, y: 0.24),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.99)
                ],
                red: [],
                green: [],
                blue: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.53),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.98)
                ]
            ),
            temperature: 5,
            tint: 0,
            saturation: 12,
            vibrance: 15,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: 10, luminance: 0),
                orange: .init(hue: 0, saturation: 15, luminance: 5),
                yellow: .init(hue: -5, saturation: 10, luminance: 5),
                green: .init(hue: -10, saturation: 12, luminance: 3),
                aqua: .init(hue: 5, saturation: 18, luminance: 5),
                blue: .init(hue: 0, saturation: 20, luminance: 0),
                purple: .init(hue: -5, saturation: 8, luminance: 0),
                magenta: .init(hue: 5, saturation: 10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 5,
                shadowHue: 210,
                shadowSaturation: 8,
                balance: 0
            ),
            skinToneHue: 3,
            skinToneSaturation: 8,
            clarity: 18,
            grain: GrainData(amount: 8, size: 0.25, roughness: 0.35, monochromatic: false),
            vignette: VignetteData(amount: 10, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 0,
            bloom: .none,
            halation: HalationData(intensity: 15, hue: 8, spread: 0.4),
            sharpness: 8,
            sharpenRadius: 0.9,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "CineStill 50D",
            era: "2015-present",
            characteristics: ["daylight balanced", "fine grain", "rich colors", "cinematic", "high detail"],
            author: "FilmBox"
        )
    )

    /// Kodak Vision3 500T - Professional cinema film, tungsten
    /// Hollywood's most used motion picture film stock
    static let kodakVision3500T = FilterPreset(
        id: UUID(uuidString: "10000000-0003-0000-0000-000000000003")!,
        name: "Vision3 500T",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: 8,
            highlights: -12,
            shadows: 15,
            whites: -3,
            blacks: 5,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.26),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.97)
                ],
                red: [],
                green: [],
                blue: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.77),
                    .init(x: 1, y: 0.97)
                ]
            ),
            temperature: -18,
            tint: 5,
            saturation: 0,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 8, saturation: 8, luminance: 3),
                orange: .init(hue: 3, saturation: 10, luminance: 5),
                yellow: .init(hue: -5, saturation: -5, luminance: 3),
                green: .init(hue: 15, saturation: -10, luminance: 0),
                aqua: .init(hue: -5, saturation: 12, luminance: 5),
                blue: .init(hue: 5, saturation: 10, luminance: 0),
                purple: .init(hue: 0, saturation: 5, luminance: 0),
                magenta: .init(hue: 8, saturation: 8, luminance: 3)
            ),
            splitTone: SplitToneData(
                highlightHue: 42,
                highlightSaturation: 6,
                shadowHue: 200,
                shadowSaturation: 12,
                balance: -15
            ),
            skinToneHue: 5,
            skinToneSaturation: 8,
            clarity: 8,
            grain: GrainData(amount: 18, size: 0.45, roughness: 0.5, monochromatic: false),
            vignette: VignetteData(amount: 12, midpoint: 0.55, roundness: 0, feather: 0.65),
            fade: 5,
            bloom: BloomData(intensity: 8, radius: 0.4, threshold: 0.8),
            halation: .none,
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Vision3 500T",
            era: "2007-present",
            characteristics: ["tungsten balanced", "cinema standard", "excellent latitude", "natural skin tones", "Hollywood look"],
            author: "FilmBox"
        )
    )

    /// Kodak Vision3 250D - Daylight cinema film
    /// Professional motion picture film for outdoor/daylight scenes
    static let kodakVision3250D = FilterPreset(
        id: UUID(uuidString: "10000000-0003-0000-0000-000000000004")!,
        name: "Vision3 250D",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.03,
            contrast: 12,
            highlights: -10,
            shadows: 12,
            whites: 3,
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
            temperature: 3,
            tint: 0,
            saturation: 8,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 3, saturation: 8, luminance: 0),
                orange: .init(hue: 0, saturation: 12, luminance: 5),
                yellow: .init(hue: -3, saturation: 8, luminance: 5),
                green: .init(hue: -8, saturation: 10, luminance: 3),
                aqua: .init(hue: 0, saturation: 12, luminance: 3),
                blue: .init(hue: 3, saturation: 15, luminance: 0),
                purple: .init(hue: -3, saturation: 5, luminance: 0),
                magenta: .init(hue: 3, saturation: 8, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 48,
                highlightSaturation: 5,
                shadowHue: 215,
                shadowSaturation: 6,
                balance: 0
            ),
            skinToneHue: 3,
            skinToneSaturation: 8,
            clarity: 12,
            grain: GrainData(amount: 12, size: 0.35, roughness: 0.45, monochromatic: false),
            vignette: VignetteData(amount: 10, midpoint: 0.58, roundness: 0, feather: 0.68),
            fade: 3,
            bloom: .none,
            halation: .none,
            sharpness: 5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Vision3 250D",
            era: "2007-present",
            characteristics: ["daylight balanced", "cinema film", "natural colors", "fine grain", "outdoor scenes"],
            author: "FilmBox"
        )
    )

    // MARK: - Slide Film Stocks

    /// Kodak Ektachrome E100 - Neutral, fine grain, accurate colors
    /// Modern slide film with accurate color reproduction
    static let kodakEktachromeE100 = FilterPreset(
        id: UUID(uuidString: "10000000-0004-0000-0000-000000000001")!,
        name: "Ektachrome E100",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 18,
            highlights: -5,
            shadows: -5,
            whites: 8,
            blacks: -12,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.79),
                    .init(x: 1, y: 1)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: 0,
            tint: 0,
            saturation: 15,
            vibrance: 12,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 12, luminance: 0),
                orange: .init(hue: 0, saturation: 10, luminance: 3),
                yellow: .init(hue: 0, saturation: 12, luminance: 5),
                green: .init(hue: 0, saturation: 15, luminance: 0),
                aqua: .init(hue: 0, saturation: 12, luminance: 0),
                blue: .init(hue: 0, saturation: 18, luminance: -5),
                purple: .init(hue: 0, saturation: 10, luminance: 0),
                magenta: .init(hue: 0, saturation: 12, luminance: 0)
            ),
            splitTone: .identity,
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 15,
            grain: GrainData(amount: 6, size: 0.25, roughness: 0.3, monochromatic: false),
            vignette: VignetteData(amount: 8, midpoint: 0.65, roundness: 0, feather: 0.75),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 12,
            sharpenRadius: 0.9,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodak Ektachrome E100",
            era: "2018-present",
            characteristics: ["accurate colors", "fine grain", "slide film", "high contrast", "neutral"],
            author: "FilmBox"
        )
    )

    /// Fuji Velvia 50 - Ultra-saturated, vivid colors, high contrast
    /// Legendary landscape slide film known for punchy colors
    static let fujiVelvia50 = FilterPreset(
        id: UUID(uuidString: "10000000-0004-0000-0000-000000000002")!,
        name: "Velvia 50",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: -0.05,
            contrast: 25,
            highlights: -10,
            shadows: -10,
            whites: 10,
            blacks: -15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.20),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.82),
                    .init(x: 1, y: 1)
                ],
                red: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.80),
                    .init(x: 1, y: 1)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.98)
                ]
            ),
            temperature: 3,
            tint: 5,
            saturation: 35,
            vibrance: 20,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: 25, luminance: 0),
                orange: .init(hue: 0, saturation: 20, luminance: 5),
                yellow: .init(hue: -5, saturation: 25, luminance: 8),
                green: .init(hue: -10, saturation: 30, luminance: -5),
                aqua: .init(hue: 5, saturation: 20, luminance: 0),
                blue: .init(hue: 0, saturation: 30, luminance: -8),
                purple: .init(hue: -5, saturation: 20, luminance: -5),
                magenta: .init(hue: 5, saturation: 22, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 50,
                highlightSaturation: 8,
                shadowHue: 230,
                shadowSaturation: 10,
                balance: 5
            ),
            skinToneHue: -5,
            skinToneSaturation: -5,
            clarity: 22,
            grain: GrainData(amount: 5, size: 0.2, roughness: 0.3, monochromatic: false),
            vignette: VignetteData(amount: 12, midpoint: 0.6, roundness: 0, feather: 0.7),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 15,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm Velvia 50",
            era: "1991-present",
            characteristics: ["ultra-saturated", "vivid colors", "high contrast", "landscape film", "punchy"],
            author: "FilmBox"
        )
    )

    /// Fuji Provia 100F - Balanced colors, neutral, professional
    /// Professional slide film with accurate, neutral rendering
    static let fujiProvia100F = FilterPreset(
        id: UUID(uuidString: "10000000-0004-0000-0000-000000000003")!,
        name: "Provia 100F",
        category: .film,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0,
            contrast: 15,
            highlights: -8,
            shadows: -3,
            whites: 5,
            blacks: -8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.23),
                    .init(x: 0.5, y: 0.50),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 1)
                ],
                red: [],
                green: [],
                blue: []
            ),
            temperature: -3,
            tint: 0,
            saturation: 12,
            vibrance: 10,
            hsl: HSLAdjustments(
                red: .init(hue: 0, saturation: 10, luminance: 0),
                orange: .init(hue: 0, saturation: 8, luminance: 3),
                yellow: .init(hue: 0, saturation: 10, luminance: 3),
                green: .init(hue: -5, saturation: 15, luminance: 0),
                aqua: .init(hue: 0, saturation: 12, luminance: 3),
                blue: .init(hue: 3, saturation: 15, luminance: -3),
                purple: .init(hue: 0, saturation: 8, luminance: 0),
                magenta: .init(hue: 0, saturation: 10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 3,
                shadowHue: 220,
                shadowSaturation: 5,
                balance: 0
            ),
            skinToneHue: 0,
            skinToneSaturation: 0,
            clarity: 12,
            grain: GrainData(amount: 6, size: 0.25, roughness: 0.35, monochromatic: false),
            vignette: VignetteData(amount: 8, midpoint: 0.62, roundness: 0, feather: 0.72),
            fade: 0,
            bloom: .none,
            halation: .none,
            sharpness: 10,
            sharpenRadius: 0.9,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm Provia 100F",
            era: "2002-present",
            characteristics: ["balanced colors", "neutral", "professional", "fine grain", "accurate"],
            author: "FilmBox"
        )
    )

    // MARK: - Vintage & Instant Film Stocks

    /// Kodachrome 64 - Legendary slide film, warm reds, rich colors
    /// The most iconic film ever made, discontinued in 2009
    static let kodachrome64 = FilterPreset(
        id: UUID(uuidString: "10000000-0005-0000-0000-000000000001")!,
        name: "Kodachrome 64",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.03,
            contrast: 22,
            highlights: -8,
            shadows: -12,
            whites: 8,
            blacks: -15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.01),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.80),
                    .init(x: 1, y: 0.99)
                ],
                red: [
                    .init(x: 0, y: 0.02),
                    .init(x: 0.25, y: 0.25),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.82),
                    .init(x: 1, y: 0.99)
                ],
                green: [],
                blue: [
                    .init(x: 0, y: 0),
                    .init(x: 0.25, y: 0.22),
                    .init(x: 0.5, y: 0.48),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.96)
                ]
            ),
            temperature: 12,
            tint: 5,
            saturation: 20,
            vibrance: 15,
            hsl: HSLAdjustments(
                red: .init(hue: 8, saturation: 25, luminance: 3),
                orange: .init(hue: 5, saturation: 20, luminance: 5),
                yellow: .init(hue: -8, saturation: 15, luminance: 8),
                green: .init(hue: 10, saturation: 18, luminance: 0),
                aqua: .init(hue: 5, saturation: 12, luminance: 0),
                blue: .init(hue: -5, saturation: 22, luminance: -8),
                purple: .init(hue: 10, saturation: 15, luminance: -5),
                magenta: .init(hue: 8, saturation: 18, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 42,
                highlightSaturation: 10,
                shadowHue: 25,
                shadowSaturation: 15,
                balance: -5
            ),
            skinToneHue: 5,
            skinToneSaturation: 8,
            clarity: 18,
            grain: GrainData(amount: 12, size: 0.35, roughness: 0.4, monochromatic: false),
            vignette: VignetteData(amount: 15, midpoint: 0.55, roundness: 0, feather: 0.6),
            fade: 3,
            bloom: .none,
            halation: HalationData(intensity: 8, hue: 10, spread: 0.35),
            sharpness: 10,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Kodachrome 64",
            era: "1974-2009",
            characteristics: ["legendary", "warm reds", "rich colors", "iconic", "discontinued"],
            author: "FilmBox"
        )
    )

    /// Polaroid 600 - Classic instant film look, faded colors
    /// The iconic instant film of the 80s and 90s
    static let polaroid600 = FilterPreset(
        id: UUID(uuidString: "10000000-0005-0000-0000-000000000002")!,
        name: "Polaroid 600",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.1,
            contrast: -10,
            highlights: -20,
            shadows: 25,
            whites: -15,
            blacks: 15,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.08),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.92)
                ],
                red: [
                    .init(x: 0, y: 0.06),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.76),
                    .init(x: 1, y: 0.93)
                ],
                green: [
                    .init(x: 0, y: 0.07),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.94)
                ],
                blue: [
                    .init(x: 0, y: 0.10),
                    .init(x: 0.25, y: 0.32),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.75),
                    .init(x: 1, y: 0.90)
                ]
            ),
            temperature: 10,
            tint: -5,
            saturation: -15,
            vibrance: -5,
            hsl: HSLAdjustments(
                red: .init(hue: 10, saturation: -10, luminance: 5),
                orange: .init(hue: 5, saturation: -5, luminance: 8),
                yellow: .init(hue: -10, saturation: -15, luminance: 10),
                green: .init(hue: 20, saturation: -25, luminance: 5),
                aqua: .init(hue: 10, saturation: -15, luminance: 3),
                blue: .init(hue: -10, saturation: -20, luminance: -5),
                purple: .init(hue: 15, saturation: -15, luminance: 0),
                magenta: .init(hue: 10, saturation: -10, luminance: 0)
            ),
            splitTone: SplitToneData(
                highlightHue: 55,
                highlightSaturation: 12,
                shadowHue: 35,
                shadowSaturation: 18,
                balance: -20
            ),
            skinToneHue: 5,
            skinToneSaturation: -5,
            clarity: -5,
            grain: GrainData(amount: 25, size: 0.55, roughness: 0.6, monochromatic: false),
            vignette: VignetteData(amount: 25, midpoint: 0.45, roundness: -30, feather: 0.5),
            fade: 20,
            bloom: BloomData(intensity: 15, radius: 0.5, threshold: 0.75),
            halation: .none,
            sharpness: -5,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Polaroid 600",
            era: "1981-2008, 2017-present",
            characteristics: ["instant", "faded colors", "nostalgic", "soft", "iconic"],
            author: "FilmBox"
        )
    )

    /// Fujifilm Instax - Modern instant film with vivid colors
    /// Contemporary instant film with punchy, cheerful colors
    static let fujiInstax = FilterPreset(
        id: UUID(uuidString: "10000000-0005-0000-0000-000000000003")!,
        name: "Instax",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.08,
            contrast: 5,
            highlights: -12,
            shadows: 18,
            whites: -5,
            blacks: 8,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.05),
                    .init(x: 0.25, y: 0.28),
                    .init(x: 0.5, y: 0.54),
                    .init(x: 0.75, y: 0.78),
                    .init(x: 1, y: 0.95)
                ],
                red: [],
                green: [
                    .init(x: 0, y: 0.04),
                    .init(x: 0.25, y: 0.29),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.79),
                    .init(x: 1, y: 0.96)
                ],
                blue: []
            ),
            temperature: -3,
            tint: -8,
            saturation: 12,
            vibrance: 18,
            hsl: HSLAdjustments(
                red: .init(hue: 5, saturation: 15, luminance: 3),
                orange: .init(hue: 0, saturation: 12, luminance: 5),
                yellow: .init(hue: 5, saturation: 15, luminance: 8),
                green: .init(hue: 15, saturation: 18, luminance: 5),
                aqua: .init(hue: 5, saturation: 15, luminance: 5),
                blue: .init(hue: -5, saturation: 10, luminance: 0),
                purple: .init(hue: 8, saturation: 12, luminance: 0),
                magenta: .init(hue: 5, saturation: 15, luminance: 3)
            ),
            splitTone: SplitToneData(
                highlightHue: 50,
                highlightSaturation: 8,
                shadowHue: 180,
                shadowSaturation: 10,
                balance: -10
            ),
            skinToneHue: 3,
            skinToneSaturation: 8,
            clarity: 0,
            grain: GrainData(amount: 15, size: 0.4, roughness: 0.45, monochromatic: false),
            vignette: VignetteData(amount: 18, midpoint: 0.5, roundness: -20, feather: 0.55),
            fade: 12,
            bloom: BloomData(intensity: 10, radius: 0.4, threshold: 0.8),
            halation: .none,
            sharpness: 0,
            sharpenRadius: 1.0,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Fujifilm Instax",
            era: "1998-present",
            characteristics: ["instant", "vivid colors", "cheerful", "modern instant", "popular"],
            author: "FilmBox"
        )
    )

    /// Autochrome - Early color photography look from 1907
    /// Recreates the dreamy, soft look of the first practical color process
    static let autochrome = FilterPreset(
        id: UUID(uuidString: "10000000-0005-0000-0000-000000000004")!,
        name: "Autochrome",
        category: .vintage,
        source: .builtIn,
        parameters: FilterParameters(
            exposure: 0.05,
            contrast: -8,
            highlights: -25,
            shadows: 20,
            whites: -20,
            blacks: 10,
            toneCurve: ToneCurveData(
                composite: [
                    .init(x: 0, y: 0.10),
                    .init(x: 0.25, y: 0.32),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.88)
                ],
                red: [
                    .init(x: 0, y: 0.08),
                    .init(x: 0.25, y: 0.30),
                    .init(x: 0.5, y: 0.52),
                    .init(x: 0.75, y: 0.72),
                    .init(x: 1, y: 0.86)
                ],
                green: [
                    .init(x: 0, y: 0.09),
                    .init(x: 0.25, y: 0.32),
                    .init(x: 0.5, y: 0.55),
                    .init(x: 0.75, y: 0.75),
                    .init(x: 1, y: 0.90)
                ],
                blue: [
                    .init(x: 0, y: 0.12),
                    .init(x: 0.25, y: 0.34),
                    .init(x: 0.5, y: 0.56),
                    .init(x: 0.75, y: 0.74),
                    .init(x: 1, y: 0.86)
                ]
            ),
            temperature: 5,
            tint: 10,
            saturation: -25,
            vibrance: -15,
            hsl: HSLAdjustments(
                red: .init(hue: 15, saturation: -20, luminance: -5),
                orange: .init(hue: 10, saturation: -15, luminance: 0),
                yellow: .init(hue: -10, saturation: -20, luminance: 5),
                green: .init(hue: 25, saturation: -25, luminance: -8),
                aqua: .init(hue: 15, saturation: -20, luminance: -5),
                blue: .init(hue: -15, saturation: -25, luminance: -10),
                purple: .init(hue: 20, saturation: -20, luminance: -5),
                magenta: .init(hue: 15, saturation: -18, luminance: -3)
            ),
            splitTone: SplitToneData(
                highlightHue: 45,
                highlightSaturation: 18,
                shadowHue: 280,
                shadowSaturation: 15,
                balance: -10
            ),
            skinToneHue: 10,
            skinToneSaturation: -10,
            clarity: -10,
            grain: GrainData(amount: 40, size: 0.65, roughness: 0.7, monochromatic: false),
            vignette: VignetteData(amount: 35, midpoint: 0.4, roundness: 0, feather: 0.5),
            fade: 30,
            bloom: BloomData(intensity: 20, radius: 0.6, threshold: 0.7),
            halation: .none,
            sharpness: -15,
            sharpenRadius: 1.5,
            rotation: 0,
            cropRect: nil
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Autochrome Lumière",
            era: "1907-1930s",
            characteristics: ["first color process", "dreamy", "soft", "historical", "painterly"],
            author: "FilmBox"
        )
    )

    // MARK: - All Film Presets

    /// All color negative film presets
    static let colorNegative: [FilterPreset] = [
        kodakPortra160,
        kodakPortra400,
        kodakPortra800,
        kodakGold200,
        kodakEktar100,
        kodakColorPlus200,
        fujiPro400H,
        fujiSuperia400,
        fujiC200
    ]

    /// All black & white film presets
    static let blackAndWhite: [FilterPreset] = [
        kodakTriX400,
        kodakTMax400,
        ilfordHP5Plus,
        ilfordDelta3200,
        fujiAcros100
    ]

    /// All cinema film presets
    static let cinema: [FilterPreset] = [
        cineStill800T,
        cineStill50D,
        kodakVision3500T,
        kodakVision3250D
    ]

    /// All slide film presets
    static let slide: [FilterPreset] = [
        kodakEktachromeE100,
        fujiVelvia50,
        fujiProvia100F
    ]

    /// All vintage & instant film presets
    static let vintage: [FilterPreset] = [
        kodachrome64,
        polaroid600,
        fujiInstax,
        autochrome
    ]

    /// All film emulation presets
    static let all: [FilterPreset] = colorNegative + blackAndWhite + cinema + slide + vintage
}
