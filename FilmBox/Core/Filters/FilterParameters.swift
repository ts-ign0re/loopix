import Foundation
import CoreGraphics

// MARK: - Constants

/// Epsilon for float comparisons throughout filter processing
/// Used for determining if values are effectively zero or equal
let kFilterEpsilon: Float = 0.0001

// MARK: - Main Filter Parameters

/// All adjustable parameters for a filter preset
struct FilterParameters: Codable, Hashable, Sendable {
    // === LIGHT ===
    var exposure: Float = 0         // -2...+2 EV
    var contrast: Float = 0         // -100...+100
    var highlights: Float = 0       // -100...+100
    var shadows: Float = 0          // -100...+100
    var whites: Float = 0           // -100...+100
    var blacks: Float = 0           // -100...+100

    // === TONE CURVE ===
    var toneCurve: ToneCurveData = .identity

    // === COLOR ===
    var temperature: Float = 0      // -100...+100 (Kelvin shift)
    var tint: Float = 0             // -100...+100 (Green-Magenta)
    var saturation: Float = 0       // -100...+100
    var vibrance: Float = 0         // -100...+100

    // === HSL (8 channels) ===
    var hsl: HSLAdjustments = .identity

    // === SPLIT TONE ===
    var splitTone: SplitToneData = .identity

    // === SKIN TONE ===
    var skinToneHue: Float = 0      // -100...+100
    var skinToneSaturation: Float = 0

    // === EFFECTS ===
    var clarity: Float = 0          // -100...+100
    var grain: GrainData = .none
    var vignette: VignetteData = .none
    var fade: Float = 0             // 0...100
    var bloom: BloomData = .none
    var halation: HalationData = .none

    // === FUJI SIMULATION ===
    var filmSimulation: FilmSimulationType = .none
    var colorChrome: ColorChromeData = .none
    var whiteBalanceShift: WhiteBalanceShift = .identity
    var dynamicRange: DynamicRangeMode = .dr100

    // === SHARPENING ===
    var sharpness: Float = 0        // 0...100
    var sharpenRadius: Float = 1.0  // 0.5...3.0

    // === TRANSFORM (not part of color processing) ===
    var rotation: Float = 0         // degrees (0, 90, 180, 270)
    var flipHorizontal: Bool = false
    var flipVertical: Bool = false
    var cropRect: CGRect?

    static let identity = FilterParameters()

    /// Check if parameters differ from identity (any adjustments applied)
    var hasAdjustments: Bool {
        self != .identity
    }
}

// MARK: - Tone Curve

struct ToneCurveData: Codable, Hashable, Sendable {
    var composite: [CurvePoint]
    var red: [CurvePoint]
    var green: [CurvePoint]
    var blue: [CurvePoint]

    struct CurvePoint: Codable, Hashable, Sendable {
        var x: Float  // 0...1 input
        var y: Float  // 0...1 output

        static func == (lhs: CurvePoint, rhs: CurvePoint) -> Bool {
            abs(lhs.x - rhs.x) < kFilterEpsilon && abs(lhs.y - rhs.y) < kFilterEpsilon
        }
    }

    static let identity = ToneCurveData(
        composite: [
            .init(x: 0, y: 0),
            .init(x: 0.25, y: 0.25),
            .init(x: 0.5, y: 0.5),
            .init(x: 0.75, y: 0.75),
            .init(x: 1, y: 1)
        ],
        red: [],
        green: [],
        blue: []
    )

    /// Check if the curve is identity (no adjustments)
    var isIdentity: Bool {
        self == .identity
    }

    /// Interpolate Y value for a given X using cubic spline
    func interpolateComposite(at x: Float) -> Float {
        interpolate(points: composite, at: x)
    }

    func interpolateRed(at x: Float) -> Float {
        red.isEmpty ? x : interpolate(points: red, at: x)
    }

    func interpolateGreen(at x: Float) -> Float {
        green.isEmpty ? x : interpolate(points: green, at: x)
    }

    func interpolateBlue(at x: Float) -> Float {
        blue.isEmpty ? x : interpolate(points: blue, at: x)
    }

    private func interpolate(points: [CurvePoint], at x: Float) -> Float {
        guard !points.isEmpty else { return x }
        guard points.count >= 2 else { return points[0].y }

        // Find surrounding points
        var lowerIndex = 0
        for (index, point) in points.enumerated() {
            if point.x <= x {
                lowerIndex = index
            } else {
                break
            }
        }

        let upperIndex = min(lowerIndex + 1, points.count - 1)

        if lowerIndex == upperIndex {
            return points[lowerIndex].y
        }

        let lower = points[lowerIndex]
        let upper = points[upperIndex]

        // Linear interpolation (can be upgraded to cubic spline)
        let t = (x - lower.x) / (upper.x - lower.x)
        return lower.y + t * (upper.y - lower.y)
    }
}

