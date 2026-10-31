import AppKit
import XCTest
@testable import Amoxtli

@MainActor
final class ReadOnlyMenuTests: XCTestCase {
    private func items(of menu: NSMenu) -> [NSMenuItem] {
        menu.items.flatMap { item in
            [item] + (item.submenu.map(items(of:)) ?? [])
        }
    }

    func testMenuBarOffersNoWayToChangeTheDocument() throws {
        let menu = try XCTUnwrap(NSApp.mainMenu)
        let forbidden = [
            "saveDocument:",
            "saveDocumentAs:",
            "duplicateDocument:",
            "renameDocument:",
            "moveDocument:",
            "revertDocumentToSaved:",
        ].map(NSSelectorFromString)
        let found = items(of: menu).filter { item in item.action.map(forbidden.contains) ?? false }
        XCTAssertEqual(found.map(\.title), [])
    }

    func testMenuBarKeepsShareDisabledWithoutAFile() throws {
        let menu = try XCTUnwrap(NSApp.mainMenu)
        menu.items.compactMap(\.submenu).forEach { $0.update() }
        let share = items(of: menu).first { $0.title == "Compartir" }
        XCTAssertEqual(share?.isEnabled, false)
    }

    func testMenuBarCanStillCloseWindows() throws {
        let menu = try XCTUnwrap(NSApp.mainMenu)
        let close = items(of: menu).first { $0.keyEquivalent == "w" && $0.keyEquivalentModifierMask == .command }
        XCTAssertEqual(close?.title, "Cerrar")
    }
}
