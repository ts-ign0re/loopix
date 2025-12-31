import XCTest
@testable import FilmBox

/// Tests for FilterParameters data model
final class FilterParametersTests: XCTestCase {

    // MARK: - Identity Tests

    /// Test: Identity parameters have all default values
    func testIdentityParameters() {
        let params = FilterParameters.identity

        // Light
        XCTAssertEqual(params.exposure, 0)
        XCTAssertEqual(params.contrast, 0)
        XCTAssertEqual(params.highlights, 0)
        XCTAssertEqual(params.shadows, 0)
        XCTAssertEqual(params.whites, 0)
        XCTAssertEqual(params.blacks, 0)

        // Color
        XCTAssertEqual(params.temperature, 0)
        XCTAssertEqual(params.tint, 0)
        XCTAssertEqual(params.saturation, 0)
        XCTAssertEqual(params.vibrance, 0)

        // Effects
        XCTAssertEqual(params.clarity, 0)
        XCTAssertEqual(params.fade, 0)
        XCTAssertEqual(params.sharpness, 0)
        XCTAssertEqual(params.sharpenRadius, 1.0)

        // Transform
        XCTAssertEqual(params.rotation, 0)
        XCTAssertNil(params.cropRect)
    }

    /// Test: Identity has no adjustments
    func testIdentityHasNoAdjustments() {
        let identity = FilterParameters.identity
        XCTAssertFalse(identity.hasAdjustments, "Identity should not have adjustments")
    }

    /// Test: Modified parameters have adjustments
    func testModifiedParametersHaveAdjustments() {
        var params = FilterParameters.identity
        params.exposure = 0.5

        XCTAssertTrue(params.hasAdjustments, "Modified parameters should have adjustments")
    }

    // MARK: - Codable Tests

    /// Test: FilterParameters encode/decode round trip
    func testCodableRoundTrip() throws {
        var original = FilterParameters()
        original.exposure = 1.5
        original.contrast = 25
        original.temperature = -30
        original.saturation = 15
        original.grain.amount = 20
        original.vignette.amount = -50

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterParameters.self, from: data)

