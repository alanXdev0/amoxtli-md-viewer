import SwiftUI

@main
struct AmoxtliApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            DocumentView(document: file.document)
        }
        .defaultSize(width: 900, height: 700)
    }
}
