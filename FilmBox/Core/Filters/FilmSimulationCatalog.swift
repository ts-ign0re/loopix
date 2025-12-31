import Foundation

// MARK: - Film Simulation Catalog

/// Catalog of all available film simulation presets based on HALD CLUT files
/// This provides structured metadata for 350+ film looks organized by brand, type, and characteristics
@available(iOS 17.0, *)
struct FilmSimulationCatalog {

    // MARK: - Types

    /// Film brand information
    struct BrandInfo: Sendable {
        let id: String
        let name: String
        let characteristics: [String]
        let warmth: FilterPreset.FilterMetadata.WarmthLevel
        let defaultContrast: FilterPreset.FilterMetadata.ContrastLevel
    }

    /// Film collection (group of related presets)
    struct Collection: Sendable {
        let id: String
        let name: String
        let category: FilterCategory
        let subcategory: String
        let basePath: String
    }

    // MARK: - Brand Database

    static let brands: [String: BrandInfo] = [
        // Color Negative Brands
        "Kodak": BrandInfo(
            id: "kodak",
            name: "Kodak",
            characteristics: ["warm-shadows", "soft-highlights", "skin-tones"],
            warmth: .warm,
            defaultContrast: .medium
        ),
        "Fuji": BrandInfo(
            id: "fuji",
            name: "Fujifilm",
            characteristics: ["accurate-colors", "fine-grain", "natural"],
            warmth: .neutral,
            defaultContrast: .medium
        ),
        "Agfa": BrandInfo(
            id: "agfa",
            name: "Agfa",
            characteristics: ["european-style", "neutral", "classic"],
            warmth: .neutral,
            defaultContrast: .medium
        ),
        "Polaroid": BrandInfo(
            id: "polaroid",
            name: "Polaroid",
            characteristics: ["vintage", "fade", "instant"],
            warmth: .warm,
            defaultContrast: .low
        ),
        "Lomography": BrandInfo(
            id: "lomography",
            name: "Lomography",
            characteristics: ["creative", "cross-process", "experimental"],
            warmth: .warm,
            defaultContrast: .high
        ),

        // B&W Brands
        "Ilford": BrandInfo(
            id: "ilford",
            name: "Ilford",
            characteristics: ["classic-bw", "rich-blacks", "smooth-tones"],
            warmth: .neutral,
            defaultContrast: .medium
        ),
        "Rollei": BrandInfo(
            id: "rollei",
            name: "Rollei",
            characteristics: ["specialty", "infrared", "fine-art"],
            warmth: .neutral,
            defaultContrast: .high
        ),

        // Digital/Camera Brands
        "Apple": BrandInfo(
            id: "apple",
            name: "Apple",
            characteristics: ["modern", "clean", "vivid"],
            warmth: .neutral,
            defaultContrast: .medium
        ),
        "Fujifilm XTrans": BrandInfo(
            id: "fujifilm-xtrans",
            name: "Fujifilm X-Trans",
            characteristics: ["camera-simulation", "film-like", "fuji-colors"],
            warmth: .neutral,
            defaultContrast: .medium
        )
    ]

    // MARK: - Collections Database

