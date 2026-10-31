import Foundation

nonisolated enum LinkTrust: Equatable, Sendable {
    case known
    case unknown(host: String)
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

    /// A link without a host, like `mailto:`, visits nothing: it only starts a draft to review.
    /// The host stays in its encoded form, so a Unicode look-alike can't pass as a known site.
    func trust(for link: URL) -> LinkTrust {
        guard let host = link.host(percentEncoded: true)?.lowercased() else { return .known }
        return isKnown(host) ? .known : .unknown(host: host)
    }

    /// Compares whole domain labels: `docs.github.com` is known, `notgithub.com` isn't.
    private func isKnown(_ host: String) -> Bool {
        knownHosts.contains { host == $0 || host.hasSuffix(".\($0)") }
    }
}

/// What the user needs to see before opening a link from an unknown site.
nonisolated struct LinkWarning: Equatable, Sendable {
    private static let maxDisplayedLength = 300

    let link: URL
    let host: String

    /// A document can hold a link of any length, and the alert would grow with it.
    var displayedLink: String {
        let text = link.absoluteString
        guard text.count > Self.maxDisplayedLength else { return text }
        let kept = Self.maxDisplayedLength / 2
        return "\(text.prefix(kept))…\(text.suffix(kept))"
    }
}
