import SwiftUI
import AVFoundation
import Photos

struct ContentView: View {
    @State private var cameraAuthorized = false
    @State private var photoLibraryAuthorized = false
    @State private var checkingPermissions = true
    @State private var showSplash = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    #if DEBUG
    @State private var showDebugMenu = false
    @State private var showDebugPaywall = false
    #endif

    var body: some View {
        content
        #if DEBUG
            .overlay(alignment: .topTrailing) { debugLauncher }
            .overlay { if showDebugMenu { debugMenu } }
            .fullScreenCover(isPresented: $showDebugPaywall) { PaywallView() }
        #endif
    }

    private var content: some View {
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
            // Dismiss splash after 0.5 second
            try? await Task.sleep(for: .seconds(0.5))
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

    #if DEBUG
    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    private var debugLauncher: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { showDebugMenu.toggle() }
        } label: {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.purple.opacity(0.85), in: Circle())
        }
        .padding(.top, 4)
        .padding(.trailing, 8)
    }

    private var debugMenu: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { showDebugMenu = false }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("DEV MENU")
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { showDebugMenu = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Toggle("Premium (Pro)", isOn: Binding(
                    get: { subscription.isPro },
                    set: { subscription.debugSetPro($0) }
                ))
                Toggle("Onboarding completed", isOn: $hasCompletedOnboarding)

                Divider().overlay(Color.white.opacity(0.15))

                debugButton("Reset purchase (clear latch)") { subscription.debugReset() }
                debugButton("Force-refresh entitlements") {
                    Task { await subscription.refreshEntitlements() }
                }
                debugButton("Open paywall") {
                    showDebugMenu = false
                    showDebugPaywall = true
                }
            }
            .tint(.purple)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(20)
            .frame(width: 300)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(white: 0.13)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.purple.opacity(0.5), lineWidth: 1))
        }
    }

    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
    #endif
}
