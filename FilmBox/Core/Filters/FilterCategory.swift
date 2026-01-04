import Foundation

/// Filter categories for organizing presets in the UI
enum FilterCategory: String, Codable, CaseIterable, Sendable {
    case favorites = "favourites"
    case custom = "my"
    case fujiRecipes = "fuji"
    case all = "filters"
    case cool = "cool"
    case warm = "warm"
    case pro = "pro"
    case portrait = "portrait"
    case urban = "urban"
    case film = "film"
    case bw = "b&w"
    case vintage = "vintage"
    case creative = "creative"

    var displayName: String {
        switch self {
        case .favorites: return L10n.Category.favourites
        case .custom: return L10n.Category.my
        case .fujiRecipes: return L10n.Category.fuji
        case .all: return L10n.Category.filters
        case .cool: return L10n.Category.cool
        case .warm: return L10n.Category.warm
        case .pro: return L10n.Category.pro
        case .portrait: return L10n.Category.portrait
        case .urban: return L10n.Category.urban
        case .film: return L10n.Category.film
        case .bw: return L10n.Category.bw
        case .vintage: return L10n.Category.vintage
        case .creative: return L10n.Category.creative
        }
    }

    /// Icon name for the category (SF Symbols)
    var iconName: String {
        switch self {
        case .favorites: return "star.fill"
        case .custom: return "person.crop.circle"
        case .all: return "square.grid.2x2"
        case .cool: return "snowflake"
        case .warm: return "sun.max"
        case .pro: return "camera.aperture"
        case .portrait: return "person.crop.circle"
        case .urban: return "building.2"
        case .film: return "film"
        case .bw: return "circle.lefthalf.filled"
        case .vintage: return "clock.arrow.circlepath"
        case .creative: return "wand.and.stars"
        case .fujiRecipes: return "camera"
        }
    }

    /// Whether this category should show an icon instead of text
    var showAsIcon: Bool {
        self == .favorites
    }
}
