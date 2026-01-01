//
//  HomeView.swift
//  FilmBox
//
//  Main home screen showing imported photos with selection support
//

import SwiftUI
import Photos

@available(iOS 17.0, *)
struct HomeView: View {

    // MARK: - Properties

    @State private var manager = ImportedPhotosManager.shared
    @State private var showPhotoPicker = false
    @State private var photoToEdit: ImportedPhoto?
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var showFilters = false
    @State private var isFabExpanded = false

    // Grid configuration
    private let columns = 3
    private let spacing: CGFloat = 2

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                if manager.photos.isEmpty {
                    emptyStateView
                } else {
                    photoGridView
                }

                // FAB Button
                fabButton
            }
            .navigationTitle("filmbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if manager.isSelectionMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("done") {
                            manager.clearSelection()
                        }
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.white)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if manager.isSelectionMode && manager.selectedCount > 0 {
                    selectionActionBar
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView { assets in
                    manager.importPhotos(assets)
                }
            }
            .fullScreenCover(item: $photoToEdit) { photo in
                if let ciImage = manager.loadCIImage(for: photo) {
                    EditorView(
                        ciImage: ciImage,
                        photoID: photo.id,
                        initialParameters: manager.getEditedParameters(for: photo.id)
                    )
                } else {
                    NavigationStack {
                        ContentUnavailableView {
                            Label("photo unavailable", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text("this photo could not be loaded. the file may have been deleted.")
                        }
                        .navigationTitle("error")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("close") {
                                    photoToEdit = nil
                                }
                                .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    .preferredColorScheme(.dark)
                }
            }
            .confirmationDialog(
                "delete \(manager.selectedCount) photo\(manager.selectedCount == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("delete", role: .destructive) {
                    withAnimation {
                        manager.removeSelectedPhotos()
                    }
                }
                Button("cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showExportSheet) {
                ExportView(localPhotos: manager.getSelectedPhotosForLocalExport())
            }
            .sheet(isPresented: $showFilters) {
                FiltersManagementView()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 8) {
                Text("no photos")
                    .font(.system(.title2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white)

                Text("tap + to import photos from your library")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }

    // MARK: - Photo Grid

    private var photoGridView: some View {
        GeometryReader { geometry in
            let itemWidth = (geometry.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let itemSize = CGSize(width: itemWidth, height: itemWidth)

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
                .padding(.bottom, manager.isSelectionMode ? 90 : 80)
            }
        }
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Expanded menu items
                    if isFabExpanded {
                        VStack(alignment: .trailing, spacing: 8) {
                            // Import photos
                            fabMenuItem(title: "import", icon: "photo.on.rectangle.angled") {
                                showPhotoPicker = true
                                isFabExpanded = false
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))

                            // Filters management
                            fabMenuItem(title: "filters", icon: "slider.horizontal.3") {
                                showFilters = true
                                isFabExpanded = false
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
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
                                Image(systemName: isFabExpanded ? "xmark" : "plus")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .rotationEffect(.degrees(isFabExpanded ? 90 : 0))
                            }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
                .padding(.trailing, 20)
                .padding(.bottom, manager.isSelectionMode ? 90 : 28)
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

    // MARK: - Selection Action Bar

    private var selectionActionBar: some View {
        HStack(spacing: 24) {
            // Edit button - only show when exactly 1 image selected
            if manager.selectedCount == 1 {
                Button {
                    if let selectedID = manager.selectedPhotoIDs.first,
                       let photo = manager.photos.first(where: { $0.id == selectedID }) {
                        photoToEdit = photo
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                        Text("edit")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundStyle(.white)
                }
            }

            // Export button
            Button {
                showExportSheet = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                    Text("export")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundStyle(.white)
            }

            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    Text("delete")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(height: 70)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.85))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3), value: manager.isSelectionMode)
    }

    // MARK: - Actions

    private func handlePhotoTap(_ photo: ImportedPhoto) {
        // Always toggle selection on tap
        withAnimation(.easeInOut(duration: 0.2)) {
            manager.toggleSelection(photo)
        }
    }
}

// MARK: - Action Bar Button

private struct ActionBarButton: View {
    let icon: String
    let label: String
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
        }
        .disabled(!isEnabled)
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return .white.opacity(0.3)
        } else if isDestructive {
            return .red
        } else {
            return .white
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

// MARK: - Preview

#Preview {
    HomeView()
}
