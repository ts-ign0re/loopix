import SwiftUI

// MARK: - FilmBox Design System
//
// This file serves as the central export point for the FilmBox Design System.
// Import this file to access all design tokens and components.
//
// ## Structure
//
// Theme/
// ├── ColorTokens.swift     - Semantic colors with dark/light mode support
// ├── Typography.swift      - Text styles following Apple HIG
// ├── Spacing.swift         - 8pt grid spacing system
// ├── Animation.swift       - Animation curves and haptics
// └── ThemeManager.swift    - Runtime theme management
//
// Components/
// ├── Buttons/
// │   └── FBButton.swift    - Primary, secondary, ghost buttons
// ├── Controls/
// │   └── FBSlider.swift    - Custom sliders for adjustments
// ├── Layout/
// │   └── FBCard.swift      - Cards, sections, list rows
// ├── Editor/
// │   ├── FBFilterCell.swift    - Filter preview cells
// │   └── FBHistogram.swift     - RGB histogram display
// └── Feedback/
//     └── (Toast, Spinner, etc.)
//
// ## Usage
//
// ```swift
// import SwiftUI
//
// struct MyView: View {
//     var body: some View {
//         VStack(spacing: Spacing.md) {
//             Text("Title")
//                 .font(.fbTitle2)
//                 .foregroundStyle(.fbLabel)
//
//             FBButton.primary("Action") {
//                 // handle action
//             }
//         }
//         .padding(Spacing.screenHorizontal)
//         .background(Color.fbBackground)
//         .withTheme()
//     }
// }
// ```
//
// ## Apple Human Interface Guidelines Compliance
//
// - 44pt minimum touch targets
// - Dynamic Type support for all text
// - Semantic colors that adapt to light/dark mode
// - Consistent 8pt spacing grid
// - Spring animations for natural motion
// - Haptic feedback for interactions
// - VoiceOver accessibility labels
//

// MARK: - Design System Version

enum DesignSystem {
    static let version = "1.0.0"
    static let minimumIOSVersion = "17.0"
}

// MARK: - Quick Reference

/*
 SPACING SCALE:
 xxxs = 2pt   |   xxs = 4pt   |   xs = 8pt    |   sm = 12pt
 md = 16pt    |   lg = 24pt   |   xl = 32pt   |   xxl = 40pt

 CORNER RADIUS:
 xs = 4pt     |   sm = 6pt    |   md = 10pt   |   lg = 16pt

 TYPOGRAPHY:
 largeTitle   |   title1      |   title2      |   title3
 headline     |   body        |   callout     |   subheadline
 footnote     |   caption1    |   caption2

 ANIMATION DURATIONS:
 instant = 0.1s  |  fast = 0.2s  |  normal = 0.3s  |  slow = 0.5s

 COLORS (prefix: .fb):
 Background: fbBackground, fbBackgroundSecondary, fbBackgroundElevated
 Labels: fbLabel, fbLabelSecondary, fbLabelTertiary
 Semantic: fbAccent, fbSuccess, fbWarning, fbError, fbDestructive
 Editor: fbSliderActive, fbHistogramRed/Green/Blue, fbFilterSelected
*/

// MARK: - Environment Setup

extension View {
    /// Apply the complete FilmBox design system environment
    func filmBoxDesignSystem() -> some View {
        self
            .withTheme()
            .environment(\.themeManager, ThemeManager.shared)
    }
}

// MARK: - Debug Overlay

/// Debug overlay showing spacing guides (development only)
struct DesignSystemDebugOverlay: View {
    @State private var showGrid = false

    var body: some View {
        #if DEBUG
        GeometryReader { geometry in
            if showGrid {
                // 8pt grid
                ForEach(0..<Int(geometry.size.width / 8), id: \.self) { i in
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 1)
                        .offset(x: CGFloat(i) * 8)
                }
                ForEach(0..<Int(geometry.size.height / 8), id: \.self) { i in
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * 8)
                }
            }
        }
        .allowsHitTesting(false)
        .onShake {
            showGrid.toggle()
        }
        #else
        EmptyView()
        #endif
    }
}

#if DEBUG
// Shake gesture for debug overlay
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(action: action))
    }
}

struct ShakeDetector: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
#endif
