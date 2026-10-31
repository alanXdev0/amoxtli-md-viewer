import SwiftUI

@main
struct AmoxtliApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            DocumentView(document: file.document)
        }
        .defaultSize(width: 1120, height: 720)
        .commands {
            FolderCommands()
            SidebarCommands()
        }

        WindowGroup(for: Data.self) { $bookmark in
            FolderWindowView(bookmark: $bookmark)
        }
        .defaultSize(width: 1320, height: 760)
        .defaultLaunchBehavior(.suppressed)
        .commandsRemoved()
    }
}
