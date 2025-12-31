import SwiftUI

// MARK: - Spacing

/// Spacing system based on 4pt/8pt grid following Apple HIG
enum Spacing {

    // MARK: - Base Scale

    /// 2pt - Micro spacing (icon padding, tight gaps)
    static let xxxs: CGFloat = 2

    /// 4pt - Extra extra small (tight element spacing)
    static let xxs: CGFloat = 4

    /// 8pt - Extra small (related element spacing)
    static let xs: CGFloat = 8

    /// 12pt - Small (compact component spacing)
    static let sm: CGFloat = 12

    /// 16pt - Medium (default padding, margins)
    static let md: CGFloat = 16

    /// 20pt - Medium large
    static let ml: CGFloat = 20

    /// 24pt - Large (section spacing)
    static let lg: CGFloat = 24

    /// 32pt - Extra large (major section breaks)
    static let xl: CGFloat = 32

    /// 40pt - Extra extra large
    static let xxl: CGFloat = 40

    /// 48pt - Huge (screen section gaps)
    static let xxxl: CGFloat = 48

    /// 64pt - Maximum (hero spacing)
    static let max: CGFloat = 64

    // MARK: - Semantic Spacing

    /// Standard horizontal padding for screens
    static let screenHorizontal: CGFloat = md

    /// Standard vertical padding for screens
    static let screenVertical: CGFloat = md

    /// Padding inside cards
    static let cardPadding: CGFloat = md

    /// Gap between cards in a list
    static let cardGap: CGFloat = sm

    /// Spacing between form elements
    static let formElementGap: CGFloat = md

    /// Spacing between sections
    static let sectionGap: CGFloat = lg

    /// Spacing within a toolbar
    static let toolbarItemGap: CGFloat = xs

    /// Tab bar content inset
    static let tabBarInset: CGFloat = xs

    /// Filter strip item spacing
    static let filterItemGap: CGFloat = sm

    /// Slider label spacing
    static let sliderLabelGap: CGFloat = xs

    /// Icon to text spacing
    static let iconTextGap: CGFloat = xs

    /// Button content padding
    static let buttonPadding: CGFloat = sm

    /// Touch target minimum (44pt per Apple HIG)
    static let touchTarget: CGFloat = 44
}

// MARK: - Corner Radius

/// Corner radius values following Apple's design language
enum CornerRadius {

    /// 4pt - Very small (badges, tags)
    static let xs: CGFloat = 4

    /// 6pt - Small (buttons, inputs)
    static let sm: CGFloat = 6

    /// 8pt - Medium small
    static let ms: CGFloat = 8

    /// 10pt - Medium (standard cards)
    static let md: CGFloat = 10

    /// 12pt - Medium large (containers)
    static let ml: CGFloat = 12

    /// 16pt - Large (modals, sheets)
    static let lg: CGFloat = 16

    /// 20pt - Extra large (hero cards)
    static let xl: CGFloat = 20

    /// 24pt - Extra extra large
    static let xxl: CGFloat = 24

    /// Full rounding for pills and circles
    static let full: CGFloat = 9999

    // MARK: - Semantic

    /// Button corner radius
    static let button: CGFloat = md

    /// Card corner radius
    static let card: CGFloat = ml

    /// Input field corner radius
    static let input: CGFloat = ms

    /// Modal/sheet corner radius
    static let modal: CGFloat = lg

    /// Image thumbnail corner radius
    static let thumbnail: CGFloat = ms

    /// Filter preview corner radius
    static let filterPreview: CGFloat = ms

    /// Slider thumb corner radius
    static let sliderThumb: CGFloat = full
}

// MARK: - Shadow

/// Shadow styles for elevation
enum Shadow {

    /// Subtle shadow for cards and surfaces
    static let subtle = ShadowStyle(
        color: .black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 2
    )

    /// Medium shadow for floating elements
    static let medium = ShadowStyle(
        color: .black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 4
    )

