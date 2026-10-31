import SwiftUI

struct HeadingBlockView: View {
    let level: Int
    let content: InlineText

    var body: some View {
        Text(content.attributedString)
            .font(font)
            .fontWeight(level <= 2 ? .bold : .semibold)
            .padding(.top, level <= 2 ? BlockMetrics.spacing : BlockMetrics.nestedSpacing)
            .textSelection(.enabled)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(headingLevel)
    }

    private var font: Font {
        switch level {
        case 1: .largeTitle
        case 2: .title
        case 3: .title2
        case 4: .title3
        case 5: .headline
        default: .subheadline
        }
    }

    private var headingLevel: AccessibilityHeadingLevel {
        switch level {
        case 1: .h1
        case 2: .h2
        case 3: .h3
        case 4: .h4
        case 5: .h5
        default: .h6
        }
    }
}
