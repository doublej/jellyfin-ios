import JellyfinKit
import SwiftUI

/// One library's items, a page at a time, in the order and with the filters this device last
/// used for it.
@Observable
final class LibraryModel {
    let library: Item
    var prefs: ViewPrefs {
        didSet {
            guard prefs != oldValue else { return }
            AppModel.store(prefs, Self.key(library.id))
            Task { await reload() }
        }
    }
    var letter: String? {
        didSet { if letter != oldValue { Task { await reload() } } }
    }
    private(set) var items: [Item] = []
    private(set) var total: Int?
    private(set) var failed = false
    private(set) var loading = false
    private(set) var filters = QueryFilters()
    var client: APIClient?
    private var generation = 0

    static let pageSize = 60

    init(library: Item) {
        self.library = library
        prefs = AppModel.load(ViewPrefs.self, Self.key(library.id)) ?? ViewPrefs()
    }

    static func key(_ id: String) -> String { "jf.view.\(id)" }

    var isMovies: Bool { library.collectionType == "movies" }
    var itemType: String { isMovies ? "Movie" : "Series" }
    var sorts: [String] { isMovies ? ViewPrefs.movieSorts : ViewPrefs.seriesSorts }

    func reload() async {
        generation += 1
        items = []
        total = nil
        await loadMore()
    }

    func loadMore() async {
        guard let client, !loading, total.map({ items.count < $0 }) ?? true else { return }
        loading = true
        let request = generation
        defer { loading = false }
        let query: Query = [
            ("parentId", library.id), ("includeItemTypes", itemType), ("recursive", "true"),
            ("startIndex", "\(items.count)"), ("limit", "\(Self.pageSize)"), ("enableTotalRecordCount", "true")
        ] + prefs.query(letter: letter)
        do {
            let page = try await client.page(query)
            guard request == generation else { return }
            items += page.items ?? []
            total = page.totalRecordCount ?? items.count
            failed = false
        } catch {
            failed = items.isEmpty
        }
    }

    func loadFilters() async {
        guard let client else { return }
        filters = (try? await client.filters(parentId: library.id, types: itemType)) ?? QueryFilters()
    }
}
