import XCTest
@testable import Amoxtli

final class LocalizationTests: XCTestCase {
    private let languages = ["de", "en", "es", "fr", "it", "ja", "ko", "pt-BR", "ru", "zh-Hans", "zh-Hant"]

    private func bundle(for language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"), language)
        return try XCTUnwrap(Bundle(path: path), language)
    }

    func testAppShipsEverySupportedLanguage() {
        XCTAssertEqual(Set(Bundle.main.localizations).intersection(languages), Set(languages))
    }

    func testEveryLanguageTranslatesTheSourceText() throws {
        for language in languages where language != "es" {
            let translated = try bundle(for: language).localizedString(forKey: "Abrir enlace", value: nil, table: nil)
            XCTAssertNotEqual(translated, "Abrir enlace", language)
        }
    }

    func testSpanishTranslatesTheOneEnglishKey() throws {
        let translated = try bundle(for: "es").localizedString(forKey: "Open Folder…", value: nil, table: nil)
        XCTAssertEqual(translated, "Abrir carpeta…")
    }
}
