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
    @State private var cacheSize: Int = 0
    @State private var showClearPhotosConfirmation = false
    @State private var showClearCacheConfirmation = false
    @State private var showCopiedToast = false
    @State private var showSecurityHelp = false
    @State private var backupInfo: BackupInfo?
    @State private var isBackingUp = false
    @State private var showRestartAlert = false
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

                    // Language Section
                    languageSection

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
                // Add EditedPhotos storage to total
                let editedSize = await EditedPhotoStorage.shared.totalStorageUsed()

                // Calculate cache sizes
                let thumbnailCacheSize = await ThumbnailCache.shared.cacheSize()
                let filterPreviewCacheSize = await FilterPreviewCache.shared.diskCacheSize()

                await MainActor.run {
                    storageUsed += editedSize
                    cacheSize = thumbnailCacheSize + filterPreviewCacheSize
                }
            }

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
        .fullScreenCover(isPresented: $showSecurityHelp) {
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
            sectionHeader(L10n.Settings.storage)

            // Usage bar
            VStack(alignment: .leading, spacing: 8) {
                let usedGB = Double(storageUsed) / 1024 / 1024 / 1024
                let limitGB = settings.storageLimitGB
                let percentage = min(usedGB / limitGB, 1.0)

                Text(L10n.Settings.used(size: formatBytes(storageUsed), limit: Int(limitGB)))
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
                Text(L10n.Settings.limit)
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
                    title: L10n.Settings.clearPhotos,
                    comment: L10n.Settings.clearPhotosComment,
                    size: formatBytes(storageUsed)
                ) {
                    showClearPhotosConfirmation = true
                }

                clearButton(
                    title: L10n.Settings.clearCache,
                    comment: L10n.Settings.clearCacheComment,
                    size: formatBytes(cacheSize)
                ) {
                    showClearCacheConfirmation = true
                }
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(L10n.Settings.exportDefaults)

            // Format picker
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Settings.format)
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
                Text(L10n.Settings.quality)
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
                Text(L10n.Settings.size)
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
            sectionHeader(L10n.Settings.performance)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Settings.previewQuality)
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

                Text(L10n.Settings.affectsResponsiveness)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("settings.language".localized)

            VStack(alignment: .leading, spacing: 8) {
                VStack(spacing: 8) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        languageButton(language)
                    }
                }

                Text("settings.restart_comment".localized)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .alert("settings.restart_required".localized, isPresented: $showRestartAlert) {
            Button(L10n.Action.ok, role: .cancel) {}
        } message: {
            Text("settings.restart_message".localized)
        }
    }

    private func languageButton(_ language: AppLanguage) -> some View {
        Button {
            let oldLanguage = settings.appLanguage
            settings.appLanguage = language
            Analytics.shared.trackSettingChange(setting: "app_language", value: language.rawValue)

            if oldLanguage != language {
                showRestartAlert = true
            }
        } label: {
            HStack {
                Text(language.displayName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(settings.appLanguage == language ? .black : .white)

                Spacer()

                if settings.appLanguage == language {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(settings.appLanguage == language ? Color.yellow : Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(settings.appLanguage == language ? 0 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Security Section

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(L10n.Settings.security)
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
                        Text(L10n.Settings.stripMetadata)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)

                        Text(L10n.Settings.stripMetadataComment)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .tint(.yellow)

                if settings.securityMode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Settings.removedOnExport)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        VStack(alignment: .leading, spacing: 3) {
                            metadataItem(L10n.Settings.gpsLocation)
                            metadataItem(L10n.Settings.dateTime)
                            metadataItem(L10n.Settings.deviceModel)
                            metadataItem(L10n.Settings.cameraSettings)
                            metadataItem(L10n.Settings.softwareAuthor)
                            metadataItem(L10n.Settings.thumbnailsPreviews)
                        }

                        Text(L10n.Settings.protectedTag)
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
            sectionHeader(L10n.Settings.backup)

            VStack(alignment: .leading, spacing: 12) {
                // Status row
                HStack {
                    Text(L10n.Settings.status)
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
                    let timeText = formatRelativeTime(lastDate)
                    if let device = info.lastDeviceName {
                        Text(L10n.Settings.lastBackup(time: timeText, device: device))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Text(L10n.Settings.lastBackupNoDevice(time: timeText))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }

                // iCloud unavailable message
                if backupInfo?.status == .noAccount {
                    Text(L10n.Settings.icloudSignin)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                } else if backupInfo?.status == .disabled {
                    Text(L10n.Settings.icloudEnable)
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
                        Text(isBackingUp ? L10n.Settings.syncing : L10n.Settings.backupNow)
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
        guard let info = backupInfo else { return L10n.Settings.checking }
        switch info.status {
        case .available: return L10n.Settings.synced
        case .syncing: return L10n.Settings.syncing
        case .noAccount: return L10n.Settings.unavailable
        case .disabled: return L10n.Settings.disabled
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return L10n.Time.justNow
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return L10n.Time.minAgo(minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return L10n.Time.hrAgo(hours)
        } else {
            let days = Int(interval / 86400)
            return L10n.Time.dayAgo(days)
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
            sectionHeader(L10n.Settings.about)

            Button {
                copyDebugInfo()
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

                    Text(L10n.Settings.version(ver: version, build: build))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(L10n.Settings.tapToCopy)
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
            Text(L10n.Settings.copiedToClipboard)
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
        let clearedSize = cacheSize

        Task {
            // Clear ThumbnailCache (disk + memory)
            await ThumbnailCache.shared.clearCache()

            // Clear FilterPreviewCache (disk + memory)
            await FilterPreviewCache.shared.clearAllCaches()

            await MainActor.run {
                cacheSize = 0
            }
        }

        // Clear memory cache in ImportedPhotosManager
        manager.clearThumbnailCache()

        // Track cache clear
        Analytics.shared.trackCacheClear(type: "cache", sizeCleared: clearedSize)
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
