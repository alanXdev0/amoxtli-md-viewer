import XCTest

/// A folder tree on disk for tests.
struct TemporaryFolder {
    let url: URL

    @discardableResult
    func addFile(_ relativePath: String, contents: Data = Data("# Título".utf8)) throws -> URL {
        let file = url.appending(path: relativePath)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: file)
        return file
    }

    func addFolder(_ relativePath: String) throws {
        try FileManager.default.createDirectory(at: url.appending(path: relativePath), withIntermediateDirectories: true)
    }
}

extension XCTestCase {
    /// Tied to the test rather than to a value's lifetime, so it can't disappear mid-test.
    func makeTemporaryFolder() throws -> TemporaryFolder {
        let url = FileManager.default.temporaryDirectory.appending(path: "Amoxtli-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return TemporaryFolder(url: url)
    }
}
