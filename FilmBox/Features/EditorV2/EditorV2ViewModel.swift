import Foundation
import CoreImage
import SwiftUI
import Photos

/// ViewModel wrapper for EditorV2 that adds VSCO-style mode management
/// Delegates core editing logic to the existing EditorViewModel
@Observable
@MainActor
final class EditorV2ViewModel {

    // MARK: - Wrapped EditorViewModel

    /// The underlying editor view model that handles actual image processing
    let editor: EditorViewModel

    // MARK: - VSCO-Style State

    /// Current mode of the editor (browse, filterDetail, toolDetail)
    var mode: EditorV2Mode = .browse

    /// Currently selected tab in the VSCO tab bar
    var selectedTab: EditorV2Tab = .filters

    /// Selected tool category when in tools view
    var selectedToolCategory: ToolDefinition.ToolCategory = .all

    /// Selected filter category
    var selectedFilterCategory: FilterCategory = .all

    /// Currently active tool (when in toolDetail mode)
    var activeTool: ToolDefinition?

    /// Pending parameters snapshot for cancel functionality
    private var pendingParametersSnapshot: FilterParameters?

    /// Pending preset snapshot for cancel functionality
    private var pendingPresetSnapshot: FilterPreset?

    /// Pending intensity snapshot for cancel functionality
    private var pendingIntensitySnapshot: Float?

    // MARK: - Computed Properties

    /// Whether tab bar should be visible based on current mode
    var showTabBar: Bool {
        mode.showTabBar
    }

    /// Current filter name for display
    var currentFilterName: String {
        editor.selectedPreset?.name ?? "Original"
    }

    /// Current filter category display
    var currentFilterCategory: String {
        editor.selectedPreset?.category.rawValue.uppercased() ?? "ORIGINAL"
    }

    /// Combined filter name with category (like "A6 PRO / Analog")
    var filterDisplayName: String {
        if let preset = editor.selectedPreset {
            return "\(preset.name) / \(preset.category.rawValue.capitalized)"
        }
        return "Original"
    }

    // MARK: - Initialization

    init(editor: EditorViewModel = EditorViewModel()) {
        self.editor = editor

        // Track editor open (funnel step 2)
        Analytics.shared.trackEditorOpen()
    }

    // MARK: - Mode Transitions

    /// Enter filter detail mode to adjust filter parameters
    func enterFilterDetailMode() {
        guard editor.selectedPreset != nil else { return }

        // Snapshot current state for cancel
        pendingParametersSnapshot = editor.currentParameters
        pendingPresetSnapshot = editor.selectedPreset
        pendingIntensitySnapshot = editor.filterIntensity

        withAnimation(.easeInOut(duration: 0.25)) {
            mode = .filterDetail
        }
    }

    /// Enter tool detail mode to adjust a specific tool
    func enterToolDetailMode(_ tool: ToolDefinition) {
        // Snapshot current state for cancel
        pendingParametersSnapshot = editor.currentParameters

        activeTool = tool

        withAnimation(.easeInOut(duration: 0.25)) {
            mode = .toolDetail(tool)
        }
    }

    /// Confirm current changes and return to browse mode
    func confirmChanges() {
        // Track tool/filter usage before clearing
        if let tool = activeTool {
            let value = getValue(for: tool)
            Analytics.shared.trackToolUse(toolName: tool.name, value: value)
        }

        // Clear snapshots (changes are kept)
        pendingParametersSnapshot = nil
        pendingPresetSnapshot = nil
        pendingIntensitySnapshot = nil
        activeTool = nil

        withAnimation(.easeInOut(duration: 0.25)) {
            mode = .browse
        }
    }

    /// Cancel current changes and return to browse mode
    func cancelChanges() {
        // Restore snapshots
        if let snapshot = pendingParametersSnapshot {
            editor.currentParameters = snapshot
        }
        if let presetSnapshot = pendingPresetSnapshot {
            editor.selectedPreset = presetSnapshot
        }
        if let intensitySnapshot = pendingIntensitySnapshot {
            editor.setFilterIntensity(intensitySnapshot)
        }

        // Clear snapshots
        pendingParametersSnapshot = nil
        pendingPresetSnapshot = nil
        pendingIntensitySnapshot = nil
        activeTool = nil

        withAnimation(.easeInOut(duration: 0.25)) {
            mode = .browse
        }
    }

    // MARK: - Tool Value Access

    /// Get current value for a tool parameter
    func getValue(for tool: ToolDefinition) -> Float {
        let params = editor.currentParameters
        return getParameterValue(params, for: tool.parameterType)
    }

    /// Set value for a tool parameter
    func setValue(_ value: Float, for tool: ToolDefinition) {
        var params = editor.currentParameters
        setParameterValue(&params, value: value, for: tool.parameterType)
        editor.currentParameters = params
    }

    // MARK: - Parameter Value Helpers

