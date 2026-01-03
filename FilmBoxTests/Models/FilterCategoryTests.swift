import XCTest
@testable import FilmBox

/// Tests for FilterCategory enum
final class FilterCategoryTests: XCTestCase {

    // MARK: - Cases Tests

    /// Test: All expected cases exist
    func testAllCasesExist() {
        let allCases = FilterCategory.allCases

        XCTAssertTrue(allCases.contains(.favorites))
        XCTAssertTrue(allCases.contains(.custom))
        XCTAssertTrue(allCases.contains(.fujiRecipes))
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.cool))
        XCTAssertTrue(allCases.contains(.warm))
        XCTAssertTrue(allCases.contains(.pro))
        XCTAssertTrue(allCases.contains(.portrait))
        XCTAssertTrue(allCases.contains(.urban))
        XCTAssertTrue(allCases.contains(.film))
        XCTAssertTrue(allCases.contains(.bw))
        XCTAssertTrue(allCases.contains(.vintage))
        XCTAssertTrue(allCases.contains(.creative))
    }

    /// Test: Total number of categories
    func testCategoriesCount() {
        XCTAssertEqual(FilterCategory.allCases.count, 13)
    }

    // MARK: - Raw Value Tests

    /// Test: Raw values are correct
    func testRawValues() {
        XCTAssertEqual(FilterCategory.favorites.rawValue, "favourites")
        XCTAssertEqual(FilterCategory.custom.rawValue, "my")
        XCTAssertEqual(FilterCategory.fujiRecipes.rawValue, "fuji")
        XCTAssertEqual(FilterCategory.all.rawValue, "filters")
        XCTAssertEqual(FilterCategory.cool.rawValue, "cool")
        XCTAssertEqual(FilterCategory.warm.rawValue, "warm")
        XCTAssertEqual(FilterCategory.pro.rawValue, "pro")
        XCTAssertEqual(FilterCategory.portrait.rawValue, "portrait")
        XCTAssertEqual(FilterCategory.urban.rawValue, "urban")
        XCTAssertEqual(FilterCategory.film.rawValue, "film")
        XCTAssertEqual(FilterCategory.bw.rawValue, "b&w")
        XCTAssertEqual(FilterCategory.vintage.rawValue, "vintage")
        XCTAssertEqual(FilterCategory.creative.rawValue, "creative")
    }

    /// Test: Can initialize from raw value
    func testInitFromRawValue() {
        XCTAssertEqual(FilterCategory(rawValue: "favourites"), .favorites)
        XCTAssertEqual(FilterCategory(rawValue: "my"), .custom)
        XCTAssertEqual(FilterCategory(rawValue: "b&w"), .bw)
        XCTAssertNil(FilterCategory(rawValue: "invalid"))
    }

    // MARK: - Display Name Tests

    /// Test: All categories have non-empty display names
    func testAllCategoriesHaveDisplayNames() {
        for category in FilterCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "\(category) should have a display name")
        }
    }

    /// Test: Fuji recipes has custom display name
    func testFujiRecipesDisplayName() {
        XCTAssertEqual(FilterCategory.fujiRecipes.displayName, "fuji recipes")
    }

    /// Test: Other categories use raw value as display name
    func testOtherCategoriesUseRawValueAsDisplayName() {
        XCTAssertEqual(FilterCategory.cool.displayName, "cool")
        XCTAssertEqual(FilterCategory.warm.displayName, "warm")
        XCTAssertEqual(FilterCategory.film.displayName, "film")
    }

    // MARK: - Icon Name Tests

    /// Test: All categories have non-empty icons
    func testAllCategoriesHaveIcons() {
        for category in FilterCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "\(category) should have an icon")
        }
    }

    /// Test: Icon names are SF Symbols format
    func testIconNamesAreSFSymbols() {
        // SF Symbols don't have file extensions
        for category in FilterCategory.allCases {
            XCTAssertFalse(category.iconName.contains(".png"), "Icon should be SF Symbol, not PNG")
            XCTAssertFalse(category.iconName.contains(".svg"), "Icon should be SF Symbol, not SVG")
        }
    }

    /// Test: Specific icon names
    func testSpecificIconNames() {
        XCTAssertEqual(FilterCategory.favorites.iconName, "star.fill")
        XCTAssertEqual(FilterCategory.custom.iconName, "person.crop.circle")
        XCTAssertEqual(FilterCategory.all.iconName, "square.grid.2x2")
        XCTAssertEqual(FilterCategory.cool.iconName, "snowflake")
        XCTAssertEqual(FilterCategory.warm.iconName, "sun.max")
        XCTAssertEqual(FilterCategory.pro.iconName, "camera.aperture")
        XCTAssertEqual(FilterCategory.film.iconName, "film")
        XCTAssertEqual(FilterCategory.bw.iconName, "circle.lefthalf.filled")
        XCTAssertEqual(FilterCategory.vintage.iconName, "clock.arrow.circlepath")
        XCTAssertEqual(FilterCategory.creative.iconName, "wand.and.stars")
        XCTAssertEqual(FilterCategory.fujiRecipes.iconName, "camera")
    }

    // MARK: - Show As Icon Tests

    /// Test: Only favorites shows as icon
    func testOnlyFavoritesShowsAsIcon() {
        XCTAssertTrue(FilterCategory.favorites.showAsIcon)

        for category in FilterCategory.allCases where category != .favorites {
            XCTAssertFalse(category.showAsIcon, "\(category) should not show as icon")
        }
    }

    // MARK: - Codable Tests

    /// Test: Category encodes and decodes correctly
    func testCodableRoundTrip() throws {
        for category in FilterCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(FilterCategory.self, from: data)

            XCTAssertEqual(category, decoded, "\(category) should encode/decode correctly")
        }
    }

    /// Test: Decoding from raw string works
    func testDecodingFromRawString() throws {
        let json = "\"cool\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(FilterCategory.self, from: data)

        XCTAssertEqual(decoded, .cool)
    }

    // MARK: - Hashable Tests

    /// Test: Categories can be used in Set
    func testCategoriesInSet() {
        var set: Set<FilterCategory> = [.cool, .warm, .cool]
        XCTAssertEqual(set.count, 2)

        set.insert(.film)
        XCTAssertEqual(set.count, 3)
    }

    /// Test: Categories can be used as Dictionary keys
    func testCategoriesAsDictionaryKeys() {
        var dict: [FilterCategory: Int] = [:]
        dict[.cool] = 1
        dict[.warm] = 2
        dict[.cool] = 3 // Override

        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict[.cool], 3)
        XCTAssertEqual(dict[.warm], 2)
    }
}
