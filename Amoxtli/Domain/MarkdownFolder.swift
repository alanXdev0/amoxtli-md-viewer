import Foundation

nonisolated struct MarkdownFile: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String

    var id: URL { url }
}

/// The Markdown files directly inside one folder of the tree.
nonisolated struct MarkdownFolderSection: Identifiable, Equatable, Sendable {
    /// Path relative to the opened folder, such as `docs/api`. Empty for the opened folder itself.
    let relativePath: String
    let files: [MarkdownFile]

    var id: String { relativePath }
}

nonisolated enum FolderError: Error, Equatable, Sendable {
    case staleBookmark
    case unreadable
}
