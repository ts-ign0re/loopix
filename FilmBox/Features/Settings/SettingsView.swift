//
//  SettingsView.swift
//  FilmBox
//
//  Settings screen with code-editor aesthetic
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var manager = ImportedPhotosManager.shared
    @State private var storageUsed: Int = 0
    @State private var showClearPhotosConfirmation = false
    @State private var showClearCacheConfirmation = false
    @State private var showCopiedToast = false
    @State private var showSecurityHelp = false
    @State private var backupInfo: BackupInfo?
    @State private var isBackingUp = false
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Storage Section
                    storageSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Export Section
                    exportSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Performance Section
                    performanceSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Security Section
                    securitySection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Backup Section
                    backupSection

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // About Section
                    aboutSection
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ settings")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Track screen view
            Analytics.shared.trackScreen(.settings)

            storageUsed = manager.calculateStorageUsed()
            Task {
                backupInfo = await CloudBackupManager.shared.getBackupInfo()
            }
        }
        .confirmationDialog(
            "clear_photos()",
            isPresented: $showClearPhotosConfirmation,
            titleVisibility: .visible
        ) {
            Button("delete all photos", role: .destructive) {
                let oldStorage = storageUsed
                manager.clearAllPhotos()
                storageUsed = manager.calculateStorageUsed()

                // Track photos cleared
                Analytics.shared.trackCacheClear(type: "photos", sizeCleared: oldStorage - storageUsed)
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("this will remove all imported photos.\nfilters, presets, and settings will be preserved.")
        }
        .confirmationDialog(
            "clear_cache()",
            isPresented: $showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("clear cache", role: .destructive) {
                clearCache()
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("this will remove temporary files.\nyour photos and settings will be preserved.")
        }
        .overlay {
            if showCopiedToast {
                copiedToast
            }
        }
        .sheet(isPresented: $showSecurityHelp) {
            securityHelpSheet
        }
    }

    // MARK: - Security Help Sheet

    private var securityHelpSheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("// security_mode")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showSecurityHelp = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("when enabled, all exported photos are stripped of identifying metadata.")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 12) {
                    helpItem(
                        title: "location data",
                        desc: "gps coordinates that reveal where the photo was taken are removed."
                    )

                    helpItem(
                        title: "timestamps",
                        desc: "creation and modification dates are stripped to prevent timeline analysis."
                    )

                    helpItem(
                        title: "device info",
                        desc: "camera model, lens data, and device identifiers are erased."
                    )

                    helpItem(
                        title: "software traces",
                        desc: "editing history and software signatures are cleared."
                    )

                    helpItem(
                        title: "thumbnails",
                        desc: "embedded preview images that may contain original data are removed."
                    )
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                Text("the only metadata preserved is 'Protected by Loopix iOS' as the software tag.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.8))
                    .lineSpacing(3)

                Text("// recommended for sharing sensitive images")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 4)
            }

            Spacer()
        }
        .padding(24)
        .background(Color.black)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private func helpItem(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.green.opacity(0.8))
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            Text(desc)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .lineSpacing(2)
        }
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("storage")

            // Usage bar
            VStack(alignment: .leading, spacing: 8) {
                let usedGB = Double(storageUsed) / 1024 / 1024 / 1024
                let limitGB = settings.storageLimitGB
                let percentage = min(usedGB / limitGB, 1.0)

                Text("used: \(String(format: "%.1f", usedGB))gb / \(String(format: "%.0f", limitGB))gb")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(percentage > 0.9 ? Color.red.opacity(0.8) : Color.yellow.opacity(0.8))
                            .frame(width: geometry.size.width * percentage)
                    }
                }
                .frame(height: 8)

                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Limit slider
            VStack(alignment: .leading, spacing: 6) {
                Text("limit")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 6)

                HStack(spacing: 8) {
                    Text("1gb")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))

                    Slider(
                        value: $settings.storageLimitGB,
                        in: AppSettings.minStorageGB...AppSettings.maxStorageGB,
                        step: 1
                    )
                    .tint(.yellow)

                    Text("25gb")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Text("\(Int(settings.storageLimitGB))gb")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 6)
            }

            // Clear buttons
            VStack(spacing: 12) {
                clearButton(
                    title: "clear_photos()",
                    comment: "// removes imported photos only",
                    size: formatBytes(storageUsed)
                ) {
                    showClearPhotosConfirmation = true
                }

                clearButton(
                    title: "clear_cache()",
                    comment: "// removes temporary files",
                    size: formatBytes(getCacheSize())
                ) {
                    showClearCacheConfirmation = true
                }
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("export_defaults")

            // Format picker
            VStack(alignment: .leading, spacing: 8) {
                Text("format")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 8) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        segmentButton(
                            title: format.rawValue,
                            isSelected: settings.exportFormat == format
                        ) {
                            settings.exportFormat = format
                            Analytics.shared.trackSettingChange(setting: "export_format", value: format.rawValue)
                        }
                    }
                }
            }

            // Quality slider
            VStack(alignment: .leading, spacing: 8) {
                Text("quality")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 12) {
                    Text("0%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))

                    Slider(value: $settings.exportQuality, in: 0...1, step: 0.05)
                        .tint(.yellow)

                    Text("100%")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Text("\(Int(settings.exportQuality * 100))%")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // Size picker
            VStack(alignment: .leading, spacing: 8) {
                Text("size")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 8) {
                    ForEach(ExportSize.allCases, id: \.self) { size in
                        segmentButton(
                            title: size.rawValue,
                            isSelected: settings.exportSize == size
                        ) {
                            settings.exportSize = size
                            Analytics.shared.trackSettingChange(setting: "export_size", value: size.rawValue)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Performance Section

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("performance")

            VStack(alignment: .leading, spacing: 8) {
                Text("preview_quality")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 8) {
                    ForEach(PreviewQuality.allCases, id: \.self) { quality in
                        segmentButton(
                            title: quality.rawValue,
                            isSelected: settings.previewQuality == quality
                        ) {
                            settings.previewQuality = quality
                            Analytics.shared.trackSettingChange(setting: "preview_quality", value: quality.rawValue)
                        }
                    }
                }

                Text("// affects editor responsiveness")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader("security")
                Spacer()
                Button {
                    showSecurityHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: Binding(
                    get: { settings.securityMode },
                    set: { newValue in
                        settings.securityMode = newValue
                        Analytics.shared.trackFeatureToggle(feature: "security_mode", enabled: newValue)
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("strip_metadata")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)

                        Text("// removes identifying info on export")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .tint(.yellow)

                if settings.securityMode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("removed on export:")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        VStack(alignment: .leading, spacing: 3) {
                            metadataItem("gps / location")
                            metadataItem("date / time")
                            metadataItem("device model")
                            metadataItem("camera settings")
                            metadataItem("software / author")
                            metadataItem("thumbnails / previews")
                        }

                        Text("// only 'Protected by Loopix iOS' tag preserved")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.yellow.opacity(0.6))
                            .padding(.top, 4)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: settings.securityMode)
    }

    private func metadataItem(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.red.opacity(0.8))
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Backup Section

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("backup")

            VStack(alignment: .leading, spacing: 12) {
                // Status row
                HStack {
                    Text("status")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(backupStatusColor)
                            .frame(width: 8, height: 8)
                        Text(backupStatusText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                // Last backup info
                if let info = backupInfo, let lastDate = info.lastBackupDate {
                    Text("last: \(formatRelativeTime(lastDate))\(info.lastDeviceName.map { " from \($0)" } ?? "")")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // iCloud unavailable message
                if backupInfo?.status == .noAccount {
                    Text("// sign in to iCloud to enable backup")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                } else if backupInfo?.status == .disabled {
                    Text("// enable iCloud Drive to enable backup")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Action button
            if backupInfo?.status == .available || backupInfo?.status == .syncing {
                Button {
                    triggerBackup()
                } label: {
                    HStack {
                        if isBackingUp {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                                .scaleEffect(0.8)
                        }
                        Text(isBackingUp ? "syncing..." : "backup_now()")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.yellow)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isBackingUp)
            } else {
                // Open Settings button for iCloud issues
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("open_settings()")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var backupStatusColor: Color {
        guard let info = backupInfo else { return .gray }
        switch info.status {
        case .available: return .green
        case .syncing: return .yellow
        case .noAccount, .disabled: return .red
        }
    }

    private var backupStatusText: String {
        guard let info = backupInfo else { return "checking..." }
        switch info.status {
        case .available: return "synced"
        case .syncing: return "syncing..."
        case .noAccount: return "unavailable"
        case .disabled: return "disabled"
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hr ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    private func triggerBackup() {
        isBackingUp = true
        Task {
            do {
                try await CloudBackupManager.shared.triggerManualBackup()
                Analytics.shared.trackCloudBackup(action: "manual_backup", success: true)
            } catch {
                Analytics.shared.trackCloudBackup(action: "manual_backup", success: false)
            }
            backupInfo = await CloudBackupManager.shared.getBackupInfo()
            isBackingUp = false
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("about")

            Button {
                copyDebugInfo()
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

                    Text("filmbox v\(version) (\(build))")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)

                    Text("// tap to copy debug info")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text("// \(title)")
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundStyle(.yellow.opacity(0.8))
    }

    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.yellow : Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func clearButton(title: String, comment: String, size: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(comment)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text("→ \(size)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.yellow.opacity(0.8))
            }
            .padding(12)
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var copiedToast: some View {
        VStack {
            Spacer()
            Text("copied to clipboard")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.yellow)
                .clipShape(Capsule())
                .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: showCopiedToast)
    }

    // MARK: - Actions

    private func copyDebugInfo() {
        let filterCount = 24 // TODO: Get actual filter count from FilterStorage
        let debugInfo = settings.getDebugInfo(
            storageUsed: storageUsed,
            photoCount: manager.photoCount,
            filterCount: filterCount
        )
        UIPasteboard.general.string = debugInfo

        withAnimation {
            showCopiedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }

    private func clearCache() {
        let cacheSize = getCacheSize()

        // Clear thumbnail cache
        manager.clearThumbnailCache()
        // TODO: Clear filter preview cache if available

        // Track cache clear
        Analytics.shared.trackCacheClear(type: "cache", sizeCleared: cacheSize)
    }

    private func getCacheSize() -> Int {
        // Estimate cache size (in a real implementation, calculate from cache directories)
        return 50 * 1024 * 1024 // Placeholder: 50MB
    }

    private func formatBytes(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1024 / 1024 / 1024
        if gb >= 1 {
            return String(format: "%.1fgb", gb)
        }
        let mb = Double(bytes) / 1024 / 1024
        return String(format: "%.0fmb", mb)
    }
}

#Preview {
    SettingsView()
}
