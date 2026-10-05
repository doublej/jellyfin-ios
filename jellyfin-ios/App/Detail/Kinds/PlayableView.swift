import JellyfinKit
import SwiftUI

/// A film or an episode: play actions, pickers, overview, facts, chapters, cast and similar items.
/// Episodes also link to their series and season and list the rest of the season.
struct PlayableView: View {
    let item: Item
    @Environment(AppModel.self) private var app
    @State private var choice = StreamChoice()
    @State private var similar: [Item] = []
    @State private var season: [Item] = []

    var body: some View {
        DetailScaffold(item: item) {
            DetailHeader(item: item)
            if item.kind == .episode { links }
            PlayActions(item: item, choice: choice)
            StreamPickers(item: item, choice: $choice)
            Overview(text: item.overview)
            Facts(item: item)
            ChaptersRow(item: item, choice: choice)
            CastRow(people: item.people ?? [])
            if !season.isEmpty {
                SectionTitle(text: L10n.f("more_from_season", item.seasonName ?? ""))
                EpisodeList(episodes: season)
            }
            if !similar.isEmpty {
                SectionTitle(text: L10n.t("similar"))
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) { ForEach(similar) { PosterCard(item: $0) } }
                }
                .scrollIndicators(.hidden)
            }
        }
        .task { await loadMore() }
    }

    private var links: some View {
        HStack(spacing: 16) {
            if let seriesId = item.seriesId {
                NavigationLink(value: Route.item(Item(id: seriesId, name: item.seriesName, type: "Series"))) {
                    Text(L10n.f("series_link", item.seriesName ?? ""))
                }
            }
            if let seasonId = item.seasonId {
                NavigationLink(value: Route.item(Item(id: seasonId, name: item.seasonName, type: "Season"))) {
                    Text(L10n.f("season_link", item.seasonName ?? ""))
                }
            }
        }
        .font(Theme.meta.weight(.semibold)).foregroundStyle(Theme.text2)
    }

    private func loadMore() async {
        guard let client = app.client else { return }
        if item.kind == .episode, let seriesId = item.seriesId {
            season = ((try? await client.episodes(seriesId: seriesId, seasonId: item.seasonId)) ?? []).filter { $0.id != item.id }
        } else {
            similar = (try? await client.similar(item.id)) ?? []
        }
    }
}
