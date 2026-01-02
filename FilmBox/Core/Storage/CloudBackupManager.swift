//
//  CloudBackupManager.swift
//  FilmBox
//
//  iCloud backup manager for user presets and favorites
//

import Foundation
import UIKit

// MARK: - Cloud Status

enum CloudStatus: Equatable {
    case available
    case noAccount
    case disabled
    case syncing
}

// MARK: - Cloud Backup Data

struct CloudBackup: Codable {
    let version: Int
    let createdAt: Date
    let modifiedAt: Date
    let deviceName: String
    let userPresets: [FilterPreset]
    let favoriteIDs: [UUID]
}

// MARK: - Backup Info (for UI)

struct BackupInfo {
    let status: CloudStatus
    let lastBackupDate: Date?
    let lastDeviceName: String?
    let version: Int
}

// MARK: - Cloud Backup Manager

actor CloudBackupManager {

    // MARK: - Singleton

    static let shared = CloudBackupManager()

    // MARK: - Constants

    private let containerID = "iCloud.redroom.truebloom.ltd"
    private let backupFileName = "backup.json"
    private let localVersionKey = "com.filmbox.cloudBackupVersion"
    private let localCreatedAtKey = "com.filmbox.cloudBackupCreatedAt"

    // MARK: - State

    private var currentStatus: CloudStatus = .disabled
    private var lastBackupInfo: BackupInfo?
    private var isSyncing = false

    // MARK: - JSON Coders

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Sync on app launch - check for cloud backup and import if newer
    func syncOnLaunch() async {
        // Check cloud status
        currentStatus = checkCloudStatus()

        guard currentStatus == .available else {
            return
        }

        isSyncing = true
        currentStatus = .syncing

        defer {
            isSyncing = false
            currentStatus = checkCloudStatus()
        }

        do {
            if let cloudBackup = try await loadCloudBackup() {
                let localVersion = getLocalVersion()

                if cloudBackup.version > localVersion {
                    // Cloud is newer - import
                    try await importBackup(cloudBackup)
                }

                // Update last backup info
                lastBackupInfo = BackupInfo(
                    status: .available,
                    lastBackupDate: cloudBackup.modifiedAt,
                    lastDeviceName: cloudBackup.deviceName,
                    version: cloudBackup.version
                )
            }

            // Create new backup after sync
            try await createBackup()

        } catch {
            // Silently fail - app works locally
        }
    }

    /// Create a backup now (called on filter/favorite changes)
    func backupNow() async {
        guard checkCloudStatus() == .available else {
            return
        }

        do {
            try await createBackup()
        } catch {
            // Silently fail
        }
    }

    /// Get current backup info for UI
    func getBackupInfo() async -> BackupInfo {
        let status = checkCloudStatus()

        if let info = lastBackupInfo {
            return BackupInfo(
                status: isSyncing ? .syncing : status,
                lastBackupDate: info.lastBackupDate,
                lastDeviceName: info.lastDeviceName,
                version: info.version
            )
        }

        return BackupInfo(
            status: isSyncing ? .syncing : status,
            lastBackupDate: nil,
            lastDeviceName: nil,
            version: getLocalVersion()
        )
    }

    /// Force a manual backup from UI
    func triggerManualBackup() async throws {
        guard checkCloudStatus() == .available else {
            throw CloudBackupError.cloudUnavailable
        }

        isSyncing = true
        defer { isSyncing = false }

        try await createBackup()
    }

    // MARK: - Cloud Status Check

    nonisolated func checkCloudStatus() -> CloudStatus {
        // Check if signed into iCloud
        guard FileManager.default.ubiquityIdentityToken != nil else {
            return .noAccount
        }

        // Check if container is accessible
        guard FileManager.default.url(forUbiquityContainerIdentifier: containerID) != nil else {
            return .disabled
        }

        return .available
    }

    // MARK: - Cloud URL

    private func getCloudBackupURL() -> URL? {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
            return nil
        }

        let documentsURL = containerURL.appendingPathComponent("Documents", isDirectory: true)

        // Ensure Documents directory exists
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        }

        return documentsURL.appendingPathComponent(backupFileName)
    }

    // MARK: - Backup Operations

    private func createBackup() async throws {
        guard let cloudURL = getCloudBackupURL() else {
            throw CloudBackupError.cloudUnavailable
        }

        // Gather data
        let presets = await FilterStorage.shared.getUserPresets()
        let favorites = await RecentlyUsedFiltersManager.shared.getFavoriteIDs()

        let newVersion = getLocalVersion() + 1
        let createdAt = getCreatedAt() ?? Date()

        let backup = CloudBackup(
            version: newVersion,
            createdAt: createdAt,
            modifiedAt: Date(),
            deviceName: await UIDevice.current.name,
            userPresets: presets,
            favoriteIDs: Array(favorites)
        )

        // Encode and write
        let data = try encoder.encode(backup)
        try data.write(to: cloudURL, options: .atomicWrite)

        // Update local tracking
        saveLocalVersion(newVersion)
        if getCreatedAt() == nil {
            saveCreatedAt(createdAt)
        }

        // Update info
        lastBackupInfo = BackupInfo(
            status: .available,
            lastBackupDate: backup.modifiedAt,
            lastDeviceName: backup.deviceName,
            version: newVersion
        )
    }

    private func loadCloudBackup() async throws -> CloudBackup? {
        guard let cloudURL = getCloudBackupURL() else {
            return nil
        }

        guard FileManager.default.fileExists(atPath: cloudURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: cloudURL)
        return try decoder.decode(CloudBackup.self, from: data)
    }

    private func importBackup(_ backup: CloudBackup) async throws {
        // Import presets (will handle duplicates)
        for preset in backup.userPresets {
            // Check if preset already exists
            if await FilterStorage.shared.getPreset(by: preset.id) == nil {
                try await FilterStorage.shared.save(preset)
            }
        }

        // Import favorites
        await setFavorites(Set(backup.favoriteIDs))

        // Update local version
        saveLocalVersion(backup.version)
    }

    // MARK: - Favorites Helper

    private func setFavorites(_ ids: Set<UUID>) async {
        // Get current favorites
        let currentFavorites = await RecentlyUsedFiltersManager.shared.getFavoriteIDs()

        // Add new favorites
        for id in ids {
            if !currentFavorites.contains(id) {
                // Create a minimal preset just for toggling favorite
                let preset = FilterPreset(
                    id: id,
                    name: "",
                    category: .custom,
                    source: .userCreated,
                    parameters: .identity,
                    metadata: FilterPreset.FilterMetadata()
                )
                await RecentlyUsedFiltersManager.shared.toggleFavorite(preset)
            }
        }
    }

    // MARK: - Local Version Tracking

    private func getLocalVersion() -> Int {
        UserDefaults.standard.integer(forKey: localVersionKey)
    }

    private func saveLocalVersion(_ version: Int) {
        UserDefaults.standard.set(version, forKey: localVersionKey)
    }

    private func getCreatedAt() -> Date? {
        UserDefaults.standard.object(forKey: localCreatedAtKey) as? Date
    }

    private func saveCreatedAt(_ date: Date) {
        UserDefaults.standard.set(date, forKey: localCreatedAtKey)
    }
}

// MARK: - Errors

enum CloudBackupError: LocalizedError {
    case cloudUnavailable
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .cloudUnavailable:
            return "iCloud is not available"
        case .encodingFailed:
            return "Failed to encode backup data"
        case .decodingFailed:
            return "Failed to decode backup data"
        }
    }
}
