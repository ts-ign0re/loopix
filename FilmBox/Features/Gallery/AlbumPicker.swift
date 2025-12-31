import SwiftUI
import Photos

/// Sheet view for selecting a photo album
struct AlbumPicker: View {

    // MARK: - Properties

    @Binding var selectedAlbum: PHAssetCollection?
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var smartAlbums: [PHAssetCollection] = []
    @State private var userAlbums: [PHAssetCollection] = []
    @State private var albumCounts: [String: Int] = [:]
    @State private var albumThumbnails: [String: UIImage] = [:]
    @State private var isLoading = true

    // MARK: - Private Properties

    private static let imageManager = PHCachingImageManager()
    private let thumbnailSize = CGSize(width: 160, height: 160)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading albums...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    albumList
                }
            }
            .navigationTitle("Albums")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadAlbums()
        }
    }

    // MARK: - Subviews

    private var albumList: some View {
        List {
            // All Photos option
            Section {
                albumRow(
                    title: "All Photos",
                    count: fetchAllPhotosCount(),
                    thumbnail: albumThumbnails["all"],
                    isSelected: selectedAlbum == nil
                ) {
                    selectedAlbum = nil
                    dismiss()
                }
            }

            // Smart Albums (Camera Roll, Favorites, etc.)
            if !smartAlbums.isEmpty {
                Section("Smart Albums") {
                    ForEach(smartAlbums, id: \.localIdentifier) { album in
                        albumRow(
                            title: album.localizedTitle ?? "Untitled",
                            count: albumCounts[album.localIdentifier] ?? 0,
                            thumbnail: albumThumbnails[album.localIdentifier],
                            isSelected: selectedAlbum?.localIdentifier == album.localIdentifier
                        ) {
                            selectedAlbum = album
                            dismiss()
                        }
                    }
                }
            }

            // User Albums
            if !userAlbums.isEmpty {
                Section("My Albums") {
                    ForEach(userAlbums, id: \.localIdentifier) { album in
                        albumRow(
                            title: album.localizedTitle ?? "Untitled",
                            count: albumCounts[album.localIdentifier] ?? 0,
                            thumbnail: albumThumbnails[album.localIdentifier],
                            isSelected: selectedAlbum?.localIdentifier == album.localIdentifier
                        ) {
                            selectedAlbum = album
                            dismiss()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func albumRow(
        title: String,
        count: Int,
        thumbnail: UIImage?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                Image(systemName: "photo.on.rectangle")
                                    .foregroundColor(.gray)
                            }
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Album info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text("\(count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.body.weight(.semibold))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func loadAlbums() async {
        isLoading = true

        // Fetch smart albums
        let smartAlbumTypes: [PHAssetCollectionSubtype] = [
            .smartAlbumUserLibrary,     // Camera Roll / All Photos
            .smartAlbumFavorites,       // Favorites
            .smartAlbumRecentlyAdded,   // Recently Added
            .smartAlbumScreenshots,     // Screenshots
            .smartAlbumSelfPortraits,   // Selfies
            .smartAlbumPanoramas,       // Panoramas
            .smartAlbumLivePhotos,      // Live Photos
            .smartAlbumBursts           // Bursts
        ]

        var fetchedSmartAlbums: [PHAssetCollection] = []

        for subtype in smartAlbumTypes {
            let result = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: subtype,
                options: nil
            )
            result.enumerateObjects { collection, _, _ in
                // Only include albums with photos
                let count = PHAsset.fetchAssets(in: collection, options: imageOnlyFetchOptions()).count
                if count > 0 {
                    fetchedSmartAlbums.append(collection)
                    albumCounts[collection.localIdentifier] = count
                }
            }
        }

        // Fetch user albums
        let userAlbumsResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )

        var fetchedUserAlbums: [PHAssetCollection] = []
        userAlbumsResult.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: imageOnlyFetchOptions()).count
            if count > 0 {
                fetchedUserAlbums.append(collection)
                albumCounts[collection.localIdentifier] = count
            }
        }

        // Sort user albums by title
        fetchedUserAlbums.sort { ($0.localizedTitle ?? "") < ($1.localizedTitle ?? "") }

        // Load thumbnails for all albums
        await loadAllThumbnails(smartAlbums: fetchedSmartAlbums, userAlbums: fetchedUserAlbums)

        await MainActor.run {
            self.smartAlbums = fetchedSmartAlbums
            self.userAlbums = fetchedUserAlbums
            self.isLoading = false
        }
    }

    private func loadAllThumbnails(
        smartAlbums: [PHAssetCollection],
        userAlbums: [PHAssetCollection]
    ) async {
        // Load "All Photos" thumbnail
        let allPhotosResult = PHAsset.fetchAssets(with: .image, options: sortedFetchOptions())
        if let firstAsset = allPhotosResult.firstObject {
            if let image = await loadThumbnail(for: firstAsset) {
                await MainActor.run {
                    albumThumbnails["all"] = image
                }
            }
        }

        // Load thumbnails for smart albums
        for album in smartAlbums {
            let assets = PHAsset.fetchAssets(in: album, options: sortedFetchOptions())
            if let firstAsset = assets.firstObject {
                if let image = await loadThumbnail(for: firstAsset) {
                    await MainActor.run {
                        albumThumbnails[album.localIdentifier] = image
                    }
                }
            }
        }

        // Load thumbnails for user albums
        for album in userAlbums {
            let assets = PHAsset.fetchAssets(in: album, options: sortedFetchOptions())
            if let firstAsset = assets.firstObject {
                if let image = await loadThumbnail(for: firstAsset) {
                    await MainActor.run {
                        albumThumbnails[album.localIdentifier] = image
                    }
                }
            }
        }
    }

    private func loadThumbnail(for asset: PHAsset) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        return await withCheckedContinuation { continuation in
            Self.imageManager.requestImage(
                for: asset,
                targetSize: thumbnailSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    private func fetchAllPhotosCount() -> Int {
        PHAsset.fetchAssets(with: .image, options: nil).count
    }

    private func imageOnlyFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return options
    }

    private func sortedFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        return options
    }
}

// MARK: - Preview

#Preview {
    AlbumPicker(selectedAlbum: .constant(nil))
}
