import SwiftUI

// MARK: - Presets Tab View

/// User presets management tab
struct PresetsTabView: View {

    // MARK: - Properties

    /// Current filter parameters
    @Binding var parameters: FilterParameters

    /// Currently selected preset
    @Binding var selectedPreset: FilterPreset?

    /// Preset manager for storage operations
    @State private var presetManager = PresetManager.shared

    /// Whether the save preset sheet is shown
    @State private var showingSaveSheet = false

    /// Whether the edit preset sheet is shown
    @State private var showingEditSheet = false

    /// Preset being edited
    @State private var editingPreset: FilterPreset?

    /// Search text
    @State private var searchText = ""

    /// Confirmation dialog for deletion
    @State private var presetToDelete: FilterPreset?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Content
            if presetManager.userPresets.isEmpty && searchText.isEmpty {
                emptyStateView
            } else {
                presetsList
            }

            Divider()

            // Save current as preset button
            saveCurrentButton
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingSaveSheet) {
            SavePresetSheet(
                parameters: parameters,
                onSave: { name, category in
                    saveNewPreset(name: name, category: category)
                }
            )
        }
        .sheet(item: $editingPreset) { preset in
            EditPresetSheet(
                preset: preset,
                onSave: { updatedPreset in
                    presetManager.updatePreset(updatedPreset)
                }
            )
        }
        .confirmationDialog(
            "Delete Preset",
            isPresented: .init(
                get: { presetToDelete != nil },
                set: { if !$0 { presetToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let preset = presetToDelete {
                Button("Delete \"\(preset.name)\"", role: .destructive) {
                    presetManager.deletePreset(preset)
                    presetToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    presetToDelete = nil
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search presets", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Saved Presets")
                .font(.headline)

            Text("Save your current adjustments as a preset to quickly apply them to other photos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Presets List

    private var presetsList: some View {
        List {
            ForEach(filteredPresets) { preset in
                PresetRow(
                    preset: preset,
                    isSelected: selectedPreset?.id == preset.id,
                    onSelect: {
                        applyPreset(preset)
                    },
                    onEdit: {
                        editingPreset = preset
                    },
                    onDelete: {
                        presetToDelete = preset
                    },
                    onExport: {
                        exportPreset(preset)
                    }
                )
            }
        }
        .listStyle(.plain)
    }

    private var filteredPresets: [FilterPreset] {
        if searchText.isEmpty {
            return presetManager.userPresets
        }
        return presetManager.userPresets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Save Current Button

    private var saveCurrentButton: some View {
        Button {
            showingSaveSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Save Current as Preset")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func applyPreset(_ preset: FilterPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedPreset = preset
            parameters = preset.parameters
        }
    }

    private func saveNewPreset(name: String, category: FilterCategory) {
        let newPreset = FilterPreset(
            id: UUID(),
            name: name,
            category: category,
            source: .userCreated,
            parameters: parameters,
            metadata: FilterPreset.FilterMetadata(
                characteristics: [],
                author: nil
            )
        )
        presetManager.savePreset(newPreset)
    }

    private func exportPreset(_ preset: FilterPreset) {
        // Export as JSON file
        if let data = try? JSONEncoder().encode(preset) {
            // In a real app, this would use a document picker or share sheet
            print("Preset exported: \(preset.name)")
        }
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset: FilterPreset
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Circle()
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)

            // Preset info
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)

                HStack(spacing: 8) {
                    Text(preset.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let date = preset.modifiedAt {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Actions menu
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    onExport()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Save Preset Sheet

private struct SavePresetSheet: View {
    let parameters: FilterParameters
    let onSave: (String, FilterCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var presetName = ""
    @State private var selectedCategory: FilterCategory = .custom

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Preset Name", text: $presetName)
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(FilterCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section {
                    presetPreview
                } header: {
                    Text("Settings Preview")
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(presetName, selectedCategory)
                        dismiss()
                    }
                    .disabled(presetName.isEmpty)
                }
            }
        }
    }

    private var presetPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            if parameters.exposure != 0 {
                parameterRow("Exposure", value: String(format: "%.2f", parameters.exposure))
            }
            if parameters.contrast != 0 {
                parameterRow("Contrast", value: "\(Int(parameters.contrast))")
            }
            if parameters.saturation != 0 {
                parameterRow("Saturation", value: "\(Int(parameters.saturation))")
            }
            if parameters.temperature != 0 {
                parameterRow("Temperature", value: "\(Int(parameters.temperature))")
            }
            if parameters.grain.amount > 0 {
                parameterRow("Grain", value: "\(Int(parameters.grain.amount))")
            }
            if parameters.vignette.amount != 0 {
                parameterRow("Vignette", value: "\(Int(parameters.vignette.amount))")
            }
        }
        .font(.caption)
    }

    private func parameterRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

// MARK: - Edit Preset Sheet

private struct EditPresetSheet: View {
    let preset: FilterPreset
    let onSave: (FilterPreset) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String
    @State private var editedCategory: FilterCategory

    init(preset: FilterPreset, onSave: @escaping (FilterPreset) -> Void) {
        self.preset = preset
        self.onSave = onSave
        self._editedName = State(initialValue: preset.name)
        self._editedCategory = State(initialValue: preset.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Preset Name", text: $editedName)
                }

                Section {
                    Picker("Category", selection: $editedCategory) {
                        ForEach(FilterCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Created")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(preset.createdAt, style: .date)
                    }

                    HStack {
                        Text("Modified")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let modified = preset.modifiedAt {
                            Text(modified, style: .date)
                        } else {
                            Text("Never")
                        }
                    }
                } header: {
                    Text("Info")
                }
            }
            .navigationTitle("Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updatedPreset = preset
                        updatedPreset.name = editedName
                        updatedPreset.category = editedCategory
                        updatedPreset.modifiedAt = Date()
                        onSave(updatedPreset)
                        dismiss()
                    }
                    .disabled(editedName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var parameters = FilterParameters()
        @State private var selectedPreset: FilterPreset?

        var body: some View {
            PresetsTabView(
                parameters: $parameters,
                selectedPreset: $selectedPreset
            )
        }
    }

    return PreviewWrapper()
}
