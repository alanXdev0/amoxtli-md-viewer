import Observation

@Observable
final class DocumentViewModel {
    enum State: Equatable {
        case loading
        case loaded(MarkdownModel)
        case failed(MarkdownDocumentError)
    }

    private(set) var state: State = .loading
    private let parser: any MarkdownParsing

    init(parser: any MarkdownParsing = MarkdownParser()) {
        self.parser = parser
    }

    func load(_ content: Result<String, MarkdownDocumentError>) async {
        state = .loading
        switch content {
        case .success(let source):
            let result = await Self.parse(source, with: parser)
            guard !Task.isCancelled else { return }
            state = result
        case .failure(let error):
            state = .failed(error)
        }
    }

    @concurrent
    private static func parse(_ source: String, with parser: any MarkdownParsing) async -> State {
        do {
            return .loaded(try parser.parse(source))
        } catch {
            return .failed(.unparsable)
        }
    }
}