    static let collections: [Collection] = [
        // Film Simulation - Color
        Collection(
            id: "film-color-kodak",
            name: "Kodak Color",
            category: .film,
            subcategory: "color-negative",
            basePath: "Film Simulation/Color/Kodak"
        ),
        Collection(
            id: "film-color-fuji",
            name: "Fuji Color",
            category: .film,
            subcategory: "color-negative",
            basePath: "Film Simulation/Color/Fuji"
        ),
        Collection(
            id: "film-color-agfa",
            name: "Agfa Color",
            category: .film,
            subcategory: "color-negative",
            basePath: "Film Simulation/Color/Agfa"
        ),
        Collection(
            id: "film-color-polaroid",
            name: "Polaroid Color",
            category: .film,
            subcategory: "instant",
            basePath: "Film Simulation/Color/Polaroid"
        ),
        Collection(
            id: "film-color-lomography",
            name: "Lomography",
            category: .film,
            subcategory: "creative",
            basePath: "Film Simulation/Color/Lomography"
        ),
        Collection(
            id: "film-color-creative",
            name: "Creative Pack",
            category: .film,
            subcategory: "creative",
            basePath: "Film Simulation/Color/CreativePack-1"
        ),

        // Film Simulation - B&W
        Collection(
            id: "film-bw-kodak",
            name: "Kodak B&W",
            category: .bw,
            subcategory: "black-and-white",
            basePath: "Film Simulation/Black and White/Kodak"
        ),
        Collection(
            id: "film-bw-fuji",
            name: "Fuji B&W",
            category: .bw,
            subcategory: "black-and-white",
            basePath: "Film Simulation/Black and White/Fuji"
        ),
        Collection(
            id: "film-bw-ilford",
            name: "Ilford",
            category: .bw,
            subcategory: "black-and-white",
            basePath: "Film Simulation/Black and White/Ilford"
        ),
        Collection(
            id: "film-bw-agfa",
            name: "Agfa B&W",
            category: .bw,
            subcategory: "black-and-white",
            basePath: "Film Simulation/Black and White/Agfa"
        ),
        Collection(
            id: "film-bw-polaroid",
            name: "Polaroid B&W",
            category: .bw,
            subcategory: "instant",
            basePath: "Film Simulation/Black and White/Polaroid"
        ),
        Collection(
            id: "film-bw-rollei",
            name: "Rollei",
            category: .bw,
            subcategory: "specialty",
            basePath: "Film Simulation/Black and White/Rollei"
        ),

        // Camera Simulations
        Collection(
            id: "fujifilm-xtrans",
            name: "Fujifilm X-Trans III",
            category: .film,
            subcategory: "camera-simulation",
            basePath: "Fujifilm XTrans III"
        ),
        Collection(
            id: "apple-styles",
            name: "Apple Styles",
            category: .pro,
            subcategory: "digital",
            basePath: "Apple"
        ),

        // Creative/Effects
        Collection(
            id: "pixelmator-pro",
            name: "Pixelmator Pro",
            category: .pro,
            subcategory: "creative",
            basePath: "Pixelmator Pro"
        ),
        Collection(
            id: "picturefx-analog",
            name: "AnalogFX",
            category: .vintage,
            subcategory: "analog",
            basePath: "PictureFX/AnalogFX"
        ),
        Collection(
            id: "picturefx-gold",
            name: "GoldFX",
            category: .warm,
            subcategory: "creative",
            basePath: "PictureFX/GoldFX"
        ),
        Collection(
            id: "picturefx-zilver",
            name: "ZilverFX",
            category: .cool,
            subcategory: "creative",
            basePath: "PictureFX/ZilverFX"
        ),
        Collection(
            id: "picturefx-technical",
            name: "TechnicalFX",
            category: .pro,
            subcategory: "technical",
            basePath: "PictureFX/TechnicalFX"
        )
    ]

    // MARK: - Film Stock Database (known ISO and characteristics)

