import SwiftUI

struct FloatingPill: View {
    let text: String
    let systemImage: String?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private let maxWidth: CGFloat = 520

    var body: some View {
        if reduceTransparency {
            label
                .background(Color(nsColor: .windowBackgroundColor), in: .capsule)
                .overlay(Capsule().strokeBorder(.separator))
        } else {
            GlassEffectContainer {
                label.glassEffect(.regular, in: .capsule)
            }
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(verbatim: text)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    FloatingPill(text: "https://www.example.com/una/ruta/bastante/larga", systemImage: nil)
        .padding()
}
