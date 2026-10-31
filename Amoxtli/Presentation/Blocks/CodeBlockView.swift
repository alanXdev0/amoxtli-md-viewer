import SwiftUI

struct CodeBlockView: View {
    let languageHint: String?
    let code: String

    var body: some View {
        ScrollView(.horizontal) {
            Text(code)
                .font(.system(.body, design: .monospaced))
                .fixedSize()
                .textSelection(.enabled)
                .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: .rect(cornerRadius: BlockMetrics.cornerRadius))
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(code)
    }

    private var accessibilityTitle: Text {
        if let languageHint {
            Text("Bloque de código en \(languageHint)")
        } else {
            Text("Bloque de código")
        }
    }
}
