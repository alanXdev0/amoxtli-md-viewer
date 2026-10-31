import AppKit

/// Builds the `NSMenu` shown when right-clicking a link.
enum LinkContextMenu {
    private static let iconSize = NSSize(width: 16, height: 16)

    static func make(model: LinkMenuModel, links: LinkInteractionViewModel) -> NSMenu {
        let menu = NSMenu()
        menu.allowsContextMenuPlugIns = false
        menu.addItem(primaryItem(for: model, links: links))
        if !model.applications.isEmpty {
            menu.addItem(openWithItem(for: model, links: links))
        }
        menu.addItem(.separator())
        menu.addItem(actionItem(title: String(localized: "Copiar enlace")) { [weak links] in
            links?.copy(model.link)
        })
        return menu
    }

    private static func primaryItem(for model: LinkMenuModel, links: LinkInteractionViewModel) -> NSMenuItem {
        let link = model.link
        switch model.primaryAction {
        case .open(let application):
            return actionItem(title: String(localized: "Abrir en \(application.name)")) { [weak links] in
                Task { await links?.activate(link) }
            }
        case .goToSection:
            return actionItem(title: String(localized: "Ir a la sección")) { [weak links] in
                Task { await links?.activate(link) }
            }
        case .unavailable:
            let item = NSMenuItem(title: String(localized: "Enlace no admitido"), action: nil, keyEquivalent: "")
            item.isEnabled = false
            return item
        }
    }

    private static func openWithItem(for model: LinkMenuModel, links: LinkInteractionViewModel) -> NSMenuItem {
        let submenu = NSMenu()
        for application in model.applications {
            submenu.addItem(applicationItem(application, link: model.link, links: links))
        }
        let item = NSMenuItem(title: String(localized: "Abrir con"), action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private static func applicationItem(
        _ application: LinkMenuModel.Application,
        link: URL,
        links: LinkInteractionViewModel
    ) -> NSMenuItem {
        let item = actionItem(title: application.name) { [weak links] in
            Task { await links?.open(link, withApplicationAt: application.url) }
        }
        let icon = links.applicationIcon(at: application.url)
        icon.size = iconSize
        item.image = icon
        item.state = application.isDefault ? .on : .off
        return item
    }
}

/// Menu action that owns its closure. The item retains it through `representedObject`,
/// so that no other object has to outlive the menu as its target.
final class MenuAction: NSObject {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func invoke() {
        handler()
    }
}

private func actionItem(title: String, handler: @escaping () -> Void) -> NSMenuItem {
    let action = MenuAction(handler: handler)
    let item = NSMenuItem(title: title, action: #selector(MenuAction.invoke), keyEquivalent: "")
    item.target = action
    item.representedObject = action
    return item
}
