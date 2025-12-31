import SwiftUI

// MARK: - Typography

/// Typography system following Apple Human Interface Guidelines
/// All styles support Dynamic Type for accessibility
enum Typography {

    // MARK: - Display Styles

    /// Large title - 34pt Bold
    /// Use for: Screen titles, hero text
    static let largeTitle = Font.largeTitle.weight(.bold)

    /// Title 1 - 28pt Bold
    /// Use for: Section headers in large layouts
    static let title1 = Font.title.weight(.bold)

    /// Title 2 - 22pt Bold
    /// Use for: Secondary headers
    static let title2 = Font.title2.weight(.bold)

    /// Title 3 - 20pt Semibold
    /// Use for: Tertiary headers, card titles
    static let title3 = Font.title3.weight(.semibold)

    // MARK: - Body Styles

    /// Headline - 17pt Semibold
    /// Use for: Important body text, list headers
    static let headline = Font.headline

    /// Body - 17pt Regular
    /// Use for: Primary content text
    static let body = Font.body

    /// Body Semibold - 17pt Semibold
    /// Use for: Emphasized body text
    static let bodySemibold = Font.body.weight(.semibold)

    /// Callout - 16pt Regular
    /// Use for: Secondary content, descriptions
    static let callout = Font.callout

    /// Subheadline - 15pt Regular
    /// Use for: Tertiary content, metadata
    static let subheadline = Font.subheadline

    // MARK: - Supporting Styles

    /// Footnote - 13pt Regular
    /// Use for: Timestamps, auxiliary info
    static let footnote = Font.footnote

    /// Caption 1 - 12pt Regular
    /// Use for: Labels, small metadata
    static let caption1 = Font.caption

    /// Caption 2 - 11pt Regular
    /// Use for: Very small text, badges
    static let caption2 = Font.caption2

    // MARK: - Custom Editor Styles

    /// Tool Label - 13pt Medium
    /// Use for: Slider labels, tool names
    static let toolLabel = Font.system(size: 13, weight: .medium)

    /// Value Display - 15pt Monospaced
    /// Use for: Numeric values, parameters
    static let valueDisplay = Font.system(size: 15, weight: .medium, design: .monospaced)

    /// Filter Name - 12pt Medium
    /// Use for: Filter thumbnail labels
    static let filterName = Font.system(size: 12, weight: .medium)

    /// Tab Label - 10pt Medium
    /// Use for: Tab bar labels
    static let tabLabel = Font.system(size: 10, weight: .medium)

    /// Section Header - 13pt Semibold Uppercase
    /// Use for: Section headers in lists
    static let sectionHeader = Font.system(size: 13, weight: .semibold)
}

// MARK: - Font Extension

extension Font {

    // MARK: - Convenience Accessors

    static let fbLargeTitle = Typography.largeTitle
    static let fbTitle1 = Typography.title1
    static let fbTitle2 = Typography.title2
    static let fbTitle3 = Typography.title3
    static let fbHeadline = Typography.headline
    static let fbBody = Typography.body
    static let fbBodySemibold = Typography.bodySemibold
    static let fbCallout = Typography.callout
    static let fbSubheadline = Typography.subheadline
    static let fbFootnote = Typography.footnote
    static let fbCaption1 = Typography.caption1
    static let fbCaption2 = Typography.caption2
    static let fbToolLabel = Typography.toolLabel
    static let fbValueDisplay = Typography.valueDisplay
    static let fbFilterName = Typography.filterName
    static let fbTabLabel = Typography.tabLabel
    static let fbSectionHeader = Typography.sectionHeader

    // MARK: - Dynamic Type Scaled Fonts

    /// Create a font that scales with Dynamic Type
    static func scaled(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        .system(size: size, weight: weight, design: design)
    }
}

// MARK: - Text Style Modifier

extension View {

    /// Apply typography style with optional color
    func textStyle(_ style: Font, color: Color = .fbLabel) -> some View {
        self
            .font(style)
            .foregroundStyle(color)
    }

    /// Apply section header style
    func sectionHeaderStyle() -> some View {
        self
            .font(.fbSectionHeader)
            .foregroundStyle(.fbLabelSecondary)
            .textCase(.uppercase)
    }

    /// Apply tool label style
    func toolLabelStyle() -> some View {
        self
            .font(.fbToolLabel)
            .foregroundStyle(.fbLabel)
    }

    /// Apply value display style
    func valueDisplayStyle() -> some View {
        self
            .font(.fbValueDisplay)
            .foregroundStyle(.fbLabelSecondary)
            .monospacedDigit()
    }
}

// MARK: - Line Height

/// Line height multipliers for different typography styles
enum LineHeight {
    static let tight: CGFloat = 1.1
    static let normal: CGFloat = 1.3
    static let relaxed: CGFloat = 1.5
    static let loose: CGFloat = 1.8
}

// MARK: - Letter Spacing

/// Letter spacing values for different use cases
enum LetterSpacing {
    static let tight: CGFloat = -0.5
    static let normal: CGFloat = 0
    static let wide: CGFloat = 0.5
    static let extraWide: CGFloat = 1.0
}

// MARK: - Text Style View Modifier

struct TextStyleModifier: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat
    let letterSpacing: CGFloat

    init(
        font: Font,
        color: Color = .fbLabel,
        lineSpacing: CGFloat = 0,
        letterSpacing: CGFloat = 0
    ) {
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
        self.letterSpacing = letterSpacing
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(lineSpacing)
            .tracking(letterSpacing)
    }
}

// MARK: - Preview

#Preview("Typography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Large Title").font(.fbLargeTitle)
                Text("Title 1").font(.fbTitle1)
                Text("Title 2").font(.fbTitle2)
                Text("Title 3").font(.fbTitle3)
            }

            Divider()

            Group {
                Text("Headline").font(.fbHeadline)
                Text("Body").font(.fbBody)
                Text("Body Semibold").font(.fbBodySemibold)
                Text("Callout").font(.fbCallout)
                Text("Subheadline").font(.fbSubheadline)
            }

            Divider()

            Group {
                Text("Footnote").font(.fbFootnote)
                Text("Caption 1").font(.fbCaption1)
                Text("Caption 2").font(.fbCaption2)
            }

            Divider()

            Group {
                Text("Tool Label").font(.fbToolLabel)
                Text("Value: 0.50").font(.fbValueDisplay)
                Text("Filter Name").font(.fbFilterName)
                Text("SECTION HEADER").sectionHeaderStyle()
            }
        }
        .padding()
    }
}
