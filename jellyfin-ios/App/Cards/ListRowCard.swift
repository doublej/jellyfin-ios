import JellyfinKit
import SwiftUI

/// The library's list layout: small poster, title, year, runtime and genres.
struct ListRowCard: View {
    let item: Item
    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationLink(value: Route.item(item)) {
            HStack(spacing: 14) {
                Artwork(art: item.posterArt, width: 60)
                    .frame(width: 60, height: 90)
                    .clipShape(.rect(cornerRadius: Theme.radiusSmall))
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "").font(Theme.headline).foregroundStyle(Theme.text).lineLimit(2)
                    Text(facts).metaStyle().lineLimit(1)
                    Text((item.genres ?? []).prefix(3).joined(separator: ", ")).font(Theme.caption).foregroundStyle(Theme.text3).lineLimit(1)
                }
                Spacer(minLength: 0)
                WatchBadge(item: item)
                FavoriteMark(item: item)
            }
            .contentShape(.rect)
        }
        .buttonStyle(CardButtonStyle())
        .contextMenu { CardMenu(item: item) }
        .accessibilityIdentifier("row.\(item.id)")
    }

    private var facts: String {
        [item.productionYear.map(String.init), item.officialRating, Format.duration(item.runTimeTicks)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
