import AppKit
@testable import Amoxtli

final class FakeWorkspace: WorkspaceServicing {
    struct Failure: Error {}

    var defaultApplication: URL?
    var applications: [URL] = []
    var openError: Error?
    private(set) var openedLinks: [URL] = []
    private(set) var openedWithApplication: [(link: URL, application: URL)] = []

    func defaultApplicationURL(toOpen url: URL) -> URL? {
        defaultApplication
    }

    func applicationURLs(toOpen url: URL) -> [URL] {
        applications
    }

    func applicationName(at applicationURL: URL) -> String {
        applicationURL.deletingPathExtension().lastPathComponent
    }

    func applicationIcon(at applicationURL: URL) -> NSImage {
        NSImage()
    }

    func open(_ url: URL) async throws {
        if let openError { throw openError }
        openedLinks.append(url)
    }

    func open(_ url: URL, withApplicationAt applicationURL: URL) async throws {
        if let openError { throw openError }
        openedWithApplication.append((url, applicationURL))
    }
}
