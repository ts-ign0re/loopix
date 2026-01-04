//
//  AppSettings.swift
//  FilmBox
//
//  App-wide settings with UserDefaults persistence
//

import Foundation
import SwiftUI

// MARK: - App Language

enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system = "system"
    case english = "en"
    case spanish = "es"
    case japanese = "ja"
    case chineseSimplified = "zh-Hans"

    var displayName: String {
        switch self {
        case .system: return "settings.language.system".localized
        case .english: return "English"
        case .spanish: return "Español"
        case .japanese: return "日本語"
        case .chineseSimplified: return "简体中文"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .spanish: return "es"
        case .japanese: return "ja"
        case .chineseSimplified: return "zh-Hans"
        }
    }
}

// MARK: - Preview Quality

enum PreviewQuality: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high

    var displayName: String { rawValue }

    var resolution: CGFloat {
        switch self {
        case .low: return 512      // Fast editing
        case .medium: return 1024  // Balanced (was 2048)
        case .high: return 2048    // Detail view (was 4096)
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

    var exportFormat: ExportFormat = .jpeg {
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
    /// Only keeps "Protected by Loopix iOS" as software tag
    var securityMode: Bool = false {
        didSet { save() }
    }

    // MARK: - Language Settings

    /// App language override. When set to .system, uses device language
    var appLanguage: AppLanguage = .system {
        didSet {
            save()
            applyLanguage()
        }
    }

    /// Apply the selected language by setting AppleLanguages in UserDefaults
    private func applyLanguage() {
        if let localeId = appLanguage.localeIdentifier {
            UserDefaults.standard.set([localeId], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }

    /// Check if app restart is needed after language change
    var needsRestartForLanguage: Bool {
        guard let currentLanguages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
              let currentLang = currentLanguages.first else {
            return appLanguage != .system
        }

        if let selectedLocale = appLanguage.localeIdentifier {
            return !currentLang.hasPrefix(selectedLocale)
        } else {
            return true
        }
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
            securityMode: securityMode,
            appLanguage: appLanguage
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
        appLanguage = decoded.appLanguage ?? .system
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
    var appLanguage: AppLanguage?
}
