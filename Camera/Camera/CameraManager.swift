import AVFoundation
import CoreImage
import CoreMotion
import Combine
import Metal
import Photos
import UIKit

// swiftlint:disable file_length type_body_length
/// Orchestrates the camera capture session, video data output for preview,
/// and photo output for processed capture.
@Observable
final class CameraManager: NSObject, @unchecked Sendable {

    // MARK: - Public State

    var isSessionRunning = false
    var currentCIImage: CIImage?
    var error: String?

    // MARK: - Private

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.camera.session")

    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var audioDataOutput = AVCaptureAudioDataOutput()
    private(set) var photoOutput = AVCapturePhotoOutput()
    private var currentDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private(set) var currentDevice: AVCaptureDevice?
    private weak var boundState: CameraState?

    /// Tracks the physical orientation so captured photos match how the phone is held,
    /// even though the UI itself is locked to portrait. (iOS 17+)
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    private var discoveredLenses: [CaptureDeviceManager.DiscoveredLens] = []
    private var activeCaptureProcessor: PhotoCaptureProcessor?
    private let referenceTime: Double = CACurrentMediaTime()
    private var videoRecorder: VideoRecorder?
    private var isVideoRecordingRequested = false
    private var recordingFilter: CameraFilter = .clean
    private var recordingFilterIntensity: Float = 1.0
    private var recordingGrainData: GrainData = .none
    private var recordingClumpStrength: Float = 0
    private var recordingStartTime: CMTime?

    // Motion detection — skip grain when device is stationary
    private let motionManager = CMMotionManager()
    private var lastAcceleration: CMAcceleration?
    private var stationaryTicks: Int = 0

    // MARK: - Setup

    func configure(state: CameraState) {
        boundState = state
        sessionQueue.async { [weak self] in
            self?.setupSession(state: state)
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func setupSession(state: CameraState) {
        session.beginConfiguration()

        // Don't let the capture session grab the audio session just for previewing —
        // that would interrupt music. We configure audio ourselves only when video
        // recording starts (see startVideoRecording → configureCaptureAudioSession).
        session.automaticallyConfiguresApplicationAudioSession = false
        let initialPreset = state.captureMode == .video ? preferredVideoPreset() : .photo
        if session.canSetSessionPreset(initialPreset) {
            session.sessionPreset = initialPreset
        }

        // Discover lenses
        discoveredLenses = CaptureDeviceManager.discoverBackCameras()

        let lensInfos = discoveredLenses.map { lens in
            LensInfo(
                id: "\(lens.device.uniqueID)_\(lens.deviceZoomFactor)",
                displayName: lens.displayName,
                zoomFactor: lens.zoomFactor,
                deviceType: lens.device.deviceType.rawValue
            )
        }

        // Select initial device (prefer 1x wide)
        let initialLens = discoveredLenses.first(where: { $0.zoomFactor == 1.0 }) ?? discoveredLenses.first

        guard let lens = initialLens else {
            DispatchQueue.main.async {
                self.error = "No camera available"
            }
            session.commitConfiguration()
            return
        }

        // Add device input
        do {
            let input = try AVCaptureDeviceInput(device: lens.device)
            if session.canAddInput(input) {
                session.addInput(input)
                currentDeviceInput = input
                currentDevice = lens.device
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to create camera input: \(error.localizedDescription)"
            }
            session.commitConfiguration()
            return
        }

        // Add video data output for preview
        // Keep capture callbacks and recording state on one serial queue to avoid races.
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)

            configureVideoConnection(isFront: false)
        }

        // Add microphone input/output for video recording with sound.
        if let mic = AVCaptureDevice.default(for: .audio) {
            do {
                let input = try AVCaptureDeviceInput(device: mic)
                if session.canAddInput(input) {
                    session.addInput(input)
                    audioDeviceInput = input
                }
            } catch {
                print("Failed to create audio input: \(error.localizedDescription)")
            }
        }

        audioDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(audioDataOutput) {
            session.addOutput(audioDataOutput)
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        }

        // Disable HDR / computational photography so the base matches the live preview
        if let device = currentDevice {
            try? CaptureDeviceManager.configureDevice(device)
            updateRotationCoordinator(for: device)
        }

        session.commitConfiguration()

        // Update state on main thread
        DispatchQueue.main.async {
            state.availableLenses = lensInfos
            state.selectedLensIndex = self.discoveredLenses.firstIndex(where: { $0.zoomFactor == 1.0 }) ?? 0
            if let device = self.currentDevice {
                state.minISO = device.activeFormat.minISO
                state.maxISO = device.activeFormat.maxISO
                state.currentISO = device.iso
                state.minEV = device.minExposureTargetBias
                state.maxEV = device.maxExposureTargetBias
            }
        }

        // Start session
        session.startRunning()
        DispatchQueue.main.async {
            self.isSessionRunning = self.session.isRunning
        }

        // Start motion detection
        startMotionDetection(state: state)
    }
    // swiftlint:enable cyclomatic_complexity function_body_length

