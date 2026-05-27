import SwiftUI
import Photos

// swiftlint:disable type_body_length
struct CameraView: View {
    @State private var cameraManager = CameraManager()
    @State private var state = CameraState()
    @State private var focusLocation: CGPoint?
    @State private var showFocusIndicator = false
    @State private var shutterAnimating = false
    @State private var showEVWheel = false
    @State private var showPaywall = false
    @State private var showPhotoPermissionAlert = false

    @State private var isoJustLongPressed = false

    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    private var currentFilter: CameraFilter {
        let filters = BuiltInFilters.all
        guard state.selectedFilterIndex < filters.count else { return .clean }
        return filters[state.selectedFilterIndex]
    }

    private var isFilterLocked: Bool {
        !subscription.isPro && !SubscriptionManager.freeFilterIDs.contains(currentFilter.id)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .frame(height: CameraTheme.topBarHeight)

                    // Preview — 4:3 sensor ratio (3:4 portrait)
                    ZStack {
                        CameraPreviewView(
                            cameraManager: cameraManager,
                            state: state,
                            filter: currentFilter
                        ) { point in
                            handleFocusTap(point)
                        }
                        .clipped()

                        // Grid overlay
                        if state.showGrid {
                            GridOverlay()
                        }

                        // Watermark overlay for locked filters
                        if isFilterLocked {
                            Button {
                                showPaywall = true
                            } label: {
                                Image("SplashLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120, height: 120)
                                    .opacity(0.45)
                            }
                        }

                        // Focus indicator
                        if showFocusIndicator, let loc = focusLocation {
                            FocusIndicatorView()
                                .position(
                                    x: loc.x * geometry.size.width,
                                    y: loc.y * (geometry.size.width * 4.0 / 3.0)
                                )
                        }
                    }
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)

                    // Filter strip
                    FilterStripView(
                        selectedIndex: $state.selectedFilterIndex,
                        onLockedFilterTapped: {
                            showPaywall = true
                        }
                    )
                    .padding(.top, CameraTheme.paddingMedium)
                    .padding(.bottom, CameraTheme.paddingMedium)

                    // Intensity wheel — visible for non-clean filters
                    if currentFilter.id != "clean" {
                        IntensityWheelView(value: $state.filterIntensity)
                            .padding(.bottom, CameraTheme.paddingSmall + 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Bottom controls
                    bottomBar

                    // EV Wheel — toggled by EV button
                    if showEVWheel {
                        EVWheelView(
                            value: $state.evCompensation,
                            range: state.minEV...state.maxEV
                        ) { exposureBias in
                            cameraManager.setEVCompensation(exposureBias)
                        }
                        .padding(.bottom, CameraTheme.paddingSmall)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if let errorText = cameraManager.error {
                    Text(errorText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.9))
                        )
                        .padding(.bottom, 18)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .statusBarHidden()
        .onAppear {
            cameraManager.configure(state: state)
        }
        .onDisappear {
            if state.isRecording {
                cameraManager.stopVideoRecording(state: state)
            }
            cameraManager.stop()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Allow Photo Access", isPresented: $showPhotoPermissionAlert) {
            Button("Not Now", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Loopix needs permission to save your photos. Turn on Photos access in Settings to start shooting.")
        }
        .onChange(of: state.selectedFilterIndex) { _, newValue in
            if newValue >= 0, newValue < BuiltInFilters.all.count {
                UserDefaults.standard.set(BuiltInFilters.all[newValue].id, forKey: "selectedFilterID")
            }
            if state.captureMode == .video, state.isRecording {
                cameraManager.updateVideoRecordingFilter(state: state, filter: currentFilter)
            }
        }
        .onChange(of: state.filterIntensity) { _, _ in
            if state.captureMode == .video, state.isRecording {
                cameraManager.updateVideoRecordingFilter(state: state, filter: currentFilter)
            }
        }
        .onChange(of: state.captureMode) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "captureMode")
            if newValue == .photo, state.isRecording {
                cameraManager.stopVideoRecording(state: state)
            }
            cameraManager.setCaptureMode(newValue)
        }
        .onChange(of: cameraManager.error) { _, message in
            guard let message else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if cameraManager.error == message {
                    cameraManager.error = nil
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Grid toggle
            Button {
                state.showGrid.toggle()
            } label: {
                Image(systemName: "grid")
                    .font(.system(size: 16))
                    .foregroundColor(state.showGrid ? CameraTheme.controlActive : CameraTheme.text)
            }
            .padding(.leading, CameraTheme.paddingLarge)

            // Handedness toggle
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    state.isRightHanded.toggle()
                    UserDefaults.standard.set(state.isRightHanded, forKey: "isRightHanded")
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: state.isRightHanded ? "hand.point.right" : "hand.point.left")
                    .font(.system(size: 14))
                    .foregroundColor(CameraTheme.textSecondary)
            }
            .padding(.leading, CameraTheme.paddingMedium)

            Spacer()

            VStack(spacing: 4) {
                captureModeSwitch

                if state.isRecording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("REC")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color.red)
                    }
                }
            }

            Spacer()

            // ISO Selector
            Button {
                guard !isoJustLongPressed else { return }
                let isoStops = isoStopValues()
                if state.isAutoISO {
                    state.isAutoISO = false
                    let nextISO = isoStops.first ?? state.currentISO
                    cameraManager.setISO(nextISO)
                } else {
                    let current = state.currentISO
                    if let idx = isoStops.firstIndex(where: { abs($0 - current) < 1 }),
                       idx + 1 < isoStops.count {
                        cameraManager.setISO(isoStops[idx + 1])
                    } else {
                        state.isAutoISO = true
                        cameraManager.setAutoExposure()
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 14))
                    Text(isoLabel)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(state.isAutoISO ? CameraTheme.textSecondary : CameraTheme.controlActive)
                .frame(width: 60, alignment: .trailing)
            }
            .padding(.trailing, CameraTheme.paddingLarge)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                    isoJustLongPressed = true
                    state.isAutoISO = true
                    cameraManager.setAutoExposure()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isoJustLongPressed = false
                    }
                }
            )
        }
        .background(CameraTheme.background)
    }

    private var captureModeSwitch: some View {
        HStack(spacing: 4) {
            captureModeButton(.photo, label: "PHOTO")
            captureModeButton(.video, label: "VIDEO")
        }
        .padding(3)
        .background(
            Capsule()
                .fill(CameraTheme.pillBackground)
        )
    }

    private func captureModeButton(_ mode: CaptureMode, label: String) -> some View {
        let isSelected = state.captureMode == mode

        return Button {
            guard state.captureMode != mode else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                state.captureMode = mode
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .black : CameraTheme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? CameraTheme.controlActive : Color.clear)
                )
        }
    }

    // MARK: - Bottom Bar

    // Controls group: lenses + EV
    private var controlsGroup: some View {
        HStack(spacing: 12) {
            LensSelectorView(
                lenses: state.availableLenses,
                selectedIndex: $state.selectedLensIndex
            ) { index in
                cameraManager.switchLens(to: index, state: state)
            }

            // EV toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showEVWheel.toggle()
                }
            } label: {
                Text("EV")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(showEVWheel ? CameraTheme.controlActive : CameraTheme.textSecondary)
                    .frame(width: CameraTheme.lensButtonSize, height: CameraTheme.lensButtonSize)
                    .background(
                        Circle()
                            .fill(showEVWheel ? CameraTheme.controlActive.opacity(0.15) : CameraTheme.pillBackground)
                    )
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if state.isRightHanded {
                controlsGroup
                shutterButton
            } else {
                shutterButton
                controlsGroup
            }
        }
        .padding(.horizontal, CameraTheme.paddingLarge)
        .padding(.vertical, CameraTheme.paddingSmall)
    }

    private var shutterButton: some View {
        ShutterButton(
            isCapturing: state.isCapturing,
            captureMode: state.captureMode,
            isRecording: state.isRecording,
            shutterAnimating: $shutterAnimating
        ) {
            if isFilterLocked {
                showPaywall = true
                return
            }

            if state.captureMode == .photo {
                attemptPhotoCapture()
            } else {
                if state.isRecording {
                    cameraManager.stopVideoRecording(state: state)
                } else {
                    cameraManager.startVideoRecording(state: state, filter: currentFilter)
                }
            }
        }
    }

    // MARK: - Focus

    private func handleFocusTap(_ point: CGPoint) {
        focusLocation = point
        showFocusIndicator = true

        // Convert for AVFoundation (y is flipped)
        let avPoint = CGPoint(x: point.x, y: 1 - point.y)
        cameraManager.setFocusPoint(avPoint, lock: state.isFocusLocked)

        // Auto-hide focus indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showFocusIndicator = false
            }
        }
    }

    // MARK: - Photo Capture Gating

    /// A photo is only useful if we can save it. Gate the shutter on Photos "add" access:
    /// ask the first time, and send the user to Settings if they've denied it.
    private func attemptPhotoCapture() {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            performPhotoCapture()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        performPhotoCapture()
                    } else {
                        showPhotoPermissionAlert = true
                    }
                }
            }
        default:
            showPhotoPermissionAlert = true
        }
    }

    private func performPhotoCapture() {
        shutterAnimating = true
        cameraManager.capturePhoto(state: state, filter: currentFilter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            shutterAnimating = false
        }
    }

    // MARK: - ISO Selector

    private func isoStopValues() -> [Float] {
        let minISO = max(state.minISO, 25)
        let maxISO = state.maxISO
        var stops = [minISO]
        for iso: Float in [50, 100, 200, 400, 800, 1600, 3200, 6400] {
            if iso > minISO && iso < maxISO { stops.append(iso) }
        }
        stops.append(maxISO)
        return stops
    }

    private var isoLabel: String {
        state.isAutoISO ? "Auto" : "\(Int(state.currentISO))"
    }
}
// swiftlint:enable type_body_length

// MARK: - Grid Overlay

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            Path { path in
                // Vertical lines (thirds)
                path.move(to: CGPoint(x: width / 3, y: 0))
                path.addLine(to: CGPoint(x: width / 3, y: height))
                path.move(to: CGPoint(x: 2 * width / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * width / 3, y: height))

                // Horizontal lines (thirds)
                path.move(to: CGPoint(x: 0, y: height / 3))
                path.addLine(to: CGPoint(x: width, y: height / 3))
                path.move(to: CGPoint(x: 0, y: 2 * height / 3))
                path.addLine(to: CGPoint(x: width, y: 2 * height / 3))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
