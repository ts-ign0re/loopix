//
//  FujiRecipeFormView.swift
//  FilmBox
//
//  Unified filter editor for all presets (Fuji-style interface)
//

import SwiftUI

// MARK: - Grain Effect Options

enum GrainEffectOption: String, CaseIterable {
    case off = "Off"
    case weakSmall = "Weak / Small"
    case weakLarge = "Weak / Large"
    case strongSmall = "Strong / Small"
    case strongLarge = "Strong / Large"

    var displayName: String {
        switch self {
        case .off: return L10n.FujiRecipe.grainOff
        case .weakSmall: return L10n.FujiRecipe.grainWeakSmall
        case .weakLarge: return L10n.FujiRecipe.grainWeakLarge
        case .strongSmall: return L10n.FujiRecipe.grainStrongSmall
        case .strongLarge: return L10n.FujiRecipe.grainStrongLarge
        }
    }

    /// Convert to GrainData parameters
    var toGrainData: GrainData {
        switch self {
        case .off:
            return GrainData(amount: 0, size: 0.5, roughness: 0.5, monochromatic: true)
        case .weakSmall:
            return GrainData(amount: 30, size: 0.35, roughness: 0.5, monochromatic: true)
        case .weakLarge:
            return GrainData(amount: 30, size: 0.55, roughness: 0.55, monochromatic: true)
        case .strongSmall:
            return GrainData(amount: 65, size: 0.4, roughness: 0.6, monochromatic: true)
        case .strongLarge:
            return GrainData(amount: 65, size: 0.6, roughness: 0.65, monochromatic: true)
        }
    }

    /// Create from GrainData
    static func from(_ grain: GrainData) -> GrainEffectOption {
        if grain.amount <= 0 { return .off }
        let isStrong = grain.amount >= 50
        let isLarge = grain.size >= 0.5
        switch (isStrong, isLarge) {
        case (false, false): return .weakSmall
        case (false, true): return .weakLarge
        case (true, false): return .strongSmall
        case (true, true): return .strongLarge
        }
    }
}

// MARK: - Fuji Recipe Form View

