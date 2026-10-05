import JellyfinKit
import SwiftUI

/// The long-press menu on every card: the watched and favourite toggles, plus the way to the
/// item's own page where a tap plays instead.
struct CardMenu: View {
    let item: Item
    var showsDetails = false
    @Environment(AppModel.self) private var app

    var body: some View {
        if showsDetails {
            NavigationLink(value: Route.item(item)) { Label(L10n.t("details"), systemImage: "info.circle") }
        }
        if item.kind == .episode, let seriesId = item.seriesId {
            NavigationLink(value: Route.item(Item(id: seriesId, name: item.seriesName, type: "Series"))) {
                Label(L10n.f("series_link", item.seriesName ?? ""), systemImage: "tv")
            }
        }
        if item.kind != .person {
            Button { app.userData.togglePlayed(item, client: app.client) } label: {
                app.userData.isPlayed(item)
                    ? Label(L10n.t("mark_unplayed"), systemImage: "eye.slash")
                    : Label(L10n.t("mark_played"), systemImage: "checkmark.circle")
            }
        }
        Button { app.userData.toggleFavorite(item, client: app.client) } label: {
            app.userData.isFavorite(item)
                ? Label(L10n.t("remove_favorite"), systemImage: "heart.slash")
                : Label(L10n.t("add_favorite"), systemImage: "heart")
        }
    }
}
