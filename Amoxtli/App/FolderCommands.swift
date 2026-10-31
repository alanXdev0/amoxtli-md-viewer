import SwiftUI

struct FolderCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Folder…") {
                if let bookmark = FolderPicker().chooseFolder() {
                    openWindow(value: bookmark)
                }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])
        }
    }
}
