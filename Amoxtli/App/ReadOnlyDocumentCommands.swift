import SwiftUI

/// `DocumentGroup(viewing:)` keeps the standard save items, even though nothing can be written.
/// The placement also holds the close items, so closing has to be added back.
struct ReadOnlyDocumentCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Cerrar") {
                NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("w")
        }
    }
}
