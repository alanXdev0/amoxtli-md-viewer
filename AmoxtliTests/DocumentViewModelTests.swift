import XCTest
@testable import Amoxtli

@MainActor
final class DocumentViewModelTests: XCTestCase {
    private struct FailingParser: MarkdownParsing {
        struct Failure: Error {}

        func parse(_ source: String) throws -> MarkdownModel {
            throw Failure()
        }
    }

    func testStartsLoading() {
        XCTAssertEqual(DocumentViewModel().state, .loading)
    }

    func testValidContentLoadsModel() async throws {
        let viewModel = DocumentViewModel()
        await viewModel.load(.success("párrafo"))
        let expected = try MarkdownParser().parse("párrafo")
        XCTAssertEqual(viewModel.state, .loaded(expected))
    }

    func testDocumentErrorIsExposed() async {
        let viewModel = DocumentViewModel()
        await viewModel.load(.failure(.invalidEncoding))
        XCTAssertEqual(viewModel.state, .failed(.invalidEncoding))
    }

    func testParserFailureIsExposed() async {
        let viewModel = DocumentViewModel(parser: FailingParser())
        await viewModel.load(.success("párrafo"))
        XCTAssertEqual(viewModel.state, .failed(.unparsable))
    }

    func testReloadRecoversFromFailure() async {
        let viewModel = DocumentViewModel()
        await viewModel.load(.failure(.empty))
        await viewModel.load(.success("párrafo"))
        guard case .loaded = viewModel.state else {
            return XCTFail("Se esperaba el estado loaded, no \(viewModel.state)")
        }
    }
}
