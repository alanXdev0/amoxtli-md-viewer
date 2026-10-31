import Foundation

/// What the context menu of a link offers, independent of how the menu is drawn.
nonisolated struct LinkMenuModel: Equatable, Sendable {
    struct Application: Equatable, Sendable {
        let url: URL
        let name: String
        let isDefault: Bool
    }

    enum PrimaryAction: Equatable, Sendable {
        case open(in: Application)
        case goToSection
        case unavailable
    }

    let link: URL
    let primaryAction: PrimaryAction
    let applications: [Application]
}
