import AppKit
import Observation

@Observable
final class LinkInteractionViewModel {
    struct Notice: Equatable {
        enum Reason: Equatable {
            case unsupportedLink
            case missingSection
            case openFailed
        }

        let reason: Reason
        let link: URL
    }

    struct ScrollRequest: Equatable {
        let blockIndex: Int
        let sequence: Int
    }

    private(set) var hoveredLink: URL?
    private(set) var notice: Notice?
    private(set) var scrollRequest: ScrollRequest?

    @ObservationIgnored private var anchors = HeadingAnchors()
    @ObservationIgnored private var noticeTask: Task<Void, Never>?
    @ObservationIgnored private let workspace: any WorkspaceServicing
    @ObservationIgnored private let pasteboard: NSPasteboard
    @ObservationIgnored private let noticeDuration: Duration
    @ObservationIgnored private let trustedHosts: TrustedHostsStore
    @ObservationIgnored private let warningPrompter: any LinkWarningPrompting

    init(
        workspace: any WorkspaceServicing = SystemWorkspace(),
        pasteboard: NSPasteboard = .general,
        noticeDuration: Duration = .seconds(4),
        trustedHosts: TrustedHostsStore = TrustedHostsStore(),
        warningPrompter: any LinkWarningPrompting = LinkWarningAlert()
    ) {
        self.workspace = workspace
        self.pasteboard = pasteboard
        self.noticeDuration = noticeDuration
        self.trustedHosts = trustedHosts
        self.warningPrompter = warningPrompter
    }

    func updateAnchors(_ anchors: HeadingAnchors) {
        self.anchors = anchors
    }

    func hover(_ link: URL?) {
        if hoveredLink != link {
            hoveredLink = link
        }
    }

    func activate(_ link: URL) async {
        switch LinkClassifier.classify(link) {
        case .system(let url):
            guard confirmOpening(url) else { return }
            await perform(on: url) { try await workspace.open(url) }
        case .anchor(let anchor):
            scroll(toAnchor: anchor, of: link)
        case .unsupported:
            show(Notice(reason: .unsupportedLink, link: link))
        }
    }

    func open(_ link: URL, withApplicationAt applicationURL: URL) async {
        guard case .system(let url) = LinkClassifier.classify(link) else {
            return show(Notice(reason: .unsupportedLink, link: link))
        }
        guard confirmOpening(url) else { return }
        await perform(on: url) { try await workspace.open(url, withApplicationAt: applicationURL) }
    }

    func copy(_ link: URL) {
        pasteboard.clearContents()
        pasteboard.setString(link.absoluteString, forType: .URL)
        pasteboard.setString(link.absoluteString, forType: .string)
    }

    func menuModel(for link: URL) -> LinkMenuModel {
        switch LinkClassifier.classify(link) {
        case .system(let url):
            systemLinkMenuModel(for: url)
        case .anchor:
            LinkMenuModel(link: link, primaryAction: .goToSection, applications: [])
        case .unsupported:
            LinkMenuModel(link: link, primaryAction: .unavailable, applications: [])
        }
    }

    func applicationIcon(at applicationURL: URL) -> NSImage {
        workspace.applicationIcon(at: applicationURL)
    }

    func scroll(toBlock blockIndex: Int) {
        scrollRequest = ScrollRequest(blockIndex: blockIndex, sequence: (scrollRequest?.sequence ?? 0) + 1)
    }

    private func systemLinkMenuModel(for url: URL) -> LinkMenuModel {
        let defaultURL = workspace.defaultApplicationURL(toOpen: url)
        let applications = applicationModels(for: url, defaultURL: defaultURL)
        let primary = applications.first(where: \.isDefault).map(LinkMenuModel.PrimaryAction.open(in:))
        return LinkMenuModel(link: url, primaryAction: primary ?? .unavailable, applications: applications)
    }

    private func applicationModels(for url: URL, defaultURL: URL?) -> [LinkMenuModel.Application] {
        var seen = Set<URL>()
        return ([defaultURL].compactMap(\.self) + workspace.applicationURLs(toOpen: url))
            .filter { seen.insert($0).inserted }
            .map { applicationURL in
                LinkMenuModel.Application(
                    url: applicationURL,
                    name: workspace.applicationName(at: applicationURL),
                    isDefault: applicationURL == defaultURL
                )
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The alert takes the pointer away from the link, and the text view won't report that it left.
    private func confirmOpening(_ url: URL) -> Bool {
        let policy = LinkTrustPolicy(knownHosts: LinkTrustPolicy.builtInHosts.union(trustedHosts.hosts))
        guard case .unknown(let host) = policy.trust(for: url) else { return true }
        hover(nil)
        let answer = warningPrompter.confirmOpening(LinkWarning(link: url, host: host))
        if answer.opens && answer.alwaysTrusts {
            trustedHosts.add(host)
        }
        return answer.opens
    }

    private func perform(on link: URL, _ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch {
            show(Notice(reason: .openFailed, link: link))
        }
    }

    private func scroll(toAnchor anchor: String, of link: URL) {
        guard let blockIndex = anchors.blockIndex(forAnchor: anchor) else {
            return show(Notice(reason: .missingSection, link: link))
        }
        scroll(toBlock: blockIndex)
    }

    private func show(_ notice: Notice) {
        self.notice = notice
        noticeTask?.cancel()
        noticeTask = Task { [noticeDuration] in
            try? await Task.sleep(for: noticeDuration)
            guard !Task.isCancelled else { return }
            self.notice = nil
        }
    }
}