@available(iOS 17.0, *)
struct FujiRecipeFormView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Input

    /// Existing filter to edit (nil for new filter)
    let existingFilter: FilterPreset?

    // MARK: - Form State - Fuji Simulation

    @State private var name = ""
    @State private var filmSimulation: FilmSimulationType = .classicNegative
    @State private var grainEffect: GrainEffectOption = .off
    @State private var colorChrome: ColorChromeData.ColorChromeLevel = .off
    @State private var colorChromeFxBlue: ColorChromeData.ColorChromeLevel = .off
    @State private var wbRedShift: Int = 0
    @State private var wbBlueShift: Int = 0
    @State private var dynamicRange: DynamicRangeMode = .dr400
    @State private var highlight: Float = 0
    @State private var shadow: Float = 0
    @State private var color: Int = 0
    @State private var sharpness: Int = 0
    @State private var noiseReduction: Int = 0
    @State private var clarity: Int = 0

    // MARK: - Form State - Additional Effects

    @State private var grainAmount: Float = 0
    @State private var grainSize: Float = 0.5
    @State private var grainRoughness: Float = 0.5
    @State private var grainMonochromatic: Bool = true

    @State private var vignetteAmount: Float = 0
    @State private var vignetteMidpoint: Float = 0.5
    @State private var vignetteRoundness: Float = 0
    @State private var vignetteFeather: Float = 0.5

    @State private var fade: Float = 0
    @State private var sharpenRadius: Float = 1.0

    // MARK: - UI State

    @State private var isCreating = false
    @State private var showHelp = false
    @State private var showNameRequired = false
    @State private var showAdvancedGrain = false

    // MARK: - Computed

    private var isEditing: Bool { existingFilter != nil }
    private var isReadOnly: Bool {
        guard let filter = existingFilter else { return false }
        return filter.source == .builtIn
    }

    // MARK: - Callback

    var onSave: (FilterPreset) -> Void

    // MARK: - Init

    init(existingFilter: FilterPreset? = nil, onSave: @escaping (FilterPreset) -> Void) {
        self.existingFilter = existingFilter
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    nameSection
                    filmSimulationSection
                    grainSection
                    colorChromeSection
                    whiteBalanceSection
                    dynamicRangeSection
                    toneSection
                    detailSection

                    // Loopix app-specific parameters
                    loopixParametersSection

                    // Read-only notice
                    if isReadOnly {
                        Text("Built-in filters are read-only. Use Duplicate to create an editable copy.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text(isEditing ? "/ edit recipe" : L10n.FujiRecipe.title)
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                        Button {
                            showHelp = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !isReadOnly {
                        createButton
                    }
                }
            }
            .fullScreenCover(isPresented: $showHelp) {
                recipeHelpSheet
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadExistingFilter()
        }
    }

    // MARK: - Load Existing Filter

    private func loadExistingFilter() {
        guard let filter = existingFilter else { return }

        name = filter.name

        let params = filter.parameters

        // Fuji simulation
        filmSimulation = params.filmSimulation
        colorChrome = params.colorChrome.effect
        colorChromeFxBlue = params.colorChrome.fxBlue
        wbRedShift = params.whiteBalanceShift.redShift
        wbBlueShift = params.whiteBalanceShift.blueShift
        dynamicRange = params.dynamicRange

        // Tone
        highlight = params.highlights / 25  // Map -100..100 to -4..4
        shadow = params.shadows / 25
        color = Int(params.saturation / 25)

        // Detail
        sharpness = Int(params.sharpness / 25)  // Map 0..100 to -4..4
        noiseReduction = Int(params.noiseReduction / 25)
        clarity = Int(params.clarity / 20)  // Map -100..100 to -5..5

        // Grain - use preset or advanced values
        grainEffect = GrainEffectOption.from(params.grain)
        grainAmount = params.grain.amount
        grainSize = params.grain.size
        grainRoughness = params.grain.roughness
        grainMonochromatic = params.grain.monochromatic

        // Show advanced grain if custom values
        if params.grain.amount > 0 && grainEffect.toGrainData != params.grain {
            showAdvancedGrain = true
        }

        // Vignette
        vignetteAmount = params.vignette.amount
        vignetteMidpoint = params.vignette.midpoint
        vignetteRoundness = params.vignette.roundness
        vignetteFeather = params.vignette.feather

        // Effects
        fade = params.fade
        sharpenRadius = params.sharpenRadius
    }

    // MARK: - Help Sheet

    private var recipeHelpSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(L10n.FujiRecipe.helpTitle)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showHelp = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Definition
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.FujiRecipe.helpIntro)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(4)

                        Text(L10n.FujiRecipe.helpCredit)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(L10n.FujiRecipe.helpInstruction)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 12) {
                        helpItem(
                            title: L10n.FujiRecipe.helpFilmSim,
                            desc: L10n.FujiRecipe.helpFilmSimDesc
                        )

                        helpItem(
                            title: L10n.FujiRecipe.helpWbShift,
                            desc: L10n.FujiRecipe.helpWbShiftDesc
                        )

                        helpItem(
                            title: L10n.FujiRecipe.helpDynamicRange,
                            desc: L10n.FujiRecipe.helpDynamicRangeDesc
                        )

                        helpItem(
                            title: L10n.FujiRecipe.helpHighlightShadow,
                            desc: L10n.FujiRecipe.helpHighlightShadowDesc
                        )

                        helpItem(
                            title: L10n.FujiRecipe.helpColor,
                            desc: L10n.FujiRecipe.helpColorDesc
                        )

                        helpItem(
                            title: L10n.FujiRecipe.helpGrain,
                            desc: L10n.FujiRecipe.helpGrainDesc
                        )

                        helpItem(
                            title: L10n.FujiRecipe.helpColorChrome,
                            desc: L10n.FujiRecipe.helpColorChromeDesc
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.12))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func helpItem(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.yellow)
            Text(desc)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(2)
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        FormSection(title: L10n.FujiRecipe.name) {
            TextField(L10n.FujiRecipe.recipeName, text: $name)
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var filmSimulationSection: some View {
        FormSection(title: L10n.FujiRecipe.filmSimulation) {
            FormPicker(
                selection: $filmSimulation,
                options: FilmSimulationType.allCases.filter { $0 != .none }
            ) { type in
                type.displayName
            }
        }
        .disabled(isReadOnly)
    }

    private var grainSection: some View {
        FormSection(title: L10n.FujiRecipe.grainEffect) {
            FormPicker(
                selection: $grainEffect,
                options: GrainEffectOption.allCases
            ) { option in
                option.displayName
            }
        }
        .disabled(isReadOnly)
    }

    private var colorChromeSection: some View {
        FormSection(title: L10n.FujiRecipe.colorChrome) {
            VStack(spacing: 12) {
                LabeledPicker(label: L10n.FujiRecipe.effect, selection: $colorChrome)
                LabeledPicker(label: L10n.FujiRecipe.fxBlue, selection: $colorChromeFxBlue)
            }
        }
        .disabled(isReadOnly)
    }

    private var whiteBalanceSection: some View {
        FormSection(title: L10n.FujiRecipe.whiteBalanceShift) {
            VStack(spacing: 16) {
                // Red Shift - cyan to red gradient
                GradientSlider(
                    value: Binding(
                        get: { Float(wbRedShift) },
                        set: { wbRedShift = Int($0) }
                    ),
                    range: -9...9,
                    step: 1,
                    label: L10n.FujiRecipe.red,
                    gradient: Gradient(colors: [.cyan, .white, .red])
                )

                // Blue Shift - yellow to blue gradient
                GradientSlider(
                    value: Binding(
                        get: { Float(wbBlueShift) },
                        set: { wbBlueShift = Int($0) }
                    ),
                    range: -9...9,
                    step: 1,
                    label: L10n.FujiRecipe.blue,
                    gradient: Gradient(colors: [.yellow, .white, .blue])
                )
            }
        }
        .disabled(isReadOnly)
    }

    private var dynamicRangeSection: some View {
        FormSection(title: L10n.FujiRecipe.dynamicRange) {
            FormPicker(
                selection: $dynamicRange,
                options: DynamicRangeMode.allCases
            ) { mode in
                mode.rawValue
            }
        }
        .disabled(isReadOnly)
    }

    private var toneSection: some View {
        FormSection(title: L10n.FujiRecipe.tone) {
            VStack(spacing: 12) {
                StepSlider(value: $highlight, range: -2...4, step: 0.5, label: L10n.FujiRecipe.highlight)
                StepSlider(value: $shadow, range: -2...4, step: 0.5, label: L10n.FujiRecipe.shadow)
                StepSlider(
                    value: Binding(
                        get: { Float(color) },
                        set: { color = Int($0) }
                    ),
                    range: -4...4,
                    step: 1,
                    label: L10n.FujiRecipe.color
                )
            }
        }
        .disabled(isReadOnly)
    }

    private var detailSection: some View {
        FormSection(title: L10n.FujiRecipe.detail) {
            VStack(spacing: 12) {
                StepSlider(
                    value: Binding(
                        get: { Float(sharpness) },
                        set: { sharpness = Int($0) }
                    ),
                    range: -4...4,
                    step: 1,
                    label: L10n.FujiRecipe.sharpness
                )
                StepSlider(
                    value: Binding(
                        get: { Float(noiseReduction) },
                        set: { noiseReduction = Int($0) }
                    ),
                    range: -4...4,
                    step: 1,
                    label: L10n.FujiRecipe.noiseReduction
                )
                StepSlider(
                    value: Binding(
                        get: { Float(clarity) },
                        set: { clarity = Int($0) }
                    ),
                    range: -5...5,
                    step: 1,
                    label: L10n.FujiRecipe.clarity
                )
            }
        }
        .disabled(isReadOnly)
    }

    // MARK: - Loopix App Parameters Section

    private var loopixParametersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with app icon style
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.yellow)
                Text("loopix parameters")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Parameters container
            VStack(spacing: 16) {
                effectsSection
                advancedGrainSection
                vignetteSection
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                    )
            )

            // Explanation text
            Text("these parameters are app-specific and not part of fuji recipe format. they will be exported with qr code but may not work in other apps.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Effects Section

    private var effectsSection: some View {
        FormSection(title: "effects") {
            VStack(spacing: 12) {
                // Fade
                StepSlider(
                    value: $fade,
                    range: 0...100,
                    step: 5,
                    label: "fade"
                )

                // Sharpen radius
                ContinuousSlider(
                    value: $sharpenRadius,
                    range: 0.5...3.0,
                    label: "sharpen radius",
                    format: "%.1f"
                )
            }
        }
        .disabled(isReadOnly)
    }

    // MARK: - Advanced Grain Section

    private var advancedGrainSection: some View {
        FormSection(title: "grain (advanced)") {
            VStack(spacing: 12) {
                // Toggle for advanced mode
                HStack {
                    Text("custom grain")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Toggle("", isOn: $showAdvancedGrain)
                        .labelsHidden()
                        .tint(.yellow)
                }

                if showAdvancedGrain {
                    // Grain amount
                    ContinuousSlider(
                        value: $grainAmount,
                        range: 0...100,
                        label: "amount",
                        format: "%.0f"
                    )

                    // Grain size
                    ContinuousSlider(
                        value: $grainSize,
                        range: 0...1,
                        label: "size",
                        format: "%.2f"
                    )

                    // Grain roughness
                    ContinuousSlider(
                        value: $grainRoughness,
                        range: 0...1,
                        label: "roughness",
                        format: "%.2f"
                    )

                    // Monochromatic toggle
                    HStack {
                        Text("monochromatic")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Toggle("", isOn: $grainMonochromatic)
                            .labelsHidden()
                            .tint(.yellow)
                    }
                }
            }
        }
        .disabled(isReadOnly)
    }

    // MARK: - Vignette Section

    private var vignetteSection: some View {
        FormSection(title: "vignette") {
            VStack(spacing: 12) {
                // Amount (negative = brighten edges)
                ContinuousSlider(
                    value: $vignetteAmount,
                    range: -100...100,
                    label: "amount",
                    format: "%.0f"
                )

                // Only show other controls if amount != 0
                if vignetteAmount != 0 {
                    ContinuousSlider(
                        value: $vignetteMidpoint,
                        range: 0...1,
                        label: "midpoint",
                        format: "%.2f"
                    )

                    ContinuousSlider(
                        value: $vignetteRoundness,
                        range: -100...100,
                        label: "roundness",
                        format: "%.0f"
                    )

                    ContinuousSlider(
                        value: $vignetteFeather,
                        range: 0...1,
                        label: "feather",
                        format: "%.2f"
                    )
                }
            }
        }
        .disabled(isReadOnly)
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                showNameRequired = true
            } else {
                Task {
                    await createFilter()
                }
            }
        } label: {
            if isCreating {
                ApertureLoader(size: 20, color: .yellow)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .yellow)
            }
        }
        .disabled(isCreating)
        .alert(L10n.FujiRecipe.nameRequired, isPresented: $showNameRequired) {
            Button(L10n.Action.ok, role: .cancel) {}
        } message: {
            Text(L10n.FujiRecipe.enterName)
        }
    }

    // MARK: - Create Filter

    private func createFilter() async {
        isCreating = true

        // Build base parameters using FujiRecipeImporter logic
        var params = FujiRecipeImporter.buildParameters(
            filmSimulation: filmSimulation,
            grainEffect: showAdvancedGrain ? GrainEffectOption.off.rawValue : grainEffect.rawValue,
            colorChrome: colorChrome,
            colorChromeFxBlue: colorChromeFxBlue,
            wbRedShift: wbRedShift,
            wbBlueShift: wbBlueShift,
            dynamicRange: dynamicRange,
            highlight: highlight,
            shadow: shadow,
            color: color,
            sharpness: sharpness,
            noiseReduction: noiseReduction,
            clarity: clarity
        )

        // Add advanced grain if enabled
        if showAdvancedGrain {
            params.grain = GrainData(
                amount: grainAmount,
                size: grainSize,
                roughness: grainRoughness,
                monochromatic: grainMonochromatic
            )
        }

        // Add vignette
        if vignetteAmount != 0 {
            params.vignette = VignetteData(
                amount: vignetteAmount,
                midpoint: vignetteMidpoint,
                roundness: vignetteRoundness,
                feather: vignetteFeather
            )
        }

        // Add effects
        params.fade = fade
        params.sharpenRadius = sharpenRadius

        let preset = FilterPreset(
            id: existingFilter?.id ?? UUID(),
            name: name,
            category: .custom,
            source: existingFilter?.source ?? .userCreated,
            parameters: params,
            metadata: FilterPreset.FilterMetadata(
                filmStock: filmSimulation.rawValue,
                characteristics: ["fuji", "recipe", filmSimulation.rawValue.lowercased()]
            )
        )

        // Save or update to storage
        if isEditing {
            try? await FilterStorage.shared.update(preset)
            Analytics.shared.trackEvent(category: .filter, action: "update", name: preset.name)
        } else {
            try? await FilterStorage.shared.save(preset)
            Analytics.shared.trackFilterCreate(name: preset.name, source: "fuji_recipe")
        }

        // Small delay for loader visibility
        try? await Task.sleep(for: .milliseconds(300))

        onSave(preset)
        dismiss()
    }
}

