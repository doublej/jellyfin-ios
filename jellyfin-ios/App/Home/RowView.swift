import JellyfinKit
import SwiftUI

/// One titled horizontal row of cards.
struct RowView<Card: View>: View {
    let title: String
    let items: [Item]
    var link: Route?
    @ViewBuilder let card: (Item) -> Card
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let gutter = Gutter.of(geometry.size.width)
            VStack(alignment: .leading, spacing: 12) {
                header.padding(.horizontal, gutter)
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(items) { card($0) }
                    }
                    .padding(.horizontal, gutter)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(height: rowHeight)
    }

    private var header: some View {
        HStack {
            SectionTitle(text: title)
            if let link {
                NavigationLink(value: link) { Text(L10n.t("see_all")).metaStyle() }
            }
        }
    }

    /// GeometryReader needs a height; cards are fixed-size, so the row is too.
    private var rowHeight: CGFloat {
        let size = CardSize.of(sizeClass)
        let isThumb = Card.self == ThumbCard.self
        return 40 + (isThumb ? size.thumb * 9 / 16 : size.poster * 3 / 2) + 46
    }
}
