import SwiftUI
import Photos

/// Root content view - displays MainTabView as the main screen
struct ContentView: View {

    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var hasCheckedPermission = false

    var body: some View {
        Group {
            if authorizationStatus == .authorized {
                MainTabView()
            } else if authorizationStatus == .notDetermined {
                // Show loading while checking permission
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            } else {
                // Permission denied or limited - need full access
                fullAccessRequiredView
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if !hasCheckedPermission {
                hasCheckedPermission = true
                await checkAndRequestPermission()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Re-check permission when app comes to foreground
            Task {
                await recheckPermission()
            }
        }
    }

    private var fullAccessRequiredView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.3))

                VStack(spacing: 8) {
                    Text("Full Photo Access Required")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)

                    Text("FilmBox needs full access to your photo library to import and edit photos.\n\nPlease select \"Full Access\" in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Open Settings")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
            .padding(40)
        }
    }

    private func checkAndRequestPermission() async {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if currentStatus == .notDetermined {
            // Request full access permission
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                authorizationStatus = newStatus
                if newStatus == .authorized {
                    ImportedPhotosManager.shared.reloadPhotos()
                }
            }
        } else {
            await MainActor.run {
                authorizationStatus = currentStatus
                if currentStatus == .authorized {
                    ImportedPhotosManager.shared.reloadPhotos()
                }
            }
        }
    }

    private func recheckPermission() async {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        await MainActor.run {
            authorizationStatus = currentStatus
            if currentStatus == .authorized {
                ImportedPhotosManager.shared.reloadPhotos()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
