import XCTest
@testable import FilmBox

/// Unit tests for FilterParameters struct and related parameter handling
final class FilterParametersTests: XCTestCase {

    // MARK: - Identity Tests

    func testIdentityHasZeroValues() {
        let identity = FilterParameters.identity

        // Light parameters
        XCTAssertEqual(identity.exposure, 0)
        XCTAssertEqual(identity.contrast, 0)
        XCTAssertEqual(identity.highlights, 0)
        XCTAssertEqual(identity.shadows, 0)
        XCTAssertEqual(identity.whites, 0)
        XCTAssertEqual(identity.blacks, 0)

        // Color parameters
        XCTAssertEqual(identity.temperature, 0)
        XCTAssertEqual(identity.tint, 0)
        XCTAssertEqual(identity.saturation, 0)
        XCTAssertEqual(identity.vibrance, 0)

        // Effects
        XCTAssertEqual(identity.clarity, 0)
        XCTAssertEqual(identity.fade, 0)
        XCTAssertEqual(identity.sharpness, 0)
        XCTAssertEqual(identity.sharpenRadius, 1.0)

        // Skin tone
        XCTAssertEqual(identity.skinToneHue, 0)
        XCTAssertEqual(identity.skinToneSaturation, 0)

        // Transform
        XCTAssertEqual(identity.rotation, 0)
        XCTAssertNil(identity.cropRect)
    }

    func testIdentityToneCurve() {
        let identity = FilterParameters.identity
        XCTAssertTrue(identity.toneCurve.isIdentity)
    }

    func testIdentityHSL() {
        let identity = FilterParameters.identity
        XCTAssertTrue(identity.hsl.isIdentity)
    }

    func testIdentitySplitTone() {
        let identity = FilterParameters.identity
        XCTAssertTrue(identity.splitTone.isIdentity)
    }

    func testIdentityGrain() {
        let identity = FilterParameters.identity
        XCTAssertFalse(identity.grain.isActive)
        XCTAssertEqual(identity.grain.amount, 0)
    }

    func testIdentityVignette() {
        let identity = FilterParameters.identity
        XCTAssertFalse(identity.vignette.isActive)
        XCTAssertEqual(identity.vignette.amount, 0)
    }

    func testIdentityBloom() {
        let identity = FilterParameters.identity
        XCTAssertFalse(identity.bloom.isActive)
        XCTAssertEqual(identity.bloom.intensity, 0)
    }

    func testIdentityHalation() {
        let identity = FilterParameters.identity
        XCTAssertFalse(identity.halation.isActive)
        XCTAssertEqual(identity.halation.intensity, 0)
    }

    // MARK: - hasAdjustments Tests

    func testHasAdjustmentsReturnsFalseForIdentity() {
        let identity = FilterParameters.identity
        XCTAssertFalse(identity.hasAdjustments)
    }

    func testHasAdjustmentsReturnsTrueWhenExposureChanged() {
        var params = FilterParameters.identity
        params.exposure = 0.5
        XCTAssertTrue(params.hasAdjustments)
    }

    func testHasAdjustmentsReturnsTrueWhenContrastChanged() {
        var params = FilterParameters.identity
        params.contrast = 25
        XCTAssertTrue(params.hasAdjustments)
    }

    func testHasAdjustmentsReturnsTrueWhenSaturationChanged() {
        var params = FilterParameters.identity
        params.saturation = -10
        XCTAssertTrue(params.hasAdjustments)
    }

    func testHasAdjustmentsReturnsTrueWhenGrainIsActive() {
        var params = FilterParameters.identity
        params.grain.amount = 50
        XCTAssertTrue(params.hasAdjustments)
    }

    func testHasAdjustmentsReturnsTrueWhenVignetteIsActive() {
        var params = FilterParameters.identity
        params.vignette.amount = -30
        XCTAssertTrue(params.hasAdjustments)
    }

    // MARK: - Codable Tests

