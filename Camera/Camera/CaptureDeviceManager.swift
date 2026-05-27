import AVFoundation

/// Discovers and manages individual camera devices (not multi-cam composites)
/// to avoid iOS computational photography (HDR, Deep Fusion, etc.)
final class CaptureDeviceManager {

    struct DiscoveredLens {
        let device: AVCaptureDevice
        let displayName: String
        let zoomFactor: CGFloat
        /// videoZoomFactor to apply on the device (1.0 for native, 2.0 for 2x crop)
        let deviceZoomFactor: CGFloat
    }

    /// Discovers all individual back cameras on the device
    static func discoverBackCameras() -> [DiscoveredLens] {
        var lenses: [DiscoveredLens] = []

        // Wide angle (main) — 1x
        let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        if let wide {
            lenses.append(DiscoveredLens(device: wide, displayName: "1x", zoomFactor: 1.0, deviceZoomFactor: 1.0))
        }

        // Telephoto — detect actual magnification from FOV ratio
        let tele = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back)
        var teleFactor: Int = 0

        if let tele, let wide {
            let wideFOV = Double(wide.activeFormat.videoFieldOfView)
            let teleFOV = Double(tele.activeFormat.videoFieldOfView)
            let rawFactor = wideFOV / teleFOV
            // Snap to nearest known Apple telephoto factor — no 4x cameras exist
            let knownFactors: [Double] = [2, 3, 5]
            teleFactor = Int(knownFactors.min(by: { abs($0 - rawFactor) < abs($1 - rawFactor) }) ?? rawFactor.rounded())
        }

        if teleFactor == 2, let tele {
            // 2x telephoto (e.g. iPhone 11 Pro) — use physical lens, better quality than crop
            lenses.append(DiscoveredLens(device: tele, displayName: "2x", zoomFactor: 2.0, deviceZoomFactor: 1.0))
        } else {
            // No 2x telephoto — use center crop of wide sensor (48MP → 12MP on newer devices)
            if let wide, wide.activeFormat.videoMaxZoomFactor >= 2.0 {
                lenses.append(DiscoveredLens(device: wide, displayName: "2x", zoomFactor: 2.0, deviceZoomFactor: 2.0))
            }
            // Add telephoto if >2x (5x, 8x, 10x etc.)
            if teleFactor > 2, let tele {
                lenses.append(
                    DiscoveredLens(
                        device: tele,
                        displayName: "\(teleFactor)x",
                        zoomFactor: CGFloat(teleFactor),
                        deviceZoomFactor: 1.0
                    )
                )
            }
        }

        return lenses
    }

    /// Gets the front-facing camera
    static func frontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }

    /// Configures device to disable all iOS computational photography
    static func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // Disable HDR
        if device.automaticallyAdjustsVideoHDREnabled {
            device.automaticallyAdjustsVideoHDREnabled = false
        }
        device.isVideoHDREnabled = false

        // Set continuous auto-exposure and auto-focus as defaults
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
    }

    /// Sets ISO on the device, returns the actual clamped value set
    @discardableResult
    static func setISO(_ iso: Float, on device: AVCaptureDevice) throws -> Float {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        let clampedISO = max(device.activeFormat.minISO, min(iso, device.activeFormat.maxISO))
        device.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: clampedISO)
        return clampedISO
    }

    /// Returns to auto exposure
    static func setAutoExposure(on device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        device.exposureMode = .continuousAutoExposure
    }

    /// Sets EV compensation on the device
    static func setEVCompensation(_ exposureBias: Float, on device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        let clampedEV = max(device.minExposureTargetBias, min(exposureBias, device.maxExposureTargetBias))
        device.setExposureTargetBias(clampedEV)
    }

    /// Sets focus point
    static func setFocusPoint(_ point: CGPoint, on device: AVCaptureDevice, lock: Bool) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        if device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = point
            device.focusMode = lock ? .autoFocus : .continuousAutoFocus
        }

        if device.isExposurePointOfInterestSupported {
            device.exposurePointOfInterest = point
            device.exposureMode = lock ? .autoExpose : .continuousAutoExposure
        }
    }

    /// Locks or unlocks focus
    static func setFocusLock(_ locked: Bool, on device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        if locked {
            if device.isFocusModeSupported(.locked) {
                device.focusMode = .locked
            }
            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            }
        } else {
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
        }
    }
}
