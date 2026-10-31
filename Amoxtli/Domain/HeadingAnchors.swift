import Foundation

/// Maps heading anchors to the top-level block that contains each heading.
nonisolated struct HeadingAnchors: Equatable, Sendable {
    private var blockIndexBySlug: [String: Int] = [:]

    init(entries: [TOCEntry] = []) {
        for entry in entries {
            blockIndexBySlug[entry.id] = entry.blockIndex
        }
    }

    func blockIndex(forAnchor anchor: String) -> Int? {
        blockIndexBySlug[anchor] ?? blockIndexBySlug[anchor.lowercased()]
    }
}
