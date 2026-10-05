import JellyfinKit
import SwiftUI

/// Home: hero, Continue Watching, Next Up, and Recently Added per library.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @State private var model = HomeModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            if let content = model.content {
                rows(content)
            } else if model.failed {
                ErrorState(message: L10n.t("home_failed")) { Task { await reload() } }.padding(.top, 120)
            } else {
                ProgressView().padding(.top, 200)
            }
        }
        .background(Theme.base)
        .ignoresSafeArea(edges: model.content?.hero == nil ? [] : .top)
        .refreshable { await reload() }
        .task {
            if let userId = app.session?.userId { model.showCached(userId: userId) }
            await reload()
        }
        .onChange(of: app.playing) { old, new in if old != nil, new == nil { Task { await reload() } } }
        .toolbar {
            if sizeClass == .compact {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsView() } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel(L10n.t("nav_settings")).accessibilityIdentifier("home.settings")
                }
            }
        }
    }

    private func reload() async {
        guard let client = app.client else { return }
        await model.load(client)
        if let error = model.error { app.check(error) }
    }

    @ViewBuilder private func rows(_ content: HomeModel.Content) -> some View {
        LazyVStack(alignment: .leading, spacing: 28) {
            if let hero = content.hero { HeroView(item: hero) }
            if content.isEmpty { Text(L10n.t("home_empty")).metaStyle().padding(24) }
            if !content.resume.isEmpty {
                RowView(title: L10n.t("home_continue"), items: content.resume) { ThumbCard(item: $0) }
            }
            if !content.nextUp.isEmpty {
                RowView(title: L10n.t("home_next_up"), items: content.nextUp) { ThumbCard(item: $0) }
            }
            ForEach(content.shelves) { shelf in
                if !shelf.items.isEmpty {
                    RowView(title: L10n.f("home_latest", shelf.library.name ?? ""), items: shelf.items, link: .library(shelf.library)) {
                        PosterCard(item: $0)
                    }
                }
            }
        }
        .padding(.bottom, 32)
        .onAppear { Timing.mark("home-drawn") }
    }
}
