import AppKit

/// AppKit is required here: SwiftUI's `fileImporter` hangs from a view, and the menu command has
/// to work with no window open.
struct FolderPicker {
    private let bookmarks: any FolderBookmarking

    init(bookmarks: any FolderBookmarking = SecurityScopedBookmarks()) {
        self.bookmarks = bookmarks
    }

    /// Returns `nil` if the person cancels. A folder that can't be bookmarked is reported here,
    /// since at this point there may be no window to explain it.
    func chooseFolder() -> Data? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Abrir")
        guard panel.runModal() == .OK, let folder = panel.url else { return nil }
        return bookmark(for: folder)
    }

    private func bookmark(for folder: URL) -> Data? {
        do {
            return try bookmarks.makeBookmark(for: folder)
        } catch {
            showFailure(for: folder)
            return nil
        }
    }

    private func showFailure(for folder: URL) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "No se pudo abrir la carpeta")
        alert.informativeText = String(localized: "Comprueba que tengas permiso para abrir «\(folder.lastPathComponent)».")
        alert.runModal()
    }
}
