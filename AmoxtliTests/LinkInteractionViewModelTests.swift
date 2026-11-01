import AppKit
import XCTest
@testable import Amoxtli

@MainActor
final class LinkInteractionViewModelTests: XCTestCase {
    private let web = URL(filePath: "/Applications/Web.app")
    private let another = URL(filePath: "/Applications/Another.app")
    private let pasteboard = NSPasteboard.withUniqueName()
    private let workspace = FakeWorkspace()
    private let prompter = FakeLinkWarningPrompter()
    private var defaults = UserDefaults()
    private var suiteName = ""

    override func setUpWithError() throws {
        suiteName = "LinkInteractionViewModelTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeViewModel(noticeDuration: Duration = .seconds(60)) -> LinkInteractionViewModel {
        LinkInteractionViewModel(
            workspace: workspace,
            pasteboard: pasteboard,
            noticeDuration: noticeDuration,
            trustedHosts: TrustedHostsStore(defaults: defaults),
            warningPrompter: prompter
        )
    }

    private func url(_ string: String) throws -> URL {
        try XCTUnwrap(URL(string: string))
    }

    // MARK: - Activation

    func testSystemLinkOpensInWorkspace() async throws {
        let link = try url("https://example.com")
        let viewModel = makeViewModel()
        await viewModel.activate(link)
        XCTAssertEqual(workspace.openedLinks, [link])
        XCTAssertNil(viewModel.notice)
    }

    func testUnsupportedLinkIsNotOpenedAndShowsNotice() async throws {
        let link = try url("ftp://example.com")
        let viewModel = makeViewModel()
        await viewModel.activate(link)
        XCTAssertEqual(workspace.openedLinks, [])
        XCTAssertEqual(viewModel.notice, .init(reason: .unsupportedLink, link: link))
    }

    func testOpenFailureShowsNotice() async throws {
        let link = try url("https://example.com")
        workspace.openError = FakeWorkspace.Failure()
        let viewModel = makeViewModel()
        await viewModel.activate(link)
        XCTAssertEqual(viewModel.notice, .init(reason: .openFailed, link: link))
    }

    func testNoticeDisappearsAfterItsDuration() async throws {
        let viewModel = makeViewModel(noticeDuration: .milliseconds(10))
        await viewModel.activate(try url("ftp://example.com"))
        XCTAssertNotNil(viewModel.notice)
        for _ in 0..<100 where viewModel.notice != nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertNil(viewModel.notice)
    }

    func testOpenWithApplicationUsesThatApplication() async throws {
        let link = try url("https://example.com")
        await makeViewModel().open(link, withApplicationAt: another)
        XCTAssertEqual(workspace.openedWithApplication.map(\.link), [link])
        XCTAssertEqual(workspace.openedWithApplication.map(\.application), [another])
    }

    func testOpenWithApplicationRejectsUnsupportedLink() async throws {
        let link = try url("file:///etc/hosts")
        let viewModel = makeViewModel()
        await viewModel.open(link, withApplicationAt: another)
        XCTAssertTrue(workspace.openedWithApplication.isEmpty)
        XCTAssertEqual(viewModel.notice, .init(reason: .unsupportedLink, link: link))
    }

    // MARK: - Unknown sites

    func testKnownSiteOpensWithoutWarning() async throws {
        let link = try url("https://github.com/apple/swift")
        await makeViewModel().activate(link)
        XCTAssertEqual(prompter.warnings, [])
        XCTAssertEqual(workspace.openedLinks, [link])
    }

    func testMailtoOpensWithoutWarning() async throws {
        let link = try url("mailto:hola@example.com")
        await makeViewModel().activate(link)
        XCTAssertEqual(prompter.warnings, [])
        XCTAssertEqual(workspace.openedLinks, [link])
    }

    func testUnknownSiteWarnsBeforeOpening() async throws {
        let link = try url("https://example.com/a")
        await makeViewModel().activate(link)
        XCTAssertEqual(prompter.warnings, [LinkWarning(link: link, host: "example.com")])
        XCTAssertEqual(workspace.openedLinks, [link])
    }

    func testCancelingTheWarningDoesNotOpen() async throws {
        prompter.answer = LinkWarningAnswer(opens: false, alwaysTrusts: false)
        let viewModel = makeViewModel()
        await viewModel.activate(try url("https://example.com/a"))
        XCTAssertEqual(workspace.openedLinks, [])
        XCTAssertNil(viewModel.notice)
    }

