import Foundation

/// Filter categories for organizing presets in the UI
enum FilterCategory: String, Codable, CaseIterable, Sendable {
    case favorites = "favourites"
    case custom = "my"
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

    var displayName: String { rawValue }

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
        }
    }

    /// Whether this category should show an icon instead of text
    var showAsIcon: Bool {
        self == .favorites
    }
}
