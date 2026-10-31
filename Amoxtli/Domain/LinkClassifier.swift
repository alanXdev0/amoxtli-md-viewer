import Foundation

nonisolated enum LinkDestination: Equatable, Sendable {
    case system(URL)
    case anchor(String)
    case unsupported(URL)
}

nonisolated enum LinkClassifier {
    static func classify(_ url: URL) -> LinkDestination {
        switch url.scheme?.lowercased() {
        case "http", "https":
            url.host(percentEncoded: false)?.isEmpty == false ? .system(url) : .unsupported(url)
        case "mailto":
            url.absoluteString.count > "mailto:".count ? .system(url) : .unsupported(url)
        case .none:
            anchor(in: url).map(LinkDestination.anchor) ?? .unsupported(url)
        default:
            .unsupported(url)
        }
    }

    /// A relative path with a fragment (`otro.md#x`) points to another file, so it isn't an anchor.
    private static func anchor(in url: URL) -> String? {
        guard url.relativeString.hasPrefix("#"),
              let fragment = url.fragment(percentEncoded: false),
              !fragment.isEmpty
        else { return nil }
        return fragment
    }
}
