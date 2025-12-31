import Foundation
import SwiftUI

// MARK: - Preset Manager

/// Manages user-created filter presets with persistence
@Observable
final class PresetManager {

    // MARK: - Singleton

    static let shared = PresetManager()

    // MARK: - Properties

    /// All user-created presets
    private(set) var userPresets: [FilterPreset] = []

    /// Recently used presets (limited to 10)
    private(set) var recentPresets: [FilterPreset] = []

    /// Favorite presets
    private(set) var favoritePresetIDs: Set<UUID> = []

    /// Maximum number of recent presets to track
    private let maxRecentPresets = 10

    /// File manager for persistence
    private let fileManager = FileManager.default

    /// Directory for storing presets
    private var presetsDirectory: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Presets", isDirectory: true)
    }

    /// Path to the presets index file
    private var presetsIndexPath: URL {
        presetsDirectory.appendingPathComponent("presets_index.json")
    }

    /// Path to favorites file
    private var favoritesPath: URL {
        presetsDirectory.appendingPathComponent("favorites.json")
    }

    /// Path to recents file
    private var recentsPath: URL {
        presetsDirectory.appendingPathComponent("recents.json")
    }

    // MARK: - Initialization

    private init() {
        createPresetsDirectoryIfNeeded()
        loadPresets()
        loadFavorites()
        loadRecents()
    }

    // MARK: - Directory Management

    private func createPresetsDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: presetsDirectory.path) {
            try? fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Preset Operations

    /// Save a new preset
    func savePreset(_ preset: FilterPreset) {
        var newPreset = preset
        newPreset.createdAt = Date()
        newPreset.modifiedAt = Date()

        userPresets.append(newPreset)
        savePresetToFile(newPreset)
        updateIndex()

        // Add to recents
        addToRecents(newPreset)
    }

    /// Update an existing preset
    func updatePreset(_ preset: FilterPreset) {
        var updatedPreset = preset
        updatedPreset.modifiedAt = Date()

        if let index = userPresets.firstIndex(where: { $0.id == preset.id }) {
            userPresets[index] = updatedPreset
            savePresetToFile(updatedPreset)
            updateIndex()
        }
    }

    /// Delete a preset
    func deletePreset(_ preset: FilterPreset) {
        userPresets.removeAll { $0.id == preset.id }
        recentPresets.removeAll { $0.id == preset.id }
        favoritePresetIDs.remove(preset.id)

        // Delete file
        let presetPath = presetsDirectory.appendingPathComponent("\(preset.id.uuidString).json")
        try? fileManager.removeItem(at: presetPath)

        updateIndex()
        saveFavorites()
        saveRecents()
    }

    /// Duplicate a preset
    func duplicatePreset(_ preset: FilterPreset) -> FilterPreset {
        var newPreset = preset
        newPreset.id = UUID()
        newPreset.name = "\(preset.name) Copy"
        newPreset.createdAt = Date()
        newPreset.modifiedAt = Date()
        newPreset.source = .userCreated

        savePreset(newPreset)
        return newPreset
    }

    // MARK: - Favorites

    /// Toggle favorite status for a preset
    func toggleFavorite(_ preset: FilterPreset) {
        if favoritePresetIDs.contains(preset.id) {
            favoritePresetIDs.remove(preset.id)
        } else {
            favoritePresetIDs.insert(preset.id)
        }
        saveFavorites()
    }

    /// Check if a preset is favorited
    func isFavorite(_ preset: FilterPreset) -> Bool {
        favoritePresetIDs.contains(preset.id)
    }

    /// Get all favorite presets
    var favoritePresets: [FilterPreset] {
        userPresets.filter { favoritePresetIDs.contains($0.id) }
    }

    // MARK: - Recents

    /// Add a preset to recent list
    func addToRecents(_ preset: FilterPreset) {
        recentPresets.removeAll { $0.id == preset.id }
        recentPresets.insert(preset, at: 0)

        if recentPresets.count > maxRecentPresets {
            recentPresets = Array(recentPresets.prefix(maxRecentPresets))
        }

        saveRecents()
    }

    /// Clear recent presets
    func clearRecents() {
        recentPresets.removeAll()
        saveRecents()
    }

    // MARK: - Import/Export

    /// Export a preset as JSON data
    func exportPreset(_ preset: FilterPreset) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(preset)
    }

    /// Import a preset from JSON data
    func importPreset(from data: Data) throws -> FilterPreset {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var preset = try decoder.decode(FilterPreset.self, from: data)

        // Generate new ID to avoid conflicts
        preset.id = UUID()
        preset.source = .imported(sourceName: "Imported")
        preset.createdAt = Date()
        preset.modifiedAt = Date()

        savePreset(preset)
        return preset
    }

    /// Import preset from file URL
    func importPreset(from url: URL) throws -> FilterPreset {
        let data = try Data(contentsOf: url)
        return try importPreset(from: data)
    }

    /// Export all presets as a bundle
    func exportAllPresets() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let bundle = PresetBundle(
            version: "1.0",
            exportDate: Date(),
            presets: userPresets
        )

        return try encoder.encode(bundle)
    }

    /// Import presets from bundle
    func importPresetBundle(from data: Data) throws -> [FilterPreset] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let bundle = try decoder.decode(PresetBundle.self, from: data)

        var importedPresets: [FilterPreset] = []

        for var preset in bundle.presets {
            preset.id = UUID()
            preset.source = .imported(sourceName: "Bundle Import")
            preset.createdAt = Date()
            savePreset(preset)
            importedPresets.append(preset)
        }

        return importedPresets
    }

    // MARK: - Persistence

    private func loadPresets() {
        guard fileManager.fileExists(atPath: presetsIndexPath.path) else {
            userPresets = []
            return
        }

        do {
            let data = try Data(contentsOf: presetsIndexPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let index = try decoder.decode(PresetsIndex.self, from: data)

            userPresets = index.presetIDs.compactMap { loadPresetFromFile(id: $0) }
        } catch {
            print("PresetManager: Failed to load presets index: \(error)")
            userPresets = []
        }
    }

    private func loadPresetFromFile(id: UUID) -> FilterPreset? {
        let presetPath = presetsDirectory.appendingPathComponent("\(id.uuidString).json")

        guard fileManager.fileExists(atPath: presetPath.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: presetPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(FilterPreset.self, from: data)
        } catch {
            print("PresetManager: Failed to load preset \(id): \(error)")
            return nil
        }
    }

    private func savePresetToFile(_ preset: FilterPreset) {
        let presetPath = presetsDirectory.appendingPathComponent("\(preset.id.uuidString).json")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(preset)
            try data.write(to: presetPath)
        } catch {
            print("PresetManager: Failed to save preset \(preset.id): \(error)")
        }
    }

    private func updateIndex() {
        let index = PresetsIndex(presetIDs: userPresets.map { $0.id })

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(index)
            try data.write(to: presetsIndexPath)
        } catch {
            print("PresetManager: Failed to update index: \(error)")
        }
    }

    private func loadFavorites() {
        guard fileManager.fileExists(atPath: favoritesPath.path) else {
            favoritePresetIDs = []
            return
        }

        do {
            let data = try Data(contentsOf: favoritesPath)
            let ids = try JSONDecoder().decode([UUID].self, from: data)
            favoritePresetIDs = Set(ids)
        } catch {
            print("PresetManager: Failed to load favorites: \(error)")
            favoritePresetIDs = []
        }
    }

    private func saveFavorites() {
        do {
            let data = try JSONEncoder().encode(Array(favoritePresetIDs))
            try data.write(to: favoritesPath)
        } catch {
            print("PresetManager: Failed to save favorites: \(error)")
        }
    }

    private func loadRecents() {
        guard fileManager.fileExists(atPath: recentsPath.path) else {
            recentPresets = []
            return
        }

        do {
            let data = try Data(contentsOf: recentsPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let ids = try decoder.decode([UUID].self, from: data)
            recentPresets = ids.compactMap { id in
                userPresets.first { $0.id == id }
            }
        } catch {
            print("PresetManager: Failed to load recents: \(error)")
            recentPresets = []
        }
    }

    private func saveRecents() {
        do {
            let ids = recentPresets.map { $0.id }
            let data = try JSONEncoder().encode(ids)
            try data.write(to: recentsPath)
        } catch {
            print("PresetManager: Failed to save recents: \(error)")
        }
    }

    // MARK: - Search

    /// Search presets by name or characteristics
    func searchPresets(query: String) -> [FilterPreset] {
        guard !query.isEmpty else { return userPresets }

        let lowercasedQuery = query.lowercased()

        return userPresets.filter { preset in
            preset.name.lowercased().contains(lowercasedQuery) ||
            preset.category.rawValue.lowercased().contains(lowercasedQuery) ||
            preset.metadata.characteristics.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }

    /// Get presets by category
    func presets(for category: FilterCategory) -> [FilterPreset] {
        userPresets.filter { $0.category == category }
    }
}

// MARK: - Supporting Types

/// Index file structure for tracking presets
private struct PresetsIndex: Codable {
    let presetIDs: [UUID]
}

/// Bundle format for exporting/importing multiple presets
private struct PresetBundle: Codable {
    let version: String
    let exportDate: Date
    let presets: [FilterPreset]
}

// MARK: - FilterPreset Extensions

extension FilterPreset {
    /// Apply preset at a specific intensity (0-100)
    func parameters(at intensity: Float) -> FilterParameters {
        guard intensity < 100 else { return parameters }
        guard intensity > 0 else { return .identity }

        let factor = intensity / 100.0
        var result = FilterParameters.identity

        // Interpolate numeric values
        result.exposure = parameters.exposure * factor
        result.contrast = parameters.contrast * factor
        result.highlights = parameters.highlights * factor
        result.shadows = parameters.shadows * factor
        result.whites = parameters.whites * factor
        result.blacks = parameters.blacks * factor
        result.temperature = parameters.temperature * factor
        result.tint = parameters.tint * factor
        result.saturation = parameters.saturation * factor
        result.vibrance = parameters.vibrance * factor
        result.clarity = parameters.clarity * factor
        result.sharpness = parameters.sharpness * factor
        result.fade = parameters.fade * factor

        // Grain
        result.grain = GrainData(
            amount: parameters.grain.amount * factor,
            size: parameters.grain.size,
            roughness: parameters.grain.roughness,
            monochromatic: parameters.grain.monochromatic
        )

        // Vignette
        result.vignette = VignetteData(
            amount: parameters.vignette.amount * factor,
            midpoint: parameters.vignette.midpoint,
            roundness: parameters.vignette.roundness,
            feather: parameters.vignette.feather
        )

        // Bloom
        result.bloom = BloomData(
            intensity: parameters.bloom.intensity * factor,
            radius: parameters.bloom.radius,
            threshold: parameters.bloom.threshold
        )

        // Halation
        result.halation = HalationData(
            intensity: parameters.halation.intensity * factor,
            hue: parameters.halation.hue,
            spread: parameters.halation.spread
        )

        // For complex structures like tone curve and HSL, use full values above 50%
        if intensity > 50 {
            result.toneCurve = parameters.toneCurve
            result.hsl = parameters.hsl
            result.splitTone = parameters.splitTone
        }

        return result
    }
}

// MARK: - HSLAdjustments Extension

extension HSLAdjustments {
    /// Channel names for UI display
    static let channelNames = ["Red", "Orange", "Yellow", "Green", "Aqua", "Blue", "Purple", "Magenta"]

    /// Access channels by index
    subscript(index: Int) -> HSLChannel {
        get {
            switch index {
            case 0: return red
            case 1: return orange
            case 2: return yellow
            case 3: return green
            case 4: return aqua
            case 5: return blue
            case 6: return purple
            case 7: return magenta
            default: return .identity
            }
        }
        set {
            switch index {
            case 0: red = newValue
            case 1: orange = newValue
            case 2: yellow = newValue
            case 3: green = newValue
            case 4: aqua = newValue
            case 5: blue = newValue
            case 6: purple = newValue
            case 7: magenta = newValue
            default: break
            }
        }
    }
}

// MARK: - VignetteData Extension

extension VignetteData {
    /// Whether vignette is active (has non-zero amount)
    var isActive: Bool {
        amount != 0
    }
}
