import Foundation

/// Actor responsible for persisting and managing user filter presets
actor FilterStorage {

    // MARK: - Properties

    /// Shared instance for app-wide access
    static let shared = FilterStorage()

    /// User presets stored on disk
    private var userPresets: [FilterPreset] = []

    /// Whether presets have been loaded from disk
    private var isLoaded = false

    /// File manager for disk operations
    private let fileManager = FileManager.default

    /// Directory for storing preset files
    private var presetsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let presetsDir = appSupport.appendingPathComponent("FilmBox/Presets", isDirectory: true)
        return presetsDir
    }

    /// File URL for the user presets JSON file
    private var userPresetsFileURL: URL {
        presetsDirectory.appendingPathComponent("user_presets.json")
    }

    /// JSON encoder configured for pretty printing
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// JSON decoder configured for ISO8601 dates
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {}

    // MARK: - Built-in Presets

    /// All built-in presets (film emulations + creative filters)
    nonisolated var builtInPresets: [FilterPreset] {
        [FilterPreset.original] + FilmEmulations.all + CreativeFilters.all
    }

    // MARK: - All Presets

    /// All available presets (built-in + user created)
    var allPresets: [FilterPreset] {
        get async {
            await ensureLoaded()
            return builtInPresets + userPresets
        }
    }

    /// Get presets filtered by category
    func presets(for category: FilterCategory) async -> [FilterPreset] {
        let all = await allPresets

        if category == .all {
            return all
        }

        if category == .custom {
            return userPresets
        }

        return all.filter { $0.category == category }
    }

    // MARK: - CRUD Operations

    /// Save a new user preset
    /// - Parameter preset: The preset to save
    /// - Returns: The saved preset
    @discardableResult
    func save(_ preset: FilterPreset) async throws -> FilterPreset {
        await ensureLoaded()

        var newPreset = preset

        // Ensure it's marked as user created
        if case .builtIn = newPreset.source {
            newPreset = FilterPreset(
                id: UUID(),
                name: newPreset.name,
                category: newPreset.category,
                source: .userCreated,
                parameters: newPreset.parameters,
                metadata: newPreset.metadata
            )
        }

        // If ID already exists, use update instead
        if userPresets.contains(where: { $0.id == newPreset.id }) {
            try await update(newPreset)
            return newPreset
        }

        // Check for duplicate names and append number if needed
        let existingNames = Set(userPresets.map { $0.name })
        if existingNames.contains(newPreset.name) {
            var counter = 2
            var candidateName = "\(newPreset.name) \(counter)"
            while existingNames.contains(candidateName) {
                counter += 1
                candidateName = "\(newPreset.name) \(counter)"
            }
            newPreset = FilterPreset(
                id: newPreset.id,
                name: candidateName,
                category: newPreset.category,
                source: newPreset.source,
                parameters: newPreset.parameters,
                metadata: newPreset.metadata
            )
        }

        userPresets.append(newPreset)
        try await persistToDisk()

        return newPreset
    }

    /// Update an existing user preset
    /// - Parameter preset: The preset with updated values
    /// - Throws: FilterStorageError if preset not found or is built-in
    func update(_ preset: FilterPreset) async throws {
        await ensureLoaded()

        guard let index = userPresets.firstIndex(where: { $0.id == preset.id }) else {
            throw FilterStorageError.presetNotFound(preset.id)
        }

        var updatedPreset = preset
        updatedPreset.touch()
        userPresets[index] = updatedPreset

        try await persistToDisk()
    }

    /// Delete a user preset
    /// - Parameter id: The ID of the preset to delete
    /// - Throws: FilterStorageError if preset not found or is built-in
    func delete(id: UUID) async throws {
        await ensureLoaded()

        // Check if it's a built-in preset
        if builtInPresets.contains(where: { $0.id == id }) {
            throw FilterStorageError.cannotModifyBuiltIn
        }

        guard let index = userPresets.firstIndex(where: { $0.id == id }) else {
            throw FilterStorageError.presetNotFound(id)
        }

        userPresets.remove(at: index)
        try await persistToDisk()
    }

    /// Get a preset by ID
    /// - Parameter id: The preset ID
    /// - Returns: The preset if found, nil otherwise
    func getPreset(by id: UUID) async -> FilterPreset? {
        await ensureLoaded()

        // Check built-in presets first
        if let builtIn = builtInPresets.first(where: { $0.id == id }) {
            return builtIn
        }

        // Check user presets
        return userPresets.first { $0.id == id }
    }

    /// Toggle favorite status for a preset
    /// - Parameter id: The preset ID
    /// - Returns: The updated preset
    @discardableResult
    func toggleFavorite(id: UUID) async throws -> FilterPreset {
        await ensureLoaded()

        guard let index = userPresets.firstIndex(where: { $0.id == id }) else {
            throw FilterStorageError.presetNotFound(id)
        }

        userPresets[index].metadata.isFavorite.toggle()
        userPresets[index].touch()

        try await persistToDisk()

        return userPresets[index]
    }

    /// Record usage of a preset (increments usage count)
    /// - Parameter id: The preset ID
    func recordUsage(id: UUID) async throws {
        await ensureLoaded()

        guard let index = userPresets.firstIndex(where: { $0.id == id }) else {
            // Silently ignore if preset is built-in or not found
            return
        }

        userPresets[index].recordUsage()
        try await persistToDisk()
    }

    /// Duplicate an existing preset
    /// - Parameters:
    ///   - id: The ID of the preset to duplicate
    ///   - newName: Optional new name for the duplicate
    /// - Returns: The new duplicated preset
    @discardableResult
    func duplicate(id: UUID, newName: String? = nil) async throws -> FilterPreset {
        await ensureLoaded()

        let all = await allPresets
        guard let original = all.first(where: { $0.id == id }) else {
            throw FilterStorageError.presetNotFound(id)
        }

        let name = newName ?? "\(original.name) Copy"
        let duplicate = original.duplicate(newName: name)

        return try await save(duplicate)
    }

    // MARK: - User Presets Access

    /// Get all user-created presets
    func getUserPresets() async -> [FilterPreset] {
        await ensureLoaded()
        return userPresets
    }

    // MARK: - Favorites

    /// Get all favorite presets
    var favoritePresets: [FilterPreset] {
        get async {
            await ensureLoaded()
            return userPresets.filter { $0.metadata.isFavorite }
        }
    }

    // MARK: - Recently Used

    /// Get recently used presets, sorted by last modified date
    /// - Parameter limit: Maximum number of presets to return
    func recentlyUsedPresets(limit: Int = 10) async -> [FilterPreset] {
        await ensureLoaded()

        return userPresets
            .filter { $0.metadata.usageCount > 0 }
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(limit)
            .map { $0 }
    }

    /// Get most used presets, sorted by usage count
    /// - Parameter limit: Maximum number of presets to return
    func mostUsedPresets(limit: Int = 10) async -> [FilterPreset] {
        await ensureLoaded()

        return userPresets
            .filter { $0.metadata.usageCount > 0 }
            .sorted { $0.metadata.usageCount > $1.metadata.usageCount }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Import/Export

    /// Export a preset as JSON data
    /// - Parameter id: The preset ID
    /// - Returns: JSON data representation of the preset
    func exportPreset(id: UUID) async throws -> Data {
        guard let preset = await getPreset(by: id) else {
            throw FilterStorageError.presetNotFound(id)
        }

        return try encoder.encode(preset)
    }

    /// Import a preset from JSON data
    /// - Parameter data: JSON data representation of a preset
    /// - Returns: The imported preset
    @discardableResult
    func importPreset(from data: Data) async throws -> FilterPreset {
        let preset = try decoder.decode(FilterPreset.self, from: data)

        // Create a new preset with a fresh ID and user source
        let importedPreset = FilterPreset(
            id: UUID(),
            name: preset.name,
            category: preset.category,
            source: .imported(sourceName: preset.metadata.author ?? "Unknown"),
            parameters: preset.parameters,
            metadata: preset.metadata
        )

        return try await save(importedPreset)
    }

    /// Export all user presets as JSON data
    /// - Returns: JSON data representation of all user presets
    func exportAllUserPresets() async throws -> Data {
        await ensureLoaded()
        return try encoder.encode(userPresets)
    }

    // MARK: - Persistence

    /// Ensure presets are loaded from disk
    private func ensureLoaded() async {
        guard !isLoaded else { return }

        do {
            try await loadFromDisk()
        } catch {
            // If loading fails, start with empty user presets
            userPresets = []
        }

        isLoaded = true
    }

    /// Load user presets from disk
    private func loadFromDisk() async throws {
        // Ensure directory exists
        try createPresetsDirectoryIfNeeded()

        guard fileManager.fileExists(atPath: userPresetsFileURL.path) else {
            userPresets = []
            return
        }

        let data = try Data(contentsOf: userPresetsFileURL)
        let loadedPresets = try decoder.decode([FilterPreset].self, from: data)

        // Remove duplicates by ID, keeping the most recent (last) one
        var seenIDs = Set<UUID>()
        var uniquePresets: [FilterPreset] = []
        for preset in loadedPresets.reversed() {
            if !seenIDs.contains(preset.id) {
                seenIDs.insert(preset.id)
                uniquePresets.append(preset)
            }
        }
        userPresets = uniquePresets.reversed()

        // If duplicates were removed, persist the cleaned data
        if userPresets.count != loadedPresets.count {
            try await persistToDisk()
        }
    }

    /// Persist user presets to disk
    private func persistToDisk() async throws {
        try createPresetsDirectoryIfNeeded()

        let data = try encoder.encode(userPresets)
        try data.write(to: userPresetsFileURL, options: .atomic)
    }

    /// Create the presets directory if it doesn't exist
    private func createPresetsDirectoryIfNeeded() throws {
        guard !fileManager.fileExists(atPath: presetsDirectory.path) else { return }

        try fileManager.createDirectory(
            at: presetsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    /// Force reload presets from disk (useful after external changes)
    func reload() async throws {
        isLoaded = false
        try await loadFromDisk()
        isLoaded = true
    }

    /// Clear all user presets (use with caution)
    func clearAllUserPresets() async throws {
        userPresets = []
        try await persistToDisk()
    }
}

// MARK: - Errors

/// Errors that can occur during filter storage operations
enum FilterStorageError: LocalizedError {
    case presetNotFound(UUID)
    case cannotModifyBuiltIn
    case encodingFailed
    case decodingFailed
    case fileOperationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .presetNotFound(let id):
            return "Preset with ID \(id) not found"
        case .cannotModifyBuiltIn:
            return "Cannot modify or delete built-in presets"
        case .encodingFailed:
            return "Failed to encode preset data"
        case .decodingFailed:
            return "Failed to decode preset data"
        case .fileOperationFailed(let error):
            return "File operation failed: \(error.localizedDescription)"
        }
    }
}
