import Foundation

/// Filter categories for organizing presets in the UI
enum FilterCategory: String, Codable, CaseIterable, Sendable {
    case all = "FILTERS"
    case cool = "COOL"
    case warm = "WARM"
    case pro = "PRO"
    case portrait = "PORTRAIT"
    case urban = "URBAN"
    case film = "FILM"
    case bw = "B&W"
    case vintage = "VINTAGE"
    case creative = "CREATIVE"
    case custom = "MY FILTERS"

    var displayName: String { rawValue }

    /// Icon name for the category (SF Symbols)
    var iconName: String {
        switch self {
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
        case .custom: return "star"
        }
    }
}
