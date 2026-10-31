import SwiftUI
import UniformTypeIdentifiers

/// Read-only document. Decoding failures are stored instead of thrown so the window can
/// explain the problem, rather than the system refusing to open the file with a generic alert.
nonisolated struct MarkdownDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.markdown]

    let content: Result<String, MarkdownDocumentError>

    init(data: Data?) {
        content = Self.decode(data)
    }

    init(configuration: ReadConfiguration) {
        self.init(data: configuration.file.regularFileContents)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }

    private static func decode(_ data: Data?) -> Result<String, MarkdownDocumentError> {
        guard let data else { return .failure(.unreadable) }
        guard let text = String(data: data, encoding: .utf8) else { return .failure(.invalidEncoding) }
        let source = removingByteOrderMark(from: text)
        let hasContent = source.contains { !$0.isWhitespace }
        return hasContent ? .success(source) : .failure(.empty)
    }

    private static func removingByteOrderMark(from text: String) -> String {
        text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
    }
}
