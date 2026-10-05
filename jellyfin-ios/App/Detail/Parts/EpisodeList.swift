import JellyfinKit
import SwiftUI

/// A season's episodes: still, code and name, runtime, overview; a tap plays, the menu toggles.
struct EpisodeList: View {
    let episodes: [Item]
    @Environment(AppModel.self) private var app

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(episodes) { episode in row(episode) }
        }
    }

    private func row(_ episode: Item) -> some View {
        let current = app.userData.current(episode)
        return HStack(alignment: .top, spacing: 14) {
            thumb(episode, current)
            NavigationLink(value: Route.item(episode)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(episode.indexNumber.map { "\($0). " } ?? "")\(episode.name ?? "")").font(Theme.headline).foregroundStyle(Theme.text)
                    Text(Format.duration(episode.runTimeTicks)).font(Theme.caption).foregroundStyle(Theme.text3)
                    Text(episode.overview ?? "").font(Theme.meta).foregroundStyle(Theme.text2).lineLimit(3)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("episode.\(episode.id)")
        }
        .contextMenu { CardMenu(item: episode) }
    }

    private func thumb(_ episode: Item, _ current: Item) -> some View {
        Button { app.play(PlayRequest(item: episode)) } label: {
            Artwork(art: episode.thumbArt, width: 180).frame(width: 160, height: 90)
                .clipShape(.rect(cornerRadius: Theme.radius))
                .overlay(alignment: .bottom) {
                    if Format.progress(current) > 0, !current.isPlayed { ProgressBar(percent: Format.progress(current)).padding(6) }
                }
                .overlay(alignment: .topTrailing) { WatchBadge(item: episode).padding(6) }
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityLabel(L10n.f("play_episode_named", "\(episode.indexNumber ?? 0)", episode.name ?? ""))
    }
}