    // MARK: - Motion Detection

    private func startMotionDetection(state: CameraState) {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.5
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let accel = data?.acceleration else { return }
            if let last = self.lastAcceleration {
                let deltaX = accel.x - last.x
                let deltaY = accel.y - last.y
                let deltaZ = accel.z - last.z
                let delta = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
                if delta < 0.008 {
                    self.stationaryTicks += 1
                } else {
                    self.stationaryTicks = 0
                }
                // Stationary after ~2s of no movement
                state.isDeviceStationary = self.stationaryTicks >= 4
            }
            self.lastAcceleration = accel
        }
    }

    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Orientation

    /// Rebuilds the rotation coordinator for the active device. Must be called whenever
    /// the physical camera device changes (lens swap, front/back switch).
    private func updateRotationCoordinator(for device: AVCaptureDevice) {
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
    }

    // MARK: - Lens Switching

    func switchLens(to index: Int, state: CameraState) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard index < self.discoveredLenses.count else { return }

            let lens = self.discoveredLenses[index]
            let sameDevice = self.currentDevice?.uniqueID == lens.device.uniqueID

            if sameDevice {
                // Same physical device — just change videoZoomFactor (e.g. 1x ↔ 2x)
                try? lens.device.lockForConfiguration()
                lens.device.videoZoomFactor = lens.deviceZoomFactor
                lens.device.unlockForConfiguration()
            } else {
                // Different physical device — swap input
                self.session.beginConfiguration()

                if let currentInput = self.currentDeviceInput {
                    self.session.removeInput(currentInput)
                }

                do {
                    let input = try AVCaptureDeviceInput(device: lens.device)
                    if self.session.canAddInput(input) {
                        self.session.addInput(input)
                        self.currentDeviceInput = input
                        self.currentDevice = lens.device

                        try? CaptureDeviceManager.configureDevice(lens.device)
                        self.updateRotationCoordinator(for: lens.device)
                    }
                } catch {
                    print("Failed to switch lens: \(error)")
                }

                // Set zoom factor for the new device
                try? lens.device.lockForConfiguration()
                lens.device.videoZoomFactor = lens.deviceZoomFactor
                lens.device.unlockForConfiguration()

                // Update video orientation
                if let connection = self.videoDataOutput.connection(with: .video) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = false
                    }
                }

                self.session.commitConfiguration()
            }

            DispatchQueue.main.async {
                state.selectedLensIndex = index
                if let device = self.currentDevice {
                    state.minISO = device.activeFormat.minISO
                    state.maxISO = device.activeFormat.maxISO
                    state.currentISO = device.iso
                    state.minEV = device.minExposureTargetBias
                    state.maxEV = device.maxExposureTargetBias
                }
            }
        }
    }

    // MARK: - Front/Back Switch

    func switchToFrontCamera(state: CameraState) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let frontDevice = CaptureDeviceManager.frontCamera() else { return }

            self.session.beginConfiguration()

            if let currentInput = self.currentDeviceInput {
                self.session.removeInput(currentInput)
            }

            do {
                let input = try AVCaptureDeviceInput(device: frontDevice)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.currentDeviceInput = input
                    self.currentDevice = frontDevice
                    self.updateRotationCoordinator(for: frontDevice)
                }
            } catch {
                print("Failed to switch to front camera: \(error)")
            }

            self.updateVideoOrientation(isFront: true)
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                state.isFrontCamera = true
            }
        }
    }

    func switchToBackCamera(state: CameraState) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()

            if let currentInput = self.currentDeviceInput {
                self.session.removeInput(currentInput)
            }

            let lens = self.discoveredLenses.isEmpty ? nil :
                self.discoveredLenses[min(state.selectedLensIndex, self.discoveredLenses.count - 1)]

            guard let targetLens = lens else {
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: targetLens.device)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                    self.currentDeviceInput = input
                    self.currentDevice = targetLens.device
                    try? CaptureDeviceManager.configureDevice(targetLens.device)
                    self.updateRotationCoordinator(for: targetLens.device)
                }
            } catch {
                print("Failed to switch to back camera: \(error)")
            }

            self.updateVideoOrientation(isFront: false)
            self.session.commitConfiguration()

            DispatchQueue.main.async {
                state.isFrontCamera = false
            }
        }
    }

    // MARK: - Photo Capture

    func capturePhoto(state: CameraState, filter: CameraFilter) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Capture grain seed — use delta from reference for Float precision
            let grainSeed = Float(CACurrentMediaTime() - self.referenceTime)
            DispatchQueue.main.async {
                state.capturedGrainSeed = grainSeed
                state.isCapturing = true
            }

            // Match the photo connection to the physical orientation so a landscape-held
            // shot is saved as landscape (the UI itself stays locked to portrait).
            if let connection = self.photoOutput.connection(with: .video),
               let angle = self.rotationCoordinator?.videoRotationAngleForHorizonLevelCapture,
               connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }

            // Processed capture — ISP-rendered HEVC, same tone curve as the live preview.
            // Filter + grain are applied on top in PhotoCaptureProcessor.
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])

            settings.isHighResolutionPhotoEnabled = true

            let processor = PhotoCaptureProcessor(
                filter: filter,
                filterIntensity: state.filterIntensity,
                grainData: state.grainEnabled ? state.grainData : .none,
                grainSeed: grainSeed
            ) { [weak self] thumbnailData, captureError in
                DispatchQueue.main.async {
                    state.isCapturing = false
                    if let captureError {
                        self?.error = "Couldn't save photo"
                        print("Photo save failed: \(captureError.localizedDescription)")
                    } else {
                        state.lastCapturedImageData = thumbnailData
                    }
                }
                self?.activeCaptureProcessor = nil
            }

            self.activeCaptureProcessor = processor
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }

    // MARK: - Video Capture

    func startVideoRecording(state: CameraState, filter: CameraFilter) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isVideoRecordingRequested else { return }

            self.configureCaptureAudioSession()
            self.isVideoRecordingRequested = true
            self.recordingFilter = filter
            self.recordingFilterIntensity = state.filterIntensity
            self.configureRecordingGrain(for: filter, state: state)
            self.recordingStartTime = nil

            DispatchQueue.main.async {
                state.isRecording = true
            }
        }
    }

    func updateVideoRecordingFilter(state: CameraState, filter: CameraFilter) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isVideoRecordingRequested else { return }

            self.recordingFilter = filter
            self.recordingFilterIntensity = state.filterIntensity
            self.configureRecordingGrain(for: filter, state: state)
        }
    }

    func stopVideoRecording(state: CameraState) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isVideoRecordingRequested else { return }

            self.isVideoRecordingRequested = false
            self.recordingStartTime = nil
            self.recordingClumpStrength = 0

            guard let recorder = self.videoRecorder else {
                DispatchQueue.main.async {
                    state.isRecording = false
                }
                return
            }

            self.videoRecorder = nil
            let fallbackURL = recorder.outputURL
            recorder.finish { [self] outputURL, finishError in
                if let outputURL {
                    self.saveVideoToPhotoLibrary(outputURL)
                } else {
                    try? FileManager.default.removeItem(at: fallbackURL)
                    if let finishError {
                        DispatchQueue.main.async {
                            self.error = "Video recording failed"
                        }
                        print("Video finish error: \(finishError.localizedDescription)")
                    }
                }
                DispatchQueue.main.async {
                    state.isRecording = false
                }
            }
        }
    }

    private func processVideoFrame(_ image: CIImage, at time: CMTime) -> CIImage {
        var result = LiveFilterPipeline.apply(recordingFilter, to: image, intensity: recordingFilterIntensity)

        if recordingGrainData.isActive {
            let elapsed = Float(CMTimeGetSeconds(time))
            if let grained = try? MetalFilterLoader.shared.applyGrain(
                to: result,
                grainData: recordingGrainData,
                time: elapsed,
                clumpStrength: recordingClumpStrength
            ) {
                result = grained
            }
        }

        return result
    }

    private func configureRecordingGrain(for filter: CameraFilter, state: CameraState) {
        let base = state.grainEnabled ? state.grainData : .none
        let profiled = filter.profiledGrainData(from: base)
        recordingGrainData = videoOptimizedGrain(profiled)
        recordingClumpStrength = videoOptimizedClump(from: filter.grainClumpBoost)
    }

    /// Video compression hates aggressive grain; keep character, trim artifacts.
    private func videoOptimizedGrain(_ grain: GrainData) -> GrainData {
        guard grain.isActive else { return .none }
        var tuned = grain
        tuned.amount = min(56, grain.amount * 0.68)
        tuned.size = min(0.62, grain.size * 0.80)
        tuned.roughness = min(0.78, max(0.35, grain.roughness * 0.88))
        return tuned
    }

    private func videoOptimizedClump(from clump: Float) -> Float {
        min(0.24, clump * 0.42)
    }

    private func makeVideoRecorder(width: Int, height: Int) -> VideoRecorder? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("loopix-\(UUID().uuidString).mov")
        try? FileManager.default.removeItem(at: tempURL)

        let audioSettings = (audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov)
            as? [String: Any]) ?? [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48_000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 96_000
            ]

        do {
            return try VideoRecorder(
                outputURL: tempURL,
                width: width,
                height: height,
                audioSettings: audioSettings
            )
        } catch {
            print("Failed to create VideoRecorder: \(error.localizedDescription)")
            return nil
        }
    }

    private func saveVideoToPhotoLibrary(_ url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self?.error = "Photo Library access denied"
                }
                try? FileManager.default.removeItem(at: url)
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: { success, error in
                if let error {
                    print("Video save error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.error = "Failed to save video"
                    }
                } else if !success {
                    DispatchQueue.main.async {
                        self?.error = "Failed to save video"
                    }
                }
                try? FileManager.default.removeItem(at: url)
            })
        }
    }

    private func configureCaptureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            var targetMode: AVAudioSession.Mode = .videoRecording
            let voiceIsolationMode = AVAudioSession.Mode(rawValue: "AVAudioSessionModeVoiceIsolation")
            if session.availableModes.contains(voiceIsolationMode) {
                targetMode = voiceIsolationMode
            } else if session.availableModes.contains(.videoRecording) {
                targetMode = .videoRecording
            } else if session.availableModes.contains(.voiceChat) {
                targetMode = .voiceChat
            }

            try session.setCategory(
                .playAndRecord,
                mode: targetMode,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try session.setPreferredSampleRate(48_000)
            try session.setActive(true)
        } catch {
            print("Audio session config failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Camera Controls

    func setCaptureMode(_ mode: CaptureMode) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()
            let preset = mode == .video ? self.preferredVideoPreset() : .photo
            if self.session.canSetSessionPreset(preset) {
                self.session.sessionPreset = preset
            }
            self.configureVideoConnection(isFront: self.boundState?.isFrontCamera ?? false)
            self.session.commitConfiguration()
        }
    }

    func setISO(_ iso: Float) {
        guard let device = currentDevice else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let actualISO = try? CaptureDeviceManager.setISO(iso, on: device) {
                DispatchQueue.main.async {
                    self.boundState?.currentISO = actualISO
                }
            }
        }
    }

    func setAutoExposure() {
        guard let device = currentDevice else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            try? CaptureDeviceManager.setAutoExposure(on: device)
            let iso = device.iso
            DispatchQueue.main.async {
                self.boundState?.currentISO = iso
            }
        }
    }

    func setEVCompensation(_ exposureBias: Float) {
        guard let device = currentDevice else { return }
        sessionQueue.async {
            try? CaptureDeviceManager.setEVCompensation(exposureBias, on: device)
        }
    }

    func setFocusPoint(_ point: CGPoint, lock: Bool) {
        guard let device = currentDevice else { return }
        sessionQueue.async {
            try? CaptureDeviceManager.setFocusPoint(point, on: device, lock: lock)
        }
    }

    func setFocusLock(_ locked: Bool) {
        guard let device = currentDevice else { return }
        sessionQueue.async {
            try? CaptureDeviceManager.setFocusLock(locked, on: device)
        }
    }

    // MARK: - Video Connection

    /// Configures video data output connection for correct portrait orientation
    private func updateVideoOrientation(isFront: Bool = false) {
        configureVideoConnection(isFront: isFront)
    }

    private func preferredVideoPreset() -> AVCaptureSession.Preset {
        if session.canSetSessionPreset(.hd1920x1080) {
            return .hd1920x1080
        }
        if session.canSetSessionPreset(.hd1280x720) {
            return .hd1280x720
        }
        return .high
    }

    private func configureVideoConnection(isFront: Bool) {
        guard let connection = videoDataOutput.connection(with: .video) else { return }

        if connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = isFront
        }
    }

    // MARK: - Lifecycle

    func stop() {
        stopMotionDetection()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isVideoRecordingRequested = false
            self.recordingStartTime = nil
            self.recordingClumpStrength = 0
            if let recorder = self.videoRecorder {
                self.videoRecorder = nil
                let fallbackURL = recorder.outputURL
                recorder.finish { outputURL, _ in
                    let urlToRemove = outputURL ?? fallbackURL
                    try? FileManager.default.removeItem(at: urlToRemove)
                }
            }
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
}
// swiftlint:enable type_body_length

