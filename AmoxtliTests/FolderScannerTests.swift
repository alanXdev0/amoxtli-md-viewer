import XCTest
@testable import Amoxtli

final class FolderScannerTests: XCTestCase {
    private func scan(_ folder: TemporaryFolder) throws -> [String: [String]] {
        let sections = try FolderScanner().scan(folder.url)
        return Dictionary(uniqueKeysWithValues: sections.map { ($0.relativePath, $0.files.map(\.name)) })
    }

    func testFindsOnlyMarkdownFiles() throws {
        let folder = try makeTemporaryFolder()
        for name in ["a.md", "b.markdown", "c.txt", "d.mdown", "e.pdf", "md", "f.md.bak"] {
            try folder.addFile(name)
        }
        XCTAssertEqual(try scan(folder), ["": ["a.md", "b.markdown"]])
    }

    func testExtensionMatchIsCaseInsensitive() throws {
        let folder = try makeTemporaryFolder()
        for name in ["a.MD", "b.Markdown", "c.mD"] {
            try folder.addFile(name)
        }
        XCTAssertEqual(try scan(folder), ["": ["a.MD", "b.Markdown", "c.mD"]])
    }

    func testScansRecursivelyAndGroupsBySubfolder() throws {
        let folder = try makeTemporaryFolder()
        try folder.addFile("raiz.md")
        try folder.addFile("docs/guia.md")
        try folder.addFile("docs/api/rest.md")
        XCTAssertEqual(try scan(folder), ["": ["raiz.md"], "docs": ["guia.md"], "docs/api": ["rest.md"]])
    }

    func testFoldersWithoutMarkdownAreOmitted() throws {
        let folder = try makeTemporaryFolder()
        try folder.addFolder("vacia")
        try folder.addFile("imagenes/foto.png")
        try folder.addFile("intermedia/profunda/nota.md")
        XCTAssertEqual(try scan(folder), ["intermedia/profunda": ["nota.md"]])
    }

    func testEmptyFolderHasNoSections() throws {
        XCTAssertEqual(try FolderScanner().scan(try makeTemporaryFolder().url), [])
    }

    func testFolderWithOnlyOtherFormatsHasNoSections() throws {
        let folder = try makeTemporaryFolder()
        try folder.addFile("nota.txt")
        XCTAssertEqual(try FolderScanner().scan(folder.url), [])
    }

    func testFolderNamedLikeMarkdownIsNotAFile() throws {
        let folder = try makeTemporaryFolder()
        try folder.addFile("carpeta.md/dentro.md")
        XCTAssertEqual(try scan(folder), ["carpeta.md": ["dentro.md"]])
    }

    func testSkipsHiddenItems() throws {
        let folder = try makeTemporaryFolder()
        try folder.addFile(".oculto.md")
        try folder.addFile(".git/notas.md")
        XCTAssertEqual(try scan(folder), [:])
    }

    func testSkipsPackageContents() throws {
        let folder = try makeTemporaryFolder()
        try folder.addFile("Herramienta.app/Contents/leeme.md")
        XCTAssertEqual(try scan(folder), [:])
    }

    func testSkipsSymbolicLinks() throws {
        let folder = try makeTemporaryFolder()
        let target = try folder.addFile("real/nota.md")
        try FileManager.default.createSymbolicLink(at: folder.url.appending(path: "enlace.md"), withDestinationURL: target)
        try FileManager.default.createSymbolicLink(
            at: folder.url.appending(path: "ciclo"),
            withDestinationURL: folder.url
        )
        XCTAssertEqual(try scan(folder), ["real": ["nota.md"]])
    }

    func testFilesAreInLocalizedOrder() throws {
        let folder = try makeTemporaryFolder()
        for name in ["zeta.md", "Árbol.md", "10.md", "2.md", "beta.md"] {
            try folder.addFile(name)
        }
        XCTAssertEqual(try scan(folder)[""], ["2.md", "10.md", "Árbol.md", "beta.md", "zeta.md"])
    }

    func testSectionsAreInLocalizedOrderWithOpenedFolderFirst() throws {
        let folder = try makeTemporaryFolder()
        for path in ["zeta/a.md", "Árbol/a.md", "beta/sub/a.md", "beta/a.md", "raiz.md"] {
            try folder.addFile(path)
        }
        let paths = try FolderScanner().scan(folder.url).map(\.relativePath)
        XCTAssertEqual(paths, ["", "Árbol", "beta", "beta/sub", "zeta"])
    }

    func testMissingFolderIsUnreadable() throws {
        let missing = try makeTemporaryFolder().url.appending(path: "no-existe")
        XCTAssertThrowsError(try FolderScanner().scan(missing)) { error in
            XCTAssertEqual(error as? FolderError, .unreadable)
        }
    }

    func testFileInsteadOfFolderIsUnreadable() throws {
        let folder = try makeTemporaryFolder()
        let file = try folder.addFile("nota.md")
        XCTAssertThrowsError(try FolderScanner().scan(file)) { error in
            XCTAssertEqual(error as? FolderError, .unreadable)
        }
    }
}