// MARK: - HSL Adjustments

struct HSLAdjustments: Codable, Hashable, Sendable {
    var red: HSLChannel = .identity
    var orange: HSLChannel = .identity
    var yellow: HSLChannel = .identity
    var green: HSLChannel = .identity
    var aqua: HSLChannel = .identity
    var blue: HSLChannel = .identity
    var purple: HSLChannel = .identity
    var magenta: HSLChannel = .identity

    struct HSLChannel: Codable, Hashable, Sendable {
        var hue: Float = 0        // -180...+180
        var saturation: Float = 0 // -100...+100
        var luminance: Float = 0  // -100...+100

        static let identity = HSLChannel()

        var isIdentity: Bool {
            hue == 0 && saturation == 0 && luminance == 0
        }
    }

    static let identity = HSLAdjustments()

    var isIdentity: Bool {
        red.isIdentity && orange.isIdentity && yellow.isIdentity &&
        green.isIdentity && aqua.isIdentity && blue.isIdentity &&
        purple.isIdentity && magenta.isIdentity
    }

    /// Get channel by index (0-7)
    subscript(index: Int) -> HSLChannel {
        get {
            switch index {
            case 0: return red
            case 1: return orange
            case 2: return yellow
            case 3: return green
            case 4: return aqua
            case 5: return blue
            case 6: return purple
            case 7: return magenta
            default: return .identity
            }
        }
        set {
            switch index {
            case 0: red = newValue
            case 1: orange = newValue
            case 2: yellow = newValue
            case 3: green = newValue
            case 4: aqua = newValue
            case 5: blue = newValue
            case 6: purple = newValue
            case 7: magenta = newValue
            default: break
            }
        }
    }

    static let channelNames = ["Red", "Orange", "Yellow", "Green", "Aqua", "Blue", "Purple", "Magenta"]
    static let channelColors: [(Float, Float, Float)] = [
        (1.0, 0.0, 0.0),    // Red
        (1.0, 0.5, 0.0),    // Orange
        (1.0, 1.0, 0.0),    // Yellow
        (0.0, 1.0, 0.0),    // Green
        (0.0, 1.0, 1.0),    // Aqua
        (0.0, 0.0, 1.0),    // Blue
        (0.5, 0.0, 1.0),    // Purple
        (1.0, 0.0, 1.0)     // Magenta
    ]
}

// MARK: - Split Tone

struct SplitToneData: Codable, Hashable, Sendable {
    var highlightHue: Float = 0       // 0...360
    var highlightSaturation: Float = 0 // 0...100
    var shadowHue: Float = 0          // 0...360
    var shadowSaturation: Float = 0   // 0...100
    var balance: Float = 0            // -100...+100 (negative = more shadow, positive = more highlight)

    static let identity = SplitToneData()

    var isIdentity: Bool {
        highlightSaturation == 0 && shadowSaturation == 0
    }
}

// MARK: - Grain

struct GrainData: Codable, Hashable, Sendable {
    var amount: Float = 0       // 0...100
    var size: Float = 0.5       // 0...1 (small to large)
    var roughness: Float = 0.5  // 0...1
    var monochromatic: Bool = true

    static let none = GrainData()

    var isActive: Bool {
        amount > 0
    }
}

// MARK: - Vignette

struct VignetteData: Codable, Hashable, Sendable {
    var amount: Float = 0       // -100...+100 (negative = brighten edges)
    var midpoint: Float = 0.5   // 0...1
    var roundness: Float = 0    // -100...+100
    var feather: Float = 0.5    // 0...1

    static let none = VignetteData()

    var isActive: Bool {
        amount != 0
    }
}

// MARK: - Bloom

struct BloomData: Codable, Hashable, Sendable {
    var intensity: Float = 0    // 0...100
    var radius: Float = 0.5     // 0...1
    var threshold: Float = 0.8  // 0...1 (brightness threshold)

    static let none = BloomData()

    var isActive: Bool {
        intensity > 0
    }
}

// MARK: - Halation

struct HalationData: Codable, Hashable, Sendable {
    var intensity: Float = 0    // 0...100
    var hue: Float = 0          // 0...360 (typically red ~0-30)
    var spread: Float = 0.5     // 0...1

    static let none = HalationData()

    var isActive: Bool {
        intensity > 0
    }
}

// MARK: - Film Simulation (Fuji-style)

