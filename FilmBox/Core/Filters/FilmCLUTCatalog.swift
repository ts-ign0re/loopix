import Foundation

/// Catalog of all available HALD CLUT film simulation presets
/// Auto-generated from hald-clut-master directory
struct FilmCLUTCatalog {

    // MARK: - Types

    /// Film brand/manufacturer
    enum Brand: String, Codable, CaseIterable, Sendable {
        case kodak = "Kodak"
        case fuji = "Fuji"
        case ilford = "Ilford"
        case polaroid = "Polaroid"
        case agfa = "Agfa"
        case rollei = "Rollei"
        case lomography = "Lomography"
        case fujifilm = "Fujifilm"
        case apple = "Apple"
        case pixelmator = "Pixelmator"
        case pictureFX = "PictureFX"
        case creative = "Creative"
        case other = "Other"
    }

    /// Film type classification
    enum FilmType: String, Codable, CaseIterable, Sendable {
        case colorNegative = "Color Negative"
        case colorSlide = "Color Slide"
        case blackAndWhite = "Black & White"
        case instant = "Instant"
        case digital = "Digital"
        case creative = "Creative"
    }

    /// Color temperature feel
    enum Warmth: String, Codable, CaseIterable, Sendable {
        case cool
        case neutral
        case warm
    }

    /// Contrast level
    enum Contrast: String, Codable, CaseIterable, Sendable {
        case low
        case medium
        case high
    }

    /// A single CLUT entry with metadata
    struct CLUTEntry: Identifiable, Codable, Hashable, Sendable {
        let id: UUID
        let name: String
        let path: String
        let brand: Brand
        let filmType: FilmType
        let filmStock: String?
        let iso: Int?
        let warmth: Warmth
        let contrast: Contrast
        let variant: String?
        let subcategory: String?

        init(
            name: String,
            path: String,
            brand: Brand,
            filmType: FilmType,
            filmStock: String? = nil,
            iso: Int? = nil,
            warmth: Warmth = .neutral,
            contrast: Contrast = .medium,
            variant: String? = nil,
            subcategory: String? = nil
        ) {
            self.id = UUID()
            self.name = name
            self.path = path
            self.brand = brand
            self.filmType = filmType
            self.filmStock = filmStock
            self.iso = iso
            self.warmth = warmth
            self.contrast = contrast
            self.variant = variant
            self.subcategory = subcategory
        }
    }

    // MARK: - Catalog Data

    /// All available CLUT entries
    static let allEntries: [CLUTEntry] = {
        var entries: [CLUTEntry] = []

        // Apple Digital Filters (9)
        entries.append(contentsOf: appleFilters)

        // Film Simulation - Black and White
        entries.append(contentsOf: bwAgfaFilters)
        entries.append(contentsOf: bwFujiFilters)
        entries.append(contentsOf: bwIlfordFilters)
        entries.append(contentsOf: bwKodakFilters)
        entries.append(contentsOf: bwPolaroidFilters)
        entries.append(contentsOf: bwRolleiFilters)

        // Film Simulation - Color
        entries.append(contentsOf: colorAgfaFilters)
        entries.append(contentsOf: colorFujiFilters)
        entries.append(contentsOf: colorKodakFilters)
        entries.append(contentsOf: colorLomographyFilters)
        entries.append(contentsOf: colorPolaroidFilters)
        entries.append(contentsOf: creativePackFilters)

        // Digital Camera Simulations
        entries.append(contentsOf: fujiXTransFilters)

        // PictureFX Effects
        entries.append(contentsOf: pictureFXFilters)

        // Pixelmator Pro
        entries.append(contentsOf: pixelmatorFilters)

        return entries
    }()

    // MARK: - Apple Filters

