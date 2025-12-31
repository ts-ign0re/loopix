import SwiftUI

// MARK: - Card Style

/// Card visual style variants
enum FBCardStyle {
    case elevated   // Shadow, elevated surface
    case filled     // Filled background, no shadow
    case outlined   // Border, transparent background
    case plain      // No decoration
}

// MARK: - FBCard

/// Reusable card container component
struct FBCard<Content: View>: View {

    // MARK: - Properties

    let style: FBCardStyle
    let padding: CGFloat
    let cornerRadius: CGFloat
    let content: () -> Content

    // MARK: - Initialization

    init(
        style: FBCardStyle = .elevated,
        padding: CGFloat = Spacing.cardPadding,
        cornerRadius: CGFloat = CornerRadius.card,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        content()
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(shadowStyle)
    }

    // MARK: - Style Properties

    private var backgroundColor: Color {
        switch style {
        case .elevated: return .fbBackgroundElevated
        case .filled: return .fbFillSecondary
        case .outlined: return .clear
        case .plain: return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .outlined: return .fbSeparator
        default: return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .outlined: return BorderWidth.thin
        default: return 0
        }
    }

    private var shadowStyle: ShadowStyle {
        switch style {
        case .elevated: return Shadow.subtle
        default: return ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        }
    }
}

// MARK: - Section Component

/// Section container with header
struct FBSection<Content: View>: View {

    let title: String?
    let icon: String?
    let action: (() -> Void)?
    let actionLabel: String?
    let content: () -> Content

    init(
        _ title: String? = nil,
        icon: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.actionLabel = actionLabel
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if title != nil || action != nil {
                header
            }

            content()
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.fbLabelSecondary)
            }

            if let title = title {
                Text(title)
                    .sectionHeaderStyle()
            }

            Spacer()

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.fbCaption1)
                        .foregroundStyle(.fbAccent)
                }
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

// MARK: - Empty State

/// Empty state placeholder view
struct FBEmptyState: View {

    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.fbLabelTertiary)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.fbHeadline)
                    .foregroundStyle(.fbLabel)

                Text(message)
                    .font(.fbSubheadline)
                    .foregroundStyle(.fbLabelSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                FBButton.primary(actionTitle, action: action)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Divider

/// Styled divider component
struct FBDivider: View {

    let inset: CGFloat

    init(inset: CGFloat = 0) {
        self.inset = inset
    }

    var body: some View {
        Divider()
            .padding(.leading, inset)
    }
}

// MARK: - List Row

/// Standard list row with icon, title, and accessory
struct FBListRow<Accessory: View>: View {

    let icon: String?
    let iconColor: Color
    let title: String
    let subtitle: String?
    let accessory: () -> Accessory
    let action: (() -> Void)?

    init(
        icon: String? = nil,
        iconColor: Color = .fbAccent,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() }
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.action = action
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: 28)
                }

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(title)
                        .font(.fbBody)
                        .foregroundStyle(.fbLabel)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.fbCaption1)
                            .foregroundStyle(.fbLabelSecondary)
                    }
                }

                Spacer()

                accessory()

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.fbLabelTertiary)
                }
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Preview

#Preview("Layout Components") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            // Cards
            FBCard(style: .elevated) {
                Text("Elevated Card")
            }

            FBCard(style: .filled) {
                Text("Filled Card")
            }

            FBCard(style: .outlined) {
                Text("Outlined Card")
            }

            Divider()

            // Section
            FBSection("Section Header", icon: "slider.horizontal.3", action: {}, actionLabel: "Reset") {
                VStack {
                    Text("Section content goes here")
                }
                .padding(.horizontal)
            }

            Divider()

            // List rows
            VStack(spacing: 0) {
                FBListRow(icon: "photo", title: "Photos", subtitle: "1,234 items", action: {})
                FBDivider(inset: 44)
                FBListRow(icon: "gear", title: "Settings", action: {})
                FBDivider(inset: 44)
                FBListRow(title: "No icon row") {
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                }
            }
            .background(Color.fbBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))

            Divider()

            // Empty state
            FBEmptyState(
                icon: "photo.on.rectangle.angled",
                title: "No Photos",
                message: "Your edited photos will appear here.",
                actionTitle: "Browse Photos"
            ) {}
                .frame(height: 300)
                .background(Color.fbBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .padding()
    }
    .background(Color.fbBackground)
}
