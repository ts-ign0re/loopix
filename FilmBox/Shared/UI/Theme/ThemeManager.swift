import SwiftUI
import Combine

// MARK: - Theme Mode

/// Available theme modes
enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Accent Color Option

/// Available accent colors for customization
enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case orange = "Orange"
    case purple = "Purple"
    case pink = "Pink"
    case green = "Green"
    case red = "Red"
    case teal = "Teal"
    case indigo = "Indigo"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .green: return .green
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    var uiColor: UIColor {
        switch self {
        case .blue: return .systemBlue
        case .orange: return .systemOrange
        case .purple: return .systemPurple
        case .pink: return .systemPink
        case .green: return .systemGreen
        case .red: return .systemRed
        case .teal: return .systemTeal
        case .indigo: return .systemIndigo
        }
    }
}

// MARK: - Theme Manager

/// Manages app-wide theming and appearance settings
@Observable
final class ThemeManager {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Published Properties

    /// Current theme mode
    var themeMode: ThemeMode = .system {
        didSet {
            saveThemeMode()
            applyTheme()
        }
    }

    /// Current accent color
    var accentColor: AccentColorOption = .orange {
        didSet {
            saveAccentColor()
            applyAccentColor()
        }
    }

    /// Whether high contrast mode is enabled
    var useHighContrast: Bool = false {
        didSet {
            saveHighContrast()
        }
    }

    /// Whether to reduce transparency
    var reduceTransparency: Bool = false {
        didSet {
            saveReduceTransparency()
        }
    }

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let themeMode = "FilmBox.themeMode"
        static let accentColor = "FilmBox.accentColor"
        static let highContrast = "FilmBox.highContrast"
        static let reduceTransparency = "FilmBox.reduceTransparency"
    }

    // MARK: - Initialization

    private init() {
        loadSettings()
        applyTheme()
    }

    // MARK: - Theme Application

    /// Apply current theme to all windows
    func applyTheme() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.compactMap { $0 as? UIWindowScene }

        for windowScene in windowScenes {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = uiInterfaceStyle
            }
        }
    }

    /// Apply accent color to tint color
    func applyAccentColor() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.compactMap { $0 as? UIWindowScene }

        for windowScene in windowScenes {
            for window in windowScene.windows {
                window.tintColor = accentColor.uiColor
            }
        }
    }

    // MARK: - Computed Properties

    /// UIKit interface style based on current theme mode
    var uiInterfaceStyle: UIUserInterfaceStyle {
        switch themeMode {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Current color scheme for SwiftUI
    var colorScheme: ColorScheme? {
        themeMode.colorScheme
    }

    /// Whether dark mode is currently active
    var isDarkMode: Bool {
        switch themeMode {
        case .dark: return true
        case .light: return false
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }

    // MARK: - Persistence

    private func loadSettings() {
        if let themeModeString = userDefaults.string(forKey: Keys.themeMode),
           let mode = ThemeMode(rawValue: themeModeString) {
            themeMode = mode
        }

        if let accentColorString = userDefaults.string(forKey: Keys.accentColor),
           let color = AccentColorOption(rawValue: accentColorString) {
            accentColor = color
        }

        useHighContrast = userDefaults.bool(forKey: Keys.highContrast)
        reduceTransparency = userDefaults.bool(forKey: Keys.reduceTransparency)
    }

    private func saveThemeMode() {
        userDefaults.set(themeMode.rawValue, forKey: Keys.themeMode)
    }

    private func saveAccentColor() {
        userDefaults.set(accentColor.rawValue, forKey: Keys.accentColor)
    }

    private func saveHighContrast() {
        userDefaults.set(useHighContrast, forKey: Keys.highContrast)
    }

    private func saveReduceTransparency() {
        userDefaults.set(reduceTransparency, forKey: Keys.reduceTransparency)
    }

    // MARK: - Convenience Methods

    /// Reset to default theme settings
    func resetToDefaults() {
        themeMode = .system
        accentColor = .orange
        useHighContrast = false
        reduceTransparency = false
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Apply theme manager's color scheme override
    func withTheme() -> some View {
        modifier(ThemeModifier())
    }
}

// MARK: - Theme Modifier

private struct ThemeModifier: ViewModifier {
    @Environment(\.themeManager) private var themeManager

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
            .tint(themeManager.accentColor.color)
    }
}

// MARK: - Preview Helper

extension ThemeManager {

    /// Create a preview instance with specific settings
    static func preview(
        mode: ThemeMode = .system,
        accent: AccentColorOption = .orange
    ) -> ThemeManager {
        let manager = ThemeManager.shared
        manager.themeMode = mode
        manager.accentColor = accent
        return manager
    }
}
