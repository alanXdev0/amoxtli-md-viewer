import AppKit

/// AppKit is required here: SwiftUI's `Text` only exposes hover and context menus for the whole
/// view, with no way to know which link is under the pointer. See "Links" in the README.
final class MarkdownTextView: NSTextView {
    weak var links: LinkInteractionViewModel?
    var wrapsLines = true

    private var hoverTrackingArea: NSTrackingArea?
    // Measuring has its own layout: while laying out, a text view can resize itself, which would
    // reset its container to the current width and ignore the proposed one.
    private let measuringLayoutManager = NSLayoutManager()
    private let measuringContainer = NSTextContainer()

    static func make() -> MarkdownTextView {
        let view = MarkdownTextView(usingTextLayoutManager: false)
        view.configure()
        return view
    }

    private func configure() {
        isEditable = false
        isSelectable = true
        drawsBackground = false
        isRichText = true
        usesFontPanel = false
        allowsUndo = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticDataDetectionEnabled = false
        writingToolsBehavior = .none
        textContainerInset = .zero
        isVerticallyResizable = false
        isHorizontallyResizable = false
        autoresizingMask = []
        textContainer?.lineFragmentPadding = 0
        textContainer?.widthTracksTextView = false
        textContainer?.heightTracksTextView = false
        measuringContainer.lineFragmentPadding = 0
        measuringLayoutManager.addTextContainer(measuringContainer)
        textStorage?.addLayoutManager(measuringLayoutManager)
    }

    func setContent(_ content: NSAttributedString) {
        guard let textStorage, !textStorage.isEqual(to: content) else { return }
        textStorage.setAttributedString(content)
        setSelectedRange(NSRange(location: 0, length: 0))
    }

    func setLinksUnderlined(_ isUnderlined: Bool) {
        linkTextAttributes = [
            .foregroundColor: NSColor.linkColor,
            .cursor: NSCursor.pointingHand,
            .underlineStyle: isUnderlined ? NSUnderlineStyle.single.rawValue : 0,
        ]
    }

    // MARK: - Sizing

    func fittingSize(forProposedWidth proposedWidth: CGFloat?) -> CGSize {
        measuringContainer.size = NSSize(width: containerWidth(for: proposedWidth), height: Self.unbounded)
        measuringLayoutManager.ensureLayout(for: measuringContainer)
        let used = measuringLayoutManager.usedRect(for: measuringContainer)
        return CGSize(width: ceil(used.width), height: ceil(used.height))
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        textContainer?.size = NSSize(width: containerWidth(for: bounds.width), height: Self.unbounded)
    }

    private func containerWidth(for width: CGFloat?) -> CGFloat {
        guard wrapsLines, let width else { return Self.unbounded }
        return min(width, Self.unbounded)
    }

    private static let unbounded: CGFloat = 10_000_000

    // MARK: - Hit testing

    func link(at point: NSPoint) -> URL? {
        guard let window, let textStorage else { return nil }
        let screenPoint = window.convertPoint(toScreen: convert(point, to: nil))
        let insertionIndex = characterIndexForInsertion(at: screenPoint)
        // The insertion point can sit on either side of the character under the pointer.
        let candidates = [insertionIndex, insertionIndex - 1].filter { (0..<textStorage.length).contains($0) }
        guard let index = candidates.first(where: { rect(ofCharacterAt: $0).contains(point) }) else { return nil }
        return Self.url(from: textStorage.attribute(.link, at: index, effectiveRange: nil))
    }

    private func rect(ofCharacterAt index: Int) -> NSRect {
        guard let layoutManager, let textContainer else { return .zero }
        let characters = NSRange(location: index, length: 1)
        let glyphs = layoutManager.glyphRange(forCharacterRange: characters, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphs, in: textContainer)
            .offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
    }

    private static func url(from attribute: Any?) -> URL? {
        switch attribute {
        case let url as URL: url
        case let string as String: URL(string: string)
        default: nil
        }
    }

    // MARK: - Hover

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        hoverTrackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let link = link(at: convert(event.locationInWindow, from: nil))
        links?.hover(link)
        if link != nil {
            NSCursor.pointingHand.set()
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        links?.hover(nil)
    }

    // MARK: - Activation

    override func clicked(onLink link: Any, at charIndex: Int) {
        guard let url = Self.url(from: link) else { return }
        activate(url)
    }

    private func activate(_ url: URL) {
        guard let links else { return }
        Task { await links.activate(url) }
    }

    // MARK: - Context menus

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        if let links, let url = link(at: point) {
            return LinkContextMenu.make(model: links.menuModel(for: url), links: links)
        }
        return selectionMenu()
    }

    private func selectionMenu() -> NSMenu {
        let menu = NSMenu()
        menu.allowsContextMenuPlugIns = false
        menu.addItem(selectionItem(String(localized: "Copiar"), action: #selector(copy(_:)), key: "c"))
        menu.addItem(selectionItem(String(localized: "Seleccionar todo"), action: #selector(selectAll(_:)), key: "a"))
        return menu
    }

    private func selectionItem(_ title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Keyboard

    override func insertTab(_ sender: Any?) {
        if !selectLink(forward: true) {
            window?.selectNextKeyView(sender)
        }
    }

    override func insertBacktab(_ sender: Any?) {
        if !selectLink(forward: false) {
            window?.selectPreviousKeyView(sender)
        }
    }

    override func insertNewline(_ sender: Any?) {
        if let url = selectedLink {
            activate(url)
        }
    }

    /// Only one block keeps a selection at a time, since each one is an independent text view.
    override func resignFirstResponder() -> Bool {
        let didResign = super.resignFirstResponder()
        if didResign {
            setSelectedRange(NSRange(location: 0, length: 0))
            links?.hover(nil)
        }
        return didResign
    }

    private var selectedLink: URL? {
        guard let textStorage, selectedRange().length > 0 else { return nil }
        return Self.url(from: textStorage.attribute(.link, at: selectedRange().location, effectiveRange: nil))
    }

    private func selectLink(forward: Bool) -> Bool {
        let selection = selectedRange()
        let ranges = linkRanges()
        // With nothing selected, going backward starts from the last link, as when arriving with ⇧⇥.
        let hasNoSelection = selection == NSRange(location: 0, length: 0)
        let next = forward
            ? ranges.first { $0.location >= NSMaxRange(selection) }
            : ranges.last { hasNoSelection || NSMaxRange($0) <= selection.location }
        guard let next else {
            links?.hover(nil)
            return false
        }
        setSelectedRange(next)
        scrollRangeToVisible(next)
        links?.hover(selectedLink)
        return true
    }

    private func linkRanges() -> [NSRange] {
        guard let textStorage else { return [] }
        var ranges: [NSRange] = []
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            if value != nil {
                ranges.append(range)
            }
        }
        return ranges
    }
}
