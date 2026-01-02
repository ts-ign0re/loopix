//
//  MainTabView.swift
//  FilmBox
//
//  Main tab navigation with Fitness-style tab bar
//

import SwiftUI
import ImageIO

// MARK: - App Tab

enum AppTab: Int, CaseIterable, Identifiable {
    case library = 0
    case filters = 1
    case importTab = 2
    case settings = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .library: return "Library"
        case .filters: return "Filters"
        case .importTab: return "Import"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .library: return "photo.on.rectangle.angled"
        case .filters: return "camera.filters"
        case .importTab: return "plus.circle"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {

    @State private var showPhotoPicker = false
    @State private var manager = ImportedPhotosManager.shared

    var body: some View {
        LibraryContentView(showPhotoPicker: $showPhotoPicker)
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView { assets in
                    manager.importPhotos(assets)
                }
            }
    }
}

// MARK: - Library Content View (HomeView without tab bar)

struct LibraryContentView: View {
    @Binding var showPhotoPicker: Bool
    @State private var manager = ImportedPhotosManager.shared
    @State private var isFabExpanded = false
    @State private var showDeleteConfirmation = false
    @State private var photoToEdit: ImportedPhoto?
    @State private var isExporting = false
    @State private var showSettings = false
    @State private var showFilters = false
    @State private var showStorageLimitAlert = false

    // Grid configuration
    private let columns = 3
    private let spacing: CGFloat = 2

    private var hasSelection: Bool {
        manager.selectedCount > 0
    }

    private var isSingleSelection: Bool {
        manager.selectedCount == 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if manager.photos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }

                // FAB Menu - always visible
                fabMenuOverlay
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ home")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Delete \(manager.selectedCount) photo\(manager.selectedCount == 1 ? "" : "s")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    manager.removeSelectedPhotos()
                    isFabExpanded = false
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(item: $photoToEdit) { photo in
            if let ciImage = manager.loadCIImage(for: photo) {
                EditorView(
                    ciImage: ciImage,
                    photoID: photo.id,
                    initialParameters: manager.getEditedParameters(for: photo.id)
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showFilters) {
            FiltersManagementView()
        }
        .alert("// storage_limit_reached", isPresented: $showStorageLimitAlert) {
            Button("cancel", role: .cancel) {}
            Button("open_settings") {
                showSettings = true
            }
        } message: {
            let usedGB = Double(manager.calculateStorageUsed()) / 1024 / 1024 / 1024
            let limitGB = AppSettings.shared.storageLimitGB
            Text("storage is full (\(String(format: "%.1f", usedGB))gb / \(String(format: "%.0f", limitGB))gb)\nfree up space to import new photos")
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))

            VStack(spacing: 8) {
                Text("// no_photos")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                Text("tap [import] to add files")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(40)
    }

    // MARK: - Photo Grid

    private var photoGridView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            // Guard against invalid dimensions
            let itemWidth = width > 0 ? (width - spacing * CGFloat(columns - 1)) / CGFloat(columns) : 100
            let itemSize = CGSize(width: max(itemWidth, 1), height: max(itemWidth, 1))

            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: spacing),
                        count: columns
                    ),
                    spacing: spacing
                ) {
                    ForEach(manager.photos) { photo in
                        HomePhotoCell(
                            photo: photo,
                            isSelected: manager.isSelected(photo),
                            isSelectionMode: manager.isSelectionMode,
                            targetSize: itemSize,
                            onTap: {
                                handlePhotoTap(photo)
                            }
                        )
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - FAB Menu Overlay

    private var fabMenuOverlay: some View {
        ZStack(alignment: .bottom) {
            // Left side - Action tabs (when photos selected)
            if hasSelection {
                VStack {
                    Spacer()
                    HStack {
                        actionTabsView
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 28)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Right side - Navigation FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        // Expanded menu items - navigation only
                        if isFabExpanded {
                            fabMenuItem(title: "import", icon: "plus") {
                                isFabExpanded = false
                                // Check storage limit before importing
                                if manager.isStorageLimitExceeded() {
                                    showStorageLimitAlert = true
                                } else {
                                    showPhotoPicker = true
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            fabMenuItem(title: "filters", icon: "camera.filters") {
                                isFabExpanded = false
                                showFilters = true
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            fabMenuItem(title: "settings", icon: "gearshape") {
                                isFabExpanded = false
                                showSettings = true
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Main FAB button - Yellow with navigation icon
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isFabExpanded.toggle()
                            }
                        } label: {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 56, height: 56)
                                .shadow(color: .yellow.opacity(0.4), radius: 8, y: 2)
                                .overlay {
                                    Image(systemName: isFabExpanded ? "xmark" : "line.3.horizontal")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.black)
                                        .rotationEffect(.degrees(isFabExpanded ? 90 : 0))
                                }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasSelection)
    }

    // MARK: - Action Tabs (left side when photos selected)

    private var actionTabsView: some View {
        HStack(spacing: 0) {
            if isSingleSelection {
                // Single selection: edit | export | delete
                actionTab(title: "edit") {
                    if let selectedID = manager.selectedPhotoIDs.first,
                       let photo = manager.photos.first(where: { $0.id == selectedID }) {
                        photoToEdit = photo
                    }
                }

                actionTabDivider

                actionTab(title: "export") {
                    exportAndShare()
                }

                actionTabDivider

                actionTab(title: "delete") {
                    showDeleteConfirmation = true
                }
            } else {
                // Multiple selection: export | delete
                actionTab(title: "export") {
                    exportAndShare()
                }

                actionTabDivider

                actionTab(title: "delete") {
                    showDeleteConfirmation = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    private func actionTab(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private var actionTabDivider: some View {
        Text("|")
            .font(.system(size: 14, weight: .light, design: .monospaced))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 12)
    }

    private func fabMenuItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handlePhotoTap(_ photo: ImportedPhoto) {
        withAnimation(.easeInOut(duration: 0.2)) {
            manager.toggleSelection(photo)
        }
    }

    /// Add RedRoom iOS source metadata to image data
    /// When securityMode is true, strips ALL identifying metadata
    private func addSourceMetadata(to data: Data, securityMode: Bool = false) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let utType = CGImageSourceGetType(source) else {
            return nil
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            utType,
            1,
            nil
        ) else {
            return nil
        }

        if securityMode {
            // Security mode: strip ALL metadata, only keep RedRoom iOS
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }
            let cleanMetadata: [String: Any] = [
                kCGImagePropertyTIFFDictionary as String: [
                    kCGImagePropertyTIFFSoftware as String: "RedRoom iOS"
                ]
            ]
            CGImageDestinationAddImage(destination, cgImage, cleanMetadata as CFDictionary)
        } else {
            // Normal mode: preserve metadata, add RedRoom iOS
            let metadata: [String: Any] = [
                kCGImagePropertyTIFFDictionary as String: [
                    kCGImagePropertyTIFFSoftware as String: "RedRoom iOS"
                ]
            ]
            CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return mutableData as Data
    }

    private func exportAndShare() {
        let photos = manager.getSelectedPhotosForLocalExport()
        guard !photos.isEmpty else { return }

        Task {
            isExporting = true
            var urls: [URL] = []

            // Check security mode setting
            let securityMode = AppSettings.shared.securityMode

            for item in photos {
                if let ciImage = ImportedPhotosManager.shared.loadCIImage(for: item.photo) {
                    var processedImage = ciImage
                    if let params = item.parameters {
                        processedImage = await FilterEngine.shared.apply(params, to: ciImage)
                    }

                    let context = CIContext()
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(item.photo.id.uuidString).heic")

                    if var heicData = context.heifRepresentation(
                        of: processedImage,
                        format: .RGBA8,
                        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                        options: [:]
                    ) {
                        // Add RedRoom iOS source metadata (strip all if security mode)
                        heicData = addSourceMetadata(to: heicData, securityMode: securityMode) ?? heicData
                        try? heicData.write(to: tempURL)
                        urls.append(tempURL)
                    }
                }
            }

            isExporting = false

            if !urls.isEmpty {
                let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    // Find the topmost presented controller
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController {
                        topVC = presented
                    }
                    topVC.present(activityVC, animated: true)
                }
            }
        }
    }
}

// MARK: - Home Photo Cell

struct HomePhotoCell: View {
    let photo: ImportedPhoto
    let isSelected: Bool
    let isSelectionMode: Bool
    let targetSize: CGSize
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            // Thumbnail
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(white: 0.9).opacity(0.08))
                    .frame(width: targetSize.width, height: targetSize.height)
            }

            // Selection overlay
            if isSelected {
                Color.black.opacity(0.4)

                // Selection border
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 3)

                // Square checkmark badge
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.yellow)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.black)
                        }
                        .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .task(id: photo.thumbnailVersion) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        // Load thumbnail - manager handles caching
        let thumb = await MainActor.run {
            ImportedPhotosManager.shared.loadThumbnail(for: photo)
        }
        if let thumb {
            self.thumbnail = thumb
        }
    }
}

// MARK: - Placeholder Views

struct FiltersTabPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "camera.filters")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.2))

                    Text("// filters")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("film presets & luts")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("/ filters")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