// MARK: - Form Section

private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.lowercase)

            content()
        }
    }
}

// MARK: - Form Picker

private struct FormPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let labelProvider: (T) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = option
                        }
                    } label: {
                        Text(labelProvider(option))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(selection == option ? .black : .white.opacity(0.7))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selection == option
                                    ? Color.yellow
                                    : Color.white.opacity(0.1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Labeled Picker

private struct LabeledPicker: View {
    let label: String
    @Binding var selection: ColorChromeData.ColorChromeLevel

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 70, alignment: .leading)

            Spacer()

            HStack(spacing: 6) {
                ForEach(ColorChromeData.ColorChromeLevel.allCases, id: \.self) { level in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = level
                        }
                    } label: {
                        Text(level.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(selection == level ? .black : .white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selection == level
                                    ? Color.yellow
                                    : Color.white.opacity(0.1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Gradient Slider

private struct GradientSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let label: String
    let gradient: Gradient

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Text(formatValue(value))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(value == 0 ? .white.opacity(0.5) : .white)
            }

            GeometryReader { geometry in
                let centerX = geometry.size.width * CGFloat((0 - range.lowerBound) / (range.upperBound - range.lowerBound))
                let thumbX = geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))

                ZStack {
                    // Gradient track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)

                    // Center marker
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 4)
                        .position(x: centerX, y: geometry.size.height / 2)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .position(x: thumbX, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let percent = gesture.location.x / geometry.size.width
                            let newValue = range.lowerBound + Float(percent) * (range.upperBound - range.lowerBound)
                            let stepped = (newValue / step).rounded() * step
                            value = min(max(stepped, range.lowerBound), range.upperBound)
                        }
                )
            }
            .frame(height: 24)
        }
    }

    private func formatValue(_ val: Float) -> String {
        let intVal = Int(val)
        if intVal > 0 {
            return "+\(intVal)"
        } else {
            return "\(intVal)"
        }
    }
}

