//
//  Theme.swift
//  FilmBox
//
//  Created for FilmBox iOS App
//

import SwiftUI

// MARK: - Theme

/// Central theme configuration for the FilmBox app
enum Theme {

    // MARK: - Colors

    enum Colors {

        // MARK: Primary Colors

        /// Primary brand color
        static let primary = Color("Primary", bundle: .main)

        /// Secondary brand color
        static let secondary = Color("Secondary", bundle: .main)

        /// Accent color for interactive elements
        static let accent = Color("Accent", bundle: .main)

        // MARK: Semantic Colors

        /// Background color for main content areas
        static let background = Color(.systemBackground)

        /// Secondary background color for grouped content
        static let secondaryBackground = Color(.secondarySystemBackground)

        /// Tertiary background color for nested content
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        /// Primary text color
        static let textPrimary = Color(.label)

        /// Secondary text color
        static let textSecondary = Color(.secondaryLabel)

        /// Tertiary text color
        static let textTertiary = Color(.tertiaryLabel)

        /// Placeholder text color
        static let textPlaceholder = Color(.placeholderText)

        // MARK: UI Element Colors

        /// Separator color
        static let separator = Color(.separator)

        /// Opaque separator color
        static let opaqueSeparator = Color(.opaqueSeparator)

        /// Link color
        static let link = Color(.link)

        // MARK: Status Colors

        /// Success color (green)
        static let success = Color.green

        /// Warning color (orange)
        static let warning = Color.orange

        /// Error color (red)
        static let error = Color.red

        /// Info color (blue)
        static let info = Color.blue

        // MARK: Film-Specific Colors

        /// Film strip color
        static let filmStrip = Color(red: 0.15, green: 0.15, blue: 0.15)

        /// Film sprocket color
        static let filmSprocket = Color(red: 0.2, green: 0.2, blue: 0.2)

        /// Vintage sepia tone
        static let vintageSepia = Color(red: 0.94, green: 0.87, blue: 0.73)

        /// Dark room red
        static let darkroomRed = Color(red: 0.6, green: 0.1, blue: 0.1)

        // MARK: Gradient Colors

        /// Primary gradient
        static let primaryGradient = LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.3, blue: 0.6),
                Color(red: 0.6, green: 0.4, blue: 0.5),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Dark overlay gradient
        static let darkOverlay = LinearGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(0.6),
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        // MARK: Adaptive Colors

