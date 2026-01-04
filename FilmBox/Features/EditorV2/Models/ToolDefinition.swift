import Foundation
import SwiftUI

/// Defines a single editing tool with its properties and parameter mapping
struct ToolDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let icon: String
    let category: ToolCategory
    let parameterType: ParameterType
    let range: ClosedRange<Float>
    let defaultValue: Float
    let isNew: Bool

    /// Localized name for display in UI
    var localizedName: String {
        switch id {
        case "exposure": return L10n.Tool.exposure
        case "contrast": return L10n.Tool.contrast
        case "highlights": return L10n.Tool.highlights
        case "shadows": return L10n.Tool.shadows
        case "whites": return L10n.Tool.whites
        case "blacks": return L10n.Tool.blacks
        case "saturation": return L10n.Tool.saturation
        case "vibrance": return L10n.Tool.vibrance
        case "temperature": return L10n.Tool.temperature
        case "tint": return L10n.Tool.tint
        case "skinTone": return L10n.Tool.skinTone
        case "clarity": return L10n.Tool.clarity
        case "sharpen": return L10n.Tool.sharpen
        case "grain": return L10n.Tool.grain
        case "vignette": return L10n.Tool.vignette
        case "fade": return L10n.Tool.fade
        case "bloom": return L10n.Tool.bloom
        case "halation": return L10n.Tool.halation
        default: return name
        }
    }

    /// Tool categories matching VSCO style
    enum ToolCategory: String, CaseIterable, Sendable {
        case all = "ALL TOOLS"
        case essential = "ESSENTIAL"
        case light = "LIGHT"
        case color = "COLOR"
        case effects = "EFFECTS"

        var displayName: String {
            switch self {
            case .all: return L10n.ToolCategory.all
            case .essential: return L10n.ToolCategory.essential
            case .light: return L10n.ToolCategory.light
            case .color: return L10n.ToolCategory.color
            case .effects: return L10n.ToolCategory.effects
            }
        }
    }

    /// Maps to FilterParameters keyPaths
    enum ParameterType: Hashable, Sendable {
        // Light
        case exposure
        case contrast
        case highlights
        case shadows
        case whites
        case blacks

        // Color
        case saturation
        case vibrance
        case temperature
        case tint
        case hsl
        case splitTone
        case skinToneHue
        case skinToneSaturation

        // Effects
        case clarity
        case sharpen
        case grain
        case vignette
        case fade
        case bloom
        case halation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ToolDefinition, rhs: ToolDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tool Catalog

extension ToolDefinition {

    /// All available tools
    static let allTools: [ToolDefinition] = [
        // Light tools
        .exposure,
        .contrast,
        .highlights,
        .shadows,
        .whites,
        .blacks,

        // Color tools
        .saturation,
        .vibrance,
        .temperature,
        .tint,
        .skinTone,

        // Effects tools
        .clarity,
        .sharpen,
        .grain,
        .vignette,
        .fade,
        .bloom,
        .halation
    ]

    /// Tools filtered by category
    static func tools(for category: ToolCategory) -> [ToolDefinition] {
        switch category {
        case .all:
            return allTools
        case .essential:
            return [.exposure, .contrast, .saturation, .temperature, .sharpen]
        case .light:
            return [.exposure, .contrast, .highlights, .shadows, .whites, .blacks]
        case .color:
            return [.saturation, .vibrance, .temperature, .tint, .skinTone]
        case .effects:
            return [.sharpen, .clarity, .bloom, .halation, .grain, .vignette, .fade]
        }
    }

    // MARK: - Light Tools

    static let exposure = ToolDefinition(
        id: "exposure",
        name: "Exposure",
        icon: "sun.max",
        category: .light,
        parameterType: .exposure,
        range: -2...2,
        defaultValue: 0,
        isNew: false
    )

    static let contrast = ToolDefinition(
        id: "contrast",
        name: "Contrast",
        icon: "circle.lefthalf.filled",
        category: .light,
        parameterType: .contrast,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let highlights = ToolDefinition(
        id: "highlights",
        name: "Highlights",
        icon: "sun.max.fill",
        category: .light,
        parameterType: .highlights,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let shadows = ToolDefinition(
        id: "shadows",
        name: "Shadows",
        icon: "moon.fill",
        category: .light,
        parameterType: .shadows,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let whites = ToolDefinition(
        id: "whites",
        name: "Whites",
        icon: "circle",
        category: .light,
        parameterType: .whites,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let blacks = ToolDefinition(
        id: "blacks",
        name: "Blacks",
        icon: "circle.fill",
        category: .light,
        parameterType: .blacks,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    // MARK: - Color Tools

    static let saturation = ToolDefinition(
        id: "saturation",
        name: "Saturation",
        icon: "drop.fill",
        category: .color,
        parameterType: .saturation,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let vibrance = ToolDefinition(
        id: "vibrance",
        name: "Vibrance",
        icon: "paintpalette",
        category: .color,
        parameterType: .vibrance,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let temperature = ToolDefinition(
        id: "temperature",
        name: "Temperature",
        icon: "thermometer.medium",
        category: .color,
        parameterType: .temperature,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let tint = ToolDefinition(
        id: "tint",
        name: "Tint",
        icon: "eyedropper",
        category: .color,
        parameterType: .tint,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let skinTone = ToolDefinition(
        id: "skinTone",
        name: "Skin Tone",
        icon: "person.fill",
        category: .color,
        parameterType: .skinToneHue,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    // MARK: - Effects Tools

    static let clarity = ToolDefinition(
        id: "clarity",
        name: "Clarity",
        icon: "wand.and.rays",
        category: .effects,
        parameterType: .clarity,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let sharpen = ToolDefinition(
        id: "sharpen",
        name: "Sharpen",
        icon: "triangle",
        category: .effects,
        parameterType: .sharpen,
        range: 0...100,
        defaultValue: 0,
        isNew: false
    )

    static let grain = ToolDefinition(
        id: "grain",
        name: "Grain",
        icon: "circle.hexagongrid",
        category: .effects,
        parameterType: .grain,
        range: 0...100,
        defaultValue: 0,
        isNew: false
    )

    static let vignette = ToolDefinition(
        id: "vignette",
        name: "Vignette",
        icon: "viewfinder",
        category: .effects,
        parameterType: .vignette,
        range: -100...100,
        defaultValue: 0,
        isNew: false
    )

    static let fade = ToolDefinition(
        id: "fade",
        name: "Fade",
        icon: "square.stack.3d.up",
        category: .effects,
        parameterType: .fade,
        range: 0...100,
        defaultValue: 0,
        isNew: false
    )

    static let bloom = ToolDefinition(
        id: "bloom",
        name: "Bloom",
        icon: "sparkle",
        category: .effects,
        parameterType: .bloom,
        range: 0...100,
        defaultValue: 0,
        isNew: false
    )

    static let halation = ToolDefinition(
        id: "halation",
        name: "Halation",
        icon: "light.max",
        category: .effects,
        parameterType: .halation,
        range: 0...100,
        defaultValue: 0,
        isNew: false
    )
}
