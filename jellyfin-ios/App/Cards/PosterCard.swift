import JellyfinKit
import SwiftUI

/// 2:3 poster with title and year, opening the item's page.
struct PosterCard: View {
    let item: Item
    var width: CGFloat?
    @Environment(\.cardSize) private var size
    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationLink(value: Route.item(item)) {
            VStack(alignment: .leading, spacing: 6) {
                Artwork(art: item.posterArt, width: cardWidth)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: Theme.radius))
                    .overlay(alignment: .topTrailing) { WatchBadge(item: item).padding(6) }
                    .overlay(alignment: .topLeading) { FavoriteMark(item: item) }
                    .overlay(alignment: .bottom) { progress }
                Text(item.name ?? "").font(Theme.meta.weight(.medium)).foregroundStyle(Theme.text).lineLimit(1)
                Text(subtitle).font(Theme.caption).foregroundStyle(Theme.text3).lineLimit(1)
            }
            .frame(width: width)
        }
        .buttonStyle(CardButtonStyle())
        .contextMenu { CardMenu(item: item) }
        .accessibilityIdentifier("card.\(item.id)")
    }

    private var cardWidth: CGFloat { width ?? size.poster }

    private var subtitle: String {
        item.kind == .episode ? Format.episodeCode(season: item.parentIndexNumber, episode: item.indexNumber)
            : item.productionYear.map(String.init) ?? ""
    }

    @ViewBuilder private var progress: some View {
        let current = app.userData.current(item)
        let percent = Format.progress(current)
        if percent > 0, !current.isPlayed { ProgressBar(percent: percent).padding(6) }
    }
}
