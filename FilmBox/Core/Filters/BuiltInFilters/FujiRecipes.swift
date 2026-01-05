import Foundation

/// Built-in Fuji X camera recipe presets
/// Loaded from bundled JSON and converted using FujiRecipeImporter
enum FujiRecipes {

    // MARK: - Static UUIDs for consistency

    /// Generate consistent UUID for a recipe based on its index
    /// Using fixed UUIDs for stability across app launches
    private static let recipeUUIDs: [String: UUID] = [
        "Classic Cuban Neg": UUID(uuidString: "20000000-F001-0000-0000-000000000001")!,
        "Cinematic Gold": UUID(uuidString: "20000000-F001-0000-0000-000000000002")!,
        "Summer Chrome": UUID(uuidString: "20000000-F001-0000-0000-000000000003")!,
        "Last Summer Roll": UUID(uuidString: "20000000-F001-0000-0000-000000000004")!,
        "Classic Continental": UUID(uuidString: "20000000-F001-0000-0000-000000000005")!,
        "Savanna Chrome": UUID(uuidString: "20000000-F001-0000-0000-000000000006")!,
        "7 Iron": UUID(uuidString: "20000000-F001-0000-0000-000000000007")!,
        "Kodak Gold 200": UUID(uuidString: "20000000-F001-0000-0000-000000000008")!,
        "Portra 400": UUID(uuidString: "20000000-F001-0000-0000-000000000009")!,
        "Tokyo Streets": UUID(uuidString: "20000000-F001-0000-0000-000000000010")!,
        "Nordic Light": UUID(uuidString: "20000000-F001-0000-0000-000000000011")!,
        "Warm Nostalgia": UUID(uuidString: "20000000-F001-0000-0000-000000000012")!,
        "Eterna Cinema": UUID(uuidString: "20000000-F001-0000-0000-000000000013")!,
        "Acros Street": UUID(uuidString: "20000000-F001-0000-0000-000000000014")!,
        "Velvia Landscape": UUID(uuidString: "20000000-F001-0000-0000-000000000015")!
    ]

    private static func uuid(for name: String) -> UUID {
        recipeUUIDs[name] ?? UUID()
    }

    // MARK: - Recipe Definitions