        /// Returns a color that adapts to the current color scheme
        static func adaptive(light: Color, dark: Color) -> Color {
            Color(
                UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(dark)
                        : UIColor(light)
                })
        }
    }

    // MARK: - Fonts

    enum Fonts {

        // MARK: Display

        /// Large title font
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Title font
        static let title = Font.title.weight(.semibold)

        /// Title 2 font
        static let title2 = Font.title2.weight(.semibold)

        /// Title 3 font
        static let title3 = Font.title3.weight(.medium)

        // MARK: Body

        /// Headline font
        static let headline = Font.headline

        /// Subheadline font
        static let subheadline = Font.subheadline

        /// Body font
        static let body = Font.body

        /// Callout font
        static let callout = Font.callout

        // MARK: Supporting

        /// Footnote font
        static let footnote = Font.footnote

        /// Caption font
        static let caption = Font.caption

        /// Caption 2 font
        static let caption2 = Font.caption2

        // MARK: Custom Sizes

        /// Returns a system font with the specified size and weight
        static func system(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight)
        }

        /// Returns a rounded system font with the specified size and weight
        static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }

        /// Returns a monospaced system font with the specified size and weight
        static func monospaced(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        // MARK: Film-Themed Fonts

        /// Vintage style font for film labels
        static let filmLabel = Font.system(size: 12, weight: .medium, design: .monospaced)

        /// Frame counter font
        static let frameCounter = Font.system(size: 10, weight: .bold, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {

        // MARK: Base Spacing

        /// Extra extra small spacing (2pt)
        static let xxs: CGFloat = 2

        /// Extra small spacing (4pt)
        static let xs: CGFloat = 4

        /// Small spacing (8pt)
        static let sm: CGFloat = 8

        /// Medium spacing (12pt)
        static let md: CGFloat = 12

        /// Standard spacing (16pt)
        static let standard: CGFloat = 16

        /// Large spacing (20pt)
        static let lg: CGFloat = 20

        /// Extra large spacing (24pt)
        static let xl: CGFloat = 24

        /// Extra extra large spacing (32pt)
        static let xxl: CGFloat = 32

        /// Huge spacing (40pt)
        static let huge: CGFloat = 40

        // MARK: Component Spacing

        /// Padding for cards and containers
        static let cardPadding: CGFloat = 16

        /// Padding for list items
        static let listItemPadding: CGFloat = 12

        /// Spacing between grid items
        static let gridSpacing: CGFloat = 2

        /// Spacing between sections
        static let sectionSpacing: CGFloat = 24

        /// Toolbar height
        static let toolbarHeight: CGFloat = 44

        /// Bottom safe area padding
        static let bottomSafeArea: CGFloat = 34

        // MARK: Edge Insets

        /// Standard content insets
        static let contentInsets = EdgeInsets(
            top: standard,
            leading: standard,
            bottom: standard,
            trailing: standard
        )

        /// Compact content insets
        static let compactInsets = EdgeInsets(
            top: sm,
            leading: sm,
            bottom: sm,
            trailing: sm
        )

        /// Card insets
        static let cardInsets = EdgeInsets(
            top: cardPadding,
            leading: cardPadding,
            bottom: cardPadding,
            trailing: cardPadding
        )
    }

    // MARK: - Corner Radius

    enum CornerRadius {

        /// No corner radius
        static let none: CGFloat = 0

        /// Small corner radius (4pt)
        static let small: CGFloat = 4

        /// Medium corner radius (8pt)
        static let medium: CGFloat = 8

        /// Standard corner radius (12pt)
        static let standard: CGFloat = 12

        /// Large corner radius (16pt)
        static let large: CGFloat = 16

        /// Extra large corner radius (20pt)
        static let xl: CGFloat = 20

        /// Circular (use with .clipShape(Circle()) instead)
        static let circular: CGFloat = .infinity
    }

    // MARK: - Shadows

    enum Shadows {

        /// Small shadow
        static let small = ShadowStyle(
            color: .black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )

        /// Medium shadow
        static let medium = ShadowStyle(
            color: .black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )

        /// Large shadow
        static let large = ShadowStyle(
            color: .black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )

        /// Card shadow
        static let card = ShadowStyle(
            color: .black.opacity(0.1),
            radius: 6,
            x: 0,
            y: 3
        )
    }

    // MARK: - Animation

    enum Animation {

        /// Quick animation duration
        static let quick: Double = 0.15

        /// Standard animation duration
        static let standard: Double = 0.25

        /// Slow animation duration
        static let slow: Double = 0.4

        /// Spring animation
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)

        /// Bouncy spring animation
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)

        /// Smooth ease in out
        static let smooth = SwiftUI.Animation.easeInOut(duration: standard)
    }

    // MARK: - Icon Sizes

    enum IconSize {

        /// Extra small icon (12pt)
        static let xs: CGFloat = 12

        /// Small icon (16pt)
        static let small: CGFloat = 16

        /// Medium icon (20pt)
        static let medium: CGFloat = 20

        /// Standard icon (24pt)
        static let standard: CGFloat = 24

        /// Large icon (32pt)
        static let large: CGFloat = 32

        /// Extra large icon (40pt)
        static let xl: CGFloat = 40

        /// Huge icon (48pt)
        static let huge: CGFloat = 48
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {

    /// Applies a theme shadow style to the view
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    /// Applies standard card styling
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.standard))
            .shadow(Theme.Shadows.card)
    }

    /// Applies film strip styling
    func filmStripStyle() -> some View {
        self
            .background(Theme.Colors.filmStrip)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                isEnabled
                    ? Theme.Colors.accent
                    : Theme.Colors.textTertiary
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.standard))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.spring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline)
            .foregroundColor(isEnabled ? Theme.Colors.accent : Theme.Colors.textTertiary)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.standard)
                    .stroke(
                        isEnabled ? Theme.Colors.accent : Theme.Colors.textTertiary,
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.spring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Color Scheme Extension

extension ColorScheme {

    /// Returns true if the current color scheme is dark mode
    var isDark: Bool {
        self == .dark
    }
}
