import SwiftUI

struct ParagraphBlockView: View {
    let content: InlineText

    var body: some View {
        Text(content.attributedString)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}
