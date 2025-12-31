import XCTest
@testable import FilmBox

/// Unit tests for ToneCurveData struct
final class ToneCurveDataTests: XCTestCase {

    // MARK: - Identity Tests

    func testIdentityHasFiveCompositePoints() {
        let identity = ToneCurveData.identity
        XCTAssertEqual(identity.composite.count, 5)
    }

    func testIdentityCompositePointsAreLinear() {
        let identity = ToneCurveData.identity

        XCTAssertEqual(identity.composite[0].x, 0)
        XCTAssertEqual(identity.composite[0].y, 0)

        XCTAssertEqual(identity.composite[1].x, 0.25)
        XCTAssertEqual(identity.composite[1].y, 0.25)

        XCTAssertEqual(identity.composite[2].x, 0.5)
        XCTAssertEqual(identity.composite[2].y, 0.5)

        XCTAssertEqual(identity.composite[3].x, 0.75)
        XCTAssertEqual(identity.composite[3].y, 0.75)

        XCTAssertEqual(identity.composite[4].x, 1)
        XCTAssertEqual(identity.composite[4].y, 1)
    }

    func testIdentityRedChannelIsEmpty() {
        let identity = ToneCurveData.identity
        XCTAssertTrue(identity.red.isEmpty)
    }

    func testIdentityGreenChannelIsEmpty() {
        let identity = ToneCurveData.identity
        XCTAssertTrue(identity.green.isEmpty)
    }

    func testIdentityBlueChannelIsEmpty() {
        let identity = ToneCurveData.identity
        XCTAssertTrue(identity.blue.isEmpty)
    }

    // MARK: - isIdentity Tests

