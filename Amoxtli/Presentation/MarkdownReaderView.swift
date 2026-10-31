import SwiftUI

/// A document with its table of contents, shared by the single-file and folder windows.
struct MarkdownReaderView: View {
    let viewModel: DocumentViewModel
    var fileURL: URL?

    @State private var links = LinkInteractionViewModel()
    @SceneStorage("isTableOfContentsPresented") private var isTableOfContentsPresented = true

    var body: some View {
        content
            .frame(minWidth: 480, minHeight: 360)
            .focusedSceneValue(\.shownFileURL, fileURL)
            .inspector(isPresented: $isTableOfContentsPresented) {
                TableOfContentsView(entries: viewModel.tableOfContents) { entry in
                    links.scroll(toBlock: entry.blockIndex)
                }
                .inspectorColumnWidth(min: 200, ideal: 260, max: 400)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Índice", systemImage: "list.bullet.indent") {
                        isTableOfContentsPresented.toggle()
                    }
                    .keyboardShortcut("i", modifiers: [.command, .control])
                    .help(isTableOfContentsPresented ? "Ocultar el índice (⌃⌘I)" : "Mostrar el índice (⌃⌘I)")
                }
            }
            .onChange(of: viewModel.tableOfContents, initial: true) { _, entries in
                links.updateAnchors(HeadingAnchors(entries: entries))
                links.hover(nil)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let model):
            MarkdownContentView(model: model, links: links)
                .id(viewModel.loadCount)
        case .failed(let error):
            DocumentErrorView(error: error)
        }
    }
}

#Preview {
    MarkdownReaderView(viewModel: DocumentViewModel())
}
