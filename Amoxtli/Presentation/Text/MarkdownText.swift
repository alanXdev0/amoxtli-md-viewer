import SwiftUI

extension EnvironmentValues {
    @Entry var markdownTextColor: NSColor = .labelColor
}

/// Selectable text for every text block, backed by `MarkdownTextView`.
struct MarkdownText: NSViewRepresentable {
    let content: InlineText
    let style: MarkdownTextStyle
    var wrapsLines = true

    @Environment(LinkInteractionViewModel.self) private var links: LinkInteractionViewModel?
    @Environment(\.markdownTextColor) private var color
    @Environment(\.colorSchemeContrast) private var contrast

    func makeNSView(context: Context) -> MarkdownTextView {
        MarkdownTextView.make()
    }

    func updateNSView(_ view: MarkdownTextView, context: Context) {
        view.links = links
        view.wrapsLines = wrapsLines
        view.setLinksUnderlined(contrast == .increased)
        view.setContent(content.attributedString(style: style, color: color))
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: MarkdownTextView, context: Context) -> CGSize? {
        let size = nsView.fittingSize(forProposedWidth: proposal.width)
        // Filling the width lets selections start from the empty area beside short lines.
        if wrapsLines, let width = proposal.width, width.isFinite {
            return CGSize(width: width, height: size.height)
        }
        return size
    }
}

extension MarkdownText {
    /// Aligns the first line with SwiftUI text, such as list markers.
    func alignedToFirstBaseline() -> some View {
        let ascender = style.font.ascender
        return alignmentGuide(.firstTextBaseline) { _ in ascender }
    }
}
