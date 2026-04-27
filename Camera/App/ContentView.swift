import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @State private var cameraAuthorized = false
    @State private var photoLibraryAuthorized = false
    @State private var checkingPermissions = true
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else if checkingPermissions {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
            } else if !hasCompletedOnboarding {
                OnboardingView { isRightHanded in
                    UserDefaults.standard.set(isRightHanded, forKey: "isRightHanded")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasCompletedOnboarding = true
                    }
                }
            } else if cameraAuthorized {
                CameraView()
            } else {
                permissionDeniedView
            }
        }
        .task {
            // Dismiss splash after 1 second
            try? await Task.sleep(for: .seconds(1))
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
            await checkPermissions()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("Please allow camera access in Settings to use this app.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func checkPermissions() async {
        // Camera — required before showing UI
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraStatus {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            cameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            cameraAuthorized = false
        }

        // Show camera immediately, don't wait for photo library
        checkingPermissions = false

        // Photo library — only needed when saving, request in background
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch photoStatus {
        case .authorized, .limited:
            photoLibraryAuthorized = true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            photoLibraryAuthorized = status == .authorized || status == .limited
        default:
            photoLibraryAuthorized = false
        }
    }
}