    static let filmStockInfo: [String: (iso: Int?, warmth: FilterPreset.FilterMetadata.WarmthLevel, contrast: FilterPreset.FilterMetadata.ContrastLevel, filmType: FilterPreset.FilterMetadata.FilmType)] = [
        // Kodak Color
        "Portra 160": (160, .warm, .low, .colorNegative),
        "Portra 400": (400, .warm, .low, .colorNegative),
        "Portra 800": (800, .warm, .low, .colorNegative),
        "Ektar 100": (100, .neutral, .high, .colorNegative),
        "Gold 200": (200, .warm, .medium, .colorNegative),
        "ColorPlus 200": (200, .warm, .medium, .colorNegative),
        "UltraMax 400": (400, .warm, .medium, .colorNegative),
        "Vision3 50D": (50, .neutral, .medium, .cinema),
        "Vision3 250D": (250, .neutral, .medium, .cinema),
        "Vision3 500T": (500, .cool, .medium, .cinema),

        // Kodak B&W
        "Tri-X 400": (400, .neutral, .high, .blackAndWhite),
        "TRI-X 400": (400, .neutral, .high, .blackAndWhite),
        "T-Max 100": (100, .neutral, .medium, .blackAndWhite),
        "T-Max 400": (400, .neutral, .medium, .blackAndWhite),
        "TMAX 3200": (3200, .neutral, .high, .blackAndWhite),
        "BW 400 CN": (400, .neutral, .medium, .blackAndWhite),

        // Fuji Color
        "Pro 400H": (400, .neutral, .low, .colorNegative),
        "400H": (400, .neutral, .low, .colorNegative),
        "160C": (160, .neutral, .low, .colorNegative),
        "Superia 400": (400, .neutral, .medium, .colorNegative),
        "Superia 800": (800, .neutral, .medium, .colorNegative),
        "Superia 1600": (1600, .neutral, .medium, .colorNegative),
        "Velvia 50": (50, .warm, .high, .colorSlide),
        "Velvia 100": (100, .warm, .high, .colorSlide),
        "Provia 100F": (100, .neutral, .medium, .colorSlide),
        "Provia 400F": (400, .neutral, .medium, .colorSlide),
        "Sensia 100": (100, .neutral, .medium, .colorSlide),
        "800Z": (800, .neutral, .low, .colorNegative),

        // Fuji B&W
        "Neopan Acros": (100, .neutral, .medium, .blackAndWhite),
        "Neopan Acros 100": (100, .neutral, .medium, .blackAndWhite),
        "Neopan 1600": (1600, .neutral, .high, .blackAndWhite),
        "FP-3000b": (3000, .neutral, .high, .instant),

        // Ilford
        "HP5 Plus 400": (400, .neutral, .medium, .blackAndWhite),
        "HP5": (400, .neutral, .medium, .blackAndWhite),
        "Delta 100": (100, .neutral, .medium, .blackAndWhite),
        "Delta 400": (400, .neutral, .medium, .blackAndWhite),
        "Delta 3200": (3200, .neutral, .high, .blackAndWhite),
        "Pan F Plus 50": (50, .neutral, .medium, .blackAndWhite),
        "FP4 Plus 125": (125, .neutral, .medium, .blackAndWhite),
        "XP2": (400, .neutral, .medium, .blackAndWhite),
        "HPS 800": (800, .neutral, .high, .blackAndWhite),

        // Polaroid
        "FP-100C": (100, .warm, .low, .instant),
        "Spectra": (nil, .warm, .low, .instant),
        "665": (nil, .neutral, .medium, .instant),
        "664": (nil, .neutral, .medium, .instant),
        "667": (nil, .neutral, .high, .instant),
        "672": (nil, .neutral, .medium, .instant),

        // Agfa
        "Vista 100": (100, .neutral, .medium, .colorNegative),
        "Vista 200": (200, .neutral, .medium, .colorNegative),
        "Vista 400": (400, .neutral, .medium, .colorNegative),
        "Ultra 100": (100, .warm, .high, .colorNegative),
        "Optima 100": (100, .neutral, .medium, .colorNegative),
        "APX 25": (25, .neutral, .high, .blackAndWhite),
        "APX 100": (100, .neutral, .high, .blackAndWhite),

        // Rollei
        "Retro 80s": (80, .neutral, .high, .blackAndWhite),
        "Retro 100 Tonal": (100, .neutral, .medium, .blackAndWhite),
        "IR 400": (400, .neutral, .high, .blackAndWhite),
        "Ortho 25": (25, .neutral, .high, .blackAndWhite)
    ]

    // MARK: - Preset Generation

    /// Generate all film simulation presets by scanning the CLUT directory
    static func generatePresets(from baseURL: URL) -> [FilterPreset] {
        var presets: [FilterPreset] = []

        for collection in collections {
            let collectionURL = baseURL.appendingPathComponent(collection.basePath)

            guard let files = try? FileManager.default.contentsOfDirectory(
                at: collectionURL,
                includingPropertiesForKeys: nil
            ) else {
                continue
            }

            let pngFiles = files.filter { $0.pathExtension.lowercased() == "png" }

            for file in pngFiles {
                if let preset = createPreset(
                    from: file,
                    collection: collection,
                    baseURL: baseURL
                ) {
                    presets.append(preset)
                }
            }
        }

        return presets.sorted { $0.name < $1.name }
    }

