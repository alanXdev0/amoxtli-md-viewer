import AppKit

/// Minimal wrapper around `NSWorkspace`, so that link handling can be tested without opening apps.
protocol WorkspaceServicing {
    func defaultApplicationURL(toOpen url: URL) -> URL?
    func applicationURLs(toOpen url: URL) -> [URL]
    func applicationName(at applicationURL: URL) -> String
    func applicationIcon(at applicationURL: URL) -> NSImage
    func open(_ url: URL) async throws
    func open(_ url: URL, withApplicationAt applicationURL: URL) async throws
}

struct SystemWorkspace: WorkspaceServicing {
    func defaultApplicationURL(toOpen url: URL) -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: url)
    }

    func applicationURLs(toOpen url: URL) -> [URL] {
        NSWorkspace.shared.urlsForApplications(toOpen: url)
    }

    func applicationName(at applicationURL: URL) -> String {
        let name = FileManager.default.displayName(atPath: applicationURL.path(percentEncoded: false))
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }

    func applicationIcon(at applicationURL: URL) -> NSImage {
        NSWorkspace.shared.icon(forFile: applicationURL.path(percentEncoded: false))
    }

    func open(_ url: URL) async throws {
        _ = try await NSWorkspace.shared.open(url, configuration: NSWorkspace.OpenConfiguration())
    }

    func open(_ url: URL, withApplicationAt applicationURL: URL) async throws {
        _ = try await NSWorkspace.shared.open(
            [url],
            withApplicationAt: applicationURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
