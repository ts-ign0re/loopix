import Foundation
import SwiftUI

/// Available tabs in the VSCO-style editor interface
enum EditorV2Tab: String, CaseIterable, Identifiable, Sendable {
    case filters
    case light
    case crop
    case effects

    var id: String { rawValue }

    /// SF Symbol icon name for the tab
    var iconName: String {
        switch self {
        case .filters:
            return "square.stack"
        case .light:
            return "sun.max"
        case .crop:
            return "crop"
        case .effects:
            return "sparkles"
        }
    }

    /// Display name for accessibility
    var displayName: String {
        switch self {
        case .filters:
            return "Filters"
        case .light:
            return "Light"
        case .crop:
            return "Crop"
        case .effects:
            return "Effects"
        }
    }
}
