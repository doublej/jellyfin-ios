import JellyfinKit
import SwiftUI

/// Signed in: Home, the libraries, Downloads, Settings and Search. Phones get a tab bar (Settings
/// sits behind Home's gear, so nothing spills into More); iPads a sidebar they can collapse.
struct MainTabs: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var libraries: [Item] = []

    var body: some View {
        TabView {
            Tab(L10n.t("nav_home"), systemImage: "house") { stack { HomeView() } }
                .accessibilityIdentifier("tab.home")
            TabSection(L10n.t("nav_libraries")) {
                ForEach(libraries) { library in
                    Tab(library.name ?? "", systemImage: library.collectionType == "movies" ? "film" : "tv") {
                        stack { LibraryView(library: library) }
                    }
                }
            }
            Tab(L10n.t("nav_downloads"), systemImage: "arrow.down.circle") { stack { DownloadsView() } }
            if sizeClass != .compact {
                Tab(L10n.t("nav_settings"), systemImage: "gearshape") { stack { SettingsView() } }
            }
            Tab(L10n.t("nav_search"), systemImage: "magnifyingglass", role: .search) { stack { SearchView() } }
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(\.cardSize, CardSize.of(sizeClass))
        .task { await loadLibraries() }
    }

    private func stack(@ViewBuilder _ content: () -> some View) -> some View {
        NavigationStack { content().routeDestinations() }
    }

    private func loadLibraries() async {
        if let userId = app.session?.userId { libraries = HomeCache.load(userId: userId)?.libraries ?? [] }
        guard let views = try? await app.client?.views() else { return }
        libraries = views.filter { $0.collectionType == "movies" || $0.collectionType == "tvshows" }
    }
}
