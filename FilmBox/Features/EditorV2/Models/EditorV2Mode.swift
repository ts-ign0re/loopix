import Foundation

/// Represents the current mode of the EditorV2 interface
enum EditorV2Mode: Equatable, Sendable {
    /// Default browsing mode - selecting filters, viewing tools
    case browse

    /// Detailed filter adjustment mode with intensity slider and sub-parameters
    case filterDetail

    /// Tool adjustment mode with full-screen slider
    case toolDetail(ToolDefinition)

    /// Whether the tab bar should be visible in this mode
    var showTabBar: Bool {
        switch self {
        case .browse:
            return true
        case .filterDetail, .toolDetail:
            return false
        }
    }

    /// Whether the navigation bar (header) should be visible in this mode
    var showNavigationBar: Bool {
        switch self {
        case .browse, .filterDetail:
            return true
        case .toolDetail:
            return false
        }
    }

    /// Whether the histogram overlay should be visible
    var showHistogram: Bool {
        true // Always show histogram in VSCO style
    }

    static func == (lhs: EditorV2Mode, rhs: EditorV2Mode) -> Bool {
        switch (lhs, rhs) {
        case (.browse, .browse):
            return true
        case (.filterDetail, .filterDetail):
            return true
        case (.toolDetail(let lhsTool), .toolDetail(let rhsTool)):
            return lhsTool.id == rhsTool.id
        default:
            return false
        }
    }
}