    func testOpenWithApplicationAlsoWarns() async throws {
        prompter.answer = LinkWarningAnswer(opens: false, alwaysTrusts: false)
        await makeViewModel().open(try url("https://example.com/a"), withApplicationAt: another)
        XCTAssertEqual(prompter.warnings.count, 1)
        XCTAssertTrue(workspace.openedWithApplication.isEmpty)
    }

    func testAlwaysTrustingASiteStopsWarningAboutIt() async throws {
        prompter.answer = LinkWarningAnswer(opens: true, alwaysTrusts: true)
        let viewModel = makeViewModel()
        await viewModel.activate(try url("https://example.com/a"))
        await viewModel.activate(try url("https://www.example.com/b"))
        XCTAssertEqual(prompter.warnings.count, 1)
        XCTAssertEqual(workspace.openedLinks.count, 2)
    }

    func testCancelingDoesNotTrustTheSiteEvenWithTheCheckboxOn() async throws {
        prompter.answer = LinkWarningAnswer(opens: false, alwaysTrusts: true)
        await makeViewModel().activate(try url("https://example.com/a"))
        XCTAssertEqual(TrustedHostsStore(defaults: defaults).hosts, [])
    }

    func testWarningClearsTheHoveredLink() async throws {
        let link = try url("https://example.com/a")
        let viewModel = makeViewModel()
        viewModel.hover(link)
        await viewModel.activate(link)
        XCTAssertNil(viewModel.hoveredLink)
    }

    // MARK: - Misleading text

    func testMisleadingTextWarnsEvenWhenTheSiteIsKnown() async throws {
        let link = try url("https://github.com/malware")
        prompter.answer = LinkWarningAnswer(opens: false, alwaysTrusts: false)
        await makeViewModel().activate(link, displayedText: "apple.com")
        XCTAssertEqual(prompter.warnings, [
            LinkWarning(link: link, host: "github.com", reason: .misleadingText(claimedHost: "apple.com")),
        ])
        XCTAssertEqual(workspace.openedLinks, [])
    }

    func testMisleadingTextWarnsEvenWhenTheSiteIsTrusted() async throws {
        TrustedHostsStore(defaults: defaults).add("example.org")
        await makeViewModel().activate(try url("https://example.org"), displayedText: "apple.com")
        XCTAssertEqual(prompter.warnings.count, 1)
    }

    func testMisleadingTextWarnsWhenOpeningWithAnApplication() async throws {
        prompter.answer = LinkWarningAnswer(opens: false, alwaysTrusts: false)
        await makeViewModel().open(try url("https://github.com"), withApplicationAt: another, displayedText: "apple.com")
        XCTAssertEqual(prompter.warnings.count, 1)
        XCTAssertTrue(workspace.openedWithApplication.isEmpty)
    }

    func testOpeningAMisleadingLinkDoesNotTrustItsSite() async throws {
        prompter.answer = LinkWarningAnswer(opens: true, alwaysTrusts: true)
        await makeViewModel().activate(try url("https://example.org"), displayedText: "apple.com")
        XCTAssertEqual(workspace.openedLinks.count, 1)
        XCTAssertEqual(TrustedHostsStore(defaults: defaults).hosts, [])
    }

    func testMisleadingAlertExplainsTheMismatchAndOffersNoTrust() throws {
        let warning = LinkWarning(
            link: try url("https://example.org/a"),
            host: "example.org",
            reason: .misleadingText(claimedHost: "apple.com")
        )
        let alert = LinkWarningAlert.makeAlert(for: warning)
        XCTAssertEqual(alert.messageText, String(localized: "Este enlace podría engañarte"))
        XCTAssertTrue(alert.informativeText.contains("apple.com"))
        XCTAssertTrue(alert.informativeText.contains("example.org"))
        XCTAssertFalse(alert.showsSuppressionButton)
    }

    func testUnknownSiteAlertOffersToTrustIt() throws {
        let alert = LinkWarningAlert.makeAlert(for: LinkWarning(link: try url("https://example.org"), host: "example.org"))
        XCTAssertEqual(alert.messageText, String(localized: "Cuidado con este enlace"))
        XCTAssertTrue(alert.showsSuppressionButton)
    }

    func testWarningAlertShowsTheSiteAndCancelsWithEscapeOnly() throws {
        let link = try url("https://example.com/a")
        let alert = LinkWarningAlert.makeAlert(for: LinkWarning(link: link, host: "example.com"))
        XCTAssertTrue(alert.informativeText.contains("example.com"))
        XCTAssertTrue(alert.informativeText.contains("https://example.com/a"))
        XCTAssertEqual(alert.buttons.map(\.title), [String(localized: "Cancelar"), String(localized: "Abrir enlace")])
        XCTAssertEqual(alert.buttons.map(\.keyEquivalent), ["\u{1b}", ""])
    }

