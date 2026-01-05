//
//  MainTabView.swift
//  FilmBox
//
//  Main tab navigation with Fitness-style tab bar
//

import ImageIO
import Metal
import Photos
import SwiftUI

// MARK: - App Tab

enum AppTab: Int, CaseIterable, Identifiable {
    case library = 0
    case filters = 1
    case importTab = 2
    case settings = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .library: return L10n.Tab.library
        case .filters: return L10n.Tab.filters
        case .importTab: return L10n.Tab.import
        case .settings: return L10n.Tab.settings
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
    @State private var showCopiedFeedback = false
    @State private var showMoreMenu = false
    @State private var showPermissionDeniedAlert = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Grid configuration - adaptive for iPad
    private var columns: Int {
        horizontalSizeClass == .regular ? 5 : 3
    }
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
                    Text(L10n.Nav.home)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            L10n.Home.deleteConfirmation(count: manager.selectedCount),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Action.delete, role: .destructive) {
                withAnimation {
                    manager.removeSelectedPhotos()
                    isFabExpanded = false
                }
            }
            Button(L10n.Action.cancel, role: .cancel) {}
        }
        .fullScreenCover(item: $photoToEdit) { photo in
            if let ciImage = manager.loadCIImage(for: photo) {
                let viewModel = EditorV2ViewModel()
                let editSnapshot = manager.getEditSnapshot(for: photo.id)
                EditorV2View(viewModel: viewModel, photoID: photo.id)
                    .onAppear {
                        viewModel.loadImage(ciImage, snapshot: editSnapshot)
                    }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(isPresented: $showFilters) {
            FiltersManagementView()
        }
        .alert(L10n.Home.storageLimit, isPresented: $showStorageLimitAlert) {
            Button(L10n.Action.cancel, role: .cancel) {}
            Button(L10n.Home.openSettings) {
                showSettings = true
            }
        } message: {
            let usedGB = Double(manager.calculateStorageUsed()) / 1024 / 1024 / 1024
            let limitGB = AppSettings.shared.storageLimitGB
            Text(L10n.Home.storageFull(used: String(format: "%.1f", usedGB), limit: String(format: "%.0f", limitGB)))
        }
        .alert(L10n.Home.photoAccess, isPresented: $showPermissionDeniedAlert) {
            Button(L10n.Action.cancel, role: .cancel) {}
            Button(L10n.Home.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(L10n.Home.allowAccess)
        }
    }

    // MARK: - Permission Handling

    private func requestPermissionAndOpenPicker() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            await MainActor.run {
                showPhotoPicker = true
            }
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                if newStatus == .authorized || newStatus == .limited {
                    showPhotoPicker = true
                } else {
                    showPermissionDeniedAlert = true
                }
            }
        case .denied, .restricted:
            await MainActor.run {
                showPermissionDeniedAlert = true
            }
        @unknown default:
            break
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))

            VStack(spacing: 8) {
                Text(L10n.Home.noPhotos)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))

                Text(L10n.Home.tapToAdd)
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
            let itemWidth =
                width > 0 ? (width - spacing * CGFloat(columns - 1)) / CGFloat(columns) : 100
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
                            isRegenerating: manager.regeneratingPhotoIDs.contains(photo.id),
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
            // Dismiss overlay for popup menu
            if showMoreMenu {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            showMoreMenu = false
                        }
                    }
            }

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
                            fabMenuItem(title: L10n.Fab.import, icon: "plus") {
                                isFabExpanded = false
                                // Check storage limit before importing
                                if manager.isStorageLimitExceeded() {
                                    showStorageLimitAlert = true
                                } else {
                                    // Request permission first, then open picker
                                    Task {
                                        await requestPermissionAndOpenPicker()
                                    }
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            fabMenuItem(title: L10n.Fab.filters, icon: "camera.filters") {
                                isFabExpanded = false
                                showFilters = true
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            fabMenuItem(title: L10n.Fab.settings, icon: "gearshape") {
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

    /// Check if we should show "more" button (has copy or paste available)
    private var hasMoreOptions: Bool {
        manager.selectedHasEdits() || manager.canPasteToSelection()
    }

    private var actionTabsView: some View {
        // Main action bar
        HStack(spacing: 0) {
            if isSingleSelection {
                // Single selection: EDIT (primary) | export | delete | more
                // Edit button - highlighted with text label
                Button {
                    if let selectedID = manager.selectedPhotoIDs.first,
                        let photo = manager.photos.first(where: { $0.id == selectedID })
                    {
                        photoToEdit = photo
                    }
                } label: {
                    Text(L10n.Action.edit)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.yellow)
                        )
                }
                .buttonStyle(.plain)

                actionTabDivider

                actionButton(icon: "square.and.arrow.up") {
                    exportAndShare()
                }

                actionTabDivider

                actionButton(icon: "trash") {
                    showDeleteConfirmation = true
                }

                // Show "more" button if copy or paste is available
                if hasMoreOptions {
                    actionTabDivider
                    actionButton(icon: "ellipsis") {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showMoreMenu.toggle()
                        }
                    }
                }
            } else {
                // Multiple selection: export | delete | more (for paste)
                actionButton(icon: "square.and.arrow.up") {
                    exportAndShare()
                }

                actionTabDivider

                actionButton(icon: "trash") {
                    showDeleteConfirmation = true
                }

                // Show "more" button if paste is available
                if manager.canPasteToSelection() {
                    actionTabDivider
                    actionButton(icon: "ellipsis") {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showMoreMenu.toggle()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .overlay(alignment: .topTrailing) {
            // Floating popup menu
            if showMoreMenu {
                floatingMoreMenu
                    .offset(x: 0, y: -52)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .bottomTrailing).combined(
                                with: .opacity),
                            removal: .scale(scale: 0.8, anchor: .bottomTrailing).combined(
                                with: .opacity)
                        ))
            }
        }
    }

    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var actionTabDivider: some View {
        Text("|")
            .font(.system(size: 14, weight: .light, design: .monospaced))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 2)
    }

    // MARK: - Floating Popup Menu (Glass style)

    private var floatingMoreMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Copy Edits - only for single selection with edits
            if isSingleSelection && manager.selectedHasEdits() {
                menuItem(
                    title: showCopiedFeedback ? L10n.Action.copied : L10n.Action.copyEdits,
                    icon: showCopiedFeedback ? "checkmark" : "doc.on.doc"
                ) {
                    _ = manager.copyEditsFromSelected()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showCopiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showCopiedFeedback = false
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            showMoreMenu = false
                        }
                    }
                }
            }

            // Paste Edits - when edits are copied and can paste
            if manager.canPasteToSelection() {
                // Add divider if both options visible
                if isSingleSelection && manager.selectedHasEdits() {
                    Divider()
                        .background(Color.white.opacity(0.15))
                }

                menuItem(title: L10n.Action.pasteEdits, icon: "doc.on.clipboard") {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        showMoreMenu = false
                    }
                    Task {
                        await manager.pasteEditsToSelected()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        )
    }

    private func menuItem(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func fabMenuItem(title: String, icon: String, action: @escaping () -> Void) -> some View
    {
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
        // Close FAB menu if open
        if isFabExpanded {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isFabExpanded = false
            }
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            manager.toggleSelection(photo)
        }
    }

    /// Add Loopix iOS source metadata to image data
    /// When securityMode is true, strips ALL identifying metadata
    private func addSourceMetadata(to data: Data, securityMode: Bool = false) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let utType = CGImageSourceGetType(source)
        else {
            return nil
        }

        let mutableData = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                mutableData,
                utType,
                1,
                nil
            )
        else {
            return nil
        }

        if securityMode {
            // Security mode: strip ALL metadata, only keep "Protected by Loopix iOS"
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }
            let protectedTiffDict: [String: Any] = [
                kCGImagePropertyTIFFSoftware as String: "Protected by Loopix iOS",
                kCGImagePropertyTIFFMake as String: "Loopix",
                kCGImagePropertyTIFFModel as String: "Protected",
            ]
            let cleanMetadata: [String: Any] = [
                kCGImagePropertyTIFFDictionary as String: protectedTiffDict
            ]
            CGImageDestinationAddImage(destination, cgImage, cleanMetadata as CFDictionary)
        } else {
            // Normal mode: preserve metadata, add Loopix iOS
            let loopixTiffDict: [String: Any] = [
                kCGImagePropertyTIFFSoftware as String: "Loopix iOS",
                kCGImagePropertyTIFFMake as String: "Loopix",
                kCGImagePropertyTIFFModel as String: "iOS",
            ]
            let metadata: [String: Any] = [
                kCGImagePropertyTIFFDictionary as String: loopixTiffDict
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

        let format = AppSettings.shared.exportFormat

        // Track export start (North Star funnel)
        Analytics.shared.trackExportStart(photoCount: photos.count, format: format.rawValue)

        let exportStartTime = Date()

        Task {
            isExporting = true
            var urls: [URL] = []
            var hasFilter = false
            var hasToolEdits = false

            // Check security mode setting
            let securityMode = AppSettings.shared.securityMode
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

            for item in photos {
                if let ciImage = ImportedPhotosManager.shared.loadCIImage(for: item.photo) {
                    var processedImage = ciImage

                    // Apply filter preset (CLUT) if selected
                    if let presetID = item.snapshot?.selectedPresetID {
                        let allPresets = await FilterStorage.shared.allPresets
                        if var preset = allPresets.first(where: { $0.id == presetID }) {
                            // Apply preset with intensity
                            let intensity = item.snapshot?.filterIntensity ?? 100
                            preset.clutIntensity = intensity
                            processedImage = await FilterEngine.shared.apply(preset, to: processedImage)
                            hasFilter = true
                        }
                    }

                    // Apply additional parameters (exposure, contrast, crop, etc.)
                    if let params = item.snapshot?.parameters {
                        processedImage = await FilterEngine.shared.apply(params, to: processedImage)
                        hasToolEdits = params.hasAdjustments
                    }

                    // Use Metal-backed CIContext to properly render Metal kernel effects (grain, etc.)
                    let context: CIContext
                    if let metalDevice = MTLCreateSystemDefaultDevice() {
                        context = CIContext(mtlDevice: metalDevice, options: [
                            .workingColorSpace: CGColorSpace(name: CGColorSpace.linearSRGB)!,
                            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
                        ])
                    } else {
                        context = CIContext()
                    }
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(item.photo.id.uuidString).\(format.fileExtension)")

                    var imageData: Data?

                    switch format {
                    case .jpeg:
                        imageData = context.jpegRepresentation(
                            of: processedImage,
                            colorSpace: colorSpace,
                            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.95]
                        )
                    case .png:
                        imageData = context.pngRepresentation(
                            of: processedImage,
                            format: .RGBA8,
                            colorSpace: colorSpace
                        )
                    }

                    if var data = imageData {
                        // Add Loopix iOS source metadata (strip all if security mode)
                        if format == .jpeg {
                            data = addSourceMetadata(to: data, securityMode: securityMode) ?? data
                        }
                        try? data.write(to: tempURL)
                        urls.append(tempURL)
                    }
                }
            }

            isExporting = false

            // Track export complete (NORTH STAR METRIC)
            let exportDuration = Float(Date().timeIntervalSince(exportStartTime))
            Analytics.shared.trackExportComplete(
                photoCount: photos.count,
                successCount: urls.count,
                format: format.rawValue,
                durationSeconds: exportDuration
            )

            // Track export details for analytics
            Analytics.shared.trackExportWithDetails(
                photoCount: urls.count,
                hasFilter: hasFilter,
                hasToolEdits: hasToolEdits,
                format: format.rawValue
            )

            if !urls.isEmpty {
                let activityVC = UIActivityViewController(
                    activityItems: urls, applicationActivities: nil)

                // Clear selection after share sheet is dismissed
                activityVC.completionWithItemsHandler = { _, completed, _, _ in
                    if completed {
                        Task { @MainActor in
                            manager.clearSelection()
                        }
                    }
                }

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let window = windowScene.windows.first,
                    let rootVC = window.rootViewController
                {
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
    let isRegenerating: Bool
    let targetSize: CGSize
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            // Thumbnail or loading placeholder
            if photo.isImporting {
                // Show placeholder with activity indicator while importing
                ZStack {
                    Rectangle()
                        .fill(Color(white: 0.12))
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.6)))
                        .scaleEffect(0.8)
                }
                .frame(width: targetSize.width, height: targetSize.height)
            } else if let thumbnail {
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

            // Regenerating overlay (loading indicator)
            if isRegenerating && !photo.isImporting {
                Color.black.opacity(0.6)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.8)))
                    .scaleEffect(0.8)
            }

            // Selection overlay (don't show during import)
            if isSelected && !photo.isImporting {
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
            // Don't allow tap during import
            guard !photo.isImporting else { return }
            onTap()
        }
        .task(id: "\(photo.thumbnailVersion)_\(photo.isImporting)") {
            // Don't load thumbnail while importing (not ready yet)
            guard !photo.isImporting else { return }
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
