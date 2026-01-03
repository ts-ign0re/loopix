import XCTest
@testable import FilmBox

/// Tests for ToolDefinition
final class ToolDefinitionTests: XCTestCase {

    // MARK: - All Tools Tests

    /// Test: All tools list is not empty
    func testAllToolsNotEmpty() {
        XCTAssertFalse(ToolDefinition.allTools.isEmpty)
    }

    /// Test: All tools count matches expected
    func testAllToolsCount() {
        XCTAssertEqual(ToolDefinition.allTools.count, 18)
    }

    /// Test: All tools have unique IDs
    func testAllToolsHaveUniqueIds() {
        let ids = ToolDefinition.allTools.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All tool IDs should be unique")
    }

    /// Test: All tools have non-empty names
    func testAllToolsHaveNames() {
        for tool in ToolDefinition.allTools {
            XCTAssertFalse(tool.name.isEmpty, "Tool \(tool.id) should have a name")
        }
    }

    /// Test: All tools have icons
    func testAllToolsHaveIcons() {
        for tool in ToolDefinition.allTools {
            XCTAssertFalse(tool.icon.isEmpty, "Tool \(tool.id) should have an icon")
        }
    }

    // MARK: - Category Tests

    /// Test: Essential category returns expected tools
    func testEssentialCategoryTools() {
        let tools = ToolDefinition.tools(for: .essential)

        XCTAssertEqual(tools.count, 5)
        XCTAssertTrue(tools.contains(.exposure))
        XCTAssertTrue(tools.contains(.contrast))
        XCTAssertTrue(tools.contains(.saturation))
        XCTAssertTrue(tools.contains(.temperature))
        XCTAssertTrue(tools.contains(.sharpen))
    }

    /// Test: Light category returns light tools
    func testLightCategoryTools() {
        let tools = ToolDefinition.tools(for: .light)

        XCTAssertEqual(tools.count, 6)
        XCTAssertTrue(tools.contains(.exposure))
        XCTAssertTrue(tools.contains(.contrast))
        XCTAssertTrue(tools.contains(.highlights))
        XCTAssertTrue(tools.contains(.shadows))
        XCTAssertTrue(tools.contains(.whites))
        XCTAssertTrue(tools.contains(.blacks))
    }

    /// Test: Color category returns color tools
    func testColorCategoryTools() {
        let tools = ToolDefinition.tools(for: .color)

        XCTAssertEqual(tools.count, 5)
        XCTAssertTrue(tools.contains(.saturation))
        XCTAssertTrue(tools.contains(.vibrance))
        XCTAssertTrue(tools.contains(.temperature))
        XCTAssertTrue(tools.contains(.tint))
        XCTAssertTrue(tools.contains(.skinTone))
    }

    /// Test: Effects category returns effects tools
    func testEffectsCategoryTools() {
        let tools = ToolDefinition.tools(for: .effects)

        XCTAssertEqual(tools.count, 7)
        XCTAssertTrue(tools.contains(.sharpen))
        XCTAssertTrue(tools.contains(.clarity))
        XCTAssertTrue(tools.contains(.bloom))
        XCTAssertTrue(tools.contains(.halation))
        XCTAssertTrue(tools.contains(.grain))
        XCTAssertTrue(tools.contains(.vignette))
        XCTAssertTrue(tools.contains(.fade))
    }

    /// Test: All category returns all tools
    func testAllCategoryReturnsAllTools() {
        let tools = ToolDefinition.tools(for: .all)
        XCTAssertEqual(tools.count, ToolDefinition.allTools.count)
    }

    // MARK: - Tool Category Enum Tests

    /// Test: Tool category cases
    func testToolCategoryCases() {
        let cases = ToolDefinition.ToolCategory.allCases
        XCTAssertEqual(cases.count, 5)
        XCTAssertTrue(cases.contains(.all))
        XCTAssertTrue(cases.contains(.essential))
        XCTAssertTrue(cases.contains(.light))
        XCTAssertTrue(cases.contains(.color))
        XCTAssertTrue(cases.contains(.effects))
    }

    /// Test: Tool category raw values
    func testToolCategoryRawValues() {
        XCTAssertEqual(ToolDefinition.ToolCategory.all.rawValue, "ALL TOOLS")
        XCTAssertEqual(ToolDefinition.ToolCategory.essential.rawValue, "ESSENTIAL")
        XCTAssertEqual(ToolDefinition.ToolCategory.light.rawValue, "LIGHT")
        XCTAssertEqual(ToolDefinition.ToolCategory.color.rawValue, "COLOR")
        XCTAssertEqual(ToolDefinition.ToolCategory.effects.rawValue, "EFFECTS")
    }

    // MARK: - Individual Tool Tests

    /// Test: Exposure tool properties
    func testExposureTool() {
        let tool = ToolDefinition.exposure

        XCTAssertEqual(tool.id, "exposure")
        XCTAssertEqual(tool.name, "Exposure")
        XCTAssertEqual(tool.icon, "sun.max")
        XCTAssertEqual(tool.category, .light)
        XCTAssertEqual(tool.parameterType, .exposure)
        XCTAssertEqual(tool.range, -2...2)
        XCTAssertEqual(tool.defaultValue, 0)
        XCTAssertFalse(tool.isNew)
    }

