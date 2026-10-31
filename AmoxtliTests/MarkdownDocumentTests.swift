import XCTest
@testable import Amoxtli

final class MarkdownDocumentTests: XCTestCase {
    func testValidUTF8IsDecoded() {
        let document = MarkdownDocument(data: Data("# Título ñ 🌮".utf8))
        XCTAssertEqual(document.content, .success("# Título ñ 🌮"))
    }

    func testByteOrderMarkIsRemoved() {
        let document = MarkdownDocument(data: Data("\u{FEFF}# Título".utf8))
        XCTAssertEqual(document.content, .success("# Título"))
    }

    func testEmptyDataIsReportedAsEmpty() {
        XCTAssertEqual(MarkdownDocument(data: Data()).content, .failure(.empty))
    }

    func testWhitespaceOnlyIsReportedAsEmpty() {
        XCTAssertEqual(MarkdownDocument(data: Data(" \n\t\n".utf8)).content, .failure(.empty))
    }

    func testInvalidBytesAreReportedAsInvalidEncoding() {
        let document = MarkdownDocument(data: Data([0x23, 0x20, 0xFF, 0xFE, 0xC0]))
        XCTAssertEqual(document.content, .failure(.invalidEncoding))
    }

    func testMissingContentsAreReportedAsUnreadable() {
        XCTAssertEqual(MarkdownDocument(data: nil).content, .failure(.unreadable))
    }

    func testLargeFileIsDecodedCompletely() {
        let line = "Línea de un archivo grande con **texto**.\n"
        let source = String(repeating: line, count: 200_000)
        let document = MarkdownDocument(data: Data(source.utf8))
        XCTAssertGreaterThan(source.utf8.count, 8_000_000)
        XCTAssertEqual(document.content, .success(source))
    }
}