        XCTAssertEqual(original, decoded, "Decoded parameters should match original")
    }

    /// Test: Complex parameters encode/decode
    func testComplexParametersCodable() throws {
        var params = FilterParameters()
        params.exposure = 0.7
        params.contrast = 10
        params.highlights = -20
        params.shadows = 30
        params.temperature = 15
        params.saturation = 5

        params.toneCurve = ToneCurveData(
            composite: [
                .init(x: 0, y: 0.1),
                .init(x: 0.25, y: 0.2),
                .init(x: 0.5, y: 0.5),
                .init(x: 0.75, y: 0.8),
                .init(x: 1, y: 0.95)
            ],
            red: [],
            green: [],
            blue: []
        )

        params.hsl.red.hue = 10
        params.hsl.red.saturation = 20
        params.hsl.blue.luminance = -15

        params.grain = GrainData(amount: 25, size: 0.6, roughness: 0.4, monochromatic: false)
        params.vignette = VignetteData(amount: 40, midpoint: 0.6, roundness: 10, feather: 0.7)

        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(FilterParameters.self, from: data)

        XCTAssertEqual(params.exposure, decoded.exposure)
        XCTAssertEqual(params.contrast, decoded.contrast)
        XCTAssertEqual(params.grain.amount, decoded.grain.amount)
        XCTAssertEqual(params.vignette.amount, decoded.vignette.amount)
        XCTAssertEqual(params.hsl.red.hue, decoded.hsl.red.hue)
    }

    // MARK: - Interpolation Tests

    /// Test: Interpolation at t=0 returns first parameter
    func testInterpolationAtZero() {
        var a = FilterParameters.identity
        a.exposure = 0

        var b = FilterParameters()
        b.exposure = 2.0

        let result = FilterParameters.interpolate(from: a, to: b, t: 0)

        XCTAssertEqual(result.exposure, 0, accuracy: 0.001)
    }

    /// Test: Interpolation at t=1 returns second parameter
    func testInterpolationAtOne() {
        var a = FilterParameters.identity
        a.exposure = 0

        var b = FilterParameters()
        b.exposure = 2.0

        let result = FilterParameters.interpolate(from: a, to: b, t: 1.0)

        XCTAssertEqual(result.exposure, 2.0, accuracy: 0.001)
    }

    /// Test: Interpolation at t=0.5 returns midpoint
    func testInterpolationAtHalf() {
        var a = FilterParameters()
        a.exposure = 0
        a.contrast = 0
        a.saturation = -50

        var b = FilterParameters()
        b.exposure = 2.0
        b.contrast = 100
        b.saturation = 50

        let result = FilterParameters.interpolate(from: a, to: b, t: 0.5)

        XCTAssertEqual(result.exposure, 1.0, accuracy: 0.001)
        XCTAssertEqual(result.contrast, 50, accuracy: 0.001)
        XCTAssertEqual(result.saturation, 0, accuracy: 0.001)
    }

    /// Test: Grain interpolation
    func testGrainInterpolation() {
        var a = FilterParameters()
        a.grain = GrainData(amount: 0, size: 0.2, roughness: 0.3, monochromatic: true)

        var b = FilterParameters()
        b.grain = GrainData(amount: 100, size: 0.8, roughness: 0.9, monochromatic: false)

        let result = FilterParameters.interpolate(from: a, to: b, t: 0.5)

        XCTAssertEqual(result.grain.amount, 50, accuracy: 0.001)
        XCTAssertEqual(result.grain.size, 0.5, accuracy: 0.001)
        XCTAssertEqual(result.grain.roughness, 0.6, accuracy: 0.001)
    }

    /// Test: HSL interpolation
    func testHSLInterpolation() {
        var a = FilterParameters()
        a.hsl.red = HSLAdjustments.HSLChannel(hue: 0, saturation: 0, luminance: 0)

        var b = FilterParameters()
        b.hsl.red = HSLAdjustments.HSLChannel(hue: 30, saturation: 50, luminance: -20)

        let result = FilterParameters.interpolate(from: a, to: b, t: 0.5)

        XCTAssertEqual(result.hsl.red.hue, 15, accuracy: 0.001)
        XCTAssertEqual(result.hsl.red.saturation, 25, accuracy: 0.001)
        XCTAssertEqual(result.hsl.red.luminance, -10, accuracy: 0.001)
    }

    // MARK: - Parameter Range Tests

    /// Test: Exposure range is correct
    func testExposureRange() {
        let range = FilterParameters.ParameterRange.exposure.range
        XCTAssertEqual(range.lowerBound, -2)
        XCTAssertEqual(range.upperBound, 2)
    }

    /// Test: Contrast range is correct
    func testContrastRange() {
        let range = FilterParameters.ParameterRange.contrast.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    /// Test: Sharpness range is correct
    func testSharpnessRange() {
        let range = FilterParameters.ParameterRange.sharpness.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 100)
    }

    /// Test: Halation hue range is correct
    func testHalationHueRange() {
        let range = FilterParameters.ParameterRange.halationHue.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 360)
    }

    /// Test: Default values are correct
    func testDefaultValues() {
        XCTAssertEqual(FilterParameters.ParameterRange.sharpenRadius.defaultValue, 1.0)
        XCTAssertEqual(FilterParameters.ParameterRange.grainSize.defaultValue, 0.5)
        XCTAssertEqual(FilterParameters.ParameterRange.bloomThreshold.defaultValue, 0.8)
        XCTAssertEqual(FilterParameters.ParameterRange.exposure.defaultValue, 0)
    }

    // MARK: - Hashable Tests

    /// Test: Equal parameters have same hash
    func testEqualParametersHaveSameHash() {
        var a = FilterParameters()
        a.exposure = 1.0
        a.contrast = 50

        var b = FilterParameters()
        b.exposure = 1.0
        b.contrast = 50

        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    /// Test: Different parameters have different hash
    func testDifferentParametersHaveDifferentHash() {
        var a = FilterParameters()
        a.exposure = 1.0

        var b = FilterParameters()
        b.exposure = 1.5

        XCTAssertNotEqual(a.hashValue, b.hashValue)
    }
}

