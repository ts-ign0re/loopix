import SwiftUI

// MARK: - Button Variant

/// Button style variants
enum FBButtonVariant {
    case primary
    case secondary
    case tertiary
    case destructive
    case ghost

    var backgroundColor: Color {
        switch self {
        case .primary: return .fbAccent
        case .secondary: return .fbFillSecondary
        case .tertiary: return .clear
        case .destructive: return .fbDestructive
        case .ghost: return .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .fbLabel
        case .tertiary: return .fbAccent
        case .destructive: return .white
        case .ghost: return .fbAccent
        }
    }

    var pressedOpacity: Double {
        switch self {
        case .primary, .destructive: return 0.8
        case .secondary: return 0.6
        case .tertiary, .ghost: return 0.5
        }
    }
}

// MARK: - Button Size

/// Button size variants
enum FBButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return Spacing.sm
        case .medium: return Spacing.md
        case .large: return Spacing.lg
        }
    }

    var font: Font {
        switch self {
        case .small: return .fbCaption1.weight(.semibold)
        case .medium: return .fbBody.weight(.semibold)
        case .large: return .fbBody.weight(.bold)
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 20
        }
    }
}

// MARK: - FBButton

/// Primary button component following Apple HIG
struct FBButton: View {

    // MARK: - Properties

    let title: String
    let icon: String?
    let variant: FBButtonVariant
    let size: FBButtonSize
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    // MARK: - Initialization

    init(
        _ title: String,
        icon: String? = nil,
        variant: FBButtonVariant = .primary,
        size: FBButtonSize = .medium,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: variant.foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }

                Text(title)
                    .font(size.font)
            }
            .foregroundStyle(isDisabled ? .fbDisabled : variant.foregroundColor)
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .fill(isDisabled ? Color.fbFillTertiary : variant.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.button)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(FBButtonStyle(variant: variant))
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isDisabled ? .isStaticText : .isButton)
    }

    // MARK: - Private

    private var borderColor: Color {
        switch variant {
        case .secondary: return .fbSeparator
        case .tertiary: return .fbAccent
        default: return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .secondary, .tertiary: return BorderWidth.thin
        default: return 0
        }
    }

    private func handleTap() {
        Haptics.shared.light()
        action()
    }
}

// MARK: - FBButtonStyle

private struct FBButtonStyle: ButtonStyle {
    let variant: FBButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? variant.pressedOpacity : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AnimationCurve.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Icon Button

/// Icon-only button
struct FBIconButton: View {

    let icon: String
    let accessibilityLabel: String
    let variant: FBButtonVariant
    let size: FBButtonSize
    let isDisabled: Bool
    let action: () -> Void

    init(
        icon: String,
        label: String? = nil,
        variant: FBButtonVariant = .ghost,
        size: FBButtonSize = .medium,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.accessibilityLabel = label ?? Self.defaultLabel(for: icon)
        self.variant = variant
        self.size = size
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundStyle(isDisabled ? .fbDisabled : variant.foregroundColor)
                .frame(width: size.height, height: size.height)
                .background(
                    Circle()
                        .fill(variant.backgroundColor)
                )
        }
        .buttonStyle(FBButtonStyle(variant: variant))
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isDisabled ? .isStaticText : .isButton)
    }

    private func handleTap() {
        Haptics.shared.light()
        action()
    }

    /// Default accessibility labels for common SF Symbols
    private static func defaultLabel(for icon: String) -> String {
        switch icon {
        case "heart.fill", "heart": return "Favorite"
        case "square.and.arrow.up": return "Share"
        case "trash", "trash.fill": return "Delete"
        case "xmark": return "Close"
        case "checkmark": return "Done"
        case "plus": return "Add"
        case "minus": return "Remove"
        case "gear": return "Settings"
        case "slider.horizontal.3": return "Adjustments"
        case "rotate.left": return "Rotate left"
        case "rotate.right": return "Rotate right"
        case "arrow.left.and.right.righttriangle.left.righttriangle.right": return "Flip horizontal"
        case "arrow.up.and.down.righttriangle.up.righttriangle.down": return "Flip vertical"
        case "crop": return "Crop"
        case "wand.and.stars": return "Auto enhance"
        case "arrow.uturn.backward": return "Undo"
        case "arrow.uturn.forward": return "Redo"
        case "arrow.counterclockwise": return "Reset"
        default: return icon.replacingOccurrences(of: ".", with: " ")
        }
    }
}

// MARK: - Convenience Initializers

extension FBButton {

    /// Primary button
    static func primary(
        _ title: String,
        icon: String? = nil,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) -> FBButton {
        FBButton(title, icon: icon, variant: .primary, isFullWidth: isFullWidth, action: action)
    }

    /// Secondary button
    static func secondary(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> FBButton {
        FBButton(title, icon: icon, variant: .secondary, action: action)
    }

    /// Destructive button
    static func destructive(
        _ title: String,
        icon: String? = nil,
        action: @escaping () -> Void
    ) -> FBButton {
        FBButton(title, icon: icon, variant: .destructive, action: action)
    }
}

// MARK: - Preview

#Preview("Button Variants") {
    VStack(spacing: Spacing.md) {
        FBButton.primary("Primary Button", icon: "plus") {}
        FBButton.secondary("Secondary Button") {}
        FBButton("Tertiary", variant: .tertiary) {}
        FBButton.destructive("Delete", icon: "trash") {}
        FBButton("Ghost", variant: .ghost) {}

        Divider()

        FBButton("Loading", isLoading: true) {}
        FBButton("Disabled", isDisabled: true) {}

        Divider()

        HStack(spacing: Spacing.sm) {
            FBButton("Small", size: .small) {}
            FBButton("Medium", size: .medium) {}
            FBButton("Large", size: .large) {}
        }

        FBButton.primary("Full Width", isFullWidth: true) {}

        Divider()

        HStack(spacing: Spacing.md) {
            FBIconButton(icon: "heart.fill", variant: .primary) {}
            FBIconButton(icon: "square.and.arrow.up") {}
            FBIconButton(icon: "trash", variant: .destructive) {}
        }
    }
    .padding()
}
