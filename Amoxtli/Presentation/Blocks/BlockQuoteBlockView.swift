import SwiftUI

struct BlockQuoteBlockView: View {
    let blocks: [MarkdownBlock]

    var body: some View {
        NestedBlocksView(blocks: blocks)
            .foregroundStyle(.secondary)
            .environment(\.markdownTextColor, .secondaryLabelColor)
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(.separator)
                    .frame(width: 3)
            }
    }
}
