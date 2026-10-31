import SwiftUI

/// Safari-style status area in the bottom-left corner: the hovered URL and link notices.
struct LinkStatusOverlay: View {
    @Environment(LinkInteractionViewModel.self) private var links
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let notice = links.notice {
                FloatingPill(text: message(for: notice), systemImage: "exclamationmark.circle")
                    .transition(.opacity)
            }
            if let link = links.hoveredLink {
                FloatingPill(text: link.absoluteString, systemImage: nil)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .allowsHitTesting(false)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: links.hoveredLink)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: links.notice)
        .onChange(of: links.notice) { _, notice in
            if let notice {
                AccessibilityNotification.Announcement(message(for: notice)).post()
            }
        }
    }

    private func message(for notice: LinkInteractionViewModel.Notice) -> String {
        let link = notice.link.absoluteString
        return switch notice.reason {
        case .unsupportedLink: String(localized: "Enlace no admitido: \(link)")
        case .missingSection: String(localized: "No se encontró la sección \(link)")
        case .openFailed: String(localized: "No se pudo abrir \(link)")
        }
    }
}
