import SwiftUI

// MARK: - Color Tokens

/// Semantic color tokens following Apple Human Interface Guidelines
/// All colors automatically adapt to light/dark mode
enum ColorToken: String, CaseIterable {

    // MARK: - Brand
    case accent = "AccentColor"
    case brand = "BrandColor"

    // MARK: - Backgrounds
    case background = "Background"
    case backgroundSecondary = "BackgroundSecondary"
    case backgroundTertiary = "BackgroundTertiary"
    case backgroundElevated = "BackgroundElevated"
    case backgroundGrouped = "BackgroundGrouped"
    case backgroundGroupedSecondary = "BackgroundGroupedSecondary"

    // MARK: - Labels
    case label = "Label"
    case labelSecondary = "LabelSecondary"
    case labelTertiary = "LabelTertiary"
    case labelQuaternary = "LabelQuaternary"
    case labelInverse = "LabelInverse"

    // MARK: - Fills
    case fill = "Fill"
    case fillSecondary = "FillSecondary"
    case fillTertiary = "FillTertiary"
    case fillQuaternary = "FillQuaternary"

    // MARK: - Separators
    case separator = "Separator"
    case separatorOpaque = "SeparatorOpaque"

    // MARK: - Semantic States
    case success = "Success"
    case warning = "Warning"
    case error = "Error"
    case info = "Info"
    case destructive = "Destructive"
    case disabled = "Disabled"

    // MARK: - Editor Specific
    case histogramRed = "HistogramRed"
    case histogramGreen = "HistogramGreen"
    case histogramBlue = "HistogramBlue"
    case histogramLuminance = "HistogramLuminance"

    case sliderTrack = "SliderTrack"
    case sliderThumb = "SliderThumb"
    case sliderActive = "SliderActive"
    case sliderTemperatureWarm = "SliderTemperatureWarm"
    case sliderTemperatureCool = "SliderTemperatureCool"
    case sliderTintMagenta = "SliderTintMagenta"
    case sliderTintGreen = "SliderTintGreen"

    case cropGrid = "CropGrid"
    case cropHandle = "CropHandle"
    case cropOverlay = "CropOverlay"

    case filterSelected = "FilterSelected"
    case filterBorder = "FilterBorder"
    case filterOverlay = "FilterOverlay"

    case toolbarBackground = "ToolbarBackground"
    case tabBarBackground = "TabBarBackground"

    /// Returns the SwiftUI Color for this token
    var color: Color {
        Color(rawValue)
    }
}

// MARK: - Color Extension

extension Color {

    // MARK: - Brand Colors

    /// Primary accent color
    static let fbAccent = ColorToken.accent.color

    /// Brand color for logos and highlights
    static let fbBrand = ColorToken.brand.color

    // MARK: - Background Colors

    /// Primary background
    static let fbBackground = ColorToken.background.color

    /// Secondary background for grouped content
    static let fbBackgroundSecondary = ColorToken.backgroundSecondary.color

    /// Tertiary background for nested content
    static let fbBackgroundTertiary = ColorToken.backgroundTertiary.color

    /// Elevated surface background (cards, modals)
    static let fbBackgroundElevated = ColorToken.backgroundElevated.color

    /// Grouped content background
    static let fbBackgroundGrouped = ColorToken.backgroundGrouped.color

    /// Secondary grouped content background
    static let fbBackgroundGroupedSecondary = ColorToken.backgroundGroupedSecondary.color

    // MARK: - Label Colors

    /// Primary text color
    static let fbLabel = ColorToken.label.color

    /// Secondary text color
    static let fbLabelSecondary = ColorToken.labelSecondary.color

    /// Tertiary text color (placeholders)
    static let fbLabelTertiary = ColorToken.labelTertiary.color

    /// Quaternary text color (disabled)
    static let fbLabelQuaternary = ColorToken.labelQuaternary.color

    /// Inverse label for dark backgrounds
    static let fbLabelInverse = ColorToken.labelInverse.color

    // MARK: - Fill Colors

    /// Primary fill color
    static let fbFill = ColorToken.fill.color

    /// Secondary fill color
    static let fbFillSecondary = ColorToken.fillSecondary.color

    /// Tertiary fill color
    static let fbFillTertiary = ColorToken.fillTertiary.color

    /// Quaternary fill color
    static let fbFillQuaternary = ColorToken.fillQuaternary.color

    // MARK: - Separator Colors

    /// Standard separator
    static let fbSeparator = ColorToken.separator.color

    /// Opaque separator
    static let fbSeparatorOpaque = ColorToken.separatorOpaque.color

    // MARK: - Semantic Colors

    /// Success state color
    static let fbSuccess = ColorToken.success.color

    /// Warning state color
    static let fbWarning = ColorToken.warning.color

    /// Error state color
    static let fbError = ColorToken.error.color

    /// Informational color
    static let fbInfo = ColorToken.info.color

    /// Destructive action color
    static let fbDestructive = ColorToken.destructive.color

