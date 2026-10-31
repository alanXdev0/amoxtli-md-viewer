import SwiftUI

struct ImageBlockView: View {
    let image: MarkdownImage

    var body: some View {
        Group {
            if image.isRemote {
                AsyncImage(url: image.source) { phase in
                    switch phase {
                    case .success(let loaded):
                        // Natural size when it fits, so small images such as badges aren't upscaled.
                        ViewThatFits(in: .horizontal) {
                            loaded
                            loaded
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    case .empty:
                        ProgressView()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .accessibilityLabel(description)
    }

    private var description: String {
        image.altText.isEmpty ? image.source.absoluteString : image.altText
    }

    private var placeholder: some View {
        Label(description, systemImage: "photo")
            .foregroundStyle(.secondary)
    }
}
