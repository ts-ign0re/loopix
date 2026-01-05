import Foundation

// MARK: - Fuji Recipe JSON Model

/// Raw Fuji recipe data as parsed from JSON
struct FujiRecipeJSON: Codable {
    let name: String
    let filmSimulation: String
    let grainEffect: String
    let colorChromeEffect: String
    let colorChromeFxBlue: String
    let whiteBalance: WhiteBalanceJSON
    let dynamicRange: String
    let highlight: Float
    let shadow: Float
    let color: Int
    let noiseReduction: Int
    let sharpness: Int
    let clarity: Int
    let exposureCompensation: String
    let iso: String

    struct WhiteBalanceJSON: Codable {
        let mode: String
        let rShift: Int
        let bShift: Int

        enum CodingKeys: String, CodingKey {
            case mode
            case rShift = "r_shift"
            case bShift = "b_shift"
        }
    }

    enum CodingKeys: String, CodingKey {
        case name
        case filmSimulation = "film_simulation"
        case grainEffect = "grain_effect"
        case colorChromeEffect = "color_chrome_effect"
        case colorChromeFxBlue = "color_chrome_fx_blue"
        case whiteBalance = "white_balance"
        case dynamicRange = "dynamic_range"
        case highlight
        case shadow
        case color
        case noiseReduction = "noise_reduction"
        case sharpness
        case clarity
        case exposureCompensation = "exposure_compensation"
        case iso
    }
}

// MARK: - Fuji Recipe Importer

/// Imports and converts Fuji X recipes to FilterParameters
final class FujiRecipeImporter {

    // MARK: - Import from JSON

    /// Import recipes from JSON data
    /// - Parameter data: JSON data containing array of recipes
    /// - Returns: Array of FilterPreset objects
    static func importRecipes(from data: Data) throws -> [FilterPreset] {
        let decoder = JSONDecoder()
        let recipes = try decoder.decode([FujiRecipeJSON].self, from: data)
        return recipes.map { convertToPreset($0) }
    }

    /// Import recipes from a file URL
    /// - Parameter url: URL to the JSON file
    /// - Returns: Array of FilterPreset objects
    static func importRecipes(from url: URL) throws -> [FilterPreset] {
        let data = try Data(contentsOf: url)
        return try importRecipes(from: data)
    }