    // MARK: - Anchors

    func testAnchorRequestsScrollToHeading() async throws {
        let viewModel = makeViewModel()
        viewModel.updateAnchors(HeadingAnchors(entries: TOCBuilder.entries(for: try MarkdownParser().parse("texto\n\n# Uno").blocks)))
        await viewModel.activate(try url("#uno"))
        XCTAssertEqual(viewModel.scrollRequest?.blockIndex, 1)
    }

    func testRepeatedAnchorProducesNewRequest() async throws {
        let viewModel = makeViewModel()
        viewModel.updateAnchors(HeadingAnchors(entries: TOCBuilder.entries(for: try MarkdownParser().parse("# Uno").blocks)))
        await viewModel.activate(try url("#uno"))
        let first = viewModel.scrollRequest
        await viewModel.activate(try url("#uno"))
        XCTAssertNotEqual(viewModel.scrollRequest, first)
    }

    func testMissingAnchorShowsNotice() async throws {
        let link = try url("#nada")
        let viewModel = makeViewModel()
        await viewModel.activate(link)
        XCTAssertNil(viewModel.scrollRequest)
        XCTAssertEqual(viewModel.notice, .init(reason: .missingSection, link: link))
    }

    // MARK: - Hover and copy

    func testHoverTracksLink() throws {
        let link = try url("https://example.com")
        let viewModel = makeViewModel()
        viewModel.hover(link)
        XCTAssertEqual(viewModel.hoveredLink, link)
        viewModel.hover(nil)
        XCTAssertNil(viewModel.hoveredLink)
    }

    func testCopyWritesLinkToPasteboard() throws {
        makeViewModel().copy(try url("https://example.com/a"))
        XCTAssertEqual(pasteboard.string(forType: .string), "https://example.com/a")
        XCTAssertEqual(pasteboard.string(forType: .URL), "https://example.com/a")
    }

    // MARK: - Menu model

    func testMenuModelForSystemLinkMarksDefaultApplication() throws {
        let link = try url("https://example.com")
        workspace.defaultApplication = web
        workspace.applications = [web, another, web]
        let model = makeViewModel().menuModel(for: link)
        let expectedWeb = LinkMenuModel.Application(url: web, name: "Web", isDefault: true)
        let expectedAnother = LinkMenuModel.Application(url: another, name: "Another", isDefault: false)
        XCTAssertEqual(model.primaryAction, .open(in: expectedWeb))
        XCTAssertEqual(model.applications, [expectedAnother, expectedWeb])
    }

    func testMenuModelIncludesDefaultApplicationMissingFromList() throws {
        workspace.defaultApplication = web
        let model = makeViewModel().menuModel(for: try url("https://example.com"))
        XCTAssertEqual(model.applications.map(\.url), [web])
    }

    func testMenuModelWithoutApplicationsIsUnavailable() throws {
        let model = makeViewModel().menuModel(for: try url("https://example.com"))
        XCTAssertEqual(model.primaryAction, .unavailable)
        XCTAssertEqual(model.applications, [])
    }

    func testMenuModelForAnchorGoesToSection() throws {
        let model = makeViewModel().menuModel(for: try url("#uno"))
        XCTAssertEqual(model.primaryAction, .goToSection)
        XCTAssertEqual(model.applications, [])
    }

    func testMenuModelForUnsupportedLinkOffersNoApplications() throws {
        workspace.defaultApplication = web
        workspace.applications = [web]
        let model = makeViewModel().menuModel(for: try url("ftp://example.com"))
        XCTAssertEqual(model.primaryAction, .unavailable)
        XCTAssertEqual(model.applications, [])
    }

    func testSystemWorkspaceResolvesDefaultBrowser() throws {
        let workspace = SystemWorkspace()
        let link = try url("https://example.com")
        let application = try XCTUnwrap(workspace.defaultApplicationURL(toOpen: link))
        XCTAssertTrue(workspace.applicationURLs(toOpen: link).contains(application))
        XCTAssertFalse(workspace.applicationName(at: application).hasSuffix(".app"))
    }

    func testScrollToBlockCanRepeatTheSameBlock() {
        let viewModel = LinkInteractionViewModel(workspace: FakeWorkspace())
        viewModel.scroll(toBlock: 3)
        let first = viewModel.scrollRequest
        XCTAssertEqual(first?.blockIndex, 3)
        viewModel.scroll(toBlock: 3)
        XCTAssertNotEqual(viewModel.scrollRequest, first)
    }
}
