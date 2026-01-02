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
        "Classic Continental": UUID(uuidString: "20000000-F001-0000-0000-000000000005")!
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
        source: .imported(sourceName: "Fuji Recipe"),
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
        source: .imported(sourceName: "Fuji Recipe"),
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
        source: .imported(sourceName: "Fuji Recipe"),
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
        source: .imported(sourceName: "Fuji Recipe"),
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
        source: .imported(sourceName: "Fuji Recipe"),
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

    // MARK: - All Recipes

    /// All Fuji recipe presets
    static let all: [FilterPreset] = [
        classicCubanNeg,
        cinematicGold,
        summerChrome,
        lastSummerRoll,
        classicContinental
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

        // Color (Fuji 0-4 → saturation + vibrance)
        let colorBoost = Float(color) * 12.5
        params.saturation = clamp(colorBoost, min: -100, max: 100)
        params.vibrance = clamp(colorBoost * 0.3, min: -100, max: 100)

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
