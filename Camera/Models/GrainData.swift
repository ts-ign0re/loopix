import Foundation

struct GrainData: Codable, Hashable, Sendable {
    var amount: Float = 0       // 0...100
    var size: Float = 0.5       // 0...1 (small to large)
    var roughness: Float = 0.5  // 0...1
    var monochromatic: Bool = true

    static let none = GrainData()

    var isActive: Bool {
        amount > 0
    }

    /// Default grain settings — fat analog film grain
    static let defaultCamera = GrainData(
        amount: 58,
        size: 0.72,
        roughness: 0.65,
        monochromatic: true
    )

    // MARK: - Metal Parameter Mapping

    /// Maps UI size (0...1, small→large) to Metal size parameter (0.5...4.0)
    var metalSize: Float {
        0.5 + size * 3.5
    }

    /// Maps UI amount (0...100) to Metal amount parameter with film-like response curve
    var metalAmount: Float {
        let normalized = max(0, min(amount / 100.0, 1.0))
        return Float(pow(Double(normalized), 0.82)) * 0.70
    }
}