private final class VideoRecorder: @unchecked Sendable {
    private let writer: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let audioInput: AVAssetWriterInput?
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let ciContext: CIContext
    private let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()

    private let width: Int
    private let height: Int
    private(set) var outputURL: URL
    private var sessionStarted = false

    // swiftlint:disable:next function_body_length
    init(outputURL: URL, width: Int, height: Int, audioSettings: [String: Any]?) throws {
        self.outputURL = outputURL
        self.width = width
        self.height = height

        if let metalDevice = MTLCreateSystemDefaultDevice() {
            ciContext = CIContext(mtlDevice: metalDevice, options: [
                .cacheIntermediates: false,
                .priorityRequestLow: false
            ])
        } else {
            ciContext = CIContext(options: [.cacheIntermediates: false])
        }

        writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)

        let pixelCount = max(1, width * height)
        let targetBitRate = min(35_000_000, max(12_000_000, pixelCount * 10))
        let compression: [String: Any] = [
            AVVideoAverageBitRateKey: targetBitRate,
            AVVideoExpectedSourceFrameRateKey: 30,
            AVVideoMaxKeyFrameIntervalKey: 30,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
        ]
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: compression
        ]

        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true

        let audioWriterInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: audioSettings
        )
        audioWriterInput.expectsMediaDataInRealTime = true
        if writer.canAdd(audioWriterInput) {
            writer.add(audioWriterInput)
            audioInput = audioWriterInput
        } else {
            audioInput = nil
        }

        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: attrs
        )

        if writer.canAdd(videoInput) {
            writer.add(videoInput)
        } else {
            throw NSError(
                domain: "VideoRecorder",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to add writer input"]
            )
        }
    }

    func appendVideo(image: CIImage, at time: CMTime) {
        if !sessionStarted {
            guard writer.status == .unknown else { return }
            guard writer.startWriting() else { return }
            writer.startSession(atSourceTime: time)
            sessionStarted = true
        }

        guard videoInput.isReadyForMoreMediaData else { return }
        guard let pool = adaptor.pixelBufferPool else { return }

        var outBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &outBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer = outBuffer else { return }

        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        ciContext.render(image, to: pixelBuffer, bounds: bounds, colorSpace: colorSpace)
        _ = adaptor.append(pixelBuffer, withPresentationTime: time)
    }

    func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        guard let audioInput else { return }

        if !sessionStarted {
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            guard writer.status == .unknown else { return }
            guard writer.startWriting() else { return }
            writer.startSession(atSourceTime: time)
            sessionStarted = true
        }

        guard audioInput.isReadyForMoreMediaData else { return }
        _ = audioInput.append(sampleBuffer)
    }

    func finish(completion: @escaping @Sendable (URL?, Error?) -> Void) {
        guard sessionStarted else {
            let noFramesError = NSError(
                domain: "VideoRecorder",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No video frames were captured"]
            )
            completion(nil, noFramesError)
            return
        }

        videoInput.markAsFinished()
        audioInput?.markAsFinished()
        writer.finishWriting { [self] in
            if self.writer.status == .completed {
                completion(self.outputURL, nil)
            } else {
                completion(nil, self.writer.error)
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if output === audioDataOutput {
            handleAudioSampleBuffer(sampleBuffer)
            return
        }

        guard output === videoDataOutput else { return }
        handleVideoSampleBuffer(sampleBuffer)
    }

    private func handleVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        DispatchQueue.main.async {
            self.currentCIImage = ciImage
        }

        guard isVideoRecordingRequested else { return }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        if recordingStartTime == nil {
            recordingStartTime = presentationTime
        }
        let startTime = recordingStartTime ?? presentationTime
        let outputTime = CMTimeSubtract(presentationTime, startTime)

        if videoRecorder == nil {
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            videoRecorder = makeVideoRecorder(width: width, height: height)
            if videoRecorder == nil {
                isVideoRecordingRequested = false
                recordingStartTime = nil
                DispatchQueue.main.async {
                    self.error = "Failed to start video recording"
                    self.boundState?.isRecording = false
                }
                return
            }
        }

        let processedFrame = processVideoFrame(ciImage, at: outputTime)
        videoRecorder?.appendVideo(image: processedFrame, at: presentationTime)
    }

    private func handleAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard isVideoRecordingRequested else { return }
        guard let recorder = videoRecorder else { return }
        recorder.appendAudio(sampleBuffer)
    }
}
// swiftlint:enable file_length
