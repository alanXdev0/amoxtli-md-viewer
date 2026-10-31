import SwiftUI

struct DocumentView: View {
    let document: MarkdownDocument
    @State private var viewModel = DocumentViewModel()

    var body: some View {
        content
            .frame(minWidth: 480, minHeight: 360)
            .task(id: document.content) {
                await viewModel.load(document.content)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let model):
            MarkdownContentView(model: model)
        case .failed(let error):
            DocumentErrorView(error: error)
        }
    }
}

#Preview {
    DocumentView(document: MarkdownDocument(data: Data("# Amoxtli\n\nVisor de *Markdown*.".utf8)))
}
