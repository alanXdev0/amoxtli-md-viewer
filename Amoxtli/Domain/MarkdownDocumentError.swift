nonisolated enum MarkdownDocumentError: Error, Hashable, Sendable {
    case empty
    case invalidEncoding
    case unreadable
    case unparsable
}
