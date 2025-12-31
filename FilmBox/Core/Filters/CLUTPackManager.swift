import Foundation

/// Manager for CLUT pack bundling and on-demand download
/// Handles essential bundled packs and downloadable extension packs
@available(iOS 17.0, *)
actor CLUTPackManager {

    // MARK: - Types

    /// CLUT pack definition
    struct CLUTPack: Codable, Identifiable, Sendable {
        let id: String
        let name: String
        let description: String
        let clutCount: Int
        let sizeBytes: Int
        let category: PackCategory
        let clutPaths: [String]

        /// Pack category
        enum PackCategory: String, Codable, CaseIterable {
            case essential = "Essential"
            case kodak = "Kodak Collection"
            case fuji = "Fuji Collection"
            case ilford = "Ilford Collection"
            case polaroid = "Polaroid Collection"
            case bw = "B&W Collection"
            case vintage = "Vintage Collection"
            case cinema = "Cinema Collection"
            case creative = "Creative Collection"

            var iconName: String {
                switch self {
                case .essential: return "star.fill"
                case .kodak: return "k.circle"
                case .fuji: return "f.circle"
                case .ilford: return "i.circle"
                case .polaroid: return "p.circle"
                case .bw: return "circle.lefthalf.filled"
                case .vintage: return "clock.arrow.circlepath"
                case .cinema: return "film"
                case .creative: return "wand.and.stars"
                }
            }
        }

        var formattedSize: String {
            ByteCountFormatter.string(fromByteCount: Int64(sizeBytes), countStyle: .file)
        }
    }

    /// Download state for a pack
    enum DownloadState: Sendable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case error(String)
    }

    // MARK: - Constants

    /// Essential pack CLUTs (bundled with app)
    private static let essentialCLUTs: [String] = [
        // Kodak Portra series
        "Film Simulation/Color/Kodak/Kodak Portra 160 2.png",
        "Film Simulation/Color/Kodak/Kodak Portra 400 2.png",
        "Film Simulation/Color/Kodak/Kodak Portra 800 2.png",
        // Kodak Ektar & Gold
        "Film Simulation/Color/Kodak/Kodak Ektar 100 2.png",
        "Film Simulation/Color/Kodak/Kodak Gold 200 2.png",
        // Fuji Color
        "Film Simulation/Color/Fuji/Fuji Pro 400H 2.png",
        "Film Simulation/Color/Fuji/Fuji Pro 160C 2.png",
        "Film Simulation/Color/Fuji/Fuji Velvia 50 2.png",
        "Film Simulation/Color/Fuji/Fuji Provia 100F 2.png",
        "Film Simulation/Color/Fuji/Fuji Superia 400 2.png",
        // B&W Essentials
        "Film Simulation/Black and White/Kodak/Kodak TRI-X 400 2.png",
        "Film Simulation/Black and White/Kodak/Kodak T-Max 400 2.png",
        "Film Simulation/Black and White/Ilford/Ilford HP5 Plus 400 2.png",
        "Film Simulation/Black and White/Ilford/Ilford Delta 400 2.png",
        "Film Simulation/Black and White/Fuji/Fuji Neopan Acros 100 2.png",
        // Cinema
        "Film Simulation/Color/Kodak/Kodak Vision3 500T 2.png",
        "Film Simulation/Color/Kodak/Kodak Vision3 250D 2.png",
        // Instant/Vintage
        "Film Simulation/Color/Polaroid/Polaroid 669 2.png",
        "Film Simulation/Color/Polaroid/Polaroid 690 Cold 2.png",
        // Creative
        "PictureFX/AnalogFX/AnalogFX Old Photo 1.png"
    ]

    // MARK: - Properties

    /// All available packs
    private var packs: [CLUTPack] = []

    /// Download state for each pack
    private var downloadStates: [String: DownloadState] = [:]

    /// Download tasks
    private var downloadTasks: [String: Task<Void, Never>] = [:]

    /// Local storage URL for downloaded packs
    private let downloadedPacksURL: URL

    // MARK: - Singleton

    static let shared = CLUTPackManager()

    // MARK: - Initialization

    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.downloadedPacksURL = documentsURL.appendingPathComponent("CLUTPacks", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadedPacksURL, withIntermediateDirectories: true)

        // Initialize packs
        initializePacks()
    }

    // MARK: - Public Methods

    /// Get all available packs
    func allPacks() -> [CLUTPack] {
        return packs
    }

    /// Get packs by category
    func packs(for category: CLUTPack.PackCategory) -> [CLUTPack] {
        return packs.filter { $0.category == category }
    }

    /// Get download state for a pack
    func downloadState(for packID: String) -> DownloadState {
        if packID == "essential" {
            return .downloaded // Always available
        }
        return downloadStates[packID] ?? .notDownloaded
    }

    /// Check if a CLUT is available locally
    func isCLUTAvailable(_ clutPath: String) -> Bool {
        // Check if in essential pack
        if Self.essentialCLUTs.contains(clutPath) {
            return true
        }

        // Check if downloaded
        let localURL = downloadedPacksURL.appendingPathComponent(clutPath)
        return FileManager.default.fileExists(atPath: localURL.path)
    }

    /// Get the URL for a CLUT file (bundle or downloaded)
    func clutURL(for path: String) -> URL? {
        // Check bundle first
        if let bundleURL = Bundle.main.url(forResource: path, withExtension: nil) {
            return bundleURL
        }

        // Check HaldCLUT directory in bundle
        if let bundleURL = Bundle.main.url(
            forResource: path,
            withExtension: nil,
            subdirectory: "HaldCLUT"
        ) {
            return bundleURL
        }

        // Check downloaded
        let downloadedURL = downloadedPacksURL.appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: downloadedURL.path) {
            return downloadedURL
        }

        return nil
    }

    /// Download a pack
    func downloadPack(_ packID: String) async throws {
        guard downloadStates[packID] != .downloaded else { return }
        guard downloadTasks[packID] == nil else { return } // Already downloading

        downloadStates[packID] = .downloading(progress: 0)

        let task = Task<Void, Never> {
            do {
                try await performDownload(packID: packID)
                downloadStates[packID] = .downloaded
            } catch {
                downloadStates[packID] = .error(error.localizedDescription)
            }
        }

        downloadTasks[packID] = task
        await task.value
        downloadTasks.removeValue(forKey: packID)
    }

    /// Cancel a download
    func cancelDownload(_ packID: String) {
        downloadTasks[packID]?.cancel()
        downloadTasks.removeValue(forKey: packID)
        downloadStates[packID] = .notDownloaded
    }

    /// Delete a downloaded pack
    func deletePack(_ packID: String) throws {
        guard packID != "essential" else { return } // Can't delete essential

        guard let pack = packs.first(where: { $0.id == packID }) else { return }

        for clutPath in pack.clutPaths {
            let localURL = downloadedPacksURL.appendingPathComponent(clutPath)
            try? FileManager.default.removeItem(at: localURL)
        }

        downloadStates[packID] = .notDownloaded
    }

    /// Get total downloaded size
    func totalDownloadedSize() -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: downloadedPacksURL,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else {
            return 0
        }

        var total = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += size
            }
        }
        return total
    }

    // MARK: - Private Methods

    private func initializePacks() {
        packs = [
            CLUTPack(
                id: "essential",
                name: "Essential Films",
                description: "Top 20 most popular film simulations included with the app",
                clutCount: 20,
                sizeBytes: 4 * 1024 * 1024, // ~4MB
                category: .essential,
                clutPaths: Self.essentialCLUTs
            ),
            CLUTPack(
                id: "kodak",
                name: "Kodak Collection",
                description: "Complete Kodak film simulations including Portra, Ektar, Gold, and more",
                clutCount: 47,
                sizeBytes: 9 * 1024 * 1024, // ~9MB
                category: .kodak,
                clutPaths: [] // Populated from catalog
            ),
            CLUTPack(
                id: "fuji",
                name: "Fuji Collection",
                description: "Fujifilm simulations including Velvia, Provia, Superia, and Pro series",
                clutCount: 62,
                sizeBytes: 12 * 1024 * 1024, // ~12MB
                category: .fuji,
                clutPaths: []
            ),
            CLUTPack(
                id: "ilford",
                name: "Ilford Collection",
                description: "Classic Ilford black & white films: HP5, Delta, Pan F, and more",
                clutCount: 24,
                sizeBytes: 5 * 1024 * 1024, // ~5MB
                category: .ilford,
                clutPaths: []
            ),
            CLUTPack(
                id: "polaroid",
                name: "Polaroid Collection",
                description: "Instant film looks: Polaroid 600, SX-70, and Impossible Project",
                clutCount: 80,
                sizeBytes: 16 * 1024 * 1024, // ~16MB
                category: .polaroid,
                clutPaths: []
            ),
            CLUTPack(
                id: "bw",
                name: "B&W Collection",
                description: "Complete black & white collection from all brands",
                clutCount: 66,
                sizeBytes: 13 * 1024 * 1024, // ~13MB
                category: .bw,
                clutPaths: []
            ),
            CLUTPack(
                id: "vintage",
                name: "Vintage Collection",
                description: "Retro and vintage looks: Autochrome, Kodachrome, expired films",
                clutCount: 50,
                sizeBytes: 10 * 1024 * 1024, // ~10MB
                category: .vintage,
                clutPaths: []
            ),
            CLUTPack(
                id: "cinema",
                name: "Cinema Collection",
                description: "Motion picture films: Kodak Vision3, CineStill",
                clutCount: 20,
                sizeBytes: 4 * 1024 * 1024, // ~4MB
                category: .cinema,
                clutPaths: []
            ),
            CLUTPack(
                id: "creative",
                name: "Creative Collection",
                description: "Creative and experimental looks",
                clutCount: 19,
                sizeBytes: 4 * 1024 * 1024, // ~4MB
                category: .creative,
                clutPaths: []
            )
        ]

        // Mark essential as always downloaded
        downloadStates["essential"] = .downloaded

        // Check which packs are already downloaded
        for pack in packs where pack.id != "essential" {
            if isPackDownloaded(pack) {
                downloadStates[pack.id] = .downloaded
            }
        }
    }

    private func isPackDownloaded(_ pack: CLUTPack) -> Bool {
        // Check if at least one CLUT from pack exists in downloads
        for clutPath in pack.clutPaths {
            let localURL = downloadedPacksURL.appendingPathComponent(clutPath)
            if FileManager.default.fileExists(atPath: localURL.path) {
                return true
            }
        }
        return false
    }

    private func performDownload(packID: String) async throws {
        // TODO: Implement actual download from CloudKit/CDN
        // For now, simulate download delay
        for i in 0...10 {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            downloadStates[packID] = .downloading(progress: Double(i) / 10.0)

            if Task.isCancelled {
                throw CancellationError()
            }
        }

        // In production, this would:
        // 1. Download ZIP from CDN/CloudKit
        // 2. Unzip to downloadedPacksURL
        // 3. Verify checksums
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

/// View for displaying a downloadable pack
@available(iOS 17.0, *)
struct CLUTPackRow: View {
    let pack: CLUTPackManager.CLUTPack
    let downloadState: CLUTPackManager.DownloadState
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: pack.category.iconName)
                .font(.title2)
                .foregroundStyle(categoryColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.name)
                    .font(.headline)

                Text("\(pack.clutCount) films • \(pack.formattedSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button
            actionButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch downloadState {
        case .notDownloaded:
            Button(action: onDownload) {
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundStyle(.blue)
            }

        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }

        case .downloaded:
            Menu {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

        case .error(let message):
            Button(action: onDownload) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .help(message)
        }
    }

    private var categoryColor: Color {
        switch pack.category {
        case .essential: return .yellow
        case .kodak: return .orange
        case .fuji: return .green
        case .ilford: return .gray
        case .polaroid: return .blue
        case .bw: return .gray
        case .vintage: return .brown
        case .cinema: return .purple
        case .creative: return .pink
        }
    }
}