// MARK: - Tone Curve Tests

final class ToneCurveDataTests: XCTestCase {

    /// Test: Identity curve returns same value
    func testIdentityCurve() {
        let curve = ToneCurveData.identity

        XCTAssertEqual(curve.interpolateComposite(at: 0), 0, accuracy: 0.01)
        XCTAssertEqual(curve.interpolateComposite(at: 0.25), 0.25, accuracy: 0.01)
        XCTAssertEqual(curve.interpolateComposite(at: 0.5), 0.5, accuracy: 0.01)
        XCTAssertEqual(curve.interpolateComposite(at: 0.75), 0.75, accuracy: 0.01)
        XCTAssertEqual(curve.interpolateComposite(at: 1), 1, accuracy: 0.01)
    }

    /// Test: Empty RGB channels return input value
    func testEmptyRGBChannels() {
        let curve = ToneCurveData.identity

        XCTAssertEqual(curve.interpolateRed(at: 0.5), 0.5, accuracy: 0.01)
        XCTAssertEqual(curve.interpolateGreen(at: 0.3), 0.3, accuracy: 0.01)
        XCTAssertEqual(curve.interpolateBlue(at: 0.8), 0.8, accuracy: 0.01)
    }

    /// Test: Custom curve interpolation
    func testCustomCurveInterpolation() {
        let curve = ToneCurveData(
            composite: [
                .init(x: 0, y: 0.1),    // Lift blacks
                .init(x: 0.25, y: 0.25),
                .init(x: 0.5, y: 0.5),
                .init(x: 0.75, y: 0.75),
                .init(x: 1, y: 0.9)     // Crush whites
            ],
            red: [],
            green: [],
            blue: []
        )

        // At x=0, y should be 0.1 (lifted blacks)
        XCTAssertEqual(curve.interpolateComposite(at: 0), 0.1, accuracy: 0.01)

        // At x=1, y should be 0.9 (crushed whites)
        XCTAssertEqual(curve.interpolateComposite(at: 1), 0.9, accuracy: 0.01)
    }

    /// Test: Identity check
    func testIsIdentity() {
        let identity = ToneCurveData.identity
        XCTAssertTrue(identity.isIdentity)

        let modified = ToneCurveData(
            composite: [
                .init(x: 0, y: 0.1),
                .init(x: 0.25, y: 0.25),
                .init(x: 0.5, y: 0.5),
                .init(x: 0.75, y: 0.75),
                .init(x: 1, y: 1)
            ],
            red: [],
            green: [],
            blue: []
        )
        XCTAssertFalse(modified.isIdentity)
    }

    /// Test: Curve point equality with tolerance
    func testCurvePointEquality() {
        let a = ToneCurveData.CurvePoint(x: 0.5, y: 0.5)
        let b = ToneCurveData.CurvePoint(x: 0.50001, y: 0.49999)

        XCTAssertEqual(a, b, "Points within tolerance should be equal")
    }
}

// MARK: - HSL Adjustments Tests

final class HSLAdjustmentsTests: XCTestCase {

    /// Test: Identity HSL has no adjustments
    func testIdentityHSL() {
        let hsl = HSLAdjustments.identity
        XCTAssertTrue(hsl.isIdentity)
    }

    /// Test: Modified channel is not identity
    func testModifiedChannelNotIdentity() {
        var hsl = HSLAdjustments.identity
        hsl.red.hue = 10

        XCTAssertFalse(hsl.isIdentity)
    }

