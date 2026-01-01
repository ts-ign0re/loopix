//
//  MainTabView.swift
//  FilmBox
//
//  Main tab navigation with Fitness-style tab bar
//

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
            .navigationTitle("filmbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if manager.isSelectionMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            manager.clearSelection()
                            isFabExpanded = false
                        } label: {
                            Text("done")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(.yellow)
                        }
                    }
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
            SettingsTabPlaceholder()
        }
        .sheet(isPresented: $showFilters) {
            FiltersManagementView()
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
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Expanded menu items
                    if isFabExpanded {
                        VStack(alignment: .trailing, spacing: 8) {
                            if hasSelection {
                                // Selection mode menu
                                if isSingleSelection {
                                    fabMenuItem(title: "edit", icon: "slider.horizontal.3") {
                                        if let selectedID = manager.selectedPhotoIDs.first,
                                           let photo = manager.photos.first(where: { $0.id == selectedID }) {
                                            photoToEdit = photo
                                            isFabExpanded = false
                                        }
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }

                                fabMenuItem(title: "export", icon: "square.and.arrow.up") {
                                    isFabExpanded = false
                                    exportAndShare()
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))

                                fabMenuItem(title: "delete", icon: "trash") {
                                    showDeleteConfirmation = true
                                    isFabExpanded = false
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else {
                                // Default menu (no selection)
                                fabMenuItem(title: "import", icon: "plus") {
                                    isFabExpanded = false
                                    showPhotoPicker = true
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
                        }
                    }

                    // Main FAB button - Yellow
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
                                Image(systemName: isFabExpanded ? "xmark" : (hasSelection ? "ellipsis" : "plus"))
                                    .font(.system(size: 22, weight: .semibold))
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

    private func exportAndShare() {
        let photos = manager.getSelectedPhotosForLocalExport()
        guard !photos.isEmpty else { return }

        Task {
            isExporting = true
            var urls: [URL] = []

            for item in photos {
                if let ciImage = ImportedPhotosManager.shared.loadCIImage(for: item.photo) {
                    var processedImage = ciImage
                    if let params = item.parameters {
                        processedImage = await FilterEngine.shared.apply(params, to: ciImage)
                    }

                    let context = CIContext()
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(item.photo.id.uuidString).heic")

                    if let heicData = context.heifRepresentation(
                        of: processedImage,
                        format: .RGBA8,
                        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                        options: [:]
                    ) {
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
            .navigationTitle("filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
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

struct SettingsTabPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.2))

                    Text("// config")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("preferences & defaults")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
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
