//
//  AppSettings.swift
//  FilmBox
//
//  App-wide settings with UserDefaults persistence
//

import Foundation
import SwiftUI

// MARK: - Preview Quality

enum PreviewQuality: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high

    var displayName: String { rawValue }

    var resolution: CGFloat {
        switch self {
        case .low: return 1024
        case .medium: return 2048
        case .high: return 4096
        }
    }
}

// MARK: - App Settings

@MainActor
@Observable
final class AppSettings {

    // MARK: - Singleton

    static let shared = AppSettings()

    // MARK: - Storage Settings

    /// Storage limit in gigabytes (1...25)
    var storageLimitGB: Double = 5.0 {
        didSet { save() }
    }

    static let minStorageGB: Double = 1.0
    static let maxStorageGB: Double = 25.0

    /// Storage limit in bytes
    var storageLimitBytes: Int {
        Int(storageLimitGB * 1024 * 1024 * 1024)
    }

    // MARK: - Export Settings

    var exportFormat: ExportFormat = .heic {
        didSet { save() }
    }

    /// Export quality (0...1)
    var exportQuality: Double = 0.85 {
        didSet { save() }
    }

    var exportSize: ExportSize = .original {
        didSet { save() }
    }

    // MARK: - Performance Settings

    var previewQuality: PreviewQuality = .medium {
        didSet { save() }
    }

    // MARK: - Security Settings

    /// When enabled, strips all identifying metadata from exports (GPS, dates, device info, etc.)
    /// Only keeps "RedRoom iOS" as software tag
    var securityMode: Bool = false {
        didSet { save() }
    }

    // MARK: - Private

    private let userDefaultsKey = "com.filmbox.appSettings"

    // MARK: - Initialization

    private init() {
        load()
    }

    // MARK: - Persistence

    private func save() {
        let data = SettingsData(
            storageLimitGB: storageLimitGB,
            exportFormat: exportFormat,
            exportQuality: exportQuality,
            exportSize: exportSize,
            previewQuality: previewQuality,
            securityMode: securityMode
        )

        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(SettingsData.self, from: data) else {
            return
        }

        storageLimitGB = decoded.storageLimitGB
        exportFormat = decoded.exportFormat
        exportQuality = decoded.exportQuality
        exportSize = decoded.exportSize
        previewQuality = decoded.previewQuality
        securityMode = decoded.securityMode ?? false
    }

    // MARK: - Debug Info

    func getDebugInfo(storageUsed: Int, photoCount: Int, filterCount: Int) -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model

        let usedGB = String(format: "%.1f", Double(storageUsed) / 1024 / 1024 / 1024)
        let limitGB = String(format: "%.0f", storageLimitGB)

        return """
        filmbox v\(version) (\(build))
        ios: \(iosVersion)
        device: \(deviceModel.lowercased())
        storage: \(usedGB)gb / \(limitGB)gb
        photos: \(photoCount)
        filters: \(filterCount)
        """
    }
}

// MARK: - Settings Data (for Codable)

private struct SettingsData: Codable {
    var storageLimitGB: Double
    var exportFormat: ExportFormat
    var exportQuality: Double
    var exportSize: ExportSize
    var previewQuality: PreviewQuality
    var securityMode: Bool?
}