// MARK: - Step Slider

private struct StepSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 120, alignment: .leading)

            GeometryReader { geometry in
                let centerX = geometry.size.width * CGFloat((0 - range.lowerBound) / (range.upperBound - range.lowerBound))
                let thumbX = geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                let fillWidth = abs(thumbX - centerX)
                let fillX = min(thumbX, centerX) + fillWidth / 2

                ZStack {
                    // Track background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)

                    // Active fill from center (only show if value != 0)
                    if abs(value) > 0.001 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.yellow)
                            .frame(width: fillWidth, height: 6)
                            .position(x: fillX, y: geometry.size.height / 2)
                    }

                    // Center marker
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 4, height: 4)
                        .position(x: centerX, y: geometry.size.height / 2)

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .position(x: thumbX, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let percent = gesture.location.x / geometry.size.width
                            let newValue = range.lowerBound + Float(percent) * (range.upperBound - range.lowerBound)
                            let stepped = (newValue / step).rounded() * step
                            value = min(max(stepped, range.lowerBound), range.upperBound)
                        }
                )
            }
            .frame(height: 18)

            Text(formatValue(value))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(value == 0 ? .white.opacity(0.5) : .white)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func formatValue(_ val: Float) -> String {
        if step >= 1 {
            let intVal = Int(val)
            if intVal > 0 {
                return "+\(intVal)"
            } else {
                return "\(intVal)"
            }
        } else {
            if val > 0 {
                return String(format: "+%.1f", val)
            } else if val < 0 {
                return String(format: "%.1f", val)
            } else {
                return "0"
            }
        }
    }
}

// MARK: - Continuous Slider (for float values without stepping)

private struct ContinuousSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    let format: String

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 120, alignment: .leading)

            GeometryReader { geometry in
                let thumbX = geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))

                ZStack {
                    // Track background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)

                    // Active fill from start
                    if value > range.lowerBound {
                        HStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.yellow)
                                .frame(width: max(0, thumbX), height: 6)
                            Spacer()
                        }
                    }

                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        .position(x: thumbX, y: geometry.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let percent = gesture.location.x / geometry.size.width
                            let newValue = range.lowerBound + Float(percent) * (range.upperBound - range.lowerBound)
                            value = min(max(newValue, range.lowerBound), range.upperBound)
                        }
                )
            }
            .frame(height: 18)

            Text(String(format: format, value))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        FujiRecipeFormView { preset in
            print("Created preset: \(preset.name)")
        }
    }
}
