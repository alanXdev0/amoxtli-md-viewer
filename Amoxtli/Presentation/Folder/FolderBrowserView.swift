import SwiftUI

struct FolderBrowserView: View {
    let sections: [MarkdownFolderSection]
    @Bindable var viewModel: FolderViewModel
    let document: DocumentViewModel

    var body: some View {
        NavigationSplitView {
            FolderSidebarView(sections: sections, selection: $viewModel.selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 420)
        } detail: {
            detail
        }
        .task(id: viewModel.selection) {
            if let selection = viewModel.selection {
                await document.load(contentsOf: selection)
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let file = viewModel.selectedFile {
            MarkdownReaderView(viewModel: document, fileURL: file.url)
                .navigationSubtitle(Text(verbatim: file.name))
        } else {
            ContentUnavailableView(
                "Elige un archivo",
                systemImage: "doc.text",
                description: Text("Selecciona un archivo Markdown de la lista para leerlo.")
            )
        }
    }
}

private struct FolderSidebarView: View {
    let sections: [MarkdownFolderSection]
    @Binding var selection: MarkdownFile.ID?

    var body: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                Section {
                    ForEach(section.files) { file in
                        Label {
                            Text(verbatim: file.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } icon: {
                            Image(systemName: "doc.text")
                        }
                        .accessibilityLabel(accessibilityLabel(for: file, in: section))
                    }
                } header: {
                    if !section.relativePath.isEmpty {
                        Text(verbatim: section.relativePath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
        }
        .accessibilityLabel(Text("Archivos de la carpeta"))
    }

    private func accessibilityLabel(for file: MarkdownFile, in section: MarkdownFolderSection) -> Text {
        section.relativePath.isEmpty ? Text(verbatim: file.name) : Text("\(file.name), en \(section.relativePath)")
    }
}