    func testIsIdentityReturnsTrueForIdentity() {
        let identity = ToneCurveData.identity
        XCTAssertTrue(identity.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenCompositeModified() {
        var curve = ToneCurveData.identity
        curve.composite[2].y = 0.6  // Raise midtones
        XCTAssertFalse(curve.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenRedChannelHasPoints() {
        var curve = ToneCurveData.identity
        curve.red = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]
        XCTAssertFalse(curve.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenGreenChannelHasPoints() {
        var curve = ToneCurveData.identity
        curve.green = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]
        XCTAssertFalse(curve.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenBlueChannelHasPoints() {
        var curve = ToneCurveData.identity
        curve.blue = [
            ToneCurveData.CurvePoint(x: 0, y: 0.1),
            ToneCurveData.CurvePoint(x: 1, y: 0.9)
        ]
        XCTAssertFalse(curve.isIdentity)
    }

    // MARK: - Composite Interpolation Tests

    func testInterpolateCompositeAtZero() {
        let curve = ToneCurveData.identity
        let result = curve.interpolateComposite(at: 0)
        XCTAssertEqual(result, 0, accuracy: 0.001)
    }

    func testInterpolateCompositeAtOne() {
        let curve = ToneCurveData.identity
        let result = curve.interpolateComposite(at: 1)
        XCTAssertEqual(result, 1, accuracy: 0.001)
    }

    func testInterpolateCompositeAtHalf() {
        let curve = ToneCurveData.identity
        let result = curve.interpolateComposite(at: 0.5)
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    func testInterpolateCompositeAtQuarter() {
        let curve = ToneCurveData.identity
        let result = curve.interpolateComposite(at: 0.25)
        XCTAssertEqual(result, 0.25, accuracy: 0.001)
    }

    func testInterpolateCompositeAtThreeQuarters() {
        let curve = ToneCurveData.identity
        let result = curve.interpolateComposite(at: 0.75)
        XCTAssertEqual(result, 0.75, accuracy: 0.001)
    }

    func testInterpolateCompositeWithSCurve() {
        var curve = ToneCurveData.identity
        // Create an S-curve by raising highlights and lowering shadows
        curve.composite[1].y = 0.15  // Lower shadows
        curve.composite[3].y = 0.85  // Raise highlights

        let shadowResult = curve.interpolateComposite(at: 0.25)
        let highlightResult = curve.interpolateComposite(at: 0.75)

        XCTAssertEqual(shadowResult, 0.15, accuracy: 0.001)
        XCTAssertEqual(highlightResult, 0.85, accuracy: 0.001)
    }

    func testInterpolateCompositeBetweenPoints() {
        var curve = ToneCurveData.identity
        curve.composite[1].y = 0.20  // Point at x=0.25, y=0.20
        curve.composite[2].y = 0.60  // Point at x=0.50, y=0.60

        // Linear interpolation between (0.25, 0.20) and (0.50, 0.60)
        // At x=0.375, y should be 0.40
        let result = curve.interpolateComposite(at: 0.375)
        XCTAssertEqual(result, 0.40, accuracy: 0.01)
    }

    // MARK: - Red Channel Interpolation Tests

    func testInterpolateRedReturnsInputWhenEmpty() {
        let curve = ToneCurveData.identity

        XCTAssertEqual(curve.interpolateRed(at: 0), 0, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateRed(at: 0.5), 0.5, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateRed(at: 1), 1, accuracy: 0.001)
    }

    func testInterpolateRedWithCustomCurve() {
        var curve = ToneCurveData.identity
        curve.red = [
            ToneCurveData.CurvePoint(x: 0, y: 0.1),
            ToneCurveData.CurvePoint(x: 0.5, y: 0.6),
            ToneCurveData.CurvePoint(x: 1, y: 0.9)
        ]

        XCTAssertEqual(curve.interpolateRed(at: 0), 0.1, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateRed(at: 0.5), 0.6, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateRed(at: 1), 0.9, accuracy: 0.001)
    }

    func testInterpolateRedBetweenPoints() {
        var curve = ToneCurveData.identity
        curve.red = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]

        // Linear interpolation between (0, 0) and (1, 1)
        XCTAssertEqual(curve.interpolateRed(at: 0.25), 0.25, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateRed(at: 0.75), 0.75, accuracy: 0.001)
    }

    // MARK: - Green Channel Interpolation Tests

    func testInterpolateGreenReturnsInputWhenEmpty() {
        let curve = ToneCurveData.identity

        XCTAssertEqual(curve.interpolateGreen(at: 0), 0, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateGreen(at: 0.5), 0.5, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateGreen(at: 1), 1, accuracy: 0.001)
    }

    func testInterpolateGreenWithCustomCurve() {
        var curve = ToneCurveData.identity
        curve.green = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 0.5, y: 0.7),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]

        XCTAssertEqual(curve.interpolateGreen(at: 0.5), 0.7, accuracy: 0.001)
    }

    // MARK: - Blue Channel Interpolation Tests

    func testInterpolateBlueReturnsInputWhenEmpty() {
        let curve = ToneCurveData.identity

        XCTAssertEqual(curve.interpolateBlue(at: 0), 0, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateBlue(at: 0.5), 0.5, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateBlue(at: 1), 1, accuracy: 0.001)
    }

    func testInterpolateBlueWithCustomCurve() {
        var curve = ToneCurveData.identity
        curve.blue = [
            ToneCurveData.CurvePoint(x: 0, y: 0.2),
            ToneCurveData.CurvePoint(x: 0.5, y: 0.5),
            ToneCurveData.CurvePoint(x: 1, y: 0.8)
        ]

        XCTAssertEqual(curve.interpolateBlue(at: 0), 0.2, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateBlue(at: 1), 0.8, accuracy: 0.001)
    }

    // MARK: - CurvePoint Tests

    func testCurvePointEquality() {
        let point1 = ToneCurveData.CurvePoint(x: 0.5, y: 0.5)
        let point2 = ToneCurveData.CurvePoint(x: 0.5, y: 0.5)

        XCTAssertEqual(point1, point2)
    }

    func testCurvePointEqualityWithSmallDifference() {
        let point1 = ToneCurveData.CurvePoint(x: 0.50000, y: 0.50000)
        let point2 = ToneCurveData.CurvePoint(x: 0.50005, y: 0.50005)

        // Should be equal due to tolerance of 0.0001
        XCTAssertEqual(point1, point2)
    }

    func testCurvePointInequalityWithLargeDifference() {
        let point1 = ToneCurveData.CurvePoint(x: 0.5, y: 0.5)
        let point2 = ToneCurveData.CurvePoint(x: 0.5, y: 0.6)

        XCTAssertNotEqual(point1, point2)
    }

    func testCurvePointCodable() throws {
        let point = ToneCurveData.CurvePoint(x: 0.3, y: 0.7)

        let encoder = JSONEncoder()
        let data = try encoder.encode(point)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ToneCurveData.CurvePoint.self, from: data)

        XCTAssertEqual(decoded.x, 0.3, accuracy: 0.001)
        XCTAssertEqual(decoded.y, 0.7, accuracy: 0.001)
    }

    // MARK: - ToneCurveData Codable Tests

    func testToneCurveDataCodable() throws {
        var curve = ToneCurveData.identity
        curve.composite[2].y = 0.6
        curve.red = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(curve)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ToneCurveData.self, from: data)

        XCTAssertEqual(decoded.composite[2].y, 0.6, accuracy: 0.001)
        XCTAssertEqual(decoded.red.count, 2)
    }

    // MARK: - Edge Cases

    func testInterpolateWithSinglePoint() {
        var curve = ToneCurveData.identity
        curve.red = [ToneCurveData.CurvePoint(x: 0.5, y: 0.7)]

        // With a single point, should return that point's y value
        let result = curve.interpolateRed(at: 0.3)
        XCTAssertEqual(result, 0.7, accuracy: 0.001)
    }

    func testInterpolateAtExactPointLocation() {
        var curve = ToneCurveData.identity
        curve.red = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 0.5, y: 0.8),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]

        // At exact point location
        let result = curve.interpolateRed(at: 0.5)
        XCTAssertEqual(result, 0.8, accuracy: 0.001)
    }

