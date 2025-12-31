import SwiftUI
import Photos

/// Main gallery view displaying a 4-column photo grid with selection support
struct GalleryView: View {

    // MARK: - Properties

    @State private var viewModel = GalleryViewModel()
    @State private var navigateToEditor = false
    @State private var selectedAssetForEditor: PHAsset?

    // MARK: - Constants

    private let columns = 4
    private let spacing: CGFloat = 2

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                Group {
                    switch viewModel.authorizationStatus {
                    case .authorized, .limited:
                        photoGrid
                    case .denied, .restricted:
                        accessDeniedView
                    case .notDetermined:
                        requestAccessView
                    @unknown default:
                        requestAccessView
                    }
                }

                // Loading overlay
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle(viewModel.albumTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $viewModel.showAlbumPicker) {
                AlbumPicker(selectedAlbum: $viewModel.currentAlbum)
                    .onChange(of: viewModel.currentAlbum) { _, _ in
                        Task {
                            await viewModel.loadPhotos()
                        }
                    }
            }
            .navigationDestination(isPresented: $navigateToEditor) {
                if let asset = selectedAssetForEditor {
                    // Placeholder for editor navigation
                    Text("Editor for \(asset.localIdentifier)")
                        .navigationTitle("Edit")
                }
            }
        }
        .task {
            await viewModel.requestAuthorizationAndLoad()
        }
        .overlay(alignment: .bottom) {
            if viewModel.isSelectionMode && viewModel.selectedCount > 0 {
                selectionToolbar
            }
        }
    }

    // MARK: - Photo Grid

    private var photoGrid: some View {
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
                    ForEach(viewModel.photoAssets, id: \.localIdentifier) { asset in
                        PhotoGridItem(
                            asset: asset,
                            isSelected: viewModel.isSelected(asset),
                            isSelectionMode: viewModel.isSelectionMode,
                            targetSize: itemSize,
                            onTap: {
                                openEditor(for: asset)
                            },
                            onLongPress: {
                                viewModel.toggleSelection(for: asset)
                            }
                        )
                        .id(asset.localIdentifier)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 0)
                .padding(.bottom, viewModel.isSelectionMode ? 80 : 0)
            }
            .scrollIndicators(.automatic)
            .refreshable {
                await viewModel.loadPhotos()
            }
            .onScrollGeometryChange(for: CGRect.self) { geometry in
                geometry.visibleRect
            } action: { oldValue, newValue in
                handleScrollChange(
                    visibleRect: newValue,
                    itemSize: itemSize,
                    viewportHeight: geometry.size.height
                )
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                viewModel.showAlbumPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                if viewModel.isSelectionMode {
                    viewModel.deselectAll()
                } else {
                    viewModel.toggleSelectionMode()
                }
            } label: {
                Text(viewModel.isSelectionMode ? "Cancel" : "Select")
            }
        }
    }

    // MARK: - Selection Toolbar

    private var selectionToolbar: some View {
        HStack {
            // Selected count
            Text("\(viewModel.selectedCount) selected")
                .font(.subheadline.weight(.medium))

            Spacer()

            // Export button
            Button {
                exportSelectedPhotos()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            // Edit button
            Button {
                editSelectedPhotos()
            } label: {
                Label("Edit", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSelectionMode)
    }

    // MARK: - Access Views

    private var accessDeniedView: some View {
        ContentUnavailableView {
            Label("No Photo Access", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("FilmBox needs access to your photos to display them here.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var requestAccessView: some View {
        ContentUnavailableView {
            Label("Photo Library", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Tap to grant access to your photo library.")
        } actions: {
            Button("Grant Access") {
                Task {
                    await viewModel.requestAuthorizationAndLoad()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Private Methods

    private func openEditor(for asset: PHAsset) {
        selectedAssetForEditor = asset
        navigateToEditor = true
    }

    private func exportSelectedPhotos() {
        // Handle export action
        // This would typically present an export sheet
    }

    private func editSelectedPhotos() {
        // Handle batch edit action
        // This would typically navigate to batch editor
    }

    private func handleScrollChange(
        visibleRect: CGRect,
        itemSize: CGSize,
        viewportHeight: CGFloat
    ) {
        // Calculate prefetch rect (2 screens ahead)
        let prefetchRect = CGRect(
            x: visibleRect.minX,
            y: max(0, visibleRect.minY - viewportHeight),
            width: visibleRect.width,
            height: visibleRect.height + viewportHeight * 3
        )

        viewModel.updateCaching(
            visibleRect: visibleRect,
            prefetchRect: prefetchRect,
            itemSize: itemSize
        )
    }
}

// MARK: - Preview

#Preview {
    GalleryView()
}
