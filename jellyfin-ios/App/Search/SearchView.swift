import JellyfinKit
import SwiftUI

/// Search as you type, grouped by type: films, series, episodes, collections, people.
struct SearchView: View {
    @Environment(AppModel.self) private var app
    @State private var query = ""
    @State private var results: [Item] = []
    @State private var people: [Item] = []
    @State private var suggestions: [Item] = []
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    group(L10n.t("search_suggestions"), suggestions)
                } else if failed {
                    Text(L10n.t("search_failed")).metaStyle()
                } else if results.isEmpty, people.isEmpty {
                    Text(L10n.f("search_none", query)).metaStyle()
                } else {
                    group(L10n.t("group_films"), results.filter { $0.kind == .movie })
                    group(L10n.t("group_series"), results.filter { $0.kind == .series })
                    episodes(results.filter { $0.kind == .episode })
                    group(L10n.t("group_collections"), results.filter { $0.kind == .boxSet })
                    group(L10n.t("group_people"), people)
                }
            }
            .padding(16)
        }
        .background(Theme.base)
        .navigationTitle(L10n.t("nav_search"))
        .searchable(text: $query, prompt: L10n.t("search_label"))
        .task(id: query) { await search() }
        .task { await suggest() }
    }

    @ViewBuilder private func group(_ title: String, _ items: [Item]) -> some View {
        if !items.isEmpty {
            SectionTitle(text: title)
            PosterGrid(items: items)
        }
    }

    @ViewBuilder private func episodes(_ items: [Item]) -> some View {
        if !items.isEmpty {
            SectionTitle(text: L10n.t("group_episodes"))
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) { ForEach(items) { ThumbCard(item: $0) } }
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Waits 250 ms after the last keystroke; a newer query cancels this one.
    private func search() async {
        let term = query.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty, let client = app.client else { return results = [] }
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }
        do {
            async let items = client.search(term)
            async let persons = client.searchPeople(term)
            (results, people) = try await (items, persons)
            failed = false
        } catch is CancellationError {
        } catch {
            failed = (error as? URLError)?.code != .cancelled
        }
    }

    private func suggest() async {
        let query: Query = [("recursive", "true"), ("includeItemTypes", "Movie,Series"), ("sortBy", "Random"), ("limit", "12")]
        suggestions = (try? await app.client?.page(query).items) ?? []
    }
}
