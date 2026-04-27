import SwiftUI

enum CameraTheme {
    // MARK: - Colors
    static let background = Color.black
    static let surface = Color(white: 0.1)
    static let surfaceLight = Color(white: 0.15)
    static let text = Color.white
    static let textSecondary = Color(white: 0.6)
    static let accent = Color.yellow
    static let shutterRing = Color.white
    static let shutterFill = Color.white
    static let controlActive = Color.yellow
    static let controlInactive = Color(white: 0.5)
    static let pillBackground = Color(white: 0.2)
    static let pillSelected = Color.yellow

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 4
    static let paddingMedium: CGFloat = 8
    static let paddingLarge: CGFloat = 16
    static let paddingXL: CGFloat = 24

    // MARK: - Sizes
    static let shutterSize: CGFloat = 64
    static let shutterInnerSize: CGFloat = 54
    static let pillHeight: CGFloat = 32
    static let pillCornerRadius: CGFloat = 16
    static let thumbnailSize: CGFloat = 44
    static let focusSquareSize: CGFloat = 80
    static let lensButtonSize: CGFloat = 36
    static let topBarHeight: CGFloat = 56
    static let bottomBarHeight: CGFloat = 120

    // MARK: - Typography
    static let captionFont = Font.system(size: 11, weight: .medium, design: .rounded)
    static let bodyFont = Font.system(size: 14, weight: .medium, design: .rounded)
    static let titleFont = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let monoFont = Font.system(size: 13, weight: .medium, design: .monospaced)
}
