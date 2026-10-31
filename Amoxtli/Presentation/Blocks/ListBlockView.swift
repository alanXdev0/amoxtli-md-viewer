import SwiftUI

struct ListBlockView: View {
    enum Marker {
        case ordered, unordered
    }

    let items: [ListItem]
    let marker: Marker

    var body: some View {
        VStack(alignment: .leading, spacing: BlockMetrics.nestedSpacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: BlockMetrics.nestedSpacing) {
                    Text(markerText(for: item))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    NestedBlocksView(blocks: item.blocks)
                }
            }
        }
    }

    private func markerText(for item: ListItem) -> String {
        switch marker {
        case .ordered: "\(item.ordinal)."
        case .unordered: "•"
        }
    }
}
