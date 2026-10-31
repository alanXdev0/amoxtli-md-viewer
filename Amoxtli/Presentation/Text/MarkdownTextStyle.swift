import AppKit

struct MarkdownTextStyle: Equatable {
    var font: NSFont
    var lineSpacing: CGFloat = 0

    static let body = MarkdownTextStyle(font: .preferredFont(forTextStyle: .body), lineSpacing: 3)
    static let tableCell = MarkdownTextStyle(font: .preferredFont(forTextStyle: .body))
    static let tableHeader = MarkdownTextStyle(font: .preferredFont(forTextStyle: .body).withTraits(.bold))
    static let code = MarkdownTextStyle(font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))

    static func heading(level: Int) -> MarkdownTextStyle {
        MarkdownTextStyle(font: .preferredFont(forTextStyle: textStyle(forHeadingLevel: level)).withTraits(.bold))
    }

    private static func textStyle(forHeadingLevel level: Int) -> NSFont.TextStyle {
        switch level {
        case 1: .largeTitle
        case 2: .title1
        case 3: .title2
        case 4: .title3
        case 5: .headline
        default: .subheadline
        }
    }
}

extension NSFont {
    func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(traits))
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
