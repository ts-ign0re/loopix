import Foundation

/// Manager for tracking and persisting recently used filter presets
/// Uses UserDefaults for persistence with a maximum history limit
actor RecentlyUsedFiltersManager {

    // MARK: - Constants

    private static let userDefaultsKey = "com.filmbox.recentlyUsedFilters"
    private static let maxRecentItems = 20
    private static let maxFavoriteItems = 50

    // MARK: - Storage Keys

    private enum StorageKey: String {
        case recentFilterIDs = "recentFilterIDs"
        case favoriteFilterIDs = "favoriteFilterIDs"
        case lastUsedTimestamps = "lastUsedTimestamps"
    }

    // MARK: - Singleton

    static let shared = RecentlyUsedFiltersManager()

    // MARK: - Properties

    private var recentFilterIDs: [UUID] = []
    private var favoriteFilterIDs: Set<UUID> = []
    private var lastUsedTimestamps: [UUID: Date] = [:]

    // MARK: - Initialization

    init() {
        // Load synchronously during init (inline to avoid actor isolation issue)
        if let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey) {
            do {
                let storage = try JSONDecoder().decode(RecentFiltersStorage.self, from: data)
                recentFilterIDs = storage.recentFilterIDs
                favoriteFilterIDs = Set(storage.favoriteFilterIDs)
                lastUsedTimestamps = storage.lastUsedTimestamps
            } catch {
                // Storage corrupted, start fresh
                recentFilterIDs = []
                favoriteFilterIDs = []
                lastUsedTimestamps = [:]
            }
        }
    }

    // MARK: - Public Methods

    /// Record a filter as recently used
    /// - Parameter preset: The filter preset that was used
    func recordUsage(of preset: FilterPreset) {
        // Remove if already exists
        recentFilterIDs.removeAll { $0 == preset.id }

        // Add to front
        recentFilterIDs.insert(preset.id, at: 0)

        // Trim to max size
        if recentFilterIDs.count > Self.maxRecentItems {
            recentFilterIDs = Array(recentFilterIDs.prefix(Self.maxRecentItems))
        }

        // Update timestamp
        lastUsedTimestamps[preset.id] = Date()

        // Persist
        saveToStorage()
    }

    /// Get recently used filter IDs
    /// - Returns: Array of filter UUIDs in order of most recent use
    func getRecentFilterIDs() -> [UUID] {
        return recentFilterIDs
    }

    /// Get recently used presets from a catalog
    /// - Parameter allPresets: All available presets to filter from
    /// - Returns: Recently used presets in order
    func getRecentPresets(from allPresets: [FilterPreset]) -> [FilterPreset] {
        let presetMap = Dictionary(uniqueKeysWithValues: allPresets.map { ($0.id, $0) })
        return recentFilterIDs.compactMap { presetMap[$0] }
    }

    /// Check if a preset was recently used
    /// - Parameter preset: The preset to check
    /// - Returns: True if recently used
    func isRecentlyUsed(_ preset: FilterPreset) -> Bool {
        return recentFilterIDs.contains(preset.id)
    }

    /// Get the last used timestamp for a preset
    /// - Parameter preset: The preset to check
    /// - Returns: The last used date, or nil if never used
    func lastUsedDate(for preset: FilterPreset) -> Date? {
        return lastUsedTimestamps[preset.id]
    }

    /// Clear all recent history
    func clearRecents() {
        recentFilterIDs.removeAll()
        lastUsedTimestamps.removeAll()
        saveToStorage()
    }

    // MARK: - Favorites

    /// Toggle favorite status for a preset
    /// - Parameter preset: The preset to toggle
    /// - Returns: True if now favorited, false if unfavorited
    @discardableResult
    func toggleFavorite(_ preset: FilterPreset) -> Bool {
        let result: Bool
        if favoriteFilterIDs.contains(preset.id) {
            favoriteFilterIDs.remove(preset.id)
            saveToStorage()
            result = false
        } else {
            if favoriteFilterIDs.count >= Self.maxFavoriteItems {
                // Remove oldest favorite if at limit
                // (In real app, might want to handle this differently)
            }
            favoriteFilterIDs.insert(preset.id)
            saveToStorage()
            result = true
        }

        // Trigger iCloud backup
        Task { await CloudBackupManager.shared.backupNow() }

        return result
    }

    /// Check if a preset is favorited
    /// - Parameter preset: The preset to check
    /// - Returns: True if favorited
    func isFavorite(_ preset: FilterPreset) -> Bool {
        return favoriteFilterIDs.contains(preset.id)
    }

    /// Get all favorite preset IDs
    /// - Returns: Set of favorite preset UUIDs
    func getFavoriteIDs() -> Set<UUID> {
        return favoriteFilterIDs
    }

    /// Get favorite presets from a catalog
    /// - Parameter allPresets: All available presets to filter from
    /// - Returns: Favorited presets
    func getFavoritePresets(from allPresets: [FilterPreset]) -> [FilterPreset] {
        return allPresets.filter { favoriteFilterIDs.contains($0.id) }
    }

    /// Clear all favorites
    func clearFavorites() {
        favoriteFilterIDs.removeAll()
        saveToStorage()
    }

    // MARK: - Persistence

    private func loadFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey) else {
            return
        }

        do {
            let storage = try JSONDecoder().decode(RecentFiltersStorage.self, from: data)
            recentFilterIDs = storage.recentFilterIDs
            favoriteFilterIDs = Set(storage.favoriteFilterIDs)
            lastUsedTimestamps = storage.lastUsedTimestamps
        } catch {
            // Storage corrupted, start fresh
            recentFilterIDs = []
            favoriteFilterIDs = []
            lastUsedTimestamps = [:]
        }
    }

    private func saveToStorage() {
        let storage = RecentFiltersStorage(
            recentFilterIDs: recentFilterIDs,
            favoriteFilterIDs: Array(favoriteFilterIDs),
            lastUsedTimestamps: lastUsedTimestamps
        )

        do {
            let data = try JSONEncoder().encode(storage)
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        } catch {
            // Handle encoding error silently
        }
    }
}

// MARK: - Storage Model

private struct RecentFiltersStorage: Codable {
    let recentFilterIDs: [UUID]
    let favoriteFilterIDs: [UUID]
    let lastUsedTimestamps: [UUID: Date]
}

// MARK: - Non-isolated Convenience Methods

extension RecentlyUsedFiltersManager {

    /// Record usage from non-async context
    nonisolated func recordUsageSync(of preset: FilterPreset) {
        Task {
            await recordUsage(of: preset)
        }
    }

    /// Toggle favorite from non-async context
    nonisolated func toggleFavoriteSync(_ preset: FilterPreset) {
        Task {
            await toggleFavorite(preset)
        }
    }
}
