import XCTest
@testable import Amoxtli

final class HeadingAnchorsTests: XCTestCase {
    private func anchors(_ source: String) throws -> HeadingAnchors {
        HeadingAnchors(blocks: try MarkdownParser().parse(source).blocks)
    }

    func testSlugFollowsGitHubStyle() {
        XCTAssertEqual(HeadingAnchors.slug(for: "  Mi Título: ¡uno_2! "), "mi-título-uno_2")
    }

    func testAnchorResolvesToBlockIndex() throws {
        let anchors = try anchors("# Uno\n\ntexto\n\n## Dos palabras")
        XCTAssertEqual(anchors.blockIndex(forAnchor: "uno"), 0)
        XCTAssertEqual(anchors.blockIndex(forAnchor: "dos-palabras"), 2)
    }

    func testAnchorLookupIsCaseInsensitive() throws {
        XCTAssertEqual(try anchors("# Uno").blockIndex(forAnchor: "UNO"), 0)
    }

    func testRepeatedTitlesGetUniqueAnchors() throws {
        let anchors = try anchors("# A\n\n# A\n\n# A-1\n\n# A")
        XCTAssertEqual(anchors.blockIndex(forAnchor: "a"), 0)
        XCTAssertEqual(anchors.blockIndex(forAnchor: "a-1"), 1)
        XCTAssertEqual(anchors.blockIndex(forAnchor: "a-1-1"), 2)
        XCTAssertEqual(anchors.blockIndex(forAnchor: "a-2"), 3)
    }

    func testNestedHeadingResolvesToContainingBlock() throws {
        let anchors = try anchors("texto\n\n> ## Citado\n\n- ### Listado")
        XCTAssertEqual(anchors.blockIndex(forAnchor: "citado"), 1)
        XCTAssertEqual(anchors.blockIndex(forAnchor: "listado"), 2)
    }

    func testUnknownAnchorIsNil() throws {
        XCTAssertNil(try anchors("# Uno").blockIndex(forAnchor: "dos"))
    }
}
