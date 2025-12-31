import Foundation

/// A complete filter preset with metadata
struct FilterPreset: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var category: FilterCategory
    var source: FilterSource
    var parameters: FilterParameters
    var metadata: FilterMetadata
    var createdAt: Date
    var modifiedAt: Date

    /// Reference to a HALD CLUT file for film simulation presets
    /// This is the relative path within the app bundle or documents directory
    var clutPath: String?

    /// Intensity of the CLUT effect (0-100)
    var clutIntensity: Float = 100

    /// Where the preset came from
    enum FilterSource: Codable, Hashable, Sendable {
        case builtIn
        case userCreated
        case calibrated(referenceImageHash: String)
        case imported(sourceName: String)
        case haldCLUT(manufacturer: String, filmStock: String)

        private enum CodingKeys: String, CodingKey {
            case type
            case referenceImageHash
            case sourceName
            case manufacturer
            case filmStock
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "builtIn":
                self = .builtIn
            case "userCreated":
                self = .userCreated
            case "calibrated":
                let hash = try container.decode(String.self, forKey: .referenceImageHash)
                self = .calibrated(referenceImageHash: hash)
            case "imported":
                let name = try container.decode(String.self, forKey: .sourceName)
                self = .imported(sourceName: name)
            case "haldCLUT":
                let manufacturer = try container.decode(String.self, forKey: .manufacturer)
                let filmStock = try container.decode(String.self, forKey: .filmStock)
                self = .haldCLUT(manufacturer: manufacturer, filmStock: filmStock)
            default:
                self = .userCreated
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .builtIn:
                try container.encode("builtIn", forKey: .type)
            case .userCreated:
                try container.encode("userCreated", forKey: .type)
            case .calibrated(let hash):
                try container.encode("calibrated", forKey: .type)
                try container.encode(hash, forKey: .referenceImageHash)
            case .imported(let name):
                try container.encode("imported", forKey: .type)
                try container.encode(name, forKey: .sourceName)
            case .haldCLUT(let manufacturer, let filmStock):
                try container.encode("haldCLUT", forKey: .type)
                try container.encode(manufacturer, forKey: .manufacturer)
                try container.encode(filmStock, forKey: .filmStock)
            }
        }
    }

    /// Additional metadata about the filter
    struct FilterMetadata: Codable, Hashable, Sendable {
        var filmStock: String?          // "Kodak Portra 400"
        var era: String?                 // "1970s"
        var characteristics: [String]    // ["warm shadows", "muted highlights"]
        var author: String?
        var isFavorite: Bool = false
        var usageCount: Int = 0

        // Extended metadata for film simulations
        var brand: String?               // "Kodak", "Fuji", "Ilford"
        var iso: Int?                    // 400, 800, etc.
        var filmType: FilmType?          // color-negative, bw, slide
        var warmth: WarmthLevel?         // cool, neutral, warm
        var contrast: ContrastLevel?     // low, medium, high
        var subcategory: String?         // "color-negative", "slide", "instant"

        /// Film type classification
        enum FilmType: String, Codable, Hashable, Sendable, CaseIterable {
            case colorNegative = "color-negative"
            case colorSlide = "color-slide"
            case blackAndWhite = "black-and-white"
            case instant = "instant"
            case cinema = "cinema"
            case digital = "digital"

            var displayName: String {
                switch self {
                case .colorNegative: return "Color Negative"
                case .colorSlide: return "Color Slide"
                case .blackAndWhite: return "Black & White"
                case .instant: return "Instant"
                case .cinema: return "Cinema"
                case .digital: return "Digital"
                }
            }
        }

        /// Warmth level classification
        enum WarmthLevel: String, Codable, Hashable, Sendable, CaseIterable {
            case cool
            case neutral
            case warm

            var displayName: String { rawValue.capitalized }
        }

        /// Contrast level classification
        enum ContrastLevel: String, Codable, Hashable, Sendable, CaseIterable {
            case low
            case medium
            case high

            var displayName: String { rawValue.capitalized }
        }

        init(
            filmStock: String? = nil,
            era: String? = nil,
            characteristics: [String] = [],
            author: String? = nil,
            isFavorite: Bool = false,
            usageCount: Int = 0,
            brand: String? = nil,
            iso: Int? = nil,
            filmType: FilmType? = nil,
            warmth: WarmthLevel? = nil,
            contrast: ContrastLevel? = nil,
            subcategory: String? = nil
        ) {
            self.filmStock = filmStock
            self.era = era
            self.characteristics = characteristics
            self.author = author
            self.isFavorite = isFavorite
            self.usageCount = usageCount
            self.brand = brand
            self.iso = iso
            self.filmType = filmType
            self.warmth = warmth
            self.contrast = contrast
            self.subcategory = subcategory
        }
    }

    /// Create a new user preset
    init(
        id: UUID = UUID(),
        name: String,
        category: FilterCategory = .custom,
        source: FilterSource = .userCreated,
        parameters: FilterParameters = .identity,
        metadata: FilterMetadata = FilterMetadata(),
        clutPath: String? = nil,
        clutIntensity: Float = 100
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.source = source
        self.parameters = parameters
        self.metadata = metadata
        self.clutPath = clutPath
        self.clutIntensity = clutIntensity
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    /// Check if this preset uses a HALD CLUT
    var usesCLUT: Bool {
        clutPath != nil
    }

    /// Create a copy with a new name
    func duplicate(newName: String) -> FilterPreset {
        return FilterPreset(
            id: UUID(),
            name: newName,
            category: category,
            source: .userCreated,
            parameters: parameters,
            metadata: metadata,
            clutPath: clutPath,
            clutIntensity: clutIntensity
        )
    }

    /// Mark as modified
    mutating func touch() {
        modifiedAt = Date()
    }

    /// Increment usage count
    mutating func recordUsage() {
        metadata.usageCount += 1
        modifiedAt = Date()
    }
}

