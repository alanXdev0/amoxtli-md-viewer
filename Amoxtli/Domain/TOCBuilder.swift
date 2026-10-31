import Foundation

nonisolated struct TOCEntry: Identifiable, Equatable, Sendable {
    /// GitHub-style slug, unique within the document. It is also the heading's `#anchor`.
    let id: String
    let title: String
    let level: Int
    /// Top-level block that contains the heading, which is what the content view can scroll to.
    let blockIndex: Int
}

nonisolated enum TOCBuilder {
    static func entries(for blocks: [MarkdownBlock]) -> [TOCEntry] {
        var usedSlugs = Set<String>()
        return blocks.enumerated().flatMap { blockIndex, block in
            headings(in: block).compactMap { level, title in
                guard title.contains(where: { !$0.isWhitespace }) else { return nil }
                let id = uniqueSlug(for: title, usedSlugs: &usedSlugs)
                return TOCEntry(id: id, title: title, level: level, blockIndex: blockIndex)
            }
        }
    }

    static func slug(for title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let characters = trimmed.compactMap { character -> Character? in
            if character.isWhitespace || character == "-" { return "-" }
            return character.isLetter || character.isNumber || character == "_" ? character : nil
        }
        return String(characters)
    }

    private static func uniqueSlug(for title: String, usedSlugs: inout Set<String>) -> String {
        let base = slug(for: title)
        var candidate = base
        var suffix = 0
        while !usedSlugs.insert(candidate).inserted {
            suffix += 1
            candidate = "\(base)-\(suffix)"
        }
        return candidate
    }

    private static func headings(in block: MarkdownBlock) -> [(level: Int, title: String)] {
        switch block {
        case .heading(let level, let content):
            [(level, content.plainText)]
        case .blockQuote(let blocks):
            blocks.flatMap(headings)
        case .orderedList(let items), .unorderedList(let items):
            items.flatMap(\.blocks).flatMap(headings)
        default:
            []
        }
    }
}