    func testInterpolateBeforeFirstPoint() {
        var curve = ToneCurveData.identity
        curve.red = [
            ToneCurveData.CurvePoint(x: 0.2, y: 0.3),
            ToneCurveData.CurvePoint(x: 1, y: 1)
        ]

        // Before first point - should return first point's y
        let result = curve.interpolateRed(at: 0.1)
        XCTAssertEqual(result, 0.3, accuracy: 0.001)
    }

    func testInterpolateAfterLastPoint() {
        var curve = ToneCurveData.identity
        curve.red = [
            ToneCurveData.CurvePoint(x: 0, y: 0),
            ToneCurveData.CurvePoint(x: 0.8, y: 0.9)
        ]

        // After last point - should return last point's y
        let result = curve.interpolateRed(at: 0.95)
        XCTAssertEqual(result, 0.9, accuracy: 0.001)
    }

    // MARK: - Hashable Tests

    func testToneCurveDataHashable() {
        let curve1 = ToneCurveData.identity
        let curve2 = ToneCurveData.identity

        XCTAssertEqual(curve1.hashValue, curve2.hashValue)
    }

    func testToneCurveDataEquatable() {
        let curve1 = ToneCurveData.identity
        let curve2 = ToneCurveData.identity

        XCTAssertEqual(curve1, curve2)
    }

    func testToneCurveDataNotEqualWhenModified() {
        let curve1 = ToneCurveData.identity
        var curve2 = ToneCurveData.identity
        curve2.composite[2].y = 0.6

        XCTAssertNotEqual(curve1, curve2)
    }

    // MARK: - Various Curve Shapes Tests

    func testHighContrastCurve() {
        var curve = ToneCurveData.identity
        // Steep S-curve for high contrast
        curve.composite[1].y = 0.10  // Crush shadows
        curve.composite[2].y = 0.50  // Keep midtones
        curve.composite[3].y = 0.90  // Boost highlights

        XCTAssertLessThan(curve.interpolateComposite(at: 0.25), 0.25)
        XCTAssertEqual(curve.interpolateComposite(at: 0.5), 0.5, accuracy: 0.001)
        XCTAssertGreaterThan(curve.interpolateComposite(at: 0.75), 0.75)
    }

    func testLowContrastCurve() {
        var curve = ToneCurveData.identity
        // Flat curve for low contrast
        curve.composite[0].y = 0.1   // Lift blacks
        curve.composite[4].y = 0.9   // Lower whites

        XCTAssertEqual(curve.interpolateComposite(at: 0), 0.1, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateComposite(at: 1), 0.9, accuracy: 0.001)
    }

    func testNegativeCurve() {
        var curve = ToneCurveData.identity
        // Invert the curve
        curve.composite[0].y = 1.0
        curve.composite[1].y = 0.75
        curve.composite[2].y = 0.5
        curve.composite[3].y = 0.25
        curve.composite[4].y = 0.0

        XCTAssertEqual(curve.interpolateComposite(at: 0), 1.0, accuracy: 0.001)
        XCTAssertEqual(curve.interpolateComposite(at: 1), 0.0, accuracy: 0.001)
    }

    func testFadedFilmCurve() {
        var curve = ToneCurveData.identity
        // Lifted blacks, lowered whites - classic faded film look
        curve.composite[0].y = 0.05
        curve.composite[4].y = 0.95

        // Blacks should be lifted
        XCTAssertGreaterThan(curve.interpolateComposite(at: 0), 0)
        // Whites should be lowered
        XCTAssertLessThan(curve.interpolateComposite(at: 1), 1)
    }
}
