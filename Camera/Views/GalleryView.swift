import SwiftUI
import Photos

struct GalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var photos: [PHAsset] = []
    @State private var selectedPhoto: PHAsset?
    @State private var showFullScreen = false
    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var isLoading = true

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if authorizationStatus == .denied || authorizationStatus == .restricted {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                        Text("Photo Library Access Denied")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Please allow access in Settings")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if photos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("No Photos")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Take some photos with the camera!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(photos, id: \.localIdentifier) { asset in
                                PhotoThumbnailView(asset: asset)
                                    .aspectRatio(1, contentMode: .fill)
                                    .onTapGesture {
                                        selectedPhoto = asset
                                        showFullScreen = true
                                    }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            if let photo = selectedPhoto {
                FullScreenPhotoView(asset: photo, isPresented: $showFullScreen)
            }
        }
        .task {
            await loadPhotos()
        }
    }

    private func loadPhotos() async {
        // Request photo library access
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)

        await MainActor.run {
            authorizationStatus = status
        }

        guard status == .authorized || status == .limited else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []

        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        await MainActor.run {
            photos = assets
            isLoading = false
        }
    }
}

// MARK: - Photo Thumbnail

struct PhotoThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false

        let targetSize = CGSize(width: 200, height: 200)

        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                Task { @MainActor in
                    self.image = result
                }
            }
        }
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let asset: PHAsset
    @Binding var isPresented: Bool
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation {
                                        scale = 1
                                        lastScale = 1
                                    }
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            } else {
                ProgressView()
                    .tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
        .task {
            await loadFullImage()
        }
    }

    private func loadFullImage() async {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            if let result {
                Task { @MainActor in
                    self.image = result
                }
            }
        }
    }
}
