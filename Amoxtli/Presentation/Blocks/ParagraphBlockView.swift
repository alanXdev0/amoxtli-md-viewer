import SwiftUI

struct ParagraphBlockView: View {
    let content: InlineText

    var body: some View {
        MarkdownText(content: content, style: .body)
            .alignedToFirstBaseline()
    }
}
