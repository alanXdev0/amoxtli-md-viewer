import SwiftUI

struct DocumentErrorView: View {
    let error: MarkdownDocumentError

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }

    private var title: LocalizedStringKey {
        switch error {
        case .empty: "Archivo vacío"
        case .invalidEncoding: "Codificación no válida"
        case .unreadable: "No se pudo leer el archivo"
        case .unparsable: "No se pudo interpretar el archivo"
        }
    }

    private var message: LocalizedStringKey {
        switch error {
        case .empty: "Este archivo Markdown no tiene contenido."
        case .invalidEncoding: "Amoxtli solo puede abrir archivos de texto en UTF-8."
        case .unreadable: "Comprueba que el archivo exista y que tengas permiso para abrirlo."
        case .unparsable: "El contenido de este archivo no se pudo convertir a Markdown."
        }
    }

    private var systemImage: String {
        switch error {
        case .empty: "doc"
        case .invalidEncoding, .unparsable: "exclamationmark.triangle"
        case .unreadable: "lock.doc"
        }
    }
}

#Preview {
    DocumentErrorView(error: .invalidEncoding)
}
