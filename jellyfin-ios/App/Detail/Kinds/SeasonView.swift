import JellyfinKit
import SwiftUI

/// A season: its episodes, with a way back to the series.
struct SeasonView: View {
    let item: Item
    @Environment(AppModel.self) private var app
    @State private var episodes: [Item] = []

    var body: some View {
        DetailScaffold(item: item) {
            VStack(alignment: .leading, spacing: 8) {
                if let seriesId = item.seriesId {
                    NavigationLink(value: Route.item(Item(id: seriesId, name: item.seriesName, type: "Series"))) {
                        Text(L10n.f("series_link", item.seriesName ?? "")).font(Theme.meta.weight(.semibold)).foregroundStyle(Theme.text2)
                    }
                }
                Text(item.name ?? "").titleStyle(Theme.largeTitle)
            }
            HStack(spacing: 10) {
                if let first = episodes.first(where: { !app.userData.isPlayed($0) }) ?? episodes.first { PlayButton(item: first) }
                Toggles(item: item)
            }
            Overview(text: item.overview)
            SectionTitle(text: L10n.t("episodes"))
            EpisodeList(episodes: episodes)
        }
        .task {
            guard let client = app.client, let seriesId = item.seriesId else { return }
            episodes = (try? await client.episodes(seriesId: seriesId, seasonId: item.id)) ?? []
        }
    }
}
