import SwiftUI

struct TableBlockView: View {
    let table: MarkdownTable

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: BlockMetrics.nestedSpacing) {
                GridRow {
                    ForEach(Array(table.header.enumerated()), id: \.offset) { column, cell in
                        Text(cell.attributedString)
                            .fontWeight(.semibold)
                            .textSelection(.enabled)
                            .gridColumnAlignment(alignment(ofColumn: column))
                    }
                }
                Divider()
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(cell.attributedString)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func alignment(ofColumn column: Int) -> HorizontalAlignment {
        switch table.columns[column] {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
