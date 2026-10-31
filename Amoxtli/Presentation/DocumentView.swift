import SwiftUI

struct DocumentView: View {
    let document: MarkdownDocument
    @State private var viewModel = DocumentViewModel()

    var body: some View {
        MarkdownReaderView(viewModel: viewModel)
            .task(id: document.content) {
                await viewModel.load(document.content)
            }
    }
}

#Preview {
    DocumentView(document: MarkdownDocument(data: Data("# Amoxtli\n\nVisor de *Markdown*.".utf8)))
}
