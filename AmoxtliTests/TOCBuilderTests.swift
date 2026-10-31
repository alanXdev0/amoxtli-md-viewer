import XCTest
@testable import Amoxtli

final class TOCBuilderTests: XCTestCase {
    private func entries(_ source: String) throws -> [TOCEntry] {
        TOCBuilder.entries(for: try MarkdownParser().parse(source).blocks)
    }

    func testSlugFollowsGitHubStyle() {
        XCTAssertEqual(TOCBuilder.slug(for: "  Mi Título: ¡uno_2! "), "mi-título-uno_2")
    }

    func testKeepsEveryLevelInDocumentOrder() throws {
        let entries = try entries("# a\n\n## b\n\n### c\n\n#### d\n\n##### e\n\n###### f\n\n## g")
        XCTAssertEqual(entries.map(\.level), [1, 2, 3, 4, 5, 6, 2])
        XCTAssertEqual(entries.map(\.title), ["a", "b", "c", "d", "e", "f", "g"])
    }

    func testDuplicateTitlesGetUniqueIDs() throws {
        let entries = try entries("# Notas\n\n## Notas\n\n# Notas-1\n\n### Notas")
        XCTAssertEqual(entries.map(\.id), ["notas", "notas-1", "notas-1-1", "notas-2"])
        XCTAssertEqual(entries.map(\.title), ["Notas", "Notas", "Notas-1", "Notas"])
    }

    func testDocumentWithoutHeadingsHasNoEntries() throws {
        XCTAssertEqual(try entries("texto\n\n- lista\n\n> cita"), [])
        XCTAssertEqual(TOCBuilder.entries(for: []), [])
    }

    func testEntryPointsToItsTopLevelBlock() throws {
        let entries = try entries("texto\n\n# Uno\n\ntexto\n\n## Dos")
        XCTAssertEqual(entries.map(\.blockIndex), [1, 3])
    }

    func testFindsHeadingsInsideQuotesAndLists() throws {
        let entries = try entries("> ## Citado\n\n- ### Listado")
        XCTAssertEqual(entries.map(\.title), ["Citado", "Listado"])
        XCTAssertEqual(entries.map(\.blockIndex), [0, 1])
    }

    func testTitleIsPlainTextWithoutInlineMarkup() throws {
        let entries = try entries("# Un **título** con `código` y [link](https://example.com)")
        XCTAssertEqual(entries.first?.title, "Un título con código y link")
    }

    func testHeadingWithoutTextIsSkipped() {
        let blocks: [MarkdownBlock] = [.heading(level: 1, content: InlineText(runs: [InlineRun(text: "  ")]))]
        XCTAssertEqual(TOCBuilder.entries(for: blocks), [])
    }
}