    private static let appleFilters: [CLUTEntry] = [
        CLUTEntry(name: "Apple Black", path: "HaldCLUT/Apple/Apple Black.png", brand: .apple, filmType: .digital, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Apple Intense", path: "HaldCLUT/Apple/Apple Intense.png", brand: .apple, filmType: .digital, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Apple Intense Cold", path: "HaldCLUT/Apple/Apple Intense Cold.png", brand: .apple, filmType: .digital, warmth: .cool, contrast: .high),
        CLUTEntry(name: "Apple Intense Warm", path: "HaldCLUT/Apple/Apple Intense Warm.png", brand: .apple, filmType: .digital, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Apple Mono", path: "HaldCLUT/Apple/Apple Mono.png", brand: .apple, filmType: .blackAndWhite, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Apple Silver", path: "HaldCLUT/Apple/Apple Silver.png", brand: .apple, filmType: .blackAndWhite, warmth: .cool, contrast: .medium),
        CLUTEntry(name: "Apple Spectacular", path: "HaldCLUT/Apple/Apple Spectacular.png", brand: .apple, filmType: .digital, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Apple Spectacular Cold", path: "HaldCLUT/Apple/Apple Spectacular Cold.png", brand: .apple, filmType: .digital, warmth: .cool, contrast: .high),
        CLUTEntry(name: "Apple Spectacular Warm", path: "HaldCLUT/Apple/Apple Spectacular Warm.png", brand: .apple, filmType: .digital, warmth: .warm, contrast: .high),
    ]

    // MARK: - B&W Agfa

    private static let bwAgfaFilters: [CLUTEntry] = [
        CLUTEntry(name: "Agfa APX 25", path: "HaldCLUT/Film Simulation/Black and White/Agfa/Agfa APX 25.png", brand: .agfa, filmType: .blackAndWhite, filmStock: "APX 25", iso: 25, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Agfa APX 100", path: "HaldCLUT/Film Simulation/Black and White/Agfa/Agfa APX 100.png", brand: .agfa, filmType: .blackAndWhite, filmStock: "APX 100", iso: 100, warmth: .neutral, contrast: .medium),
    ]

    // MARK: - B&W Fuji

    private static let bwFujiFilters: [CLUTEntry] = [
        CLUTEntry(name: "Fuji Neopan Acros 100", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji Neopan Acros 100.png", brand: .fuji, filmType: .blackAndWhite, filmStock: "Neopan Acros", iso: 100, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Fuji Neopan 1600 1 -", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji Neopan 1600 1 -.png", brand: .fuji, filmType: .blackAndWhite, filmStock: "Neopan 1600", iso: 1600, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji Neopan 1600 2", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji Neopan 1600 2.png", brand: .fuji, filmType: .blackAndWhite, filmStock: "Neopan 1600", iso: 1600, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji Neopan 1600 3 +", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji Neopan 1600 3 +.png", brand: .fuji, filmType: .blackAndWhite, filmStock: "Neopan 1600", iso: 1600, warmth: .neutral, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji Neopan 1600 4 ++", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji Neopan 1600 4 ++.png", brand: .fuji, filmType: .blackAndWhite, filmStock: "Neopan 1600", iso: 1600, warmth: .neutral, contrast: .high, variant: "4 ++"),
        CLUTEntry(name: "Fuji FP-3000b 1 --", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b 1 --.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Fuji FP-3000b 2 -", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b 2 -.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Fuji FP-3000b 3", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b 3.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Fuji FP-3000b 4 +", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b 4 +.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Fuji FP-3000b 5 ++", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b 5 ++.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Fuji FP-3000b 6 +++", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b 6 +++.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .high, variant: "6 +++"),
        CLUTEntry(name: "Fuji FP-3000b HC", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b HC.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b", iso: 3000, warmth: .neutral, contrast: .high, variant: "HC"),
        CLUTEntry(name: "Fuji FP-3000b Negative 1 --", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative 1 --.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .neutral, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Fuji FP-3000b Negative 2 -", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative 2 -.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .neutral, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Fuji FP-3000b Negative 3", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative 3.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .neutral, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Fuji FP-3000b Negative 4 +", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative 4 +.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .neutral, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Fuji FP-3000b Negative 5 ++", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative 5 ++.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .neutral, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Fuji FP-3000b Negative 6 +++", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative 6 +++.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .neutral, contrast: .high, variant: "6 +++"),
        CLUTEntry(name: "Fuji FP-3000b Negative Early", path: "HaldCLUT/Film Simulation/Black and White/Fuji/Fuji FP-3000b Negative Early.png", brand: .fuji, filmType: .instant, filmStock: "FP-3000b Negative", iso: 3000, warmth: .warm, contrast: .medium, variant: "Early"),
    ]

    // MARK: - B&W Ilford

    private static let bwIlfordFilters: [CLUTEntry] = [
        CLUTEntry(name: "Ilford Delta 100", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Delta 100.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Delta 100", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Ilford Delta 400", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Delta 400.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Delta 400", iso: 400, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Ilford Delta 3200 1 -", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Delta 3200 1 -.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Delta 3200", iso: 3200, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Ilford Delta 3200 2", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Delta 3200 2.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Delta 3200", iso: 3200, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Ilford Delta 3200 3 +", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Delta 3200 3 +.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Delta 3200", iso: 3200, warmth: .neutral, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Ilford Delta 3200 4 ++", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Delta 3200 4 ++.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Delta 3200", iso: 3200, warmth: .neutral, contrast: .high, variant: "4 ++"),
        CLUTEntry(name: "Ilford FP4 Plus 125", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford FP4 Plus 125.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "FP4 Plus", iso: 125, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Ilford HP5 Plus 400", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford HP5 Plus 400.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "HP5 Plus", iso: 400, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Ilford HP5 1 -", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford HP5 1 -.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "HP5", iso: 400, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Ilford HP5 2", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford HP5 2.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "HP5", iso: 400, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Ilford HP5 3 +", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford HP5 3 +.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "HP5", iso: 400, warmth: .neutral, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Ilford HP5 4 ++", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford HP5 4 ++.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "HP5", iso: 400, warmth: .neutral, contrast: .high, variant: "4 ++"),
        CLUTEntry(name: "Ilford HPS 800", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford HPS 800.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "HPS", iso: 800, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Ilford Pan F Plus 50", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford Pan F Plus 50.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "Pan F Plus", iso: 50, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Ilford XP2", path: "HaldCLUT/Film Simulation/Black and White/Ilford/Ilford XP2.png", brand: .ilford, filmType: .blackAndWhite, filmStock: "XP2", iso: 400, warmth: .neutral, contrast: .medium),
    ]

    // MARK: - B&W Kodak

    private static let bwKodakFilters: [CLUTEntry] = [
        CLUTEntry(name: "Kodak BW 400 CN", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak BW 400 CN.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "BW 400 CN", iso: 400, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Kodak HIE (HS Infra)", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak HIE (HS Infra).png", brand: .kodak, filmType: .blackAndWhite, filmStock: "HIE Infrared", iso: 400, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Kodak T-Max 100", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak T-Max 100.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 100", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Kodak T-Max 400", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak T-Max 400.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 400", iso: 400, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Kodak TMAX 3200 1 -", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TMAX 3200 1 -.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 3200", iso: 3200, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak TMAX 3200 2", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TMAX 3200 2.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 3200", iso: 3200, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak TMAX 3200 3 Alt", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TMAX 3200 3 Alt.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 3200", iso: 3200, warmth: .neutral, contrast: .medium, variant: "3 Alt"),
        CLUTEntry(name: "Kodak TMAX 3200 4 +", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TMAX 3200 4 +.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 3200", iso: 3200, warmth: .neutral, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Kodak TMAX 3200 5 ++", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TMAX 3200 5 ++.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "T-Max 3200", iso: 3200, warmth: .neutral, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Kodak TRI-X 400 1 -", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TRI-X 400 1 -.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "Tri-X 400", iso: 400, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak TRI-X 400 2", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TRI-X 400 2.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "Tri-X 400", iso: 400, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak TRI-X 400 3 Alt", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TRI-X 400 3 Alt.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "Tri-X 400", iso: 400, warmth: .neutral, contrast: .medium, variant: "3 Alt"),
        CLUTEntry(name: "Kodak TRI-X 400 4 +", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TRI-X 400 4 +.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "Tri-X 400", iso: 400, warmth: .neutral, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Kodak TRI-X 400 5 ++", path: "HaldCLUT/Film Simulation/Black and White/Kodak/Kodak TRI-X 400 5 ++.png", brand: .kodak, filmType: .blackAndWhite, filmStock: "Tri-X 400", iso: 400, warmth: .neutral, contrast: .high, variant: "5 ++"),
    ]

    // MARK: - B&W Polaroid

    private static let bwPolaroidFilters: [CLUTEntry] = [
        CLUTEntry(name: "Polaroid 664", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 664.png", brand: .polaroid, filmType: .instant, filmStock: "664", warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Polaroid 665 1 --", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "665", warmth: .neutral, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid 665 2 -", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "665", warmth: .neutral, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid 665 3", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 3.png", brand: .polaroid, filmType: .instant, filmStock: "665", warmth: .neutral, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid 665 4 +", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "665", warmth: .neutral, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid 665 5 ++", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "665", warmth: .neutral, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Polaroid 665 Negative 1 -", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 Negative 1 -.png", brand: .polaroid, filmType: .instant, filmStock: "665 Negative", warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Polaroid 665 Negative 2", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 Negative 2.png", brand: .polaroid, filmType: .instant, filmStock: "665 Negative", warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Polaroid 665 Negative 3 +", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 Negative 3 +.png", brand: .polaroid, filmType: .instant, filmStock: "665 Negative", warmth: .neutral, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Polaroid 665 Negative HC", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 665 Negative HC.png", brand: .polaroid, filmType: .instant, filmStock: "665 Negative", warmth: .neutral, contrast: .high, variant: "HC"),
        CLUTEntry(name: "Polaroid 667", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 667.png", brand: .polaroid, filmType: .instant, filmStock: "667", warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Polaroid 672", path: "HaldCLUT/Film Simulation/Black and White/Polaroid/Polaroid 672.png", brand: .polaroid, filmType: .instant, filmStock: "672", warmth: .neutral, contrast: .medium),
    ]

    // MARK: - B&W Rollei

    private static let bwRolleiFilters: [CLUTEntry] = [
        CLUTEntry(name: "Rollei IR 400", path: "HaldCLUT/Film Simulation/Black and White/Rollei/Rollei IR 400.png", brand: .rollei, filmType: .blackAndWhite, filmStock: "IR 400", iso: 400, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Rollei Ortho 25", path: "HaldCLUT/Film Simulation/Black and White/Rollei/Rollei Ortho 25.png", brand: .rollei, filmType: .blackAndWhite, filmStock: "Ortho 25", iso: 25, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Rollei Retro 100 Tonal", path: "HaldCLUT/Film Simulation/Black and White/Rollei/Rollei Retro 100 Tonal.png", brand: .rollei, filmType: .blackAndWhite, filmStock: "Retro 100 Tonal", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Rollei Retro 80s", path: "HaldCLUT/Film Simulation/Black and White/Rollei/Rollei Retro 80s.png", brand: .rollei, filmType: .blackAndWhite, filmStock: "Retro 80s", iso: 80, warmth: .neutral, contrast: .medium),
    ]

    // MARK: - Color Agfa

    private static let colorAgfaFilters: [CLUTEntry] = [
        CLUTEntry(name: "Agfa Precisa 100", path: "HaldCLUT/Film Simulation/Color/Agfa/Agfa Precisa 100.png", brand: .agfa, filmType: .colorSlide, filmStock: "Precisa 100", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Agfa Ultra Color 100", path: "HaldCLUT/Film Simulation/Color/Agfa/Agfa Ultra Color 100.png", brand: .agfa, filmType: .colorNegative, filmStock: "Ultra Color 100", iso: 100, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Agfa Vista 200", path: "HaldCLUT/Film Simulation/Color/Agfa/Agfa Vista 200.png", brand: .agfa, filmType: .colorNegative, filmStock: "Vista 200", iso: 200, warmth: .warm, contrast: .medium),
    ]

    // MARK: - Color Fuji (62 entries)

    private static let colorFujiFilters: [CLUTEntry] = [
        // Pro 160C
        CLUTEntry(name: "Fuji 160C 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 160C 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 160C", iso: 160, warmth: .cool, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji 160C 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 160C 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 160C", iso: 160, warmth: .cool, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji 160C 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 160C 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 160C", iso: 160, warmth: .cool, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji 160C 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 160C 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 160C", iso: 160, warmth: .cool, contrast: .high, variant: "4 ++"),

        // Pro 400H
        CLUTEntry(name: "Fuji 400H 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 400H 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 400H", iso: 400, warmth: .cool, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji 400H 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 400H 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 400H", iso: 400, warmth: .cool, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji 400H 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 400H 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 400H", iso: 400, warmth: .cool, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji 400H 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 400H 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 400H", iso: 400, warmth: .cool, contrast: .high, variant: "4 ++"),

        // Pro 800Z
        CLUTEntry(name: "Fuji 800Z 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 800Z 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 800Z", iso: 800, warmth: .cool, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji 800Z 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 800Z 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 800Z", iso: 800, warmth: .cool, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji 800Z 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 800Z 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 800Z", iso: 800, warmth: .cool, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji 800Z 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji 800Z 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Pro 800Z", iso: 800, warmth: .cool, contrast: .high, variant: "4 ++"),

        // FP-100c (Instant Color)
        CLUTEntry(name: "Fuji FP-100c 1 --", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 1 --.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Fuji FP-100c 2 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 2 -.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Fuji FP-100c 3", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 3.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Fuji FP-100c 4 Alt", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 4 Alt.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .medium, variant: "4 Alt"),
        CLUTEntry(name: "Fuji FP-100c 5 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 5 +.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .high, variant: "5 +"),
        CLUTEntry(name: "Fuji FP-100c 6 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 6 ++.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .high, variant: "6 ++"),
        CLUTEntry(name: "Fuji FP-100c 7 ++ Alt", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 7 ++ Alt.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .high, variant: "7 ++ Alt"),
        CLUTEntry(name: "Fuji FP-100c 8 +++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c 8 +++.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c", iso: 100, warmth: .warm, contrast: .high, variant: "8 +++"),

        // FP-100c Cool
        CLUTEntry(name: "Fuji FP-100c Cool 1 --", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Cool 1 --.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Cool", iso: 100, warmth: .cool, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Fuji FP-100c Cool 2 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Cool 2 -.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Cool", iso: 100, warmth: .cool, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Fuji FP-100c Cool 3", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Cool 3.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Cool", iso: 100, warmth: .cool, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Fuji FP-100c Cool 4 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Cool 4 +.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Cool", iso: 100, warmth: .cool, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Fuji FP-100c Cool 5 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Cool 5 ++.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Cool", iso: 100, warmth: .cool, contrast: .high, variant: "5 ++"),

        // FP-100c Negative
        CLUTEntry(name: "Fuji FP-100c Negative 1 --", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 1 --.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Fuji FP-100c Negative 2 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 2 -.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Fuji FP-100c Negative 3", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 3.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Fuji FP-100c Negative 4 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 4 +.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Fuji FP-100c Negative 5 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 5 ++.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Fuji FP-100c Negative 6 ++ Alt", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 6 ++ Alt.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .high, variant: "6 ++ Alt"),
        CLUTEntry(name: "Fuji FP-100c Negative 7 +++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji FP-100c Negative 7 +++.png", brand: .fuji, filmType: .instant, filmStock: "FP-100c Negative", iso: 100, warmth: .neutral, contrast: .high, variant: "7 +++"),

        // Velvia
        CLUTEntry(name: "Fuji Velvia 50", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Velvia 50.png", brand: .fuji, filmType: .colorSlide, filmStock: "Velvia 50", iso: 50, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Fuji Velvia 100 Generic", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Velvia 100 Generic.png", brand: .fuji, filmType: .colorSlide, filmStock: "Velvia 100", iso: 100, warmth: .warm, contrast: .high),

        // Provia
        CLUTEntry(name: "Fuji Provia 100 Generic", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Provia 100 Generic.png", brand: .fuji, filmType: .colorSlide, filmStock: "Provia 100", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji Provia 100F", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Provia 100F.png", brand: .fuji, filmType: .colorSlide, filmStock: "Provia 100F", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji Provia 400F", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Provia 400F.png", brand: .fuji, filmType: .colorSlide, filmStock: "Provia 400F", iso: 400, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji Provia 400X", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Provia 400X.png", brand: .fuji, filmType: .colorSlide, filmStock: "Provia 400X", iso: 400, warmth: .neutral, contrast: .medium),

        // Astia
        CLUTEntry(name: "Fuji Astia 100 Generic", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Astia 100 Generic.png", brand: .fuji, filmType: .colorSlide, filmStock: "Astia 100", iso: 100, warmth: .neutral, contrast: .low),
        CLUTEntry(name: "Fuji Astia 100F", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Astia 100F.png", brand: .fuji, filmType: .colorSlide, filmStock: "Astia 100F", iso: 100, warmth: .neutral, contrast: .low),

        // Sensia
        CLUTEntry(name: "Fuji Sensia 100", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Sensia 100.png", brand: .fuji, filmType: .colorSlide, filmStock: "Sensia 100", iso: 100, warmth: .neutral, contrast: .medium),

        // Superia 100
        CLUTEntry(name: "Fuji Superia 100 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 100 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 100", iso: 100, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji Superia 100 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 100 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 100", iso: 100, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji Superia 100 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 100 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 100", iso: 100, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji Superia 100 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 100 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 100", iso: 100, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Superia 200
        CLUTEntry(name: "Fuji Superia 200", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 200.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 200", iso: 200, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Fuji Superia 200 XPRO", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 200 XPRO.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 200 XPRO", iso: 200, warmth: .warm, contrast: .high),

        // Superia 400
        CLUTEntry(name: "Fuji Superia 400 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 400 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 400", iso: 400, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji Superia 400 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 400 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 400", iso: 400, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji Superia 400 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 400 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 400", iso: 400, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji Superia 400 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 400 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 400", iso: 400, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Superia 800
        CLUTEntry(name: "Fuji Superia 800 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 800 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 800", iso: 800, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji Superia 800 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 800 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 800", iso: 800, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji Superia 800 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 800 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 800", iso: 800, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji Superia 800 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 800 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 800", iso: 800, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Superia 1600
        CLUTEntry(name: "Fuji Superia 1600 1 -", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 1600 1 -.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 1600", iso: 1600, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Fuji Superia 1600 2", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 1600 2.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 1600", iso: 1600, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Fuji Superia 1600 3 +", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 1600 3 +.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 1600", iso: 1600, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Fuji Superia 1600 4 ++", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia 1600 4 ++.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia 1600", iso: 1600, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Superia HG / Reala / X-Tra
        CLUTEntry(name: "Fuji Superia HG 1600", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia HG 1600.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia HG 1600", iso: 1600, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Fuji Superia Reala 100", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia Reala 100.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia Reala 100", iso: 100, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji Superia X-Tra 800", path: "HaldCLUT/Film Simulation/Color/Fuji/Fuji Superia X-Tra 800.png", brand: .fuji, filmType: .colorNegative, filmStock: "Superia X-Tra 800", iso: 800, warmth: .warm, contrast: .medium),
    ]

    // MARK: - Color Kodak (47 entries)

    private static let colorKodakFilters: [CLUTEntry] = [
        // Portra 160
        CLUTEntry(name: "Kodak Portra 160 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160", iso: 160, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 160 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160", iso: 160, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 160 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160", iso: 160, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 160 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160", iso: 160, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Portra 160 NC (Natural Color)
        CLUTEntry(name: "Kodak Portra 160 NC 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 NC 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 NC", iso: 160, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 160 NC 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 NC 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 NC", iso: 160, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 160 NC 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 NC 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 NC", iso: 160, warmth: .neutral, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 160 NC 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 NC 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 NC", iso: 160, warmth: .neutral, contrast: .high, variant: "4 ++"),

        // Portra 160 VC (Vivid Color)
        CLUTEntry(name: "Kodak Portra 160 VC 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 VC 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 VC", iso: 160, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 160 VC 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 VC 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 VC", iso: 160, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 160 VC 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 VC 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 VC", iso: 160, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 160 VC 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 160 VC 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 160 VC", iso: 160, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Portra 400
        CLUTEntry(name: "Kodak Portra 400 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400", iso: 400, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 400 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400", iso: 400, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 400 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400", iso: 400, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 400 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400", iso: 400, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Portra 400 NC
        CLUTEntry(name: "Kodak Portra 400 NC 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 NC 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 NC", iso: 400, warmth: .neutral, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 400 NC 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 NC 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 NC", iso: 400, warmth: .neutral, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 400 NC 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 NC 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 NC", iso: 400, warmth: .neutral, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 400 NC 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 NC 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 NC", iso: 400, warmth: .neutral, contrast: .high, variant: "4 ++"),

        // Portra 400 UC (Ultra Color)
        CLUTEntry(name: "Kodak Portra 400 UC 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 UC 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 UC", iso: 400, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 400 UC 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 UC 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 UC", iso: 400, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 400 UC 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 UC 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 UC", iso: 400, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 400 UC 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 UC 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 UC", iso: 400, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Portra 400 VC
        CLUTEntry(name: "Kodak Portra 400 VC 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 VC 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 VC", iso: 400, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 400 VC 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 VC 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 VC", iso: 400, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 400 VC 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 VC 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 VC", iso: 400, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 400 VC 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 400 VC 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 400 VC", iso: 400, warmth: .warm, contrast: .high, variant: "4 ++"),

        // Portra 800
        CLUTEntry(name: "Kodak Portra 800 1 -", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 800 1 -.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 800", iso: 800, warmth: .warm, contrast: .low, variant: "1 -"),
        CLUTEntry(name: "Kodak Portra 800 2", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 800 2.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 800", iso: 800, warmth: .warm, contrast: .medium, variant: "2"),
        CLUTEntry(name: "Kodak Portra 800 3 +", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 800 3 +.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 800", iso: 800, warmth: .warm, contrast: .high, variant: "3 +"),
        CLUTEntry(name: "Kodak Portra 800 4 ++", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 800 4 ++.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 800", iso: 800, warmth: .warm, contrast: .high, variant: "4 ++"),
        CLUTEntry(name: "Kodak Portra 800 HC", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Portra 800 HC.png", brand: .kodak, filmType: .colorNegative, filmStock: "Portra 800", iso: 800, warmth: .warm, contrast: .high, variant: "HC"),

        // Ektar
        CLUTEntry(name: "Kodak Ektar 100", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Ektar 100.png", brand: .kodak, filmType: .colorNegative, filmStock: "Ektar 100", iso: 100, warmth: .neutral, contrast: .high),

        // Ektachrome
        CLUTEntry(name: "Kodak Ektachrome 100 VS", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Ektachrome 100 VS.png", brand: .kodak, filmType: .colorSlide, filmStock: "Ektachrome 100 VS", iso: 100, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Kodak Ektachrome 100 VS Generic", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Ektachrome 100 VS Generic.png", brand: .kodak, filmType: .colorSlide, filmStock: "Ektachrome 100 VS", iso: 100, warmth: .neutral, contrast: .high, variant: "Generic"),
        CLUTEntry(name: "Kodak E-100 GX Ektachrome 100", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak E-100 GX Ektachrome 100.png", brand: .kodak, filmType: .colorSlide, filmStock: "E-100 GX", iso: 100, warmth: .neutral, contrast: .medium),

        // Kodachrome
        CLUTEntry(name: "Kodak Kodachrome 25", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Kodachrome 25.png", brand: .kodak, filmType: .colorSlide, filmStock: "Kodachrome 25", iso: 25, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Kodak Kodachrome 64", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Kodachrome 64.png", brand: .kodak, filmType: .colorSlide, filmStock: "Kodachrome 64", iso: 64, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Kodak Kodachrome 64 Generic", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Kodachrome 64 Generic.png", brand: .kodak, filmType: .colorSlide, filmStock: "Kodachrome 64", iso: 64, warmth: .warm, contrast: .high, variant: "Generic"),
        CLUTEntry(name: "Kodak Kodachrome 200", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Kodachrome 200.png", brand: .kodak, filmType: .colorSlide, filmStock: "Kodachrome 200", iso: 200, warmth: .warm, contrast: .high),

        // Elite series
        CLUTEntry(name: "Kodak Elite 100 XPRO", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Elite 100 XPRO.png", brand: .kodak, filmType: .colorSlide, filmStock: "Elite 100 XPRO", iso: 100, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Kodak Elite Chrome 200", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Elite Chrome 200.png", brand: .kodak, filmType: .colorSlide, filmStock: "Elite Chrome 200", iso: 200, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Kodak Elite Chrome 400", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Elite Chrome 400.png", brand: .kodak, filmType: .colorSlide, filmStock: "Elite Chrome 400", iso: 400, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Kodak Elite Color 200", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Elite Color 200.png", brand: .kodak, filmType: .colorNegative, filmStock: "Elite Color 200", iso: 200, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Kodak Elite Color 400", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Elite Color 400.png", brand: .kodak, filmType: .colorNegative, filmStock: "Elite Color 400", iso: 400, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Kodak Elite ExtraColor 100", path: "HaldCLUT/Film Simulation/Color/Kodak/Kodak Elite ExtraColor 100.png", brand: .kodak, filmType: .colorNegative, filmStock: "Elite ExtraColor 100", iso: 100, warmth: .warm, contrast: .high),
    ]

    // MARK: - Color Lomography

    private static let colorLomographyFilters: [CLUTEntry] = [
        CLUTEntry(name: "Lomography Redscale 100", path: "HaldCLUT/Film Simulation/Color/Lomography/Lomography Redscale 100.png", brand: .lomography, filmType: .colorNegative, filmStock: "Redscale 100", iso: 100, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Lomography X-Pro Slide 200", path: "HaldCLUT/Film Simulation/Color/Lomography/Lomography X-Pro Slide 200.png", brand: .lomography, filmType: .colorSlide, filmStock: "X-Pro Slide 200", iso: 200, warmth: .warm, contrast: .high),
    ]

    // MARK: - Color Polaroid (80 entries)

    private static let colorPolaroidFilters: [CLUTEntry] = [
        // 669
        CLUTEntry(name: "Polaroid 669 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "669", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid 669 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "669", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid 669 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 3.png", brand: .polaroid, filmType: .instant, filmStock: "669", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid 669 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "669", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid 669 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "669", warmth: .warm, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Polaroid 669 6 +++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 6 +++.png", brand: .polaroid, filmType: .instant, filmStock: "669", warmth: .warm, contrast: .high, variant: "6 +++"),

        // 669 Cold
        CLUTEntry(name: "Polaroid 669 Cold 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 Cold 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "669 Cold", warmth: .cool, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid 669 Cold 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 Cold 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "669 Cold", warmth: .cool, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid 669 Cold 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 Cold 3.png", brand: .polaroid, filmType: .instant, filmStock: "669 Cold", warmth: .cool, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid 669 Cold 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 669 Cold 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "669 Cold", warmth: .cool, contrast: .high, variant: "4 +"),

        // 690
        CLUTEntry(name: "Polaroid 690 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "690", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid 690 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "690", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid 690 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 3.png", brand: .polaroid, filmType: .instant, filmStock: "690", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid 690 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "690", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid 690 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "690", warmth: .warm, contrast: .high, variant: "5 ++"),

        // 690 Cold
        CLUTEntry(name: "Polaroid 690 Cold 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Cold 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "690 Cold", warmth: .cool, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid 690 Cold 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Cold 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "690 Cold", warmth: .cool, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid 690 Cold 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Cold 3.png", brand: .polaroid, filmType: .instant, filmStock: "690 Cold", warmth: .cool, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid 690 Cold 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Cold 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "690 Cold", warmth: .cool, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid 690 Cold 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Cold 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "690 Cold", warmth: .cool, contrast: .high, variant: "5 ++"),

        // 690 Warm
        CLUTEntry(name: "Polaroid 690 Warm 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Warm 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "690 Warm", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid 690 Warm 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Warm 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "690 Warm", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid 690 Warm 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Warm 3.png", brand: .polaroid, filmType: .instant, filmStock: "690 Warm", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid 690 Warm 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Warm 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "690 Warm", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid 690 Warm 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid 690 Warm 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "690 Warm", warmth: .warm, contrast: .high, variant: "5 ++"),

        // PX-70
        CLUTEntry(name: "Polaroid PX-70 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-70 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-70 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-70 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-70 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70", warmth: .warm, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Polaroid PX-70 6 +++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 6 +++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70", warmth: .warm, contrast: .high, variant: "6 +++"),

        // PX-70 Cold
        CLUTEntry(name: "Polaroid PX-70 Cold 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Cold 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Cold", warmth: .cool, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-70 Cold 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Cold 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Cold", warmth: .cool, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-70 Cold 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Cold 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Cold", warmth: .cool, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-70 Cold 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Cold 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Cold", warmth: .cool, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-70 Cold 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Cold 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Cold", warmth: .cool, contrast: .high, variant: "5 ++"),

        // PX-70 Warm
        CLUTEntry(name: "Polaroid PX-70 Warm 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Warm 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Warm", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-70 Warm 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Warm 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Warm", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-70 Warm 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Warm 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Warm", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-70 Warm 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Warm 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Warm", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-70 Warm 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-70 Warm 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-70 Warm", warmth: .warm, contrast: .high, variant: "5 ++"),

        // PX-100UV+ Cold
        CLUTEntry(name: "Polaroid PX-100UV+ Cold 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Cold 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Cold", warmth: .cool, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-100UV+ Cold 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Cold 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Cold", warmth: .cool, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-100UV+ Cold 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Cold 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Cold", warmth: .cool, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-100UV+ Cold 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Cold 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Cold", warmth: .cool, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-100UV+ Cold 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Cold 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Cold", warmth: .cool, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Polaroid PX-100UV+ Cold 6 +++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Cold 6 +++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Cold", warmth: .cool, contrast: .high, variant: "6 +++"),

        // PX-100UV+ Warm
        CLUTEntry(name: "Polaroid PX-100UV+ Warm 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Warm 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Warm", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-100UV+ Warm 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Warm 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Warm", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-100UV+ Warm 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Warm 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Warm", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-100UV+ Warm 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Warm 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Warm", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-100UV+ Warm 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Warm 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Warm", warmth: .warm, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Polaroid PX-100UV+ Warm 6 +++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-100UV+ Warm 6 +++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-100UV+ Warm", warmth: .warm, contrast: .high, variant: "6 +++"),

        // PX-680
        CLUTEntry(name: "Polaroid PX-680 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-680 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-680 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-680 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-680 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680", warmth: .warm, contrast: .high, variant: "5 ++"),

        // PX-680 Cold
        CLUTEntry(name: "Polaroid PX-680 Cold 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Cold 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Cold", warmth: .cool, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-680 Cold 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Cold 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Cold", warmth: .cool, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-680 Cold 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Cold 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Cold", warmth: .cool, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-680 Cold 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Cold 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Cold", warmth: .cool, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-680 Cold 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Cold 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Cold", warmth: .cool, contrast: .high, variant: "5 ++"),
        CLUTEntry(name: "Polaroid PX-680 Cold 6 ++ Alt", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Cold 6 ++ Alt.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Cold", warmth: .cool, contrast: .high, variant: "6 ++ Alt"),

        // PX-680 Warm
        CLUTEntry(name: "Polaroid PX-680 Warm 1 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Warm 1 --.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Warm", warmth: .warm, contrast: .low, variant: "1 --"),
        CLUTEntry(name: "Polaroid PX-680 Warm 2 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Warm 2 -.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Warm", warmth: .warm, contrast: .low, variant: "2 -"),
        CLUTEntry(name: "Polaroid PX-680 Warm 3", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Warm 3.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Warm", warmth: .warm, contrast: .medium, variant: "3"),
        CLUTEntry(name: "Polaroid PX-680 Warm 4 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Warm 4 +.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Warm", warmth: .warm, contrast: .high, variant: "4 +"),
        CLUTEntry(name: "Polaroid PX-680 Warm 5 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid PX-680 Warm 5 ++.png", brand: .polaroid, filmType: .instant, filmStock: "PX-680 Warm", warmth: .warm, contrast: .high, variant: "5 ++"),

        // Polachrome
        CLUTEntry(name: "Polaroid Polachrome", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Polachrome.png", brand: .polaroid, filmType: .instant, filmStock: "Polachrome", warmth: .neutral, contrast: .medium),

        // Time Zero (Expired)
        CLUTEntry(name: "Polaroid Time Zero (Expired) 1 ---", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) 1 ---.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired)", warmth: .warm, contrast: .low, variant: "1 ---"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) 2 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) 2 --.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired)", warmth: .warm, contrast: .low, variant: "2 --"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) 3 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) 3 -.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired)", warmth: .warm, contrast: .low, variant: "3 -"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) 4", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) 4.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired)", warmth: .warm, contrast: .medium, variant: "4"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) 5 +", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) 5 +.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired)", warmth: .warm, contrast: .high, variant: "5 +"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) 6 ++", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) 6 ++.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired)", warmth: .warm, contrast: .high, variant: "6 ++"),

        // Time Zero (Expired) Cold
        CLUTEntry(name: "Polaroid Time Zero (Expired) Cold 1 ---", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) Cold 1 ---.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired) Cold", warmth: .cool, contrast: .low, variant: "1 ---"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) Cold 2 --", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) Cold 2 --.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired) Cold", warmth: .cool, contrast: .low, variant: "2 --"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) Cold 3 -", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) Cold 3 -.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired) Cold", warmth: .cool, contrast: .low, variant: "3 -"),
        CLUTEntry(name: "Polaroid Time Zero (Expired) Cold 4", path: "HaldCLUT/Film Simulation/Color/Polaroid/Polaroid Time Zero (Expired) Cold 4.png", brand: .polaroid, filmType: .instant, filmStock: "Time Zero (Expired) Cold", warmth: .cool, contrast: .medium, variant: "4"),
    ]

    // MARK: - Creative Pack

    private static let creativePackFilters: [CLUTEntry] = [
        CLUTEntry(name: "Anime", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/Anime.png", brand: .creative, filmType: .creative, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Bleach Bypass 1", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/BleachBypass1.png", brand: .creative, filmType: .creative, warmth: .cool, contrast: .high, variant: "1"),
        CLUTEntry(name: "Bleach Bypass 2", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/BleachBypass2.png", brand: .creative, filmType: .creative, warmth: .cool, contrast: .high, variant: "2"),
        CLUTEntry(name: "Candle Light", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/CandleLight.png", brand: .creative, filmType: .creative, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Color Negative", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/ColorNegative.png", brand: .creative, filmType: .creative, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Crisp Warm", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/CrispWarm.png", brand: .creative, filmType: .creative, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Crisp Winter", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/CrispWinter.png", brand: .creative, filmType: .creative, warmth: .cool, contrast: .high),
        CLUTEntry(name: "Fall Colors", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/FallColors.png", brand: .creative, filmType: .creative, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Foggy Night", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/FoggyNight.png", brand: .creative, filmType: .creative, warmth: .cool, contrast: .low),
        CLUTEntry(name: "Horror Blue", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/HorrorBlue.png", brand: .creative, filmType: .creative, warmth: .cool, contrast: .high),
        CLUTEntry(name: "Late Sunset", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/LateSunset.png", brand: .creative, filmType: .creative, warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Moonlight", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/Moonlight.png", brand: .creative, filmType: .creative, warmth: .cool, contrast: .low),
        CLUTEntry(name: "Soft Warming", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/SoftWarming.png", brand: .creative, filmType: .creative, warmth: .warm, contrast: .low),
        CLUTEntry(name: "Teal Orange", path: "HaldCLUT/Film Simulation/Color/CreativePack-1/TealOrange.png", brand: .creative, filmType: .creative, warmth: .neutral, contrast: .high),
    ]

    // MARK: - Fujifilm XTrans III

    private static let fujiXTransFilters: [CLUTEntry] = [
        CLUTEntry(name: "Fuji XTrans III - Acros", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Acros.png", brand: .fujifilm, filmType: .blackAndWhite, filmStock: "Acros", warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Fuji XTrans III - Acros+G", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Acros+G.png", brand: .fujifilm, filmType: .blackAndWhite, filmStock: "Acros", warmth: .neutral, contrast: .high, variant: "+G"),
        CLUTEntry(name: "Fuji XTrans III - Acros+R", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Acros+R.png", brand: .fujifilm, filmType: .blackAndWhite, filmStock: "Acros", warmth: .warm, contrast: .high, variant: "+R"),
        CLUTEntry(name: "Fuji XTrans III - Acros+Ye", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Acros+Ye.png", brand: .fujifilm, filmType: .blackAndWhite, filmStock: "Acros", warmth: .warm, contrast: .high, variant: "+Ye"),
        CLUTEntry(name: "Fuji XTrans III - Astia", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Astia.png", brand: .fujifilm, filmType: .colorSlide, filmStock: "Astia", warmth: .neutral, contrast: .low),
        CLUTEntry(name: "Fuji XTrans III - Classic Chrome", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Classic Chrome.png", brand: .fujifilm, filmType: .digital, filmStock: "Classic Chrome", warmth: .cool, contrast: .medium),
        CLUTEntry(name: "Fuji XTrans III - Mono", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Mono.png", brand: .fujifilm, filmType: .blackAndWhite, filmStock: "Mono", warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji XTrans III - Pro Neg Hi", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Pro Neg Hi.png", brand: .fujifilm, filmType: .colorNegative, filmStock: "Pro Neg Hi", warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Fuji XTrans III - Pro Neg Std", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Pro Neg Std.png", brand: .fujifilm, filmType: .colorNegative, filmStock: "Pro Neg Std", warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji XTrans III - Provia", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Provia.png", brand: .fujifilm, filmType: .colorSlide, filmStock: "Provia", warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Fuji XTrans III - Sepia", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Sepia.png", brand: .fujifilm, filmType: .blackAndWhite, filmStock: "Sepia", warmth: .warm, contrast: .medium),
        CLUTEntry(name: "Fuji XTrans III - Velvia", path: "HaldCLUT/Fujifilm XTrans III/Fuji XTrans III - Velvia.png", brand: .fujifilm, filmType: .colorSlide, filmStock: "Velvia", warmth: .warm, contrast: .high),
    ]

    // MARK: - PictureFX (19 entries)

    private static let pictureFXFilters: [CLUTEntry] = [
        // AnalogFX
        CLUTEntry(name: "AnalogFX Anno 1870 Color", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Anno-1870-Color.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .medium, subcategory: "Analog"),
        CLUTEntry(name: "AnalogFX Old Style I", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Old-Style-I.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .low, subcategory: "Analog"),
        CLUTEntry(name: "AnalogFX Old Style II", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Old-Style-II.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .low, subcategory: "Analog"),
        CLUTEntry(name: "AnalogFX Old Style III", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Old-Style-III.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .medium, subcategory: "Analog"),
        CLUTEntry(name: "AnalogFX Sepia Color", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Sepia-Color.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .medium, subcategory: "Analog"),
        CLUTEntry(name: "AnalogFX Soft Sepia I", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Soft-Sepia-I.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .low, subcategory: "Analog"),
        CLUTEntry(name: "AnalogFX Soft Sepia II", path: "HaldCLUT/PictureFX/AnalogFX/AnalogFX-Soft-Sepia-II.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .low, subcategory: "Analog"),

        // GoldFX
        CLUTEntry(name: "GoldFX Bright Spring Breeze", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Bright-Spring-Breeze.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .medium, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Bright Summer Heat", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Bright-Summer-Heat.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .high, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Hot Summer Heat", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Hot-Summer-Heat.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .high, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Perfect Sunset 01min", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Perfect-Sunset-01min.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .medium, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Perfect Sunset 05min", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Perfect-Sunset-05min.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .high, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Perfect Sunset 10min", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Perfect-Sunset-10min.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .high, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Spring Breeze", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Spring-Breeze.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .low, subcategory: "Gold"),
        CLUTEntry(name: "GoldFX Summer Heat", path: "HaldCLUT/PictureFX/GoldFX/GoldFX-Summer-Heat.png", brand: .pictureFX, filmType: .creative, warmth: .warm, contrast: .medium, subcategory: "Gold"),

        // TechnicalFX
        CLUTEntry(name: "TechnicalFX Backlight Filter", path: "HaldCLUT/PictureFX/TechnicalFX/TechnicalFX-Backlight-Filter.png", brand: .pictureFX, filmType: .creative, warmth: .neutral, contrast: .medium, subcategory: "Technical"),

        // ZilverFX
        CLUTEntry(name: "ZilverFX B&W Solarization", path: "HaldCLUT/PictureFX/ZilverFX/ZilverFX-B&W-Solarization.png", brand: .pictureFX, filmType: .blackAndWhite, warmth: .neutral, contrast: .high, subcategory: "Zilver"),
        CLUTEntry(name: "ZilverFX InfraRed", path: "HaldCLUT/PictureFX/ZilverFX/ZilverFX-InfraRed.png", brand: .pictureFX, filmType: .blackAndWhite, warmth: .neutral, contrast: .high, subcategory: "Zilver"),
        CLUTEntry(name: "ZilverFX Vintage B&W", path: "HaldCLUT/PictureFX/ZilverFX/ZilverFX-Vintage-B&W.png", brand: .pictureFX, filmType: .blackAndWhite, warmth: .warm, contrast: .medium, subcategory: "Zilver"),
    ]

    // MARK: - Pixelmator Pro

    private static let pixelmatorFilters: [CLUTEntry] = [
        CLUTEntry(name: "Bright", path: "HaldCLUT/Pixelmator Pro/Bright.png", brand: .pixelmator, filmType: .digital, warmth: .neutral, contrast: .low),
        CLUTEntry(name: "Calm", path: "HaldCLUT/Pixelmator Pro/Calm.png", brand: .pixelmator, filmType: .digital, warmth: .cool, contrast: .low),
        CLUTEntry(name: "Cold", path: "HaldCLUT/Pixelmator Pro/Cold.png", brand: .pixelmator, filmType: .digital, warmth: .cool, contrast: .medium),
        CLUTEntry(name: "Dark", path: "HaldCLUT/Pixelmator Pro/Dark.png", brand: .pixelmator, filmType: .digital, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Dramatic", path: "HaldCLUT/Pixelmator Pro/Dramatic.png", brand: .pixelmator, filmType: .digital, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Flamboyant", path: "HaldCLUT/Pixelmator Pro/Flamboyant.png", brand: .pixelmator, filmType: .digital, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Intense", path: "HaldCLUT/Pixelmator Pro/Intense.png", brand: .pixelmator, filmType: .digital, warmth: .neutral, contrast: .high),
        CLUTEntry(name: "Loud", path: "HaldCLUT/Pixelmator Pro/Loud.png", brand: .pixelmator, filmType: .digital, warmth: .warm, contrast: .high),
        CLUTEntry(name: "Mono", path: "HaldCLUT/Pixelmator Pro/Mono.png", brand: .pixelmator, filmType: .blackAndWhite, warmth: .neutral, contrast: .medium),
        CLUTEntry(name: "Rosy", path: "HaldCLUT/Pixelmator Pro/Rosy.png", brand: .pixelmator, filmType: .digital, warmth: .warm, contrast: .low),
        CLUTEntry(name: "Smoky", path: "HaldCLUT/Pixelmator Pro/Smoky.png", brand: .pixelmator, filmType: .digital, warmth: .cool, contrast: .low),
        CLUTEntry(name: "Vintage", path: "HaldCLUT/Pixelmator Pro/Vintage.png", brand: .pixelmator, filmType: .digital, warmth: .warm, contrast: .low),
        CLUTEntry(name: "Warm", path: "HaldCLUT/Pixelmator Pro/Warm.png", brand: .pixelmator, filmType: .digital, warmth: .warm, contrast: .medium),
    ]

    // MARK: - Query Methods

    /// Get all entries for a specific brand
    static func entries(for brand: Brand) -> [CLUTEntry] {
        allEntries.filter { $0.brand == brand }
    }

    /// Get all entries for a specific film type
    static func entries(for filmType: FilmType) -> [CLUTEntry] {
        allEntries.filter { $0.filmType == filmType }
    }

    /// Get all entries with a specific warmth
    static func entries(withWarmth warmth: Warmth) -> [CLUTEntry] {
        allEntries.filter { $0.warmth == warmth }
    }

    /// Get all entries with a specific contrast level
    static func entries(withContrast contrast: Contrast) -> [CLUTEntry] {
        allEntries.filter { $0.contrast == contrast }
    }

    /// Search entries by name
    static func search(_ query: String) -> [CLUTEntry] {
        let lowercased = query.lowercased()
        return allEntries.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.filmStock?.lowercased().contains(lowercased) == true ||
            $0.brand.rawValue.lowercased().contains(lowercased)
        }
    }

    /// Get all unique film stocks
    static var allFilmStocks: [String] {
        Array(Set(allEntries.compactMap { $0.filmStock })).sorted()
    }

    /// Get entry count by brand
    static var countByBrand: [Brand: Int] {
        Dictionary(grouping: allEntries, by: { $0.brand })
            .mapValues { $0.count }
    }

    /// Get entry count by film type
    static var countByFilmType: [FilmType: Int] {
        Dictionary(grouping: allEntries, by: { $0.filmType })
            .mapValues { $0.count }
    }
}

// MARK: - FilterPreset Extension

extension FilterPreset {
    /// Create a FilterPreset from a CLUT catalog entry
    init(from entry: FilmCLUTCatalog.CLUTEntry, intensity: Float = 100) {
        self.init(
            name: entry.name,
            category: Self.categoryFromFilmType(entry.filmType),
            source: .haldCLUT(manufacturer: entry.brand.rawValue, filmStock: entry.filmStock ?? entry.name),
            parameters: .identity,
            metadata: FilterMetadata(
                filmStock: entry.filmStock,
                characteristics: Self.characteristicsFrom(entry),
                brand: entry.brand.rawValue,
                iso: entry.iso,
                filmType: Self.metadataFilmType(from: entry.filmType),
                warmth: Self.metadataWarmth(from: entry.warmth),
                contrast: Self.metadataContrast(from: entry.contrast)
            ),
            clutPath: entry.path,
            clutIntensity: intensity
        )
    }

    private static func categoryFromFilmType(_ type: FilmCLUTCatalog.FilmType) -> FilterCategory {
        switch type {
        case .blackAndWhite: return .bw
        case .colorNegative, .colorSlide: return .film
        case .instant: return .vintage
        case .digital: return .pro
        case .creative: return .creative
        }
    }

    private static func characteristicsFrom(_ entry: FilmCLUTCatalog.CLUTEntry) -> [String] {
        var chars: [String] = []
        chars.append(entry.warmth.rawValue)
        chars.append("\(entry.contrast.rawValue) contrast")
        if let variant = entry.variant {
            chars.append(variant)
        }
        return chars
    }

    private static func metadataFilmType(from type: FilmCLUTCatalog.FilmType) -> FilterMetadata.FilmType? {
        switch type {
        case .colorNegative: return .colorNegative
        case .colorSlide: return .colorSlide
        case .blackAndWhite: return .blackAndWhite
        case .instant: return .instant
        case .digital: return .digital
        case .creative: return nil
        }
    }

    private static func metadataWarmth(from warmth: FilmCLUTCatalog.Warmth) -> FilterMetadata.WarmthLevel? {
        switch warmth {
        case .cool: return .cool
        case .neutral: return .neutral
        case .warm: return .warm
        }
    }

    private static func metadataContrast(from contrast: FilmCLUTCatalog.Contrast) -> FilterMetadata.ContrastLevel? {
        switch contrast {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        }
    }
}
