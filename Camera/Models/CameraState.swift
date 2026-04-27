import Foundation

enum CaptureMode: String, CaseIterable, Sendable {
    case photo
    case video
}

@Observable
final class CameraState: @unchecked Sendable {
    // Camera settings
    var currentISO: Float = 100
    var minISO: Float = 50
    var maxISO: Float = 1600
    var isAutoISO: Bool = true

    var evCompensation: Float = 0
    var minEV: Float = -3.0
    var maxEV: Float = 3.0

    var isFocusLocked: Bool = false
    var isExposureLocked: Bool = false
    var focusPoint: CGPoint?

    // Lens
    var selectedLensIndex: Int = 0
    var availableLenses: [LensInfo] = []

    // Grain
    var grainData: GrainData = .defaultCamera
    var grainEnabled: Bool = true

    // Filter — restored from last session, defaults to Neutral
    var selectedFilterIndex: Int = {
        let saved = UserDefaults.standard.object(forKey: "selectedFilterIndex") as? Int
        if let saved, saved >= 0, saved < BuiltInFilters.all.count { return saved }
        return BuiltInFilters.neutralIndex
    }()

    /// Per-filter intensity: filter.id → 0.0...1.0, default 1.0
    var filterIntensityMap: [String: Float] = {
        (UserDefaults.standard.dictionary(forKey: "filterIntensityMap") as? [String: Float]) ?? [:]
    }()

    /// Current intensity for the active filter
    var filterIntensity: Float {
        get {
            let id = BuiltInFilters.all[selectedFilterIndex].id
            return filterIntensityMap[id] ?? 1.0
        }
        set {
            let id = BuiltInFilters.all[selectedFilterIndex].id
            filterIntensityMap[id] = newValue
            UserDefaults.standard.set(filterIntensityMap, forKey: "filterIntensityMap")
        }
    }

    // Capture mode
    var captureMode: CaptureMode = {
        let raw = UserDefaults.standard.string(forKey: "captureMode")
        return CaptureMode(rawValue: raw ?? "") ?? .photo
    }()

    // UI state
    var isRightHanded: Bool = UserDefaults.standard.object(forKey: "isRightHanded") as? Bool ?? true
    var showGrid: Bool = false
    var isCapturing: Bool = false
    var isRecording: Bool = false
    var lastCapturedImageData: Data?
    var isFrontCamera: Bool = false

    // Motion — skip grain when device is still
    var isDeviceStationary: Bool = false

    // Captured grain seed — frozen at shutter press
    var capturedGrainSeed: Float = 0
}

struct LensInfo: Identifiable, Hashable {
    let id: String
    let displayName: String
    let zoomFactor: CGFloat
    let deviceType: String

    static func == (lhs: LensInfo, rhs: LensInfo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