    // swiftlint:disable:next cyclomatic_complexity
    private func getParameterValue(_ params: FilterParameters, for type: ToolDefinition.ParameterType) -> Float {
        switch type {
        case .exposure: return params.exposure
        case .contrast: return params.contrast
        case .highlights: return params.highlights
        case .shadows: return params.shadows
        case .whites: return params.whites
        case .blacks: return params.blacks
        case .saturation: return params.saturation
        case .vibrance: return params.vibrance
        case .temperature: return params.temperature
        case .tint: return params.tint
        case .skinToneHue: return params.skinToneHue
        case .skinToneSaturation: return params.skinToneSaturation
        case .radialBlur: return params.radialBlur.amount
        case .linearBlur: return params.linearBlur.amount
        case .clarity: return params.clarity
        case .sharpen: return params.sharpness
        case .grain: return params.grain.amount
        case .vignette: return params.vignette.amount
        case .fade: return params.fade
        case .bloom: return params.bloom.intensity
        case .halation: return params.halation.intensity
        case .hsl, .splitTone: return 0
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func setParameterValue(_ params: inout FilterParameters, value: Float, for type: ToolDefinition.ParameterType) {
        switch type {
        case .exposure: params.exposure = value
        case .contrast: params.contrast = value
        case .highlights: params.highlights = value
        case .shadows: params.shadows = value
        case .whites: params.whites = value
        case .blacks: params.blacks = value
        case .saturation: params.saturation = value
        case .vibrance: params.vibrance = value
        case .temperature: params.temperature = value
        case .tint: params.tint = value
        case .skinToneHue: params.skinToneHue = value
        case .skinToneSaturation: params.skinToneSaturation = value
        case .radialBlur: params.radialBlur.amount = value
        case .linearBlur: params.linearBlur.amount = value
        case .clarity: params.clarity = value
        case .sharpen: params.sharpness = value
        case .grain: params.grain.amount = value
        case .vignette: params.vignette.amount = value
        case .fade: params.fade = value
        case .bloom: params.bloom.intensity = value
        case .halation: params.halation.intensity = value
        case .hsl, .splitTone: break
        }
    }

    // MARK: - Filter Actions

    /// Select a filter preset
    func selectFilter(_ preset: FilterPreset?) {
        editor.selectedPreset = preset

        // Track filter application
        if let preset = preset {
            Analytics.shared.trackFilterApply(
                filterName: preset.name,
                category: preset.category.rawValue,
                intensity: editor.filterIntensity
            )
        }
    }

    /// Update filter intensity
    func setFilterIntensity(_ intensity: Float) {
        editor.setFilterIntensity(intensity)
    }

    // MARK: - Tab Navigation

    /// Switch to a different tab
    func selectTab(_ tab: EditorV2Tab) {
        guard mode == .browse else { return }
        selectedTab = tab

        // Track tab switch
        Analytics.shared.trackEditorTabSwitch(tab: tab.rawValue)
    }

    // MARK: - Image Loading

    /// Load an image from PHAsset
    func loadAsset(_ asset: PHAsset, initialParameters: FilterParameters = .identity) {
        editor.loadAsset(asset, initialParameters: initialParameters)
    }

    /// Load a CIImage directly
    func loadImage(_ image: CIImage, parameters: FilterParameters? = nil) {
        editor.loadCIImage(image, initialParameters: parameters)
    }

    /// Load a CIImage with full edit snapshot (restores filter selection)
    func loadImage(_ image: CIImage, snapshot: EditSnapshot?) {
        editor.loadCIImage(image, initialParameters: snapshot?.parameters)

        // Restore filter selection if we have a preset ID
        if let presetID = snapshot?.selectedPresetID {
            Task {
                // Find the preset by ID
                let allPresets = await FilterStorage.shared.allPresets
                if let preset = allPresets.first(where: { $0.id == presetID }) {
                    await MainActor.run {
                        editor.selectedPreset = preset
                        editor.filterIntensity = snapshot?.filterIntensity ?? 100
                    }
                }
            }
        }
    }
}

// MARK: - Filter Parameter Mapping

extension EditorV2ViewModel {

    /// Filter sub-parameters that can be adjusted in FilterDetailView
    enum FilterSubParameter: String, CaseIterable, Identifiable {
        case strength = "Strength"
        case contrast = "Contrast"
        case color = "Color"
        case tone = "Tone"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .strength: return "chart.bar"
            case .contrast: return "circle.lefthalf.filled"
            case .color: return "paintpalette"
            case .tone: return "slider.horizontal.below.rectangle"
            }
        }
    }

    /// Get value for filter sub-parameter
    func getFilterSubValue(for param: FilterSubParameter) -> Float {
        switch param {
        case .strength:
            return editor.filterIntensity
        case .contrast:
            return editor.currentParameters.contrast
        case .color:
            return editor.currentParameters.saturation
        case .tone:
            return editor.currentParameters.temperature
        }
    }

    /// Set value for filter sub-parameter
    func setFilterSubValue(_ value: Float, for param: FilterSubParameter) {
        switch param {
        case .strength:
            editor.setFilterIntensity(value)
        case .contrast:
            var params = editor.currentParameters
            params.contrast = value
            editor.currentParameters = params
        case .color:
            var params = editor.currentParameters
            params.saturation = value
            editor.currentParameters = params
        case .tone:
            var params = editor.currentParameters
            params.temperature = value
            editor.currentParameters = params
        }
    }

    /// Range for filter sub-parameter
    func getFilterSubRange(for param: FilterSubParameter) -> ClosedRange<Float> {
        switch param {
        case .strength:
            return 0...100
        case .contrast, .color, .tone:
            return -100...100
        }
    }
}
