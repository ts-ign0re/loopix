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

    var body: some View {
        NavigationStack {
            ScrollView {
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
            storageUsed = manager.calculateStorageUsed()
        }
        .confirmationDialog(
            "clear_photos()",
            isPresented: $showClearPhotosConfirmation,
            titleVisibility: .visible
        ) {
            Button("delete all photos", role: .destructive) {
                manager.clearAllPhotos()
                storageUsed = manager.calculateStorageUsed()
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
            VStack(alignment: .leading, spacing: 8) {
                Text("limit")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 12) {
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
                        }
                    }
                }

                Text("// affects editor responsiveness")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
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
        // Clear thumbnail cache
        manager.clearThumbnailCache()
        // TODO: Clear filter preview cache if available
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
