import SwiftUI

enum BlockMetrics {
    static let spacing: CGFloat = 16
    static let nestedSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 8
}

struct BlockView: View {
    let block: MarkdownBlock

    var body: some View {
        switch block {
        case .heading(let level, let content):
            HeadingBlockView(level: level, content: content)
        case .paragraph(let content):
            ParagraphBlockView(content: content)
        case .orderedList(let items):
            ListBlockView(items: items, marker: .ordered)
        case .unorderedList(let items):
            ListBlockView(items: items, marker: .unordered)
        case .blockQuote(let blocks):
            BlockQuoteBlockView(blocks: blocks)
        case .codeBlock(let languageHint, let code):
            CodeBlockView(languageHint: languageHint, code: code)
        case .table(let table):
            TableBlockView(table: table)
        case .image(let image):
            ImageBlockView(image: image)
        case .thematicBreak:
            Divider()
        }
    }
}

/// Non-lazy stack for blocks nested inside a list item or a quote.
struct NestedBlocksView: View {
    let blocks: [MarkdownBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: BlockMetrics.nestedSpacing) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                BlockView(block: block)
            }
        }
    }
}
