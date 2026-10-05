import JellyfinKit
import SwiftUI

/// 16:9 still with a progress bar, for Continue Watching and Next Up. A tap plays; the long-press
/// menu leads to the item's page.
struct ThumbCard: View {
    let item: Item
    @Environment(\.cardSize) private var size
    @Environment(AppModel.self) private var app

    var body: some View {
        Button { app.play(PlayRequest(item: item)) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Artwork(art: item.thumbArt, width: size.thumb)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: Theme.radius))
                    .overlay(alignment: .bottom) { progress }
                    .overlay(alignment: .topTrailing) { WatchBadge(item: item).padding(6) }
                    .overlay(alignment: .topLeading) { FavoriteMark(item: item) }
                Text(CardText.title(item)).font(Theme.meta.weight(.medium)).foregroundStyle(Theme.text).lineLimit(1)
                Text(CardText.subtitle(app.userData.current(item))).font(Theme.caption).foregroundStyle(Theme.text3).lineLimit(1)
            }
            .frame(width: size.thumb)
        }
        .buttonStyle(CardButtonStyle())
        .contextMenu { CardMenu(item: item, showsDetails: true) }
        .accessibilityIdentifier("thumb.\(item.id)")
    }

    @ViewBuilder private var progress: some View {
        let percent = Format.progress(app.userData.current(item))
        if percent > 0 { ProgressBar(percent: percent).padding(8) }
    }
}

/// Card labels, as on the web client.
enum CardText {
    /// The show for an episode, the item itself otherwise.
    static func title(_ item: Item) -> String {
        (item.kind == .episode ? item.seriesName : item.name) ?? ""
    }

    /// "S1:E2 · Pilot" for episodes, "23 min left" for a started film.
    static func subtitle(_ item: Item) -> String {
        if item.kind == .episode {
            return [Format.episodeCode(season: item.parentIndexNumber, episode: item.indexNumber), item.name ?? ""]
                .filter { !$0.isEmpty }.joined(separator: " · ")
        }
        guard item.positionSeconds > 0 else { return item.productionYear.map(String.init) ?? "" }
        let left = Int(((item.runtimeSeconds - item.positionSeconds) / 60).rounded(.up))
        return L10n.f("minutes_left", "\(left)")
    }
}
