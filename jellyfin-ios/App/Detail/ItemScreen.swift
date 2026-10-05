import JellyfinKit
import SwiftUI

/// Any item's page: draws from the summary it was opened with, then the full item.
struct ItemScreen: View {
    let summary: Item
    @Environment(AppModel.self) private var app
    @State private var item: Item?
    @State private var failed = false

    var body: some View {
        Group {
            if let item {
                content(item)
            } else if failed {
                ErrorState(message: L10n.t("detail_failed")) { Task { await load() } }
            } else {
                DetailScaffold(item: summary) { ProgressView().frame(maxWidth: .infinity).padding(40) }
            }
        }
        .background(Theme.base)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onChange(of: app.playing) { old, new in if old != nil, new == nil { Task { await load() } } }
    }

    @ViewBuilder private func content(_ item: Item) -> some View {
        switch item.kind {
        case .series: SeriesView(item: item)
        case .season: SeasonView(item: item)
        case .person: PersonView(item: item)
        case .boxSet, .folder: CollectionView(item: item)
        default: PlayableView(item: item)
        }
    }

    private func load() async {
        guard let client = app.client else { return }
        do {
            let full = try await client.item(summary.id)
            item = full
            app.userData.update(full)
            failed = false
        } catch {
            app.check(error)
            failed = item == nil
        }
    }
}

/// A collection (box set): its films as a grid.
struct CollectionView: View {
    let item: Item
    @Environment(AppModel.self) private var app
    @State private var children: [Item] = []

    var body: some View {
        DetailScaffold(item: item) {
            PosterGrid(items: children)
        }
        .task { children = (try? await app.client?.items("/Items", [("parentId", item.id)] + APIClient.cardFields)) ?? [] }
    }
}
