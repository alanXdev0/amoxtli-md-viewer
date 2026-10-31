import XCTest
@testable import Amoxtli

final class LinkTrustPolicyTests: XCTestCase {
    private let policy = LinkTrustPolicy(knownHosts: ["github.com"])

    private func trust(_ string: String) throws -> LinkTrust {
        policy.trust(for: try XCTUnwrap(URL(string: string)))
    }

    func testKnownHostAndItsSubdomainsAreKnown() throws {
        XCTAssertEqual(try trust("https://github.com/apple/swift"), .known)
        XCTAssertEqual(try trust("https://docs.github.com"), .known)
        XCTAssertEqual(try trust("https://GitHub.COM"), .known)
    }

    func testUnknownHostIsReported() throws {
        XCTAssertEqual(try trust("https://example.com/a"), .unknown(host: "example.com"))
    }

    func testHostsThatOnlyResembleAKnownOneAreUnknown() throws {
        XCTAssertEqual(try trust("https://notgithub.com"), .unknown(host: "notgithub.com"))
        XCTAssertEqual(try trust("https://github.com.example.org"), .unknown(host: "github.com.example.org"))
        XCTAssertEqual(try trust("https://github.com@example.org"), .unknown(host: "example.org"))
        XCTAssertEqual(try trust("https://github.com."), .unknown(host: "github.com."))
    }

    func testUnicodeLookAlikeIsUnknownAndShownEncoded() throws {
        guard case .unknown(let host) = try trust("https://g\u{0456}thub.com") else {
            return XCTFail("Se esperaba un sitio desconocido")
        }
        XCTAssertTrue(host.allSatisfy(\.isASCII), host)
    }

    func testMailtoIsKnown() throws {
        XCTAssertEqual(try trust("mailto:hola@example.com"), .known)
    }

    func testBuiltInHostsAreKnown() throws {
        let policy = LinkTrustPolicy(knownHosts: LinkTrustPolicy.builtInHosts)
        XCTAssertEqual(policy.trust(for: try XCTUnwrap(URL(string: "https://es.wikipedia.org/wiki/Amoxtli"))), .known)
    }

    // MARK: - Misleading text

    private func trust(_ string: String, text: String) throws -> LinkTrust {
        policy.trust(for: try XCTUnwrap(URL(string: string)), displayedText: text)
    }

    func testTextNamingAnotherSiteIsMisleading() throws {
        XCTAssertEqual(
            try trust("https://example.org/login", text: "https://www.apple.com"),
            .misleading(claimedHost: "www.apple.com", host: "example.org")
        )
        XCTAssertEqual(
            try trust("https://example.org", text: "apple.com/soporte"),
            .misleading(claimedHost: "apple.com", host: "example.org")
        )
    }

    func testMisleadingTextIsReportedEvenForAKnownSite() throws {
        XCTAssertEqual(
            try trust("https://github.com/malware", text: "apple.com"),
            .misleading(claimedHost: "apple.com", host: "github.com")
        )
    }

    func testDestinationThatOnlyResemblesTheTextIsMisleading() throws {
        XCTAssertEqual(
            try trust("https://github.com.example.org", text: "github.com"),
            .misleading(claimedHost: "github.com", host: "github.com.example.org")
        )
        XCTAssertEqual(
            try trust("https://notgithub.com", text: "github.com"),
            .misleading(claimedHost: "github.com", host: "notgithub.com")
        )
    }

    func testTextMatchingTheSameSiteIsNotMisleading() throws {
        XCTAssertEqual(try trust("https://github.com/apple", text: "https://github.com"), .known)
        XCTAssertEqual(try trust("https://github.com", text: "www.github.com"), .known)
        XCTAssertEqual(try trust("https://www.github.com", text: "docs.github.com"), .known)
        XCTAssertEqual(try trust("https://docs.github.com", text: "GitHub.com"), .known)
    }

    func testTextThatIsNotAnAddressClaimsNothing() throws {
        for text in ["un enlace", "GitHub", "README.md", "archivo.swift", "v1.2", "ASP.NET", "Socket.IO", "@alan", "..."] {
            XCTAssertEqual(try trust("https://github.com", text: text), .known, text)
        }
    }

    func testUnknownSiteWithPlainTextIsOnlyUnknown() throws {
        XCTAssertEqual(try trust("https://example.org", text: "Mi sitio"), .unknown(host: "example.org"))
    }

    func testMailtoMustMatchTheAddressInItsText() throws {
        XCTAssertEqual(try trust("mailto:hola@example.org", text: "hola@example.org"), .known)
        XCTAssertEqual(try trust("mailto:hola@example.org", text: "Escríbeme"), .known)
        XCTAssertEqual(
            try trust("mailto:hola@example.org", text: "soporte@apple.com"),
            .misleading(claimedHost: "apple.com", host: "example.org")
        )
    }

    func testOnlyUnknownSitesCanBeTrusted() throws {
        let link = try XCTUnwrap(URL(string: "https://example.org"))
        XCTAssertTrue(LinkWarning(link: link, host: "example.org").canBeTrusted)
        XCTAssertFalse(LinkWarning(link: link, host: "example.org", reason: .misleadingText(claimedHost: "apple.com")).canBeTrusted)
    }

    // MARK: - Displayed link

    func testDisplayedLinkKeepsShortLinksWhole() throws {
        let link = try XCTUnwrap(URL(string: "https://example.com/a"))
        XCTAssertEqual(LinkWarning(link: link, host: "example.com").displayedLink, "https://example.com/a")
    }

    func testDisplayedLinkTruncatesLongLinksInTheMiddle() throws {
        let string = "https://example.com/" + String(repeating: "a", count: 1000) + "/fin"
        let shown = LinkWarning(link: try XCTUnwrap(URL(string: string)), host: "example.com").displayedLink
        XCTAssertEqual(shown.count, 301)
        XCTAssertTrue(shown.hasPrefix("https://example.com/"))
        XCTAssertTrue(shown.hasSuffix("/fin"))
        XCTAssertTrue(shown.contains("…"))
    }
}

@MainActor
final class TrustedHostsStoreTests: XCTestCase {
    private var defaults = UserDefaults()
    private var suiteName = ""

    override func setUpWithError() throws {
        suiteName = "TrustedHostsStoreTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testStartsEmpty() {
        XCTAssertEqual(TrustedHostsStore(defaults: defaults).hosts, [])
    }

    func testAddedHostsPersistWithoutDuplicates() {
        TrustedHostsStore(defaults: defaults).add("a.example")
        TrustedHostsStore(defaults: defaults).add("b.example")
        TrustedHostsStore(defaults: defaults).add("a.example")
        XCTAssertEqual(TrustedHostsStore(defaults: defaults).hosts, ["a.example", "b.example"])
    }

    func testRemoveAllForgetsEveryHost() {
        let store = TrustedHostsStore(defaults: defaults)
        store.add("a.example")
        store.removeAll()
        XCTAssertEqual(store.hosts, [])
    }
}
