import JellyfinKit
import SwiftUI

/// A series: next episode to play, seasons, the chosen season's episodes, cast and similar series.
struct SeriesView: View {
    let item: Item
    @Environment(AppModel.self) private var app
    @State private var seasons: [Item] = []
    @State private var seasonId: String?
    @State private var episodes: [Item] = []
    @State private var nextUp: Item?
    @State private var similar: [Item] = []

    var body: some View {
        DetailScaffold(item: item) {
            DetailHeader(item: item)
            actions
            Overview(text: item.overview)
            Facts(item: item)
            if !seasons.isEmpty { seasonPicker }
            EpisodeList(episodes: episodes)
            CastRow(people: item.people ?? [])
            if !similar.isEmpty {
                SectionTitle(text: L10n.t("similar"))
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) { ForEach(similar) { PosterCard(item: $0) } }
                }
                .scrollIndicators(.hidden)
            }
        }
        .task { await load() }
        .task(id: seasonId) { await loadEpisodes() }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            if let nextUp {
                Button { app.play(PlayRequest(item: nextUp)) } label: {
                    let code = Format.episodeCode(season: nextUp.parentIndexNumber, episode: nextUp.indexNumber)
                    Label(L10n.f(nextUp.positionSeconds > 0 ? "resume_episode" : "play_episode", code), systemImage: "play.fill")
                }
                .buttonStyle(.primary).accessibilityIdentifier("detail.play")
            }
            Toggles(item: item)
        }
    }

    private var seasonPicker: some View {
        Picker(L10n.t("seasons"), selection: $seasonId) {
            ForEach(seasons) { Text($0.name ?? "").tag($0.id as String?) }
        }
        .pickerStyle(.menu).tint(Theme.text).font(Theme.headline)
        .accessibilityIdentifier("series.seasons")
    }

    private func load() async {
        guard let client = app.client else { return }
        async let seasons = client.seasons(seriesId: item.id)
        async let next = client.nextUp(limit: 1, seriesId: item.id)
        async let similar = client.similar(item.id)
        self.seasons = (try? await seasons) ?? []
        nextUp = (try? await next)?.first
        if seasonId == nil { seasonId = nextUp?.seasonId ?? self.seasons.first?.id }
        self.similar = (try? await similar) ?? []
    }

    private func loadEpisodes() async {
        guard let client = app.client, let seasonId else { return }
        episodes = (try? await client.episodes(seriesId: item.id, seasonId: seasonId)) ?? []
    }
}
