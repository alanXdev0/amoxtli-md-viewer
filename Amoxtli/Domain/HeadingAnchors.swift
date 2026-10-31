import Foundation

/// Maps GitHub-style heading slugs to the top-level block that contains each heading.
nonisolated struct HeadingAnchors: Equatable, Sendable {
    private var blockIndexBySlug: [String: Int] = [:]

    init(blocks: [MarkdownBlock] = []) {
        for (index, block) in blocks.enumerated() {
            for title in Self.headingTitles(in: block) {
                blockIndexBySlug[uniqueSlug(for: title)] = index
            }
        }
    }

    func blockIndex(forAnchor anchor: String) -> Int? {
        blockIndexBySlug[anchor] ?? blockIndexBySlug[anchor.lowercased()]
    }

    static func slug(for title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let characters = trimmed.compactMap { character -> Character? in
            if character.isWhitespace || character == "-" { return "-" }
            return character.isLetter || character.isNumber || character == "_" ? character : nil
        }
        return String(characters)
    }

    private func uniqueSlug(for title: String) -> String {
        let base = Self.slug(for: title)
        var candidate = base
        var suffix = 0
        while blockIndexBySlug[candidate] != nil {
            suffix += 1
            candidate = "\(base)-\(suffix)"
        }
        return candidate
    }

    private static func headingTitles(in block: MarkdownBlock) -> [String] {
        switch block {
        case .heading(_, let content):
            [content.plainText]
        case .blockQuote(let blocks):
            blocks.flatMap(headingTitles)
        case .orderedList(let items), .unorderedList(let items):
            items.flatMap(\.blocks).flatMap(headingTitles)
        default:
            []
        }
    }
}