    /// Strong shadow for modals and popovers
    static let strong = ShadowStyle(
        color: .black.opacity(0.2),
        radius: 24,
        x: 0,
        y: 8
    )

    /// Inner shadow for pressed states
    static let inner = ShadowStyle(
        color: .black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2,
        isInner: true
    )
}

/// Shadow style definition
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    var isInner: Bool = false
}

// MARK: - Border Width

/// Border width values
enum BorderWidth {

    /// Hairline border (0.5pt)
    static let hairline: CGFloat = 0.5

    /// Thin border (1pt)
    static let thin: CGFloat = 1

    /// Regular border (1.5pt)
    static let regular: CGFloat = 1.5

    /// Medium border (2pt)
    static let medium: CGFloat = 2

    /// Thick border (3pt)
    static let thick: CGFloat = 3
}

// MARK: - View Extensions

extension View {

    /// Apply standard screen padding
    func screenPadding() -> some View {
        padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.screenVertical)
    }

    /// Apply card padding
    func cardPadding() -> some View {
        padding(Spacing.cardPadding)
    }

    /// Apply standard corner radius
    func standardCornerRadius() -> some View {
        clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    /// Apply card corner radius
    func cardCornerRadius() -> some View {
        clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    /// Apply shadow style
    func shadow(_ style: ShadowStyle) -> some View {
        shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    /// Apply card style (padding + corner radius + shadow)
    func cardStyle() -> some View {
        self
            .cardPadding()
            .background(Color.fbBackgroundElevated)
            .cardCornerRadius()
            .shadow(Shadow.subtle)
    }

    /// Ensure minimum touch target size (44x44pt)
    func touchTarget() -> some View {
        frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
    }
}

// MARK: - EdgeInsets Extensions

extension EdgeInsets {

    /// Standard screen insets
    static let screen = EdgeInsets(
        top: Spacing.screenVertical,
        leading: Spacing.screenHorizontal,
        bottom: Spacing.screenVertical,
        trailing: Spacing.screenHorizontal
    )

    /// Card insets
    static let card = EdgeInsets(
        top: Spacing.cardPadding,
        leading: Spacing.cardPadding,
        bottom: Spacing.cardPadding,
        trailing: Spacing.cardPadding
    )

    /// Compact insets
    static let compact = EdgeInsets(
        top: Spacing.xs,
        leading: Spacing.sm,
        bottom: Spacing.xs,
        trailing: Spacing.sm
    )

    /// Zero insets
    static let zero = EdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )
}

// MARK: - Preview

#Preview("Spacing Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach([
                ("xxxs (2pt)", Spacing.xxxs),
                ("xxs (4pt)", Spacing.xxs),
                ("xs (8pt)", Spacing.xs),
                ("sm (12pt)", Spacing.sm),
                ("md (16pt)", Spacing.md),
                ("lg (24pt)", Spacing.lg),
                ("xl (32pt)", Spacing.xl),
                ("xxl (40pt)", Spacing.xxl)
            ], id: \.0) { name, value in
                HStack {
                    Text(name)
                        .font(.caption)
                        .frame(width: 100, alignment: .leading)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: value, height: 20)

                    Spacer()
                }
            }

            Divider()

            Text("Corner Radius Scale")
                .font(.headline)

            HStack(spacing: Spacing.md) {
                ForEach([
                    ("xs", CornerRadius.xs),
                    ("sm", CornerRadius.sm),
                    ("md", CornerRadius.md),
                    ("lg", CornerRadius.lg),
                    ("xl", CornerRadius.xl)
                ], id: \.0) { name, value in
                    VStack {
                        RoundedRectangle(cornerRadius: value)
                            .fill(Color.blue)
                            .frame(width: 50, height: 50)
                        Text(name)
                            .font(.caption2)
                    }
                }
            }
        }
        .padding()
    }
}
