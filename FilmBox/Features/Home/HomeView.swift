//
//  HomeView.swift
//  FilmBox
//
//  Main home screen showing imported photos with selection support
//

import SwiftUI
import Photos

struct HomeView: View {

    // MARK: - Properties

    @State private var manager = ImportedPhotosManager.shared
    @State private var showPhotoPicker = false
    @State private var showEditor = false
    @State private var photoToEdit: ImportedPhoto?
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false

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
            .navigationTitle("FilmBox")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if manager.isSelectionMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            manager.clearSelection()
                        }
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
            .fullScreenCover(isPresented: $showEditor) {
                if let photo = photoToEdit,
                   let asset = manager.getAsset(for: photo) {
                    EditorView(
                        asset: asset,
                        photoID: photo.id,
                        initialParameters: manager.getEditedParameters(for: photo.id)
                    )
                }
            }
            .confirmationDialog(
                "Delete \(manager.selectedCount) photo\(manager.selectedCount == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        manager.removeSelectedPhotos()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showExportSheet) {
                ExportView(assets: manager.getSelectedAssets())
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
                Text("No Photos")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Tap + to import photos from your library")
                    .font(.subheadline)
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
                .padding(.bottom, manager.isSelectionMode ? 100 : 80)
            }
        }
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showPhotoPicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, manager.isSelectionMode ? 100 : 20)
            }
        }
    }

    // MARK: - Selection Action Bar

    private var selectionActionBar: some View {
        HStack(spacing: 0) {
            // Edit button
            ActionBarButton(
                icon: "slider.horizontal.3",
                label: "Edit",
                isEnabled: manager.selectedCount == 1
            ) {
                if let selectedID = manager.selectedPhotoIDs.first,
                   let photo = manager.photos.first(where: { $0.id == selectedID }) {
                    photoToEdit = photo
                    showEditor = true
                }
            }

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            // Export button
            ActionBarButton(
                icon: "square.and.arrow.up",
                label: "Export"
            ) {
                showExportSheet = true
            }

            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))

            // Delete button
            ActionBarButton(
                icon: "trash",
                label: "Delete",
                isDestructive: true
            ) {
                showDeleteConfirmation = true
            }
        }
        .frame(height: 80)
        .background(.ultraThinMaterial.opacity(0.9))
        .background(Color.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
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
                    .fill(Color.white.opacity(0.1))
                    .frame(width: targetSize.width, height: targetSize.height)
            }

            // Selection overlay
            if isSelected {
                Color.black.opacity(0.3)

                // Checkmark
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 24, height: 24)
                            )
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [photo.assetIdentifier], options: nil)
        guard let asset = result.firstObject else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        let manager = PHImageManager.default()
        let scale = await UIScreen.main.scale
        let scaledSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            manager.requestImage(
                for: asset,
                targetSize: scaledSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if let image {
                    Task { @MainActor in
                        self.thumbnail = image
                    }
                }
                if !isDegraded {
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
