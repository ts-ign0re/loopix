import XCTest
@testable import FilmBox

/// Unit tests for HSLAdjustments struct and HSLChannel
final class HSLAdjustmentsTests: XCTestCase {

    // MARK: - Identity Tests

    func testHSLAdjustmentsIdentity() {
        let identity = HSLAdjustments.identity
        XCTAssertTrue(identity.isIdentity)
    }

    func testIdentityAllChannelsAreIdentity() {
        let identity = HSLAdjustments.identity

        XCTAssertTrue(identity.red.isIdentity)
        XCTAssertTrue(identity.orange.isIdentity)
        XCTAssertTrue(identity.yellow.isIdentity)
        XCTAssertTrue(identity.green.isIdentity)
        XCTAssertTrue(identity.aqua.isIdentity)
        XCTAssertTrue(identity.blue.isIdentity)
        XCTAssertTrue(identity.purple.isIdentity)
        XCTAssertTrue(identity.magenta.isIdentity)
    }

    func testIdentityAllValuesAreZero() {
        let identity = HSLAdjustments.identity

        for i in 0..<8 {
            XCTAssertEqual(identity[i].hue, 0)
            XCTAssertEqual(identity[i].saturation, 0)
            XCTAssertEqual(identity[i].luminance, 0)
        }
    }

    // MARK: - HSLChannel Identity Tests

    func testHSLChannelIdentity() {
        let identity = HSLAdjustments.HSLChannel.identity

        XCTAssertEqual(identity.hue, 0)
        XCTAssertEqual(identity.saturation, 0)
        XCTAssertEqual(identity.luminance, 0)
        XCTAssertTrue(identity.isIdentity)
    }

    func testHSLChannelIsIdentityReturnsFalseWhenHueChanged() {
        var channel = HSLAdjustments.HSLChannel.identity
        channel.hue = 10
        XCTAssertFalse(channel.isIdentity)
    }

    func testHSLChannelIsIdentityReturnsFalseWhenSaturationChanged() {
        var channel = HSLAdjustments.HSLChannel.identity
        channel.saturation = -20
        XCTAssertFalse(channel.isIdentity)
    }

    func testHSLChannelIsIdentityReturnsFalseWhenLuminanceChanged() {
        var channel = HSLAdjustments.HSLChannel.identity
        channel.luminance = 15
        XCTAssertFalse(channel.isIdentity)
    }

    // MARK: - isIdentity Tests