/// Fuji film simulation types
enum FilmSimulationType: String, Codable, CaseIterable, Sendable {
    case none = "None"
    case classicNegative = "Classic Negative"
    case classicChrome = "Classic Chrome"
    case provia = "Provia"
    case velvia = "Velvia"
    case astia = "Astia"
    case acros = "Acros"
    case eterna = "Eterna"
    case eternaBleachBypass = "Eterna Bleach Bypass"
    case nostalgicNeg = "Nostalgic Neg"
    case reala = "Reala Ace"

    var displayName: String { rawValue }
}

// MARK: - Color Chrome

/// Color Chrome effect data (Fuji-style deep color enhancement)
struct ColorChromeData: Codable, Hashable, Sendable {
    var effect: ColorChromeLevel = .off
    var fxBlue: ColorChromeLevel = .off

    enum ColorChromeLevel: String, Codable, CaseIterable, Sendable {
        case off = "Off"
        case weak = "Weak"
        case strong = "Strong"

        var intensity: Float {
            switch self {
            case .off: return 0
            case .weak: return 0.5
            case .strong: return 1.0
            }
        }
    }

    static let none = ColorChromeData()

    var isActive: Bool {
        effect != .off || fxBlue != .off
    }
}

// MARK: - White Balance Shift

/// White balance R/B shift (Fuji-style fine tuning)
struct WhiteBalanceShift: Codable, Hashable, Sendable {
    var redShift: Int = 0     // -9...+9
    var blueShift: Int = 0    // -9...+9

    static let identity = WhiteBalanceShift()

    var isActive: Bool {
        redShift != 0 || blueShift != 0
    }
}

// MARK: - Dynamic Range

/// Dynamic range mode (Fuji-style highlight recovery)
enum DynamicRangeMode: String, Codable, CaseIterable, Sendable {
    case dr100 = "DR100"
    case dr200 = "DR200"
    case dr400 = "DR400"
    case auto = "DR Auto"

    /// How much to compress highlights (0 = none, 1 = maximum)
    var highlightCompression: Float {
        switch self {
        case .dr100: return 0
        case .dr200: return 0.33
        case .dr400: return 0.66
        case .auto: return 0.5
        }
    }
}

// MARK: - Parameter Ranges

extension FilterParameters {
    enum ParameterRange {
        case exposure
        case contrast
        case highlights
        case shadows
        case whites
        case blacks
        case temperature
        case tint
        case saturation
        case vibrance
        case clarity
        case sharpness
        case sharpenRadius
        case fade
        case grainAmount
        case grainSize
        case grainRoughness
        case vignetteAmount
        case vignetteMidpoint
        case vignetteRoundness
        case vignetteFeather
        case bloomIntensity
        case bloomRadius
        case bloomThreshold
        case halationIntensity
        case halationHue
        case halationSpread
        case hslHue
        case hslSaturation
        case hslLuminance
        case splitToneHue
        case splitToneSaturation
        case splitToneBalance
        case skinToneHue
        case skinToneSaturation

        var range: ClosedRange<Float> {
            switch self {
            case .exposure: return -2...2
            case .contrast, .highlights, .shadows, .whites, .blacks: return -100...100
            case .temperature, .tint: return -100...100
            case .saturation, .vibrance: return -100...100
            case .clarity: return -100...100
            case .sharpness: return 0...100
            case .sharpenRadius: return 0.5...3.0
            case .fade: return 0...100
            case .grainAmount: return 0...100
            case .grainSize, .grainRoughness: return 0...1
            case .vignetteAmount: return -100...100
            case .vignetteMidpoint, .vignetteFeather: return 0...1
            case .vignetteRoundness: return -100...100
            case .bloomIntensity: return 0...100
            case .bloomRadius: return 0...1
            case .bloomThreshold: return 0...1
            case .halationIntensity: return 0...100
            case .halationHue: return 0...360
            case .halationSpread: return 0...1
            case .hslHue: return -180...180
            case .hslSaturation, .hslLuminance: return -100...100
            case .splitToneHue: return 0...360
            case .splitToneSaturation: return 0...100
            case .splitToneBalance: return -100...100
            case .skinToneHue, .skinToneSaturation: return -100...100
            }
        }

        var defaultValue: Float {
            switch self {
            case .sharpenRadius: return 1.0
            case .grainSize, .grainRoughness: return 0.5
            case .vignetteMidpoint, .vignetteFeather: return 0.5
            case .bloomRadius: return 0.5
            case .bloomThreshold: return 0.8
            case .halationSpread: return 0.5
            default: return 0
            }
        }
    }
}
