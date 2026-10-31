import SwiftUI

struct FolderUnavailableView: View {
    enum Reason {
        case noFolder
        case noMarkdownFiles
        case failed(FolderError)
    }

    let reason: Reason
    let onChooseFolder: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            Button("Elegir carpeta…", action: onChooseFolder)
        }
    }

    private var title: LocalizedStringKey {
        switch reason {
        case .noFolder: "Ninguna carpeta abierta"
        case .noMarkdownFiles: "Sin archivos Markdown"
        case .failed(.staleBookmark): "No se encontró la carpeta"
        case .failed(.unreadable): "No se pudo leer la carpeta"
        }
    }

    private var message: LocalizedStringKey {
        switch reason {
        case .noFolder: "Elige una carpeta para ver sus archivos Markdown."
        case .noMarkdownFiles: "Esta carpeta y sus subcarpetas no tienen archivos .md ni .markdown."
        case .failed(.staleBookmark): "Puede que se haya movido o eliminado. Elígela de nuevo para seguir leyendo."
        case .failed(.unreadable): "Comprueba que la carpeta exista y que tengas permiso para abrirla."
        }
    }

    private var systemImage: String {
        switch reason {
        case .noFolder: "folder"
        case .noMarkdownFiles: "doc.text.magnifyingglass"
        case .failed(.staleBookmark): "questionmark.folder"
        case .failed(.unreadable): "lock"
        }
    }
}

#Preview {
    FolderUnavailableView(reason: .failed(.staleBookmark), onChooseFolder: {})
}
