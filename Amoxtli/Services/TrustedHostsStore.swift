import Foundation

/// The sites the user chose to always trust. Reads from `UserDefaults` every time, so that all
/// windows see the same list.
struct TrustedHostsStore {
    private static let hostsKey = "trustedLinkHosts"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hosts: Set<String> {
        Set(defaults.stringArray(forKey: Self.hostsKey) ?? [])
    }

    func add(_ host: String) {
        defaults.set(hosts.union([host]).sorted(), forKey: Self.hostsKey)
    }

    func removeAll() {
        defaults.removeObject(forKey: Self.hostsKey)
    }
}
