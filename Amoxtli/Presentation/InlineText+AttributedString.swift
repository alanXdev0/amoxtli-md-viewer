import Foundation

extension InlineText {
    var attributedString: AttributedString {
        runs.reduce(into: AttributedString()) { result, run in
            var piece = AttributedString(run.text)
            piece.inlinePresentationIntent = run.style.presentationIntent
            piece.link = run.link
            result += piece
        }
    }
}

private extension InlineStyle {
    var presentationIntent: InlinePresentationIntent? {
        var intent: InlinePresentationIntent = []
        if contains(.emphasis) { intent.insert(.emphasized) }
        if contains(.strong) { intent.insert(.stronglyEmphasized) }
        if contains(.code) { intent.insert(.code) }
        if contains(.strikethrough) { intent.insert(.strikethrough) }
        return intent.isEmpty ? nil : intent
    }
}
