//
//  FujiRecipeFormView.swift
//  FilmBox
//
//  Fuji X Recipe input form for creating filters
//

import SwiftUI

// MARK: - Grain Effect Options

enum GrainEffectOption: String, CaseIterable {
    case off = "Off"
    case weakSmall = "Weak / Small"
    case weakLarge = "Weak / Large"
    case strongSmall = "Strong / Small"
    case strongLarge = "Strong / Large"

    var displayName: String { rawValue }
}

// MARK: - Fuji Recipe Form View

@available(iOS 17.0, *)
struct FujiRecipeFormView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State

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

    @State private var isCreating = false

    // MARK: - Callback

    var onSave: (FilterPreset) -> Void

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
                    Text("/ fuji_recipe")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .confirmationAction) {
                    createButton
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var nameSection: some View {
        FormSection(title: "name") {
            TextField("recipe name", text: $name)
                .font(.system(size: 16, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var filmSimulationSection: some View {
        FormSection(title: "film simulation") {
            FormPicker(
                selection: $filmSimulation,
                options: FilmSimulationType.allCases.filter { $0 != .none }
            ) { type in
                type.displayName
            }
        }
    }

    private var grainSection: some View {
        FormSection(title: "grain effect") {
            FormPicker(
                selection: $grainEffect,
                options: GrainEffectOption.allCases
            ) { option in
                option.displayName
            }
        }
    }

    private var colorChromeSection: some View {
        FormSection(title: "color chrome") {
            VStack(spacing: 12) {
                LabeledPicker(label: "effect", selection: $colorChrome)
                LabeledPicker(label: "fx blue", selection: $colorChromeFxBlue)
            }
        }
    }

    private var whiteBalanceSection: some View {
        FormSection(title: "white balance shift") {
            VStack(spacing: 16) {
                // Red Shift - cyan to red gradient
                GradientSlider(
                    value: Binding(
                        get: { Float(wbRedShift) },
                        set: { wbRedShift = Int($0) }
                    ),
                    range: -9...9,
                    step: 1,
                    label: "red",
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
                    label: "blue",
                    gradient: Gradient(colors: [.yellow, .white, .blue])
                )
            }
        }
    }

    private var dynamicRangeSection: some View {
        FormSection(title: "dynamic range") {
            FormPicker(
                selection: $dynamicRange,
                options: DynamicRangeMode.allCases
            ) { mode in
                mode.rawValue
            }
        }
    }

    private var toneSection: some View {
        FormSection(title: "tone") {
            VStack(spacing: 12) {
                StepSlider(value: $highlight, range: -2...4, step: 0.5, label: "highlight")
                StepSlider(value: $shadow, range: -2...4, step: 0.5, label: "shadow")
                StepSlider(
                    value: Binding(
                        get: { Float(color) },
                        set: { color = Int($0) }
                    ),
                    range: -4...4,
                    step: 1,
                    label: "color"
                )
            }
        }
    }

    private var detailSection: some View {
        FormSection(title: "detail") {
            VStack(spacing: 12) {
                StepSlider(
                    value: Binding(
                        get: { Float(sharpness) },
                        set: { sharpness = Int($0) }
                    ),
                    range: -4...4,
                    step: 1,
                    label: "sharpness"
                )
                StepSlider(
                    value: Binding(
                        get: { Float(noiseReduction) },
                        set: { noiseReduction = Int($0) }
                    ),
                    range: -4...4,
                    step: 1,
                    label: "noise reduction"
                )
                StepSlider(
                    value: Binding(
                        get: { Float(clarity) },
                        set: { clarity = Int($0) }
                    ),
                    range: -5...5,
                    step: 1,
                    label: "clarity"
                )
            }
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            Task {
                await createFilter()
            }
        } label: {
            if isCreating {
                ApertureLoader(size: 20, color: .yellow)
            } else {
                Text("create")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(name.isEmpty ? .white.opacity(0.3) : .yellow)
            }
        }
        .disabled(name.isEmpty || isCreating)
    }

    // MARK: - Create Filter

    private func createFilter() async {
        isCreating = true

        // Build parameters using FujiRecipeImporter logic
        let params = FujiRecipeImporter.buildParameters(
            filmSimulation: filmSimulation,
            grainEffect: grainEffect.rawValue,
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

        let preset = FilterPreset(
            id: UUID(),
            name: name,
            category: .custom,
            source: .userCreated,
            parameters: params,
            metadata: FilterPreset.FilterMetadata(
                filmStock: filmSimulation.rawValue,
                characteristics: ["fuji", "recipe", filmSimulation.rawValue.lowercased()]
            )
        )

        // Save to storage
        try? await FilterStorage.shared.save(preset)

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

// MARK: - Preview

#Preview {
    if #available(iOS 17.0, *) {
        FujiRecipeFormView { preset in
            print("Created preset: \(preset.name)")
        }
    }
}