    /// Classic Cuban Neg - High contrast Classic Negative with strong grain
    static let classicCubanNeg = FilterPreset(
        id: uuid(for: "Classic Cuban Neg"),
        name: "Classic Cuban Neg",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Strong / Large",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Strong",
            whiteBalanceRShift: 4,
            whiteBalanceBShift: -5,
            dynamicRange: "DR400",
            highlight: -2,
            shadow: 1,
            color: 4,
            noiseReduction: -4,
            sharpness: 0,
            clarity: -4
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: nil,
            characteristics: ["high contrast", "strong grain", "blue shadows", "warm tones", "street photography"],
            author: "Fuji Recipe"
        )
    )

    /// Cinematic Gold - Warm cinematic look with subtle grain
    static let cinematicGold = FilterPreset(
        id: uuid(for: "Cinematic Gold"),
        name: "Cinematic Gold",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Strong / Small",
            colorChromeEffect: "Off",
            colorChromeFxBlue: "Off",
            whiteBalanceRShift: 4,
            whiteBalanceBShift: -5,
            dynamicRange: "DR400",
            highlight: 0,
            shadow: 0,
            color: 3,
            noiseReduction: -4,
            sharpness: -2,
            clarity: -2
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: nil,
            characteristics: ["cinematic", "golden tones", "soft", "warm", "movie look"],
            author: "Fuji Recipe"
        )
    )

    /// Summer Chrome - Vibrant summer look with Classic Chrome base
    static let summerChrome = FilterPreset(
        id: uuid(for: "Summer Chrome"),
        name: "Summer Chrome",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Chrome",
            grainEffect: "Strong / Large",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Strong",
            whiteBalanceRShift: 5,
            whiteBalanceBShift: -6,
            dynamicRange: "DR400",
            highlight: -2,
            shadow: -2,
            color: 4,
            noiseReduction: -4,
            sharpness: 0,
            clarity: -4
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Chrome",
            era: nil,
            characteristics: ["summer vibes", "documentary", "vibrant", "warm", "travel"],
            author: "Fuji Recipe"
        )
    )

    /// Last Summer Roll - Nostalgic summer film look
    static let lastSummerRoll = FilterPreset(
        id: uuid(for: "Last Summer Roll"),
        name: "Last Summer Roll",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Strong / Small",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Weak",
            whiteBalanceRShift: 3,
            whiteBalanceBShift: -5,
            dynamicRange: "DR400",
            highlight: -2,
            shadow: 0,
            color: 4,
            noiseReduction: -4,
            sharpness: 0,
            clarity: -2
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: nil,
            characteristics: ["nostalgic", "summer memories", "film look", "warm", "lifestyle"],
            author: "Fuji Recipe"
        )
    )

    /// Classic Continental - Subtle, elegant European look
    static let classicContinental = FilterPreset(
        id: uuid(for: "Classic Continental"),
        name: "Classic Continental",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Weak / Small",
            colorChromeEffect: "Weak",
            colorChromeFxBlue: "Weak",
            whiteBalanceRShift: 3,
            whiteBalanceBShift: -2,
            dynamicRange: "DR Auto",
            highlight: -1,
            shadow: 0,
            color: 1,
            noiseReduction: -4,
            sharpness: -1,
            clarity: 0
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: nil,
            characteristics: ["subtle", "elegant", "European", "natural", "versatile"],
            author: "Fuji Recipe"
        )
    )

    /// Savanna Chrome - Warm documentary look
    static let savannaChrome = FilterPreset(
        id: uuid(for: "Savanna Chrome"),
        name: "Savanna Chrome",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Chrome",
            grainEffect: "Strong / Small",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Weak",
            whiteBalanceRShift: 2,
            whiteBalanceBShift: -3,
            dynamicRange: "DR400",
            highlight: -2,
            shadow: -1.5,
            color: -1,
            noiseReduction: -4,
            sharpness: -1,
            clarity: 0
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Chrome",
            era: nil,
            characteristics: ["warm", "documentary", "muted", "travel", "natural"],
            author: "Fuji Recipe"
        )
    )

    /// 7 Iron - Popular community recipe with punchy colors
    static let sevenIron = FilterPreset(
        id: uuid(for: "7 Iron"),
        name: "7 Iron",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Weak / Small",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Strong",
            whiteBalanceRShift: 4,
            whiteBalanceBShift: -6,
            dynamicRange: "DR400",
            highlight: 0,
            shadow: 2,
            color: 2,
            noiseReduction: -4,
            sharpness: 0,
            clarity: 0
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: nil,
            characteristics: ["punchy", "versatile", "popular", "warm shadows", "cool highlights"],
            author: "Fuji Recipe"
        )
    )

    /// Kodak Gold 200 - Warm consumer film emulation
    static let kodakGold200 = FilterPreset(
        id: uuid(for: "Kodak Gold 200"),
        name: "Kodak Gold 200",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Weak / Small",
            colorChromeEffect: "Off",
            colorChromeFxBlue: "Off",
            whiteBalanceRShift: 5,
            whiteBalanceBShift: -3,
            dynamicRange: "DR200",
            highlight: 0,
            shadow: 1,
            color: 3,
            noiseReduction: -2,
            sharpness: 0,
            clarity: 0
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: "1980s",
            characteristics: ["warm", "golden", "nostalgic", "consumer film", "sunny"],
            author: "Fuji Recipe"
        )
    )

    /// Portra 400 - Professional portrait film emulation
    static let portra400 = FilterPreset(
        id: uuid(for: "Portra 400"),
        name: "Portra 400",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Nostalgic Neg",
            grainEffect: "Weak / Small",
            colorChromeEffect: "Weak",
            colorChromeFxBlue: "Off",
            whiteBalanceRShift: 2,
            whiteBalanceBShift: -2,
            dynamicRange: "DR400",
            highlight: -1,
            shadow: 1,
            color: 0,
            noiseReduction: -2,
            sharpness: 0,
            clarity: 0
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Nostalgic Neg",
            era: nil,
            characteristics: ["portrait", "natural skin", "soft", "professional", "wedding"],
            author: "Fuji Recipe"
        )
    )

    /// Tokyo Streets - High contrast urban look
    static let tokyoStreets = FilterPreset(
        id: uuid(for: "Tokyo Streets"),
        name: "Tokyo Streets",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Chrome",
            grainEffect: "Strong / Small",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Strong",
            whiteBalanceRShift: 0,
            whiteBalanceBShift: 2,
            dynamicRange: "DR400",
            highlight: -2,
            shadow: -2,
            color: 0,
            noiseReduction: -4,
            sharpness: 1,
            clarity: 2
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Chrome",
            era: nil,
            characteristics: ["urban", "street", "high contrast", "moody", "neon"],
            author: "Fuji Recipe"
        )
    )

    /// Nordic Light - Cool, clean Scandinavian look
    static let nordicLight = FilterPreset(
        id: uuid(for: "Nordic Light"),
        name: "Nordic Light",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Provia",
            grainEffect: "Off",
            colorChromeEffect: "Off",
            colorChromeFxBlue: "Weak",
            whiteBalanceRShift: -2,
            whiteBalanceBShift: 3,
            dynamicRange: "DR200",
            highlight: 0,
            shadow: 0,
            color: -1,
            noiseReduction: 0,
            sharpness: 0,
            clarity: 1
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Provia",
            era: nil,
            characteristics: ["cool", "clean", "minimal", "Scandinavian", "bright"],
            author: "Fuji Recipe"
        )
    )

    /// Warm Nostalgia - Golden hour memories
    static let warmNostalgia = FilterPreset(
        id: uuid(for: "Warm Nostalgia"),
        name: "Warm Nostalgia",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Classic Negative",
            grainEffect: "Strong / Large",
            colorChromeEffect: "Weak",
            colorChromeFxBlue: "Off",
            whiteBalanceRShift: 6,
            whiteBalanceBShift: -4,
            dynamicRange: "DR400",
            highlight: -1,
            shadow: 2,
            color: 2,
            noiseReduction: -4,
            sharpness: -2,
            clarity: -2
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Classic Negative",
            era: "1970s",
            characteristics: ["warm", "nostalgic", "golden", "soft", "dreamy"],
            author: "Fuji Recipe"
        )
    )

    /// Eterna Cinema - Cinematic flat profile
    static let eternaCinema = FilterPreset(
        id: uuid(for: "Eterna Cinema"),
        name: "Eterna Cinema",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Eterna",
            grainEffect: "Off",
            colorChromeEffect: "Weak",
            colorChromeFxBlue: "Weak",
            whiteBalanceRShift: 0,
            whiteBalanceBShift: 0,
            dynamicRange: "DR400",
            highlight: 0,
            shadow: 2,
            color: -2,
            noiseReduction: 0,
            sharpness: -1,
            clarity: 0
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Eterna",
            era: nil,
            characteristics: ["cinematic", "flat", "movie", "grade-ready", "professional"],
            author: "Fuji Recipe"
        )
    )

    /// Acros Street - Classic B&W street photography
    static let acrosStreet = FilterPreset(
        id: uuid(for: "Acros Street"),
        name: "Acros Street",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Acros",
            grainEffect: "Strong / Small",
            colorChromeEffect: "Off",
            colorChromeFxBlue: "Off",
            whiteBalanceRShift: 0,
            whiteBalanceBShift: 0,
            dynamicRange: "DR400",
            highlight: -1,
            shadow: 0,
            color: 0,
            noiseReduction: -4,
            sharpness: 1,
            clarity: 2
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Acros",
            era: nil,
            characteristics: ["black and white", "street", "contrasty", "gritty", "documentary"],
            author: "Fuji Recipe"
        )
    )

    /// Velvia Landscape - Vivid saturated landscapes
    static let velviaLandscape = FilterPreset(
        id: uuid(for: "Velvia Landscape"),
        name: "Velvia Landscape",
        category: .fujiRecipes,
        source: .builtIn,
        parameters: FujiRecipeImporter.convertRecipe(
            filmSimulation: "Velvia",
            grainEffect: "Off",
            colorChromeEffect: "Strong",
            colorChromeFxBlue: "Strong",
            whiteBalanceRShift: 0,
            whiteBalanceBShift: 0,
            dynamicRange: "DR200",
            highlight: -1,
            shadow: 0,
            color: 2,
            noiseReduction: 0,
            sharpness: 1,
            clarity: 2
        ),
        metadata: FilterPreset.FilterMetadata(
            filmStock: "Velvia",
            era: nil,
            characteristics: ["vivid", "saturated", "landscape", "nature", "punchy"],
            author: "Fuji Recipe"
        )
    )

    // MARK: - All Recipes

    /// All Fuji recipe presets
    static let all: [FilterPreset] = [
        classicCubanNeg,
        cinematicGold,
        summerChrome,
        lastSummerRoll,
        classicContinental,
        savannaChrome,
        sevenIron,
        kodakGold200,
        portra400,
        tokyoStreets,
        nordicLight,
        warmNostalgia,
        eternaCinema,
        acrosStreet,
        velviaLandscape
    ]
}

