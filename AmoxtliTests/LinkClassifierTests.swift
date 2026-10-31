import XCTest
@testable import Amoxtli

final class LinkClassifierTests: XCTestCase {
    private func classify(_ string: String) throws -> LinkDestination {
        LinkClassifier.classify(try XCTUnwrap(URL(string: string)))
    }

    private func url(_ string: String) throws -> URL {
        try XCTUnwrap(URL(string: string))
    }

    func testHTTPSGoesToSystem() throws {
        XCTAssertEqual(try classify("https://example.com/a?b=c"), .system(try url("https://example.com/a?b=c")))
    }

    func testHTTPGoesToSystem() throws {
        XCTAssertEqual(try classify("http://example.com"), .system(try url("http://example.com")))
    }

    func testSchemeIsCaseInsensitive() throws {
        XCTAssertEqual(try classify("HTTPS://example.com"), .system(try url("HTTPS://example.com")))
    }

    func testMailtoGoesToSystem() throws {
        XCTAssertEqual(try classify("mailto:hola@example.com"), .system(try url("mailto:hola@example.com")))
    }

    func testAnchor() throws {
        XCTAssertEqual(try classify("#instalacion"), .anchor("instalacion"))
    }

    func testAnchorIsPercentDecoded() throws {
        XCTAssertEqual(try classify("#mi%20t%C3%ADtulo"), .anchor("mi título"))
    }

    func testEmptyAnchorIsUnsupported() throws {
        XCTAssertEqual(try classify("#"), .unsupported(try url("#")))
    }

    func testRelativePathWithFragmentIsUnsupported() throws {
        XCTAssertEqual(try classify("otro.md#x"), .unsupported(try url("otro.md#x")))
    }

    func testRelativePathIsUnsupported() throws {
        XCTAssertEqual(try classify("docs/a.md"), .unsupported(try url("docs/a.md")))
    }

    func testUnknownSchemesAreUnsupported() throws {
        for link in ["ftp://example.com/a", "file:///etc/hosts", "javascript:alert(1)", "amoxtli://x", "tel:+525555"] {
            XCTAssertEqual(try classify(link), .unsupported(try url(link)), link)
        }
    }

    func testInvalidURLsAreUnsupported() throws {
        for link in ["https://", "http:sin-host", "mailto:"] {
            XCTAssertEqual(try classify(link), .unsupported(try url(link)), link)
        }
    }

    func testParserLinksKeepTheirDestination() throws {
        let blocks = try MarkdownParser().parse("[a](#seccion) [b](ftp://example.com)").blocks
        guard case .paragraph(let content) = blocks.first else { return XCTFail("Se esperaba un párrafo") }
        let destinations = content.runs.compactMap(\.link).map(LinkClassifier.classify)
        XCTAssertEqual(destinations, [.anchor("seccion"), .unsupported(try url("ftp://example.com"))])
    }
}
