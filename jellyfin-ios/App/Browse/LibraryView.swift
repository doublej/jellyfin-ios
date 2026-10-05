import JellyfinKit
import SwiftUI

/// Films or series: posters or a list, sorted and filtered, with a letter strip to jump.
struct LibraryView: View {
    let library: Item
    @Environment(AppModel.self) private var app
    @State private var model: LibraryModel
    @State private var showFilters = false

    init(library: Item) {
        self.library = library
        _model = State(initialValue: LibraryModel(library: library))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let total = model.total {
                    Text(L10n.f(model.isMovies ? "count_films" : "count_series", "\(total)")).metaStyle()
                }
                content
            }
            .padding(.horizontal, 16).padding(.trailing, 18).padding(.bottom, 32)
        }
        .overlay(alignment: .trailing) { AlphaIndex(selection: $model.letter) }
        .background(Theme.base)
        .navigationTitle(library.name ?? "")
        .toolbar { BrowseToolbar(model: model, showFilters: $showFilters) }
        .sheet(isPresented: $showFilters) { FilterSheet(model: model) }
        .task {
            model.client = app.client
            if model.items.isEmpty { await model.reload() }
        }
    }

    @ViewBuilder private var content: some View {
        if model.failed {
            ErrorState(message: L10n.t("browse_failed")) { Task { await model.reload() } }
        } else if model.total == 0 {
            Text(L10n.t("browse_empty")).metaStyle().padding(.top, 40)
        } else if model.prefs.layout == .grid {
            PosterGrid(items: model.items)
            pager
        } else {
            LazyVStack(alignment: .leading, spacing: 12) { ForEach(model.items) { ListRowCard(item: $0) } }
            pager
        }
    }

    /// Reaching the end of the loaded items asks for the next page.
    @ViewBuilder private var pager: some View {
        if model.total.map({ model.items.count < $0 }) ?? true {
            ProgressView().frame(maxWidth: .infinity).padding().onAppear { Task { await model.loadMore() } }
        }
    }
}

/// Sort, order, layout and the filter sheet.
struct BrowseToolbar: ToolbarContent {
    @Bindable var model: LibraryModel
    @Binding var showFilters: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Picker(L10n.t("sort_label"), selection: $model.prefs.sortBy) {
                    ForEach(model.sorts, id: \.self) { Text(L10n.t("sort_\($0)")).tag($0) }
                }
                Picker(L10n.t("sort_label"), selection: $model.prefs.ascending) {
                    Text(L10n.t("sort_ascending")).tag(true)
                    Text(L10n.t("sort_descending")).tag(false)
                }
            } label: { Image(systemName: "arrow.up.arrow.down") }
                .accessibilityLabel(L10n.t("sort_label")).accessibilityIdentifier("browse.sort")
            Button { model.prefs.layout = model.prefs.layout == .grid ? .list : .grid } label: {
                Image(systemName: model.prefs.layout == .grid ? "list.bullet" : "square.grid.3x2")
            }
            .accessibilityLabel(model.prefs.layout == .grid ? L10n.t("layout_list") : L10n.t("layout_grid"))
            .accessibilityIdentifier("browse.layout")
            Button { showFilters = true } label: {
                Image(systemName: model.prefs.activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel(model.prefs.activeFilterCount > 0
                                ? L10n.f("filters_active", "\(model.prefs.activeFilterCount)") : L10n.t("filters"))
            .accessibilityIdentifier("browse.filters")
        }
    }
}