// MARK: - FujiRecipeImporter Extension

extension FujiRecipeImporter {

    /// Convert individual recipe parameters to FilterParameters
    /// Used for statically defining recipes in code
    static func convertRecipe(
        filmSimulation: String,
        grainEffect: String,
        colorChromeEffect: String,
        colorChromeFxBlue: String,
        whiteBalanceRShift: Int,
        whiteBalanceBShift: Int,
        dynamicRange: String,
        highlight: Float,
        shadow: Float,
        color: Int,
        noiseReduction: Int,
        sharpness: Int,
        clarity: Int
    ) -> FilterParameters {
        var params = FilterParameters()

        // Film Simulation
        params.filmSimulation = parseFilmSimulation(filmSimulation)

        // Grain Effect
        params.grain = parseGrainEffect(grainEffect)

        // Color Chrome
        params.colorChrome = ColorChromeData(
            effect: parseColorChromeLevel(colorChromeEffect),
            fxBlue: parseColorChromeLevel(colorChromeFxBlue)
        )

        // White Balance Shift
        params.whiteBalanceShift = WhiteBalanceShift(
            redShift: whiteBalanceRShift,
            blueShift: whiteBalanceBShift
        )

        // Dynamic Range
        params.dynamicRange = parseDynamicRange(dynamicRange)

        // Highlight/Shadow (Fuji -4...+4 → App -100...+100)
        params.highlights = clamp(highlight * 25, min: -100, max: 100)
        params.shadows = clamp(shadow * 25, min: -100, max: 100)

        // Color (Fuji -4...+4 → saturation + vibrance)
        // Reduced multiplier for more subtle, natural color adjustments
        let colorBoost = Float(color) * 6.0  // color: 4 → saturation: 24 (was 50)
        params.saturation = clamp(colorBoost, min: -100, max: 100)
        params.vibrance = clamp(colorBoost * 0.4, min: -100, max: 100)

        // Clarity (Fuji -4...+4 → App -100...+100)
        params.clarity = Float(clarity) * 25

        // Sharpness (Fuji -4...+4)
        if sharpness < 0 {
            params.sharpness = 0
            params.clarity += Float(sharpness) * 10
        } else {
            params.sharpness = clamp(Float(sharpness) * 12.5, min: 0, max: 100)
        }

        // Final clamp for clarity
        params.clarity = clamp(params.clarity, min: -100, max: 100)

        // Noise Reduction (Fuji -4...+4 → App -100...+100)
        params.noiseReduction = clamp(Float(noiseReduction) * 25, min: -100, max: 100)

        return params
    }

}
