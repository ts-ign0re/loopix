//
//  PhotoPickerView.swift
//  FilmBox
//
//  System photo picker for importing photos
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {

    /// Callback with selected PHAssets
    let onSelect: ([PHAsset]) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 0 // Unlimited selection
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator

        // Dark theme
        picker.overrideUserInterfaceStyle = .dark

        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Get asset identifiers
            let identifiers = results.compactMap { $0.assetIdentifier }

            if !identifiers.isEmpty {
                // Fetch PHAssets from identifiers
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
                var assets: [PHAsset] = []
                fetchResult.enumerateObjects { asset, _, _ in
                    assets.append(asset)
                }
                parent.onSelect(assets)
            }

            parent.dismiss()
        }
    }
}

// MARK: - Alternative: Multi-Select Gallery View

/// Custom gallery view for more control over the selection UI
struct PhotoGalleryPickerView: View {

    @Environment(\.dismiss) private var dismiss
    let onSelect: ([PHAsset]) -> Void

    @State private var assets: [PHAsset] = []
    @State private var selectedAssets: Set<String> = []
    @State private var isLoading = true

    private let columns = 4
    private let spacing: CGFloat = 2

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    galleryGrid
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add (\(selectedAssets.count))") {
                        let selected = assets.filter { selectedAssets.contains($0.localIdentifier) }
                        onSelect(selected)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedAssets.isEmpty ? .white.opacity(0.3) : .white)
                    .disabled(selectedAssets.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadAssets()
        }
    }

    private var galleryGrid: some View {
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
                    ForEach(assets, id: \.localIdentifier) { asset in
                        GalleryPickerCell(
                            asset: asset,
                            isSelected: selectedAssets.contains(asset.localIdentifier),
                            targetSize: itemSize
                        ) {
                            toggleSelection(asset)
                        }
                    }
                }
            }
        }
    }

    private func loadAssets() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .notDetermined {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var fetchedAssets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            fetchedAssets.append(asset)
        }

        await MainActor.run {
            assets = fetchedAssets
            isLoading = false
        }
    }

    private func toggleSelection(_ asset: PHAsset) {
        if selectedAssets.contains(asset.localIdentifier) {
            selectedAssets.remove(asset.localIdentifier)
        } else {
            selectedAssets.insert(asset.localIdentifier)
        }
    }
}

// MARK: - Gallery Picker Cell

private struct GalleryPickerCell: View {
    let asset: PHAsset
    let isSelected: Bool
    let targetSize: CGSize
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
            }

            if isSelected {
                Color.black.opacity(0.3)

                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, .blue)
                            .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            PHImageManager.default().requestImage(
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