    /// Create a preset from a CLUT file
    private static func createPreset(
        from url: URL,
        collection: Collection,
        baseURL: URL
    ) -> FilterPreset? {
        let filename = url.deletingPathExtension().lastPathComponent
        let relativePath = url.path.replacingOccurrences(of: baseURL.path + "/", with: "")

        // Parse brand from filename or path
        let brand = extractBrand(from: filename, path: collection.basePath)
        let brandInfo = brands[brand]

        // Parse film stock name and info
        let (stockName, variant) = parseFilmStockName(filename)
        let stockInfo = findStockInfo(stockName)

        // Determine characteristics
        let isBlackAndWhite = collection.basePath.contains("Black and White") ||
                              collection.category == .bw
        let filmType: FilterPreset.FilterMetadata.FilmType = stockInfo?.filmType ??
            (isBlackAndWhite ? .blackAndWhite : .colorNegative)

        // Build display name
        let displayName = buildDisplayName(
            brand: brand,
            stockName: stockName,
            variant: variant,
            filename: filename
        )

        // Generate stable UUID from path for consistent IDs
        let id = UUID(uuidString: stableUUID(from: relativePath)) ?? UUID()

        let metadata = FilterPreset.FilterMetadata(
            filmStock: stockName.isEmpty ? nil : "\(brand) \(stockName)",
            era: determineEra(brand: brand, stockName: stockName),
            characteristics: buildCharacteristics(
                brandInfo: brandInfo,
                isBlackAndWhite: isBlackAndWhite,
                variant: variant
            ),
            brand: brand,
            iso: stockInfo?.iso,
            filmType: filmType,
            warmth: stockInfo?.warmth ?? brandInfo?.warmth ?? .neutral,
            contrast: stockInfo?.contrast ?? brandInfo?.defaultContrast ?? .medium,
            subcategory: collection.subcategory
        )

        return FilterPreset(
            id: id,
            name: displayName,
            category: collection.category,
            source: .haldCLUT(manufacturer: brand, filmStock: stockName),
            parameters: .identity,
            metadata: metadata,
            clutPath: relativePath,
            clutIntensity: 100
        )
    }

    // MARK: - Helper Methods

    private static func extractBrand(from filename: String, path: String) -> String {
        // Try to extract from filename first
        for brand in brands.keys {
            if filename.hasPrefix(brand) {
                return brand
            }
        }

        // Extract from path
        let pathComponents = path.split(separator: "/")
        if let lastComponent = pathComponents.last {
            let brandName = String(lastComponent)
            if brands[brandName] != nil {
                return brandName
            }
        }

        // Special cases
        if path.contains("Apple") { return "Apple" }
        if path.contains("Fujifilm XTrans") { return "Fujifilm XTrans" }
        if path.contains("Pixelmator") { return "Pixelmator" }
        if path.contains("PictureFX") { return "PictureFX" }

        return "Unknown"
    }

    private static func parseFilmStockName(_ filename: String) -> (stock: String, variant: String) {
        // Remove brand prefix and parse stock name
        var name = filename

        // Remove common brand prefixes
        for brand in brands.keys {
            if name.hasPrefix(brand + " ") {
                name = String(name.dropFirst(brand.count + 1))
                break
            }
        }

        // Parse variants (e.g., "1 -", "2", "3 +", "4 ++", "HC", "Negative")
        var variant = ""
        let variantPatterns = [
            " 1 --", " 1 -", " 2 -", " 2", " 3 Alt", " 3 +", " 3",
            " 4 ++", " 4 +", " 4", " 5 ++", " 5", " 6 +++", " 6",
            " HC", " Negative", " Early", " Generic"
        ]

        for pattern in variantPatterns {
            if name.hasSuffix(pattern) {
                variant = pattern.trimmingCharacters(in: .whitespaces)
                name = String(name.dropLast(pattern.count))
                break
            }
        }

        return (name.trimmingCharacters(in: .whitespaces), variant)
    }

    private static func findStockInfo(_ stockName: String) -> (iso: Int?, warmth: FilterPreset.FilterMetadata.WarmthLevel, contrast: FilterPreset.FilterMetadata.ContrastLevel, filmType: FilterPreset.FilterMetadata.FilmType)? {
        // Direct match
        if let info = filmStockInfo[stockName] {
            return info
        }

        // Partial match
        for (key, info) in filmStockInfo {
            if stockName.contains(key) || key.contains(stockName) {
                return info
            }
        }

        return nil
    }

    private static func buildDisplayName(
        brand: String,
        stockName: String,
        variant: String,
        filename: String
    ) -> String {
        if stockName.isEmpty {
            return filename
        }

        var name = "\(brand) \(stockName)"
        if !variant.isEmpty && variant != "2" {
            // Add variant indicator for non-default versions
            switch variant {
            case "1 -", "1 --": name += " (Light)"
            case "3 +", "4 +": name += " (Strong)"
            case "4 ++", "5 ++", "6 +++": name += " (Intense)"
            case "HC": name += " (High Contrast)"
            case "Negative": name += " (Negative)"
            case "3 Alt": name += " (Alt)"
            default: break
            }
        }

        return name
    }

