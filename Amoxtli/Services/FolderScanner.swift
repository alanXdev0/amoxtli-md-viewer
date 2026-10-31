import Foundation

nonisolated protocol FolderScanning: Sendable {
    func scan(_ folder: URL) throws(FolderError) -> [MarkdownFolderSection]
}

/// Finds Markdown files recursively. Hidden items, package contents and symbolic links are left
/// out, and a subfolder that can't be read is skipped: only the opened folder itself can fail.
nonisolated struct FolderScanner: FolderScanning {
    private static let markdownExtensions: Set<String> = ["md", "markdown"]
    private static let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isPackageKey]

    func scan(_ folder: URL) throws(FolderError) -> [MarkdownFolderSection] {
        let items: [URL]
        do {
            items = try contents(of: folder)
        } catch {
            throw .unreadable
        }
        return sections(in: items, relativePath: "").sorted {
            $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending
        }
    }

    private func contents(of folder: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: Self.resourceKeys,
            options: .skipsHiddenFiles
        )
    }

    private func sections(in items: [URL], relativePath: String) -> [MarkdownFolderSection] {
        var files: [MarkdownFile] = []
        var nestedSections: [MarkdownFolderSection] = []
        for item in items where !Task.isCancelled {
            guard let values = try? item.resourceValues(forKeys: Set(Self.resourceKeys)) else { continue }
            if values.isRegularFile == true, Self.isMarkdown(item) {
                files.append(MarkdownFile(url: item, name: item.lastPathComponent))
            } else if values.isDirectory == true, values.isPackage != true {
                nestedSections += sections(inSubfolder: item, parentPath: relativePath)
            }
        }
        guard !files.isEmpty else { return nestedSections }
        return nestedSections + [MarkdownFolderSection(relativePath: relativePath, files: Self.sorted(files))]
    }

    private func sections(inSubfolder folder: URL, parentPath: String) -> [MarkdownFolderSection] {
        guard let items = try? contents(of: folder) else { return [] }
        let path = parentPath.isEmpty ? folder.lastPathComponent : "\(parentPath)/\(folder.lastPathComponent)"
        return sections(in: items, relativePath: path)
    }

    private static func isMarkdown(_ url: URL) -> Bool {
        markdownExtensions.contains(url.pathExtension.lowercased())
    }

    private static func sorted(_ files: [MarkdownFile]) -> [MarkdownFile] {
        files.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
