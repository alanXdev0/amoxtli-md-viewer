import AppKit

struct LinkWarningAnswer: Equatable {
    let opens: Bool
    let alwaysTrusts: Bool
}

protocol LinkWarningPrompting {
    func confirmOpening(_ warning: LinkWarning) -> LinkWarningAnswer
}

/// AppKit is required here: SwiftUI's `alert` has no checkbox.
struct LinkWarningAlert: LinkWarningPrompting {
    func confirmOpening(_ warning: LinkWarning) -> LinkWarningAnswer {
        let alert = Self.makeAlert(for: warning)
        let response = alert.runModal()
        return LinkWarningAnswer(
            opens: response == .alertSecondButtonReturn,
            alwaysTrusts: alert.suppressionButton?.state == .on
        )
    }

    static func makeAlert(for warning: LinkWarning) -> NSAlert {
        let alert = NSAlert()
        // The only style that adds the caution symbol: `.warning` just shows the app icon.
        alert.alertStyle = .critical
        alert.messageText = title(for: warning)
        alert.informativeText = String(localized: "\(explanation(for: warning)) Ábrelo solo si confías en quien escribió este documento.\n\n\(warning.displayedLink)")
        let cancel = alert.addButton(withTitle: String(localized: "Cancelar"))
        // NSAlert only gives ⎋ to a button titled "Cancel". This also takes ↩ away from the
        // buttons, so that the keyboard can't open an unknown site by accident.
        cancel.keyEquivalent = "\u{1b}"
        alert.addButton(withTitle: String(localized: "Abrir enlace"))
        if warning.canBeTrusted {
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = String(localized: "Confiar siempre en \(warning.host)")
        }
        return alert
    }

    private static func title(for warning: LinkWarning) -> String {
        switch warning.reason {
        case .unknownSite: String(localized: "Cuidado con este enlace")
        case .misleadingText: String(localized: "Este enlace podría engañarte")
        }
    }

    private static func explanation(for warning: LinkWarning) -> String {
        switch warning.reason {
        case .unknownSite:
            String(localized: "Amoxtli no conoce el sitio \(warning.host).")
        case .misleadingText(let claimedHost):
            String(localized: "El texto dice \(claimedHost), pero el enlace lleva a \(warning.host).")
        }
    }
}