    func testIsIdentityReturnsFalseWhenRedModified() {
        var hsl = HSLAdjustments.identity
        hsl.red.hue = 10
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenOrangeModified() {
        var hsl = HSLAdjustments.identity
        hsl.orange.saturation = 20
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenYellowModified() {
        var hsl = HSLAdjustments.identity
        hsl.yellow.luminance = -15
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenGreenModified() {
        var hsl = HSLAdjustments.identity
        hsl.green.hue = -30
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenAquaModified() {
        var hsl = HSLAdjustments.identity
        hsl.aqua.saturation = 50
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenBlueModified() {
        var hsl = HSLAdjustments.identity
        hsl.blue.luminance = 25
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenPurpleModified() {
        var hsl = HSLAdjustments.identity
        hsl.purple.hue = 45
        XCTAssertFalse(hsl.isIdentity)
    }

    func testIsIdentityReturnsFalseWhenMagentaModified() {
        var hsl = HSLAdjustments.identity
        hsl.magenta.saturation = -40
        XCTAssertFalse(hsl.isIdentity)
    }

    // MARK: - Subscript Get Tests

    func testSubscriptGetRed() {
        var hsl = HSLAdjustments.identity
        hsl.red = HSLAdjustments.HSLChannel(hue: 10, saturation: 20, luminance: 30)

        let channel = hsl[0]
        XCTAssertEqual(channel.hue, 10)
        XCTAssertEqual(channel.saturation, 20)
        XCTAssertEqual(channel.luminance, 30)
    }

    func testSubscriptGetOrange() {
        var hsl = HSLAdjustments.identity
        hsl.orange = HSLAdjustments.HSLChannel(hue: 15, saturation: 25, luminance: 35)

        let channel = hsl[1]
        XCTAssertEqual(channel.hue, 15)
        XCTAssertEqual(channel.saturation, 25)
        XCTAssertEqual(channel.luminance, 35)
    }

    func testSubscriptGetYellow() {
        var hsl = HSLAdjustments.identity
        hsl.yellow = HSLAdjustments.HSLChannel(hue: 20, saturation: 30, luminance: 40)

        let channel = hsl[2]
        XCTAssertEqual(channel.hue, 20)
        XCTAssertEqual(channel.saturation, 30)
        XCTAssertEqual(channel.luminance, 40)
    }

    func testSubscriptGetGreen() {
        var hsl = HSLAdjustments.identity
        hsl.green = HSLAdjustments.HSLChannel(hue: -60, saturation: 50, luminance: -20)

        let channel = hsl[3]
        XCTAssertEqual(channel.hue, -60)
        XCTAssertEqual(channel.saturation, 50)
        XCTAssertEqual(channel.luminance, -20)
    }

    func testSubscriptGetAqua() {
        var hsl = HSLAdjustments.identity
        hsl.aqua = HSLAdjustments.HSLChannel(hue: 90, saturation: -30, luminance: 10)

        let channel = hsl[4]
        XCTAssertEqual(channel.hue, 90)
        XCTAssertEqual(channel.saturation, -30)
        XCTAssertEqual(channel.luminance, 10)
    }

    func testSubscriptGetBlue() {
        var hsl = HSLAdjustments.identity
        hsl.blue = HSLAdjustments.HSLChannel(hue: -120, saturation: 80, luminance: -50)

        let channel = hsl[5]
        XCTAssertEqual(channel.hue, -120)
        XCTAssertEqual(channel.saturation, 80)
        XCTAssertEqual(channel.luminance, -50)
    }

    func testSubscriptGetPurple() {
        var hsl = HSLAdjustments.identity
        hsl.purple = HSLAdjustments.HSLChannel(hue: 45, saturation: 55, luminance: 65)

        let channel = hsl[6]
        XCTAssertEqual(channel.hue, 45)
        XCTAssertEqual(channel.saturation, 55)
        XCTAssertEqual(channel.luminance, 65)
    }

    func testSubscriptGetMagenta() {
        var hsl = HSLAdjustments.identity
        hsl.magenta = HSLAdjustments.HSLChannel(hue: -180, saturation: -100, luminance: 100)

        let channel = hsl[7]
        XCTAssertEqual(channel.hue, -180)
        XCTAssertEqual(channel.saturation, -100)
        XCTAssertEqual(channel.luminance, 100)
    }

    func testSubscriptGetOutOfBoundsReturnsIdentity() {
        let hsl = HSLAdjustments.identity

        let channelNegative = hsl[-1]
        XCTAssertTrue(channelNegative.isIdentity)

        let channelTooHigh = hsl[8]
        XCTAssertTrue(channelTooHigh.isIdentity)

        let channelVeryHigh = hsl[100]
        XCTAssertTrue(channelVeryHigh.isIdentity)
    }

    // MARK: - Subscript Set Tests

    func testSubscriptSetRed() {
        var hsl = HSLAdjustments.identity
        hsl[0] = HSLAdjustments.HSLChannel(hue: 10, saturation: 20, luminance: 30)

        XCTAssertEqual(hsl.red.hue, 10)
        XCTAssertEqual(hsl.red.saturation, 20)
        XCTAssertEqual(hsl.red.luminance, 30)
    }

    func testSubscriptSetOrange() {
        var hsl = HSLAdjustments.identity
        hsl[1] = HSLAdjustments.HSLChannel(hue: 15, saturation: 25, luminance: 35)

        XCTAssertEqual(hsl.orange.hue, 15)
        XCTAssertEqual(hsl.orange.saturation, 25)
        XCTAssertEqual(hsl.orange.luminance, 35)
    }

    func testSubscriptSetYellow() {
        var hsl = HSLAdjustments.identity
        hsl[2] = HSLAdjustments.HSLChannel(hue: -45, saturation: 60, luminance: -30)

        XCTAssertEqual(hsl.yellow.hue, -45)
        XCTAssertEqual(hsl.yellow.saturation, 60)
        XCTAssertEqual(hsl.yellow.luminance, -30)
    }

    func testSubscriptSetGreen() {
        var hsl = HSLAdjustments.identity
        hsl[3] = HSLAdjustments.HSLChannel(hue: 100, saturation: -50, luminance: 75)

        XCTAssertEqual(hsl.green.hue, 100)
        XCTAssertEqual(hsl.green.saturation, -50)
        XCTAssertEqual(hsl.green.luminance, 75)
    }

    func testSubscriptSetAqua() {
        var hsl = HSLAdjustments.identity
        hsl[4] = HSLAdjustments.HSLChannel(hue: -90, saturation: 40, luminance: -60)

        XCTAssertEqual(hsl.aqua.hue, -90)
        XCTAssertEqual(hsl.aqua.saturation, 40)
        XCTAssertEqual(hsl.aqua.luminance, -60)
    }

    func testSubscriptSetBlue() {
        var hsl = HSLAdjustments.identity
        hsl[5] = HSLAdjustments.HSLChannel(hue: 180, saturation: 100, luminance: -100)

        XCTAssertEqual(hsl.blue.hue, 180)
        XCTAssertEqual(hsl.blue.saturation, 100)
        XCTAssertEqual(hsl.blue.luminance, -100)
    }

    func testSubscriptSetPurple() {
        var hsl = HSLAdjustments.identity
        hsl[6] = HSLAdjustments.HSLChannel(hue: -135, saturation: 85, luminance: 45)

        XCTAssertEqual(hsl.purple.hue, -135)
        XCTAssertEqual(hsl.purple.saturation, 85)
        XCTAssertEqual(hsl.purple.luminance, 45)
    }

    func testSubscriptSetMagenta() {
        var hsl = HSLAdjustments.identity
        hsl[7] = HSLAdjustments.HSLChannel(hue: 60, saturation: -75, luminance: 90)

        XCTAssertEqual(hsl.magenta.hue, 60)
        XCTAssertEqual(hsl.magenta.saturation, -75)
        XCTAssertEqual(hsl.magenta.luminance, 90)
    }

    func testSubscriptSetOutOfBoundsDoesNothing() {
        var hsl = HSLAdjustments.identity
        let newChannel = HSLAdjustments.HSLChannel(hue: 50, saturation: 50, luminance: 50)

        hsl[-1] = newChannel
        hsl[8] = newChannel
        hsl[100] = newChannel

        // All channels should still be identity
        XCTAssertTrue(hsl.isIdentity)
    }

    // MARK: - Channel Names Tests

    func testChannelNamesCount() {
        XCTAssertEqual(HSLAdjustments.channelNames.count, 8)
    }

    func testChannelNamesValues() {
        XCTAssertEqual(HSLAdjustments.channelNames[0], "Red")
        XCTAssertEqual(HSLAdjustments.channelNames[1], "Orange")
        XCTAssertEqual(HSLAdjustments.channelNames[2], "Yellow")
        XCTAssertEqual(HSLAdjustments.channelNames[3], "Green")
        XCTAssertEqual(HSLAdjustments.channelNames[4], "Aqua")
        XCTAssertEqual(HSLAdjustments.channelNames[5], "Blue")
        XCTAssertEqual(HSLAdjustments.channelNames[6], "Purple")
        XCTAssertEqual(HSLAdjustments.channelNames[7], "Magenta")
    }

    // MARK: - Channel Colors Tests

    func testChannelColorsCount() {
        XCTAssertEqual(HSLAdjustments.channelColors.count, 8)
    }

    func testChannelColorsRed() {
        let red = HSLAdjustments.channelColors[0]
        XCTAssertEqual(red.0, 1.0)
        XCTAssertEqual(red.1, 0.0)
        XCTAssertEqual(red.2, 0.0)
    }

    func testChannelColorsOrange() {
        let orange = HSLAdjustments.channelColors[1]
        XCTAssertEqual(orange.0, 1.0)
        XCTAssertEqual(orange.1, 0.5)
        XCTAssertEqual(orange.2, 0.0)
    }

    func testChannelColorsYellow() {
        let yellow = HSLAdjustments.channelColors[2]
        XCTAssertEqual(yellow.0, 1.0)
        XCTAssertEqual(yellow.1, 1.0)
        XCTAssertEqual(yellow.2, 0.0)
    }

    func testChannelColorsGreen() {
        let green = HSLAdjustments.channelColors[3]
        XCTAssertEqual(green.0, 0.0)
        XCTAssertEqual(green.1, 1.0)
        XCTAssertEqual(green.2, 0.0)
    }

    func testChannelColorsAqua() {
        let aqua = HSLAdjustments.channelColors[4]
        XCTAssertEqual(aqua.0, 0.0)
        XCTAssertEqual(aqua.1, 1.0)
        XCTAssertEqual(aqua.2, 1.0)
    }

    func testChannelColorsBlue() {
        let blue = HSLAdjustments.channelColors[5]
        XCTAssertEqual(blue.0, 0.0)
        XCTAssertEqual(blue.1, 0.0)
        XCTAssertEqual(blue.2, 1.0)
    }

    func testChannelColorsPurple() {
        let purple = HSLAdjustments.channelColors[6]
        XCTAssertEqual(purple.0, 0.5)
        XCTAssertEqual(purple.1, 0.0)
        XCTAssertEqual(purple.2, 1.0)
    }

    func testChannelColorsMagenta() {
        let magenta = HSLAdjustments.channelColors[7]
        XCTAssertEqual(magenta.0, 1.0)
        XCTAssertEqual(magenta.1, 0.0)
        XCTAssertEqual(magenta.2, 1.0)
    }

    // MARK: - Codable Tests

    func testHSLChannelCodable() throws {
        let channel = HSLAdjustments.HSLChannel(hue: 45, saturation: -30, luminance: 60)

        let encoder = JSONEncoder()
        let data = try encoder.encode(channel)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HSLAdjustments.HSLChannel.self, from: data)

        XCTAssertEqual(decoded.hue, 45)
        XCTAssertEqual(decoded.saturation, -30)
        XCTAssertEqual(decoded.luminance, 60)
    }

    func testHSLAdjustmentsCodable() throws {
        var hsl = HSLAdjustments.identity
        hsl.red = HSLAdjustments.HSLChannel(hue: 10, saturation: 20, luminance: 30)
        hsl.blue = HSLAdjustments.HSLChannel(hue: -50, saturation: 40, luminance: -60)

        let encoder = JSONEncoder()
        let data = try encoder.encode(hsl)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HSLAdjustments.self, from: data)

        XCTAssertEqual(decoded.red.hue, 10)
        XCTAssertEqual(decoded.red.saturation, 20)
        XCTAssertEqual(decoded.red.luminance, 30)
        XCTAssertEqual(decoded.blue.hue, -50)
        XCTAssertEqual(decoded.blue.saturation, 40)
        XCTAssertEqual(decoded.blue.luminance, -60)

        // Other channels should remain identity
        XCTAssertTrue(decoded.orange.isIdentity)
        XCTAssertTrue(decoded.yellow.isIdentity)
        XCTAssertTrue(decoded.green.isIdentity)
    }

    func testHSLAdjustmentsIdentityCodable() throws {
        let identity = HSLAdjustments.identity

        let encoder = JSONEncoder()
        let data = try encoder.encode(identity)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HSLAdjustments.self, from: data)

        XCTAssertTrue(decoded.isIdentity)
    }

    // MARK: - Hashable Tests

    func testHSLChannelHashable() {
        let channel1 = HSLAdjustments.HSLChannel(hue: 30, saturation: 40, luminance: 50)
        let channel2 = HSLAdjustments.HSLChannel(hue: 30, saturation: 40, luminance: 50)

        XCTAssertEqual(channel1.hashValue, channel2.hashValue)
    }

    func testHSLChannelEquatable() {
        let channel1 = HSLAdjustments.HSLChannel(hue: 30, saturation: 40, luminance: 50)
        let channel2 = HSLAdjustments.HSLChannel(hue: 30, saturation: 40, luminance: 50)

        XCTAssertEqual(channel1, channel2)
    }

    func testHSLChannelNotEqual() {
        let channel1 = HSLAdjustments.HSLChannel(hue: 30, saturation: 40, luminance: 50)
        let channel2 = HSLAdjustments.HSLChannel(hue: 30, saturation: 40, luminance: 51)

        XCTAssertNotEqual(channel1, channel2)
    }

    func testHSLAdjustmentsHashable() {
        let hsl1 = HSLAdjustments.identity
        let hsl2 = HSLAdjustments.identity

        XCTAssertEqual(hsl1.hashValue, hsl2.hashValue)
    }

    func testHSLAdjustmentsEquatable() {
        let hsl1 = HSLAdjustments.identity
        let hsl2 = HSLAdjustments.identity

        XCTAssertEqual(hsl1, hsl2)
    }

    func testHSLAdjustmentsNotEqual() {
        let hsl1 = HSLAdjustments.identity
        var hsl2 = HSLAdjustments.identity
        hsl2.red.hue = 10

        XCTAssertNotEqual(hsl1, hsl2)
    }

    // MARK: - Boundary Value Tests

    func testHSLChannelWithMaxHue() {
        let channel = HSLAdjustments.HSLChannel(hue: 180, saturation: 0, luminance: 0)
        XCTAssertEqual(channel.hue, 180)
    }

    func testHSLChannelWithMinHue() {
        let channel = HSLAdjustments.HSLChannel(hue: -180, saturation: 0, luminance: 0)
        XCTAssertEqual(channel.hue, -180)
    }

    func testHSLChannelWithMaxSaturation() {
        let channel = HSLAdjustments.HSLChannel(hue: 0, saturation: 100, luminance: 0)
        XCTAssertEqual(channel.saturation, 100)
    }

    func testHSLChannelWithMinSaturation() {
        let channel = HSLAdjustments.HSLChannel(hue: 0, saturation: -100, luminance: 0)
        XCTAssertEqual(channel.saturation, -100)
    }

    func testHSLChannelWithMaxLuminance() {
        let channel = HSLAdjustments.HSLChannel(hue: 0, saturation: 0, luminance: 100)
        XCTAssertEqual(channel.luminance, 100)
    }

    func testHSLChannelWithMinLuminance() {
        let channel = HSLAdjustments.HSLChannel(hue: 0, saturation: 0, luminance: -100)
        XCTAssertEqual(channel.luminance, -100)
    }

    // MARK: - All Channels Modified Test

    func testAllChannelsModified() {
        var hsl = HSLAdjustments.identity

        for i in 0..<8 {
            hsl[i] = HSLAdjustments.HSLChannel(
                hue: Float(i * 20),
                saturation: Float(i * 10),
                luminance: Float(i * 5)
            )
        }

        XCTAssertFalse(hsl.isIdentity)

        for i in 0..<8 {
            XCTAssertEqual(hsl[i].hue, Float(i * 20))
            XCTAssertEqual(hsl[i].saturation, Float(i * 10))
            XCTAssertEqual(hsl[i].luminance, Float(i * 5))
        }
    }

    // MARK: - Iteration Test

    func testIterateThroughAllChannels() {
        var hsl = HSLAdjustments.identity

        // Set unique values for each channel
        hsl.red = HSLAdjustments.HSLChannel(hue: 1, saturation: 1, luminance: 1)
        hsl.orange = HSLAdjustments.HSLChannel(hue: 2, saturation: 2, luminance: 2)
        hsl.yellow = HSLAdjustments.HSLChannel(hue: 3, saturation: 3, luminance: 3)
        hsl.green = HSLAdjustments.HSLChannel(hue: 4, saturation: 4, luminance: 4)
        hsl.aqua = HSLAdjustments.HSLChannel(hue: 5, saturation: 5, luminance: 5)
        hsl.blue = HSLAdjustments.HSLChannel(hue: 6, saturation: 6, luminance: 6)
        hsl.purple = HSLAdjustments.HSLChannel(hue: 7, saturation: 7, luminance: 7)
        hsl.magenta = HSLAdjustments.HSLChannel(hue: 8, saturation: 8, luminance: 8)

        // Verify iteration matches direct access
        for i in 0..<8 {
            XCTAssertEqual(hsl[i].hue, Float(i + 1))
            XCTAssertEqual(hsl[i].saturation, Float(i + 1))
            XCTAssertEqual(hsl[i].luminance, Float(i + 1))
        }
    }
}