    /// Import recipes from bundle resource
    /// - Parameters:
    ///   - resourceName: Name of the resource file
    ///   - bundle: Bundle containing the resource
    /// - Returns: Array of FilterPreset objects
    static func importRecipes(resourceName: String, bundle: Bundle = .main) throws -> [FilterPreset] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw FujiImportError.resourceNotFound(resourceName)
        }
        return try importRecipes(from: url)
    }

    // MARK: - Public Builder (for UI form)

    /// Build FilterParameters from individual Fuji recipe values
    /// Used by FujiRecipeFormView to create filters with same quality as JSON imports
    static func buildParameters(
        filmSimulation: FilmSimulationType,
        grainEffect: String,
        colorChrome: ColorChromeData.ColorChromeLevel,
        colorChromeFxBlue: ColorChromeData.ColorChromeLevel,
        wbRedShift: Int,
        wbBlueShift: Int,
        dynamicRange: DynamicRangeMode,
        highlight: Float,
        shadow: Float,
        color: Int,
        sharpness: Int,
        noiseReduction: Int,
        clarity: Int
    ) -> FilterParameters {
        var params = FilterParameters()

        // Film Simulation
        params.filmSimulation = filmSimulation

        // Grain Effect
        params.grain = parseGrainEffect(grainEffect)

        // Color Chrome
        params.colorChrome = ColorChromeData(
            effect: colorChrome,
            fxBlue: colorChromeFxBlue
        )

        // White Balance Shift
        params.whiteBalanceShift = WhiteBalanceShift(
            redShift: wbRedShift,
            blueShift: wbBlueShift
        )

        // Dynamic Range
        params.dynamicRange = dynamicRange

        // Highlight/Shadow (Fuji -2...+4 scale, convert to app -100...+100)
        params.highlights = clamp(highlight * 25, min: -100, max: 100)
        params.shadows = clamp(shadow * 25, min: -100, max: 100)

        // Color (Fuji -4...+4 → saturation + vibrance)
        // Reduced multiplier for more subtle, natural color adjustments
        let colorBoost = Float(color) * 6.0  // color: 4 → saturation: 24 (was 50)
        params.saturation = clamp(colorBoost, min: -100, max: 100)
        params.vibrance = clamp(colorBoost * 0.4, min: -100, max: 100)

        // Clarity (Fuji -5...+5 → App -100...+100)
        params.clarity = Float(clarity) * 20

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

    // MARK: - Conversion

    /// Convert a Fuji recipe to a FilterPreset
    private static func convertToPreset(_ recipe: FujiRecipeJSON) -> FilterPreset {
        let parameters = convertToParameters(recipe)

        return FilterPreset(
            id: UUID(),
            name: recipe.name,
            category: .fujiRecipes,
            source: .imported(sourceName: "Fuji Recipe"),
            parameters: parameters,
            metadata: FilterPreset.FilterMetadata(
                filmStock: recipe.filmSimulation,
                characteristics: ["fuji", "recipe", recipe.filmSimulation.lowercased()]
            )
        )
    }

    /// Convert Fuji recipe to FilterParameters
    private static func convertToParameters(_ recipe: FujiRecipeJSON) -> FilterParameters {
        var params = FilterParameters()

        // Film Simulation
        params.filmSimulation = parseFilmSimulation(recipe.filmSimulation)

        // Grain Effect
        params.grain = parseGrainEffect(recipe.grainEffect)

        // Color Chrome
        params.colorChrome = ColorChromeData(
            effect: parseColorChromeLevel(recipe.colorChromeEffect),
            fxBlue: parseColorChromeLevel(recipe.colorChromeFxBlue)
        )

        // White Balance Shift
        params.whiteBalanceShift = WhiteBalanceShift(
            redShift: recipe.whiteBalance.rShift,
            blueShift: recipe.whiteBalance.bShift
        )

        // Dynamic Range
        params.dynamicRange = parseDynamicRange(recipe.dynamicRange)

        // Highlight/Shadow (Fuji -4...+4 → App -100...+100)
        params.highlights = clamp(recipe.highlight * 25, min: -100, max: 100)
        params.shadows = clamp(recipe.shadow * 25, min: -100, max: 100)

        // Color (Fuji -4...+4 → saturation + vibrance)
        // Reduced multiplier for more subtle, natural color adjustments
        let colorBoost = Float(recipe.color) * 6.0  // color: 4 → saturation: 24 (was 50)
        params.saturation = clamp(colorBoost, min: -100, max: 100)
        params.vibrance = clamp(colorBoost * 0.4, min: -100, max: 100)

        // Clarity (Fuji -4...+4 → App -100...+100)
        // Apply clarity FIRST, before sharpness modifies it
        params.clarity = Float(recipe.clarity) * 25  // -4 → -100, +4 → +100

        // Sharpness (Fuji -4...+4)
        // Negative values = softening (via additional negative clarity)
        // Positive values = sharpening (0...100 range)
        if recipe.sharpness < 0 {
            params.sharpness = 0
            // Negative sharpness adds to negative clarity
            params.clarity += Float(recipe.sharpness) * 10  // -4 → -40 additional clarity
        } else {
            params.sharpness = clamp(Float(recipe.sharpness) * 12.5, min: 0, max: 100)
        }

        // Final clamp for clarity after sharpness modification
        params.clarity = clamp(params.clarity, min: -100, max: 100)

        // Noise Reduction (Fuji -4...+4 → App -100...+100)
        // Negative = detail enhancement, Positive = noise reduction
        params.noiseReduction = clamp(Float(recipe.noiseReduction) * 25, min: -100, max: 100)

        return params
    }

    // MARK: - Validation Helper

    /// Clamp a value to a specified range
    static func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }

    // MARK: - Parsing Helpers

    /// Parse film simulation string to enum
    static func parseFilmSimulation(_ string: String) -> FilmSimulationType {
        switch string.lowercased() {
        case "classic negative":
            return .classicNegative
        case "classic chrome":
            return .classicChrome
        case "provia", "provia/standard":
            return .provia
        case "velvia", "velvia/vivid":
            return .velvia
        case "astia", "astia/soft":
            return .astia
        case "acros", "acros+ye", "acros+r", "acros+g":
            return .acros
        case "eterna", "eterna/cinema":
            return .eterna
        case "eterna bleach bypass":
            return .eternaBleachBypass
        case "nostalgic neg", "nostalgic negative":
            return .nostalgicNeg
        case "reala ace", "reala":
            return .reala
        default:
            return .none
        }
    }

    /// Parse grain effect string to GrainData
    /// Format: "Strength / Size" e.g., "Strong / Large", "Weak / Small"
    static func parseGrainEffect(_ string: String) -> GrainData {
        let components = string.lowercased().split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }

        guard components.count >= 1 else { return .none }

        // Parse strength (Fuji grain is subtle, not aggressive)
        let amount: Float
        switch components[0] {
        case "off", "none":
            return .none
        case "weak":
            amount = 3
        case "strong":
            amount = 7
        default:
            amount = 4
        }

        // Parse size
        let size: Float
        if components.count >= 2 {
            switch components[1] {
            case "small":
                size = 0.3
            case "large":
                size = 0.7
            default:
                size = 0.5
            }
        } else {
            size = 0.5
        }

        return GrainData(
            amount: amount,
            size: size,
            roughness: 0.5,
            monochromatic: true
        )
    }

    /// Parse color chrome level string
    static func parseColorChromeLevel(_ string: String) -> ColorChromeData.ColorChromeLevel {
        switch string.lowercased() {
        case "off", "none":
            return .off
        case "weak":
            return .weak
        case "strong":
            return .strong
        default:
            return .off
        }
    }

    /// Parse dynamic range string
    static func parseDynamicRange(_ string: String) -> DynamicRangeMode {
        switch string.uppercased() {
        case "DR100":
            return .dr100
        case "DR200":
            return .dr200
        case "DR400":
            return .dr400
        case "DR AUTO", "AUTO":
            return .auto
        default:
            return .dr100
        }
    }
}

// MARK: - Errors

enum FujiImportError: LocalizedError {
    case resourceNotFound(String)
    case invalidFormat
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name):
            return "Resource '\(name)' not found in bundle"
        case .invalidFormat:
            return "Invalid recipe format"
        case .decodingFailed(let error):
            return "Failed to decode recipe: \(error.localizedDescription)"
        }
    }
}
