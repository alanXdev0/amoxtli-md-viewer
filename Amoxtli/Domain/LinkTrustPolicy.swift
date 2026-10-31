import Foundation

nonisolated enum LinkTrust: Equatable, Sendable {
    case known
    case unknown(host: String)
    case misleading(claimedHost: String, host: String)
}

/// Decides which links open right away and which ones need a warning first.
nonisolated struct LinkTrustPolicy: Equatable, Sendable {
    static let builtInHosts: Set<String> = [
        "apple.com",
        "github.com",
        "mozilla.org",
        "swift.org",
        "wikipedia.org",
    ]

    let knownHosts: Set<String>

    /// Misleading text comes first: a known site doesn't explain why the text names another one.
    /// A link without a host, like `mailto:`, visits nothing: it only starts a draft to review.
    /// The host stays in its encoded form, so a Unicode look-alike can't pass as a known site.
    func trust(for link: URL, displayedText: String? = nil) -> LinkTrust {
        if let displayedText,
           let claimed = LinkTextClaim.host(in: displayedText),
           let destination = Self.destinationHost(of: link),
           !Self.isSameSite(claimed, destination) {
            return .misleading(claimedHost: claimed, host: destination)
        }
        guard let host = link.host(percentEncoded: true)?.lowercased() else { return .known }
        return isKnown(host) ? .known : .unknown(host: host)
    }

    /// Compares whole domain labels: `docs.github.com` is known, `notgithub.com` isn't.
    private func isKnown(_ host: String) -> Bool {
        knownHosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }

    private static func destinationHost(of link: URL) -> String? {
        if let host = link.host(percentEncoded: true) { return host.lowercased() }
        guard link.scheme?.lowercased() == "mailto" else { return nil }
        return link.path(percentEncoded: true).split(separator: "@").last.map { $0.lowercased() }
    }

    /// A subdomain belongs to whoever owns its parent, so `apple.com` can lead to `support.apple.com`.
    private static func isSameSite(_ first: String, _ second: String) -> Bool {
        let first = withoutWWW(first)
        let second = withoutWWW(second)
        return first == second || first.hasSuffix(".\(second)") || second.hasSuffix(".\(first)")
    }

    private static func withoutWWW(_ host: String) -> String {
        host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

/// Reads which site a link's visible text presents itself as, if any.
nonisolated enum LinkTextClaim {
    /// Only common domains count for text without a scheme. Otherwise, every file name would look
    /// like an address, since `README.md` is also a valid host.
    private static let commonTopLevelDomains: Set<String> = [
        "ai", "app", "ar", "br", "ca", "cl", "co", "com", "de", "dev", "edu", "es", "eu", "fr",
        "gob", "gov", "info", "io", "it", "me", "mx", "net", "org", "pe", "uk", "us",
    ]

    static func host(in text: String) -> String? {
        let candidate = text.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: ".,;!?()")))
        guard !candidate.isEmpty, !candidate.contains(where: \.isWhitespace) else { return nil }
        let lowercased = candidate.lowercased()
        if lowercased.hasPrefix("http://") || lowercased.hasPrefix("https://") {
            return URL(string: candidate)?.host(percentEncoded: true)?.lowercased()
        }
        return bareHost(in: candidate)
    }

    private static func bareHost(in candidate: String) -> String? {
        let authority = candidate.prefix { !"/?#:".contains($0) }
        guard let name = authority.split(separator: "@").last, looksLikeAddress(name) else { return nil }
        return URL(string: "https://\(name)")?.host(percentEncoded: true)?.lowercased()
    }

    /// The domain must be in lowercase, which leaves out names like `ASP.NET` and `Socket.IO`.
    private static func looksLikeAddress(_ name: Substring) -> Bool {
        let labels = name.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2, !labels.contains(where: \.isEmpty), let domain = labels.last else { return false }
        return name.lowercased().hasPrefix("www.") || commonTopLevelDomains.contains(String(domain))
    }
}

/// What the user needs to see before opening a link that may not be what it seems.
nonisolated struct LinkWarning: Equatable, Sendable {
    enum Reason: Equatable, Sendable {
        case unknownSite
        case misleadingText(claimedHost: String)
    }

    private static let maxDisplayedLength = 300

    let link: URL
    let host: String
    var reason = Reason.unknownSite

    /// Trusting the destination wouldn't change that the text names another site.
    var canBeTrusted: Bool {
        reason == .unknownSite
    }

    /// A document can hold a link of any length, and the alert would grow with it.
    var displayedLink: String {
        let text = link.absoluteString
        guard text.count > Self.maxDisplayedLength else { return text }
        let kept = Self.maxDisplayedLength / 2
        return "\(text.prefix(kept))…\(text.suffix(kept))"
    }
}