    /// Test: Contrast tool properties
    func testContrastTool() {
        let tool = ToolDefinition.contrast

        XCTAssertEqual(tool.id, "contrast")
        XCTAssertEqual(tool.name, "Contrast")
        XCTAssertEqual(tool.category, .light)
        XCTAssertEqual(tool.parameterType, .contrast)
        XCTAssertEqual(tool.range, -100...100)
    }

    /// Test: Saturation tool properties
    func testSaturationTool() {
        let tool = ToolDefinition.saturation

        XCTAssertEqual(tool.id, "saturation")
        XCTAssertEqual(tool.name, "Saturation")
        XCTAssertEqual(tool.category, .color)
        XCTAssertEqual(tool.parameterType, .saturation)
        XCTAssertEqual(tool.range, -100...100)
    }

    /// Test: Grain tool properties
    func testGrainTool() {
        let tool = ToolDefinition.grain

        XCTAssertEqual(tool.id, "grain")
        XCTAssertEqual(tool.name, "Grain")
        XCTAssertEqual(tool.category, .effects)
        XCTAssertEqual(tool.parameterType, .grain)
        XCTAssertEqual(tool.range, 0...100) // Grain only goes positive
    }

    /// Test: Sharpen tool properties
    func testSharpenTool() {
        let tool = ToolDefinition.sharpen

        XCTAssertEqual(tool.id, "sharpen")
        XCTAssertEqual(tool.range, 0...100) // Sharpen only goes positive
    }

    /// Test: Vignette tool properties
    func testVignetteTool() {
        let tool = ToolDefinition.vignette

        XCTAssertEqual(tool.id, "vignette")
        XCTAssertEqual(tool.range, -100...100) // Vignette can be negative
    }

    // MARK: - Range Tests

    /// Test: All light tools have -100...100 range (except exposure)
    func testLightToolRanges() {
        let lightTools = ToolDefinition.tools(for: .light)

        for tool in lightTools {
            if tool.id == "exposure" {
                XCTAssertEqual(tool.range, -2...2)
            } else {
                XCTAssertEqual(tool.range, -100...100, "Light tool \(tool.id) should have -100...100 range")
            }
        }
    }

    /// Test: All color tools have -100...100 range
    func testColorToolRanges() {
        let colorTools = ToolDefinition.tools(for: .color)

        for tool in colorTools {
            XCTAssertEqual(tool.range, -100...100, "Color tool \(tool.id) should have -100...100 range")
        }
    }

    /// Test: All tools have zero default value
    func testAllToolsHaveZeroDefault() {
        for tool in ToolDefinition.allTools {
            XCTAssertEqual(tool.defaultValue, 0, "Tool \(tool.id) should have 0 as default")
        }
    }

    // MARK: - Hashable Tests

    /// Test: Same tools are equal
    func testToolEquality() {
        XCTAssertEqual(ToolDefinition.exposure, ToolDefinition.exposure)
        XCTAssertNotEqual(ToolDefinition.exposure, ToolDefinition.contrast)
    }

    /// Test: Tools hash by ID
    func testToolHashing() {
        let tool1 = ToolDefinition.exposure
        let tool2 = ToolDefinition.exposure

        XCTAssertEqual(tool1.hashValue, tool2.hashValue)
    }

    /// Test: Tools can be used in Sets
    func testToolsInSet() {
        var toolSet: Set<ToolDefinition> = []

        toolSet.insert(.exposure)
        toolSet.insert(.contrast)
        toolSet.insert(.exposure) // Duplicate

        XCTAssertEqual(toolSet.count, 2)
    }

    // MARK: - Parameter Type Tests

    /// Test: Parameter types cover all categories
    func testParameterTypesCoverAllCategories() {
        // Light parameters
        XCTAssertEqual(ToolDefinition.exposure.parameterType, .exposure)
        XCTAssertEqual(ToolDefinition.contrast.parameterType, .contrast)
        XCTAssertEqual(ToolDefinition.highlights.parameterType, .highlights)
        XCTAssertEqual(ToolDefinition.shadows.parameterType, .shadows)
        XCTAssertEqual(ToolDefinition.whites.parameterType, .whites)
        XCTAssertEqual(ToolDefinition.blacks.parameterType, .blacks)

        // Color parameters
        XCTAssertEqual(ToolDefinition.saturation.parameterType, .saturation)
        XCTAssertEqual(ToolDefinition.vibrance.parameterType, .vibrance)
        XCTAssertEqual(ToolDefinition.temperature.parameterType, .temperature)
        XCTAssertEqual(ToolDefinition.tint.parameterType, .tint)
        XCTAssertEqual(ToolDefinition.skinTone.parameterType, .skinToneHue)

        // Effects parameters
        XCTAssertEqual(ToolDefinition.clarity.parameterType, .clarity)
        XCTAssertEqual(ToolDefinition.sharpen.parameterType, .sharpen)
        XCTAssertEqual(ToolDefinition.grain.parameterType, .grain)
        XCTAssertEqual(ToolDefinition.vignette.parameterType, .vignette)
        XCTAssertEqual(ToolDefinition.fade.parameterType, .fade)
        XCTAssertEqual(ToolDefinition.bloom.parameterType, .bloom)
        XCTAssertEqual(ToolDefinition.halation.parameterType, .halation)
    }

    // MARK: - Identifiable Tests

    /// Test: Tool ID is used for Identifiable
    func testToolIdentifiable() {
        let tool = ToolDefinition.exposure
        XCTAssertEqual(tool.id, "exposure")
    }
}
