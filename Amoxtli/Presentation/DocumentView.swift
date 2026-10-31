import SwiftUI

struct DocumentView: View {
    let document: MarkdownDocument
    var fileURL: URL?
    @State private var viewModel = DocumentViewModel()

    var body: some View {
        MarkdownReaderView(viewModel: viewModel, fileURL: fileURL)
            .task(id: document.content) {
                await viewModel.load(document.content)
            }
    }
}

#Preview {
    DocumentView(document: MarkdownDocument(data: Data("# Amoxtli\n\nVisor de *Markdown*.".utf8)))
}
