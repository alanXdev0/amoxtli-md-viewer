import AppKit
import UniformTypeIdentifiers
@testable import Amoxtli

final class FakeWorkspace: WorkspaceServicing {
    struct Failure: Error {}

    var defaultApplication: URL?
    var defaultMarkdownApplication: URL?
    var applications: [URL] = []
    var openError: Error?
    var setDefaultError: Error?
    private(set) var openedLinks: [URL] = []
    private(set) var openedWithApplication: [(link: URL, application: URL)] = []
    private(set) var setDefaultRequests: [(application: URL, contentType: UTType)] = []

    func defaultApplicationURL(toOpen url: URL) -> URL? {
        defaultApplication
    }

    func defaultApplicationURL(toOpen contentType: UTType) -> URL? {
        defaultMarkdownApplication
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

    func setDefaultApplication(at applicationURL: URL, toOpen contentType: UTType) async throws {
        setDefaultRequests.append((applicationURL, contentType))
        if let setDefaultError { throw setDefaultError }
    }
}
