import Foundation
import UniformTypeIdentifiers

/// Answers whether this app opens Markdown files, and whether it may ask to do so at launch.
struct DefaultAppChecker {
    private static let promptSuppressedKey = "isDefaultAppPromptSuppressed"

    private let workspace: any WorkspaceServicing
    private let applicationURL: URL
    private let defaults: UserDefaults

    init(
        workspace: any WorkspaceServicing = SystemWorkspace(),
        applicationURL: URL = Bundle.main.bundleURL,
        defaults: UserDefaults = .standard
    ) {
        self.workspace = workspace
        self.applicationURL = applicationURL
        self.defaults = defaults
    }

    var isDefault: Bool {
        guard let current = workspace.defaultApplicationURL(toOpen: UTType.markdown) else { return false }
        return Self.pathComponents(of: current) == Self.pathComponents(of: applicationURL)
    }

    var shouldPromptAtLaunch: Bool {
        !defaults.bool(forKey: Self.promptSuppressedKey) && !isDefault
    }

    func suppressPrompt() {
        defaults.set(true, forKey: Self.promptSuppressedKey)
    }

    func setAsDefault() async throws {
        try await workspace.setDefaultApplication(at: applicationURL, toOpen: .markdown)
    }

    /// Compares by components because the same bundle can come with or without a trailing slash.
    private static func pathComponents(of url: URL) -> [String] {
        url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
    }
}
