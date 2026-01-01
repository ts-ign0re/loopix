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

    // MARK: - Conversion

    /// Convert a Fuji recipe to a FilterPreset
    private static func convertToPreset(_ recipe: FujiRecipeJSON) -> FilterPreset {
        let parameters = convertToParameters(recipe)

        return FilterPreset(
            id: UUID(),
            name: recipe.name,
            category: .film,
            source: .imported(sourceName: "Fuji Recipe"),
            parameters: parameters,
            metadata: FilterMetadata(
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

        // Highlight/Shadow (Fuji -2...+2 → App -100...+100)
        params.highlights = recipe.highlight * 50  // -2 → -100, +2 → +100
        params.shadows = recipe.shadow * 50

        // Color (Fuji 1-4 → saturation + vibrance)
        let colorBoost = Float(recipe.color - 2) * 15  // Normalize around 2 (neutral)
        params.saturation = colorBoost
        params.vibrance = colorBoost * 0.5

        // Sharpness (Fuji -4...+4 → App 0...100, with -4 = 0, 0 = 50, +4 = 100)
        params.sharpness = (Float(recipe.sharpness) + 4) * 12.5  // Map -4...+4 to 0...100

        // Clarity (Fuji -4...+4 → App -100...+100)
        params.clarity = Float(recipe.clarity) * 25  // -4 → -100, +4 → +100

        return params
    }

    // MARK: - Parsing Helpers

    /// Parse film simulation string to enum
    private static func parseFilmSimulation(_ string: String) -> FilmSimulationType {
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
    private static func parseGrainEffect(_ string: String) -> GrainData {
        let components = string.lowercased().split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }

        guard components.count >= 1 else { return .none }

        // Parse strength
        let amount: Float
        switch components[0] {
        case "off", "none":
            return .none
        case "weak":
            amount = 25
        case "strong":
            amount = 60
        default:
            amount = 40
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
    private static func parseColorChromeLevel(_ string: String) -> ColorChromeData.ColorChromeLevel {
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
    private static func parseDynamicRange(_ string: String) -> DynamicRangeMode {
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
