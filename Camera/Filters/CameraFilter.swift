import Foundation

struct CameraFilter: Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let tagline: String

    // Basic color
    let temperature: Float      // -100...+100
    let tint: Float             // -100...+100
    let saturation: Float       // -100...+100
    let contrast: Float         // -100...+100
    let exposure: Float         // -2...+2
    let isMonochrome: Bool
    let fade: Float             // 0...100 (lifts blacks)

    // Split tone — tint shadows and highlights independently
    let shadowHue: Float        // 0...360
    let shadowTintStrength: Float  // 0...1 (how much color to add to shadows)
    let highlightHue: Float     // 0...360
    let highlightTintStrength: Float // 0...1 (how much color to add to highlights)

    // Per-stock film clamp (global-safe defaults)
    var blackFloor: Float = 0.04
    var whiteCeiling: Float = 0.955

    // Per-channel RGBA tone curves
    var curves: RGBACurves = .identity

    static let clean = CameraFilter(
        id: "clean", name: "Neutral", shortName: "NTR",
        tagline: "Plain optical image",
        temperature: 0, tint: 0, saturation: 0, contrast: 0,
        exposure: 0, isMonochrome: false, fade: 0,
        shadowHue: 0, shadowTintStrength: 0,
        highlightHue: 0, highlightTintStrength: 0,
        blackFloor: 0.04, whiteCeiling: 0.955
    )

    /// Whether split tone is active
    var hasSplitTone: Bool {
        shadowTintStrength > 0 || highlightTintStrength > 0
    }

    // swiftlint:disable large_tuple
    private var grainSignature: (amount: Float, size: Float, roughness: Float, clump: Float, monochrome: Bool?) {
        switch id {
        // B&W stocks
        case "tmax3200": return (1.52, 1.14, 1.32, 0.62, true)
        case "trix": return (1.28, 1.14, 1.20, 0.78, true)
        case "hp5": return (1.12, 1.02, 1.08, 0.58, true)
        case "delta": return (0.82, 0.78, 0.76, 0.24, true)
        case "panf": return (0.66, 0.62, 0.64, 0.16, true)
        case "bw400cn": return (0.98, 0.96, 0.88, 0.44, true)
        case "mono": return (1.32, 1.08, 1.20, 0.46, true)   // HIE Infra
        case "retro": return (1.08, 1.15, 0.92, 0.36, true)

        // Color stocks
        case "portra": return (0.62, 0.68, 0.66, 0.18, false)
        case "400h": return (0.64, 0.70, 0.68, 0.20, false)
        case "ektar": return (0.74, 0.72, 0.74, 0.26, false)
        case "velvia": return (0.84, 0.84, 0.80, 0.30, false)
        case "provia": return (0.70, 0.76, 0.72, 0.24, false)
        case "superia": return (0.90, 0.98, 0.92, 0.34, false)
        case "classicc": return (0.72, 0.82, 0.76, 0.24, false)
        case "kodachrome": return (0.69, 0.74, 0.74, 0.23, false)
        case "ultra": return (1.00, 1.03, 1.05, 0.40, false)
        case "emulsion": return (0.92, 0.97, 0.98, 0.32, false)
        case "dew": return (0.82, 0.90, 0.84, 0.26, false)
        case "uvwarm": return (1.10, 1.18, 1.02, 0.42, false)
        case "expiredcold": return (1.26, 1.22, 1.12, 0.48, false)
        case "redscale": return (1.20, 1.16, 1.08, 0.50, false)
        case "xpro100": return (1.12, 1.08, 1.08, 0.47, false)

        default: return (1.00, 1.00, 1.00, 0.12, nil)
        }
    }
    // swiftlint:enable large_tuple

    /// Applies per-film grain tuning while preserving global user grain intent.
    func profiledGrainData(from base: GrainData) -> GrainData {
        let signature = grainSignature
        var result = base
        result.amount = max(0, min(100, base.amount * signature.amount))
        result.size = max(0, min(1, base.size * signature.size))
        result.roughness = max(0, min(1, base.roughness * signature.roughness))
        if let monochrome = signature.monochrome {
            result.monochromatic = monochrome
        }
        return result
    }

    /// How strongly grain crystals should clump (Worley mask), tuned per stock.
    /// High-ISO films get stronger clumping for a more cinematic texture.
    var grainClumpBoost: Float {
        grainSignature.clump
    }

    // swiftlint:disable identifier_name large_tuple
    /// Convert hue (0-360) to normalized RGB at given strength
    static func hueToRGB(hue: Float, strength: Float) -> (r: Float, g: Float, b: Float) {
        guard strength > 0 else { return (0, 0, 0) }
        let h = hue / 60.0
        let x = 1 - abs(h.truncatingRemainder(dividingBy: 2) - 1)
        let (r0, g0, b0): (Float, Float, Float)
        switch Int(h) % 6 {
        case 0: (r0, g0, b0) = (1, x, 0)
        case 1: (r0, g0, b0) = (x, 1, 0)
        case 2: (r0, g0, b0) = (0, 1, x)
        case 3: (r0, g0, b0) = (0, x, 1)
        case 4: (r0, g0, b0) = (x, 0, 1)
        case 5: (r0, g0, b0) = (1, 0, x)
        default: (r0, g0, b0) = (0, 0, 0)
        }
        return (r0 * strength, g0 * strength, b0 * strength)
    }
    // swiftlint:enable identifier_name large_tuple
}
