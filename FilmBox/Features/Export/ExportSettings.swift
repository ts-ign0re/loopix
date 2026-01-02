import Foundation

// MARK: - Export Format

/// Supported export image formats
enum ExportFormat: String, CaseIterable, Codable, Sendable {
    case jpeg = "JPEG"
    case png = "PNG"
    case webp = "WebP"

    /// Display name with recommendation hint
    var displayName: String {
        switch self {
        case .jpeg: return "JPEG (Recommended)"
        case .png: return "PNG"
        case .webp: return "WebP"
        }
    }

    /// File extension for the format
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .webp: return "webp"
        }
    }

    /// UTType identifier for the format
    var utType: String {
        switch self {
        case .jpeg: return "public.jpeg"
        case .png: return "public.png"
        case .webp: return "org.webmproject.webp"
        }
    }

    /// Whether the format supports quality compression
    var supportsQuality: Bool {
        switch self {
        case .jpeg, .webp: return true
        case .png: return false
        }
    }

    /// Whether this format is available on the current iOS version
    var isAvailable: Bool {
        switch self {
        case .webp:
            if #available(iOS 14.0, *) {
                return true
            }
            return false
        default:
            return true
        }
    }
}

// MARK: - Export Size

/// Predefined export size options
enum ExportSize: String, CaseIterable, Codable, Sendable {
    case original = "Original"
    case large = "Large"
    case medium = "Medium"
    case small = "Small"

    /// Display name with pixel dimensions
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .large: return "Large (3000px)"
        case .medium: return "Medium (2000px)"
        case .small: return "Small (1200px)"
        }
    }

    /// Maximum dimension in pixels (nil for original)
    var maxDimension: Int? {
        switch self {
        case .original: return nil
        case .large: return 3000
        case .medium: return 2000
        case .small: return 1200
        }
    }
}

// MARK: - Export Destination

/// Export destination options
enum ExportDestination: String, CaseIterable, Codable, Sendable {
    case photoLibrary = "Photo Library"
    case files = "Files"
    case share = "Share"

    /// SF Symbol name for the destination
    var iconName: String {
        switch self {
        case .photoLibrary: return "photo.on.rectangle"
        case .files: return "folder"
        case .share: return "square.and.arrow.up"
        }
    }
}

// MARK: - Export Settings

/// Complete export configuration
struct ExportSettings: Codable, Sendable, Equatable {
    /// Output image format
    var format: ExportFormat

    /// Quality level (0.0 to 1.0, applies to JPEG/WebP)
    var quality: Double

    /// Size/dimension option
    var size: ExportSize

    /// Maximum dimension in pixels (computed from size, or custom)
    var maxDimension: Int? {
        size.maxDimension
    }

    /// Whether to preserve EXIF metadata
    var preserveEXIF: Bool

    /// Whether to include location data in metadata
    var includeLocation: Bool

    /// Export destination
    var destination: ExportDestination

    /// Quality as percentage (0-100) for UI display
    var qualityPercentage: Int {
        get { Int(quality * 100) }
        set { quality = Double(newValue) / 100.0 }
    }

    /// Default export settings
    static let `default` = ExportSettings(
        format: .jpeg,
        quality: 0.95,
        size: .original,
        preserveEXIF: true,
        includeLocation: true,
        destination: .photoLibrary
    )

    init(
        format: ExportFormat = .jpeg,
        quality: Double = 0.9,
        size: ExportSize = .original,
        preserveEXIF: Bool = true,
        includeLocation: Bool = true,
        destination: ExportDestination = .photoLibrary
    ) {
        self.format = format
        self.quality = max(0, min(1, quality))
        self.size = size
        self.preserveEXIF = preserveEXIF
        self.includeLocation = includeLocation
        self.destination = destination
    }
}

// MARK: - UserDefaults Persistence

extension ExportSettings {
    private static let userDefaultsKey = "com.filmbox.exportSettings"

    /// Load saved settings from UserDefaults
    static func loadFromUserDefaults() -> ExportSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(ExportSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    /// Save settings to UserDefaults
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }

    /// Reset to default settings
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
