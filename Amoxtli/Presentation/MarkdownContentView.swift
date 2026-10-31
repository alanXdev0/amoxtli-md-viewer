import SwiftUI

struct MarkdownContentView: View {
    let model: MarkdownModel

    private let readingWidth: CGFloat = 800

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: BlockMetrics.spacing) {
                ForEach(Array(model.blocks.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block)
                }
            }
            .frame(maxWidth: readingWidth, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
        // Temporary guard until the link classifier arrives: only web and mail links reach the system.
        .environment(\.openURL, OpenURLAction { url in
            ["http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "") ? .systemAction : .discarded
        })
    }
}

#Preview {
    MarkdownContentView(model: MarkdownModel(blocks: [
        .heading(level: 1, content: InlineText(runs: [InlineRun(text: "Amoxtli")])),
        .paragraph(InlineText(runs: [InlineRun(text: "Visor de "), InlineRun(text: "Markdown", style: .strong)])),
        .thematicBreak,
        .codeBlock(languageHint: "swift", code: "let visor = \"Amoxtli\""),
    ]))
}