    private static func determineEra(brand: String, stockName: String) -> String? {
        // Determine approximate era based on film stock
        if stockName.contains("Vision3") {
            return "2000s-present"
        } else if stockName.contains("Portra") {
            return "1990s-present"
        } else if stockName.contains("Velvia") || stockName.contains("Provia") {
            return "1990s-present"
        } else if stockName.contains("Tri-X") || stockName.contains("TRI-X") {
            return "1954-present"
        } else if stockName.contains("HP5") || stockName.contains("Delta") {
            return "1980s-present"
        } else if brand == "Polaroid" {
            return "1970s-2000s"
        }
        return nil
    }

    private static func buildCharacteristics(
        brandInfo: BrandInfo?,
        isBlackAndWhite: Bool,
        variant: String
    ) -> [String] {
        var chars = brandInfo?.characteristics ?? []

        if isBlackAndWhite {
            chars.append("monochrome")
        }

        // Add variant-specific characteristics
        switch variant {
        case "HC", "4 ++", "5 ++", "6 +++":
            chars.append("high-contrast")
        case "1 -", "1 --":
            chars.append("subtle")
        case "Negative":
            chars.append("inverted-tones")
        default:
            break
        }

        return chars
    }

    private static func stableUUID(from string: String) -> String {
        // Generate a stable UUID-like string from the path
        var hasher = Hasher()
        hasher.combine(string)
        let hash = hasher.finalize()

        // Format as UUID string
        let hex = String(format: "%016llx%016llx",
                        UInt64(bitPattern: Int64(hash)),
                        UInt64(bitPattern: Int64(hash >> 32)))

        let start = hex.startIndex
        let p1 = hex.index(start, offsetBy: 8)
        let p2 = hex.index(start, offsetBy: 12)
        let p3 = hex.index(start, offsetBy: 16)
        let p4 = hex.index(start, offsetBy: 20)

        return "\(hex[start..<p1])-\(hex[p1..<p2])-\(hex[p2..<p3])-\(hex[p3..<p4])-\(hex[p4...])"
    }
}

// MARK: - Catalog Loader

@available(iOS 17.0, *)
actor FilmSimulationCatalogLoader {

    private var cachedPresets: [FilterPreset]?

    /// Load all film simulation presets
    func loadPresets() async -> [FilterPreset] {
        if let cached = cachedPresets {
            return cached
        }

        // Find the HaldCLUT directory
        guard let baseURL = findHaldCLUTDirectory() else {
            return []
        }

        let presets = FilmSimulationCatalog.generatePresets(from: baseURL)
        cachedPresets = presets

        return presets
    }

    /// Get presets filtered by category
    func presets(for category: FilterCategory) async -> [FilterPreset] {
        let all = await loadPresets()
        return all.filter { $0.category == category }
    }

    /// Get presets filtered by brand
    func presets(forBrand brand: String) async -> [FilterPreset] {
        let all = await loadPresets()
        return all.filter { $0.metadata.brand == brand }
    }

    /// Get presets filtered by warmth
    func presets(withWarmth warmth: FilterPreset.FilterMetadata.WarmthLevel) async -> [FilterPreset] {
        let all = await loadPresets()
        return all.filter { $0.metadata.warmth == warmth }
    }

    /// Search presets by name
    func searchPresets(query: String) async -> [FilterPreset] {
        let all = await loadPresets()
        let lowercased = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(lowercased) ||
            ($0.metadata.filmStock?.lowercased().contains(lowercased) ?? false) ||
            ($0.metadata.brand?.lowercased().contains(lowercased) ?? false)
        }
    }

    /// Clear cached presets
    func clearCache() {
        cachedPresets = nil
    }

    private func findHaldCLUTDirectory() -> URL? {
        // Check bundle first
        if let bundleURL = Bundle.main.url(forResource: "HaldCLUT", withExtension: nil) {
            return bundleURL
        }

        // Check for development path
        let devPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hald-clut-master")
            .appendingPathComponent("HaldCLUT")

        if FileManager.default.fileExists(atPath: devPath.path) {
            return devPath
        }

        return nil
    }
}
