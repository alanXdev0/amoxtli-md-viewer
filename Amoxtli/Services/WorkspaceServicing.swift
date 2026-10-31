import AppKit
import UniformTypeIdentifiers

/// Minimal wrapper around `NSWorkspace`, so that link handling and the default-app flow can be
/// tested without opening apps or changing system settings.
protocol WorkspaceServicing {
    func defaultApplicationURL(toOpen url: URL) -> URL?
    func defaultApplicationURL(toOpen contentType: UTType) -> URL?
    func applicationURLs(toOpen url: URL) -> [URL]
    func applicationName(at applicationURL: URL) -> String
    func applicationIcon(at applicationURL: URL) -> NSImage
    func open(_ url: URL) async throws
    func open(_ url: URL, withApplicationAt applicationURL: URL) async throws
    func setDefaultApplication(at applicationURL: URL, toOpen contentType: UTType) async throws
}

struct SystemWorkspace: WorkspaceServicing {
    func defaultApplicationURL(toOpen url: URL) -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: url)
    }

    func defaultApplicationURL(toOpen contentType: UTType) -> URL? {
        NSWorkspace.shared.urlForApplication(toOpen: contentType)
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

    func setDefaultApplication(at applicationURL: URL, toOpen contentType: UTType) async throws {
        try await NSWorkspace.shared.setDefaultApplication(at: applicationURL, toOpen: contentType)
    }
}