    func testCodableRoundTrip() throws {
        var params = FilterParameters()
        params.exposure = 1.5
        params.contrast = 25
        params.highlights = -50
        params.shadows = 30
        params.temperature = 15
        params.saturation = -20
        params.clarity = 40
        params.grain.amount = 25
        params.grain.size = 0.7
        params.vignette.amount = -15

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterParameters.self, from: data)

        XCTAssertEqual(decoded.exposure, 1.5)
        XCTAssertEqual(decoded.contrast, 25)
        XCTAssertEqual(decoded.highlights, -50)
        XCTAssertEqual(decoded.shadows, 30)
        XCTAssertEqual(decoded.temperature, 15)
        XCTAssertEqual(decoded.saturation, -20)
        XCTAssertEqual(decoded.clarity, 40)
        XCTAssertEqual(decoded.grain.amount, 25)
        XCTAssertEqual(decoded.grain.size, 0.7)
        XCTAssertEqual(decoded.vignette.amount, -15)
    }

    func testCodableWithIdentity() throws {
        let params = FilterParameters.identity

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterParameters.self, from: data)

        XCTAssertEqual(decoded, params)
        XCTAssertFalse(decoded.hasAdjustments)
    }

    func testCodableWithHSLAdjustments() throws {
        var params = FilterParameters()
        params.hsl.red.hue = 15
        params.hsl.red.saturation = 25
        params.hsl.blue.luminance = -30

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterParameters.self, from: data)

        XCTAssertEqual(decoded.hsl.red.hue, 15)
        XCTAssertEqual(decoded.hsl.red.saturation, 25)
        XCTAssertEqual(decoded.hsl.blue.luminance, -30)
    }

    func testCodableWithSplitTone() throws {
        var params = FilterParameters()
        params.splitTone.highlightHue = 45
        params.splitTone.highlightSaturation = 30
        params.splitTone.shadowHue = 220
        params.splitTone.shadowSaturation = 25
        params.splitTone.balance = -15

        let encoder = JSONEncoder()
        let data = try encoder.encode(params)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FilterParameters.self, from: data)

        XCTAssertEqual(decoded.splitTone.highlightHue, 45)
        XCTAssertEqual(decoded.splitTone.highlightSaturation, 30)
        XCTAssertEqual(decoded.splitTone.shadowHue, 220)
        XCTAssertEqual(decoded.splitTone.shadowSaturation, 25)
        XCTAssertEqual(decoded.splitTone.balance, -15)
    }

    // MARK: - Interpolation Tests

    func testInterpolateAtZeroReturnsFromParameters() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.exposure = 2.0
        to.contrast = 100

        let result = FilterParameters.interpolate(from: from, to: to, t: 0)

        XCTAssertEqual(result.exposure, 0)
        XCTAssertEqual(result.contrast, 0)
    }

    func testInterpolateAtOneReturnsToParameters() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.exposure = 2.0
        to.contrast = 100

        let result = FilterParameters.interpolate(from: from, to: to, t: 1)

        XCTAssertEqual(result.exposure, 2.0)
        XCTAssertEqual(result.contrast, 100)
    }

    func testInterpolateAtHalfReturnsMiddleValues() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.exposure = 2.0
        to.contrast = 100
        to.saturation = -50

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.5)

        XCTAssertEqual(result.exposure, 1.0)
        XCTAssertEqual(result.contrast, 50)
        XCTAssertEqual(result.saturation, -25)
    }

    func testInterpolateGrainParameters() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.grain.amount = 100
        to.grain.size = 1.0
        to.grain.roughness = 1.0

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.25)

        XCTAssertEqual(result.grain.amount, 25)
        XCTAssertEqual(result.grain.size, 0.625, accuracy: 0.001)
        XCTAssertEqual(result.grain.roughness, 0.625, accuracy: 0.001)
    }

    func testInterpolateVignetteParameters() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.vignette.amount = -100
        to.vignette.midpoint = 1.0

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.5)

        XCTAssertEqual(result.vignette.amount, -50)
        XCTAssertEqual(result.vignette.midpoint, 0.75)
    }

    func testInterpolateBloomParameters() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.bloom.intensity = 80
        to.bloom.radius = 0.8
        to.bloom.threshold = 0.6

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.5)

        XCTAssertEqual(result.bloom.intensity, 40)
        XCTAssertEqual(result.bloom.radius, 0.65, accuracy: 0.001)
        XCTAssertEqual(result.bloom.threshold, 0.7, accuracy: 0.001)
    }

    func testInterpolateHSLChannels() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.hsl.red.hue = 100
        to.hsl.red.saturation = 50
        to.hsl.blue.luminance = -80

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.5)

        XCTAssertEqual(result.hsl.red.hue, 50)
        XCTAssertEqual(result.hsl.red.saturation, 25)
        XCTAssertEqual(result.hsl.blue.luminance, -40)
    }

    func testInterpolateSplitTone() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.splitTone.highlightHue = 60
        to.splitTone.highlightSaturation = 40
        to.splitTone.shadowHue = 240
        to.splitTone.shadowSaturation = 30
        to.splitTone.balance = 50

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.5)

        XCTAssertEqual(result.splitTone.highlightHue, 30)
        XCTAssertEqual(result.splitTone.highlightSaturation, 20)
        XCTAssertEqual(result.splitTone.shadowHue, 120)
        XCTAssertEqual(result.splitTone.shadowSaturation, 15)
        XCTAssertEqual(result.splitTone.balance, 25)
    }

    func testInterpolateSkinTone() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.skinToneHue = 40
        to.skinToneSaturation = -20

        let result = FilterParameters.interpolate(from: from, to: to, t: 0.5)

        XCTAssertEqual(result.skinToneHue, 20)
        XCTAssertEqual(result.skinToneSaturation, -10)
    }

    func testInterpolateGrainMonochromaticUsesThreshold() {
        var from = FilterParameters()
        from.grain.monochromatic = false
        var to = FilterParameters()
        to.grain.monochromatic = true

        // At t < 0.5, should use from value
        let resultLow = FilterParameters.interpolate(from: from, to: to, t: 0.4)
        XCTAssertFalse(resultLow.grain.monochromatic)

        // At t > 0.5, should use to value
        let resultHigh = FilterParameters.interpolate(from: from, to: to, t: 0.6)
        XCTAssertTrue(resultHigh.grain.monochromatic)
    }

    // MARK: - Parameter Range Tests

    func testExposureRange() {
        let range = FilterParameters.ParameterRange.exposure.range
        XCTAssertEqual(range.lowerBound, -2)
        XCTAssertEqual(range.upperBound, 2)
    }

    func testContrastRange() {
        let range = FilterParameters.ParameterRange.contrast.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testHighlightsRange() {
        let range = FilterParameters.ParameterRange.highlights.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testShadowsRange() {
        let range = FilterParameters.ParameterRange.shadows.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testWhitesRange() {
        let range = FilterParameters.ParameterRange.whites.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testBlacksRange() {
        let range = FilterParameters.ParameterRange.blacks.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testTemperatureRange() {
        let range = FilterParameters.ParameterRange.temperature.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testTintRange() {
        let range = FilterParameters.ParameterRange.tint.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testSaturationRange() {
        let range = FilterParameters.ParameterRange.saturation.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testVibranceRange() {
        let range = FilterParameters.ParameterRange.vibrance.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testClarityRange() {
        let range = FilterParameters.ParameterRange.clarity.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testSharpnessRange() {
        let range = FilterParameters.ParameterRange.sharpness.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testSharpenRadiusRange() {
        let range = FilterParameters.ParameterRange.sharpenRadius.range
        XCTAssertEqual(range.lowerBound, 0.5)
        XCTAssertEqual(range.upperBound, 3.0)
    }

    func testFadeRange() {
        let range = FilterParameters.ParameterRange.fade.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testGrainAmountRange() {
        let range = FilterParameters.ParameterRange.grainAmount.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testGrainSizeRange() {
        let range = FilterParameters.ParameterRange.grainSize.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 1)
    }

    func testVignetteAmountRange() {
        let range = FilterParameters.ParameterRange.vignetteAmount.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testBloomIntensityRange() {
        let range = FilterParameters.ParameterRange.bloomIntensity.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testHalationHueRange() {
        let range = FilterParameters.ParameterRange.halationHue.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 360)
    }

    func testHslHueRange() {
        let range = FilterParameters.ParameterRange.hslHue.range
        XCTAssertEqual(range.lowerBound, -180)
        XCTAssertEqual(range.upperBound, 180)
    }

    func testSplitToneHueRange() {
        let range = FilterParameters.ParameterRange.splitToneHue.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 360)
    }

    func testSplitToneSaturationRange() {
        let range = FilterParameters.ParameterRange.splitToneSaturation.range
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 100)
    }

    func testSplitToneBalanceRange() {
        let range = FilterParameters.ParameterRange.splitToneBalance.range
        XCTAssertEqual(range.lowerBound, -100)
        XCTAssertEqual(range.upperBound, 100)
    }

    // MARK: - Default Value Tests

    func testDefaultValueForSharpenRadius() {
        let defaultValue = FilterParameters.ParameterRange.sharpenRadius.defaultValue
        XCTAssertEqual(defaultValue, 1.0)
    }

    func testDefaultValueForGrainSize() {
        let defaultValue = FilterParameters.ParameterRange.grainSize.defaultValue
        XCTAssertEqual(defaultValue, 0.5)
    }

    func testDefaultValueForGrainRoughness() {
        let defaultValue = FilterParameters.ParameterRange.grainRoughness.defaultValue
        XCTAssertEqual(defaultValue, 0.5)
    }

    func testDefaultValueForVignetteMidpoint() {
        let defaultValue = FilterParameters.ParameterRange.vignetteMidpoint.defaultValue
        XCTAssertEqual(defaultValue, 0.5)
    }

    func testDefaultValueForVignetteFeather() {
        let defaultValue = FilterParameters.ParameterRange.vignetteFeather.defaultValue
        XCTAssertEqual(defaultValue, 0.5)
    }

    func testDefaultValueForBloomRadius() {
        let defaultValue = FilterParameters.ParameterRange.bloomRadius.defaultValue
        XCTAssertEqual(defaultValue, 0.5)
    }

    func testDefaultValueForBloomThreshold() {
        let defaultValue = FilterParameters.ParameterRange.bloomThreshold.defaultValue
        XCTAssertEqual(defaultValue, 0.8)
    }

    func testDefaultValueForHalationSpread() {
        let defaultValue = FilterParameters.ParameterRange.halationSpread.defaultValue
        XCTAssertEqual(defaultValue, 0.5)
    }

    func testDefaultValueForExposureIsZero() {
        let defaultValue = FilterParameters.ParameterRange.exposure.defaultValue
        XCTAssertEqual(defaultValue, 0)
    }

    func testDefaultValueForContrastIsZero() {
        let defaultValue = FilterParameters.ParameterRange.contrast.defaultValue
        XCTAssertEqual(defaultValue, 0)
    }

    // MARK: - Hashable Tests

    func testHashableEquality() {
        let params1 = FilterParameters.identity
        let params2 = FilterParameters.identity
        XCTAssertEqual(params1.hashValue, params2.hashValue)
    }

    func testHashableInequality() {
        let params1 = FilterParameters.identity
        var params2 = FilterParameters.identity
        params2.exposure = 1.0
        XCTAssertNotEqual(params1.hashValue, params2.hashValue)
    }

    // MARK: - Edge Cases

    func testInterpolateWithNegativeT() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.exposure = 2.0

        let result = FilterParameters.interpolate(from: from, to: to, t: -0.5)

        // Should extrapolate in the opposite direction
        XCTAssertEqual(result.exposure, -1.0)
    }

    func testInterpolateWithTGreaterThanOne() {
        let from = FilterParameters.identity
        var to = FilterParameters()
        to.exposure = 1.0

        let result = FilterParameters.interpolate(from: from, to: to, t: 1.5)

        // Should extrapolate beyond the target
        XCTAssertEqual(result.exposure, 1.5)
    }
}
