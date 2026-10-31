import SwiftUI

extension FocusedValues {
    /// The file shown in the active window, for the commands that act on it.
    @Entry var shownFileURL: URL?
}

/// `DocumentGroup(viewing:)` keeps the standard save items, even though nothing can be written.
/// The placement also holds the close and share items, so those have to be added back.
struct ReadOnlyDocumentCommands: Commands {
    @FocusedValue(\.shownFileURL) private var shownFileURL

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Cerrar") {
                NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("w")
            Divider()
            share
        }
    }

    @ViewBuilder
    private var share: some View {
        if let shownFileURL {
            ShareLink("Compartir", item: shownFileURL)
        } else {
            Button("Compartir") {}
                .disabled(true)
        }
    }
}
