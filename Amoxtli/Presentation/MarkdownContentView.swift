import SwiftUI

struct MarkdownContentView: View {
    let model: MarkdownModel
    let links: LinkInteractionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let readingWidth: CGFloat = 800

    var body: some View {
        ScrollViewReader { proxy in
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
            .onChange(of: links.scrollRequest) { _, request in
                if let request {
                    scroll(to: request.blockIndex, with: proxy)
                }
            }
        }
        .overlay { LinkStatusOverlay() }
        .environment(links)
    }

    private func scroll(to blockIndex: Int, with proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(blockIndex, anchor: .top)
        } else {
            withAnimation { proxy.scrollTo(blockIndex, anchor: .top) }
        }
    }
}

#Preview {
    MarkdownContentView(
        model: MarkdownModel(blocks: [
            .heading(level: 1, content: InlineText(runs: [InlineRun(text: "Amoxtli")])),
            .paragraph(InlineText(runs: [InlineRun(text: "Visor de "), InlineRun(text: "Markdown", style: .strong)])),
            .thematicBreak,
            .codeBlock(languageHint: "swift", code: "let visor = \"Amoxtli\""),
        ]),
        links: LinkInteractionViewModel()
    )
}