    /// Disabled state color
    static let fbDisabled = ColorToken.disabled.color

    // MARK: - Histogram Colors

    static let fbHistogramRed = ColorToken.histogramRed.color
    static let fbHistogramGreen = ColorToken.histogramGreen.color
    static let fbHistogramBlue = ColorToken.histogramBlue.color
    static let fbHistogramLuminance = ColorToken.histogramLuminance.color

    // MARK: - Slider Colors

    static let fbSliderTrack = ColorToken.sliderTrack.color
    static let fbSliderThumb = ColorToken.sliderThumb.color
    static let fbSliderActive = ColorToken.sliderActive.color
    static let fbSliderTemperatureWarm = ColorToken.sliderTemperatureWarm.color
    static let fbSliderTemperatureCool = ColorToken.sliderTemperatureCool.color
    static let fbSliderTintMagenta = ColorToken.sliderTintMagenta.color
    static let fbSliderTintGreen = ColorToken.sliderTintGreen.color

    // MARK: - Crop Colors

    static let fbCropGrid = ColorToken.cropGrid.color
    static let fbCropHandle = ColorToken.cropHandle.color
    static let fbCropOverlay = ColorToken.cropOverlay.color

    // MARK: - Filter Colors

    static let fbFilterSelected = ColorToken.filterSelected.color
    static let fbFilterBorder = ColorToken.filterBorder.color
    static let fbFilterOverlay = ColorToken.filterOverlay.color

    // MARK: - Chrome Colors

    static let fbToolbarBackground = ColorToken.toolbarBackground.color
    static let fbTabBarBackground = ColorToken.tabBarBackground.color
}

// MARK: - UIColor Extension

extension UIColor {

    /// Create UIColor from ColorToken
    convenience init(token: ColorToken) {
        self.init(named: token.rawValue) ?? .systemBackground
    }

    // MARK: - Convenience Accessors

    static let fbAccent = UIColor(token: .accent)
    static let fbBackground = UIColor(token: .background)
    static let fbBackgroundSecondary = UIColor(token: .backgroundSecondary)
    static let fbLabel = UIColor(token: .label)
    static let fbLabelSecondary = UIColor(token: .labelSecondary)
    static let fbSeparator = UIColor(token: .separator)
    static let fbDestructive = UIColor(token: .destructive)
}

// MARK: - Fallback Colors

/// Provides fallback colors when Asset Catalog colors are not available
extension ColorToken {

    /// System fallback color for development
    var fallbackColor: Color {
        switch self {
        // Brand
        case .accent: return Color.blue
        case .brand: return Color.orange

        // Backgrounds
        case .background: return Color(.systemBackground)
        case .backgroundSecondary: return Color(.secondarySystemBackground)
        case .backgroundTertiary: return Color(.tertiarySystemBackground)
        case .backgroundElevated: return Color(.systemBackground)
        case .backgroundGrouped: return Color(.systemGroupedBackground)
        case .backgroundGroupedSecondary: return Color(.secondarySystemGroupedBackground)

        // Labels
        case .label: return Color(.label)
        case .labelSecondary: return Color(.secondaryLabel)
        case .labelTertiary: return Color(.tertiaryLabel)
        case .labelQuaternary: return Color(.quaternaryLabel)
        case .labelInverse: return Color.white

        // Fills
        case .fill: return Color(.systemFill)
        case .fillSecondary: return Color(.secondarySystemFill)
        case .fillTertiary: return Color(.tertiarySystemFill)
        case .fillQuaternary: return Color(.quaternarySystemFill)

        // Separators
        case .separator: return Color(.separator)
        case .separatorOpaque: return Color(.opaqueSeparator)

        // Semantic
        case .success: return Color.green
        case .warning: return Color.orange
        case .error: return Color.red
        case .info: return Color.blue
        case .destructive: return Color.red
        case .disabled: return Color.gray.opacity(0.5)

        // Histogram
        case .histogramRed: return Color.red.opacity(0.8)
        case .histogramGreen: return Color.green.opacity(0.8)
        case .histogramBlue: return Color.blue.opacity(0.8)
        case .histogramLuminance: return Color.white.opacity(0.8)

        // Slider
        case .sliderTrack: return Color(.systemGray4)
        case .sliderThumb: return Color.white
        case .sliderActive: return Color.blue
        case .sliderTemperatureWarm: return Color.orange
        case .sliderTemperatureCool: return Color.blue
        case .sliderTintMagenta: return Color.pink
        case .sliderTintGreen: return Color.green

        // Crop
        case .cropGrid: return Color.white.opacity(0.4)
        case .cropHandle: return Color.white
        case .cropOverlay: return Color.black.opacity(0.5)

        // Filter
        case .filterSelected: return Color.blue
        case .filterBorder: return Color(.separator)
        case .filterOverlay: return Color.black.opacity(0.3)

        // Chrome
        case .toolbarBackground: return Color(.systemBackground).opacity(0.95)
        case .tabBarBackground: return Color(.systemBackground).opacity(0.95)
        }
    }
}