    /// Test: Subscript access by index
    func testSubscriptAccess() {
        var hsl = HSLAdjustments.identity

        hsl[0] = HSLAdjustments.HSLChannel(hue: 15, saturation: 20, luminance: -10)
        hsl[5] = HSLAdjustments.HSLChannel(hue: -30, saturation: 0, luminance: 5)

        XCTAssertEqual(hsl.red.hue, 15)
        XCTAssertEqual(hsl.red.saturation, 20)
        XCTAssertEqual(hsl.blue.hue, -30)
        XCTAssertEqual(hsl.blue.luminance, 5)
    }

    /// Test: All 8 channels accessible
    func testAllChannelsAccessible() {
        var hsl = HSLAdjustments.identity

        for i in 0..<8 {
            hsl[i] = HSLAdjustments.HSLChannel(hue: Float(i * 10), saturation: 0, luminance: 0)
        }

        XCTAssertEqual(hsl.red.hue, 0)
        XCTAssertEqual(hsl.orange.hue, 10)
        XCTAssertEqual(hsl.yellow.hue, 20)
        XCTAssertEqual(hsl.green.hue, 30)
        XCTAssertEqual(hsl.aqua.hue, 40)
        XCTAssertEqual(hsl.blue.hue, 50)
        XCTAssertEqual(hsl.purple.hue, 60)
        XCTAssertEqual(hsl.magenta.hue, 70)
    }

    /// Test: Channel names array
    func testChannelNames() {
        XCTAssertEqual(HSLAdjustments.channelNames.count, 8)
        XCTAssertEqual(HSLAdjustments.channelNames[0], "Red")
        XCTAssertEqual(HSLAdjustments.channelNames[7], "Magenta")
    }

    /// Test: Out of bounds subscript returns identity
    func testOutOfBoundsSubscript() {
        let hsl = HSLAdjustments.identity

        let invalid = hsl[100]
        XCTAssertEqual(invalid, HSLAdjustments.HSLChannel.identity)
    }
}

// MARK: - Effect Data Tests

final class EffectDataTests: XCTestCase {

    // MARK: - Grain Tests

    func testGrainNone() {
        let grain = GrainData.none
        XCTAssertFalse(grain.isActive)
        XCTAssertEqual(grain.amount, 0)
    }

    func testGrainActive() {
        let grain = GrainData(amount: 50, size: 0.5, roughness: 0.5, monochromatic: true)
        XCTAssertTrue(grain.isActive)
    }

    // MARK: - Vignette Tests

    func testVignetteNone() {
        let vignette = VignetteData.none
        XCTAssertFalse(vignette.isActive)
    }

    func testVignetteActive() {
        let vignette = VignetteData(amount: -30, midpoint: 0.5, roundness: 0, feather: 0.5)
        XCTAssertTrue(vignette.isActive)
    }

    func testVignetteNegativeActive() {
        // Negative vignette (brighten edges) should also be active
        var vignette = VignetteData.none
        vignette.amount = -50
        XCTAssertTrue(vignette.isActive)
    }

    // MARK: - Bloom Tests

    func testBloomNone() {
        let bloom = BloomData.none
        XCTAssertFalse(bloom.isActive)
    }

    func testBloomActive() {
        let bloom = BloomData(intensity: 25, radius: 0.5, threshold: 0.7)
        XCTAssertTrue(bloom.isActive)
    }

    // MARK: - Halation Tests

    func testHalationNone() {
        let halation = HalationData.none
        XCTAssertFalse(halation.isActive)
    }

    func testHalationActive() {
        let halation = HalationData(intensity: 15, hue: 10, spread: 0.6)
        XCTAssertTrue(halation.isActive)
    }

    // MARK: - Split Tone Tests

    func testSplitToneIdentity() {
        let splitTone = SplitToneData.identity
        XCTAssertTrue(splitTone.isIdentity)
    }

    func testSplitToneNotIdentity() {
        var splitTone = SplitToneData.identity
        splitTone.highlightSaturation = 30
        XCTAssertFalse(splitTone.isIdentity)
    }
}