// MARK: - Original (No Filter) Preset

extension FilterPreset {
    /// The "Original" preset that applies no adjustments
    static let original = FilterPreset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        name: "Original",
        category: .all,
        source: .builtIn,
        parameters: .identity,
        metadata: FilterMetadata(characteristics: ["No adjustments"])
    )
}

// MARK: - Intensity Application

extension FilterPreset {
    /// Apply the preset at a given intensity (0-100%)
    func parameters(at intensity: Float) -> FilterParameters {
        guard intensity < 100 else { return parameters }
        guard intensity > 0 else { return .identity }

        let t = intensity / 100.0
        return FilterParameters.interpolate(from: .identity, to: parameters, t: t)
    }
}

// MARK: - Parameter Interpolation

extension FilterParameters {
    /// Linearly interpolate between two parameter sets
    static func interpolate(from a: FilterParameters, to b: FilterParameters, t: Float) -> FilterParameters {
        var result = FilterParameters()

        // Light
        result.exposure = a.exposure + (b.exposure - a.exposure) * t
        result.contrast = a.contrast + (b.contrast - a.contrast) * t
        result.highlights = a.highlights + (b.highlights - a.highlights) * t
        result.shadows = a.shadows + (b.shadows - a.shadows) * t
        result.whites = a.whites + (b.whites - a.whites) * t
        result.blacks = a.blacks + (b.blacks - a.blacks) * t

        // Color
        result.temperature = a.temperature + (b.temperature - a.temperature) * t
        result.tint = a.tint + (b.tint - a.tint) * t
        result.saturation = a.saturation + (b.saturation - a.saturation) * t
        result.vibrance = a.vibrance + (b.vibrance - a.vibrance) * t

        // Effects
        result.clarity = a.clarity + (b.clarity - a.clarity) * t
        result.fade = a.fade + (b.fade - a.fade) * t
        result.sharpness = a.sharpness + (b.sharpness - a.sharpness) * t
        result.sharpenRadius = a.sharpenRadius + (b.sharpenRadius - a.sharpenRadius) * t

        // Grain
        result.grain.amount = a.grain.amount + (b.grain.amount - a.grain.amount) * t
        result.grain.size = a.grain.size + (b.grain.size - a.grain.size) * t
        result.grain.roughness = a.grain.roughness + (b.grain.roughness - a.grain.roughness) * t
        result.grain.monochromatic = t > 0.5 ? b.grain.monochromatic : a.grain.monochromatic

        // Vignette
        result.vignette.amount = a.vignette.amount + (b.vignette.amount - a.vignette.amount) * t
        result.vignette.midpoint = a.vignette.midpoint + (b.vignette.midpoint - a.vignette.midpoint) * t
        result.vignette.roundness = a.vignette.roundness + (b.vignette.roundness - a.vignette.roundness) * t
        result.vignette.feather = a.vignette.feather + (b.vignette.feather - a.vignette.feather) * t

        // Bloom
        result.bloom.intensity = a.bloom.intensity + (b.bloom.intensity - a.bloom.intensity) * t
        result.bloom.radius = a.bloom.radius + (b.bloom.radius - a.bloom.radius) * t
        result.bloom.threshold = a.bloom.threshold + (b.bloom.threshold - a.bloom.threshold) * t

        // Halation
        result.halation.intensity = a.halation.intensity + (b.halation.intensity - a.halation.intensity) * t
        result.halation.hue = a.halation.hue + (b.halation.hue - a.halation.hue) * t
        result.halation.spread = a.halation.spread + (b.halation.spread - a.halation.spread) * t

        // Split Tone
        result.splitTone.highlightHue = a.splitTone.highlightHue + (b.splitTone.highlightHue - a.splitTone.highlightHue) * t
        result.splitTone.highlightSaturation = a.splitTone.highlightSaturation + (b.splitTone.highlightSaturation - a.splitTone.highlightSaturation) * t
        result.splitTone.shadowHue = a.splitTone.shadowHue + (b.splitTone.shadowHue - a.splitTone.shadowHue) * t
        result.splitTone.shadowSaturation = a.splitTone.shadowSaturation + (b.splitTone.shadowSaturation - a.splitTone.shadowSaturation) * t
        result.splitTone.balance = a.splitTone.balance + (b.splitTone.balance - a.splitTone.balance) * t

        // Skin Tone
        result.skinToneHue = a.skinToneHue + (b.skinToneHue - a.skinToneHue) * t
        result.skinToneSaturation = a.skinToneSaturation + (b.skinToneSaturation - a.skinToneSaturation) * t

        // HSL - interpolate each channel
        for i in 0..<8 {
            let aChannel = a.hsl[i]
            let bChannel = b.hsl[i]
            result.hsl[i] = HSLAdjustments.HSLChannel(
                hue: aChannel.hue + (bChannel.hue - aChannel.hue) * t,
                saturation: aChannel.saturation + (bChannel.saturation - aChannel.saturation) * t,
                luminance: aChannel.luminance + (bChannel.luminance - aChannel.luminance) * t
            )
        }

        // Tone Curve - interpolate Y values for each point
        if b.toneCurve != .identity {
            var newCurve = ToneCurveData.identity
            for i in 0..<newCurve.composite.count {
                let aY = a.toneCurve.composite[i].y
                let bY = b.toneCurve.composite[i].y
                newCurve.composite[i].y = aY + (bY - aY) * t
            }
            result.toneCurve = newCurve
        }

        // Transform (not interpolated)
        result.rotation = b.rotation
        result.cropRect = b.cropRect

        return result
    }
}
