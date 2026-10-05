import JellyfinKit
import SwiftUI

/// Status, genre, year, age rating and (films only: a series has no file) video quality.
struct FilterSheet: View {
    @Bindable var model: LibraryModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker(L10n.t("filter_status"), selection: $model.prefs.status) {
                    ForEach(ViewPrefs.Status.allCases, id: \.self) { Text(L10n.t("status_\($0.rawValue)")).tag($0) }
                }
                chips(L10n.t("filter_genres"), model.filters.genres ?? [], selection: $model.prefs.genres) { $0 }
                chips(L10n.t("filter_years"), (model.filters.years ?? []).sorted(by: >), selection: $model.prefs.years) { String($0) }
                chips(L10n.t("filter_ratings"), model.filters.officialRatings ?? [], selection: $model.prefs.ratings) { $0 }
                if model.isMovies {
                    chips(L10n.t("filter_quality"), ViewPrefs.Quality.allCases, selection: $model.prefs.quality) {
                        L10n.t("quality_\($0.rawValue)")
                    }
                }
            }
            .navigationTitle(L10n.t("filters"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("filters_clear")) { model.prefs.clearFilters() }.disabled(model.prefs.activeFilterCount == 0)
                }
                ToolbarItem(placement: .confirmationAction) { Button(L10n.t("filters_done")) { dismiss() } }
            }
            .task { await model.loadFilters() }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func chips<T: Hashable>(_ title: String, _ options: [T], selection: Binding<[T]>,
                                    label: @escaping (T) -> String) -> some View {
        if !options.isEmpty {
            Section(title) {
                FlowChips(options: options, selection: selection, label: label)
            }
        }
    }
}

/// Multi-select chips that wrap onto as many lines as they need.
struct FlowChips<T: Hashable>: View {
    let options: [T]
    @Binding var selection: [T]
    let label: (T) -> String

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: Array(repeating: GridItem(.fixed(34), spacing: 8), count: min(3, max(1, options.count / 6 + 1))), spacing: 8) {
                ForEach(options, id: \.self) { option in chip(option) }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ option: T) -> some View {
        let on = selection.contains(option)
        return Button {
            if on { selection.removeAll { $0 == option } } else { selection.append(option) }
        } label: {
            Text(label(option)).font(Theme.meta).padding(.horizontal, 12).frame(height: 32)
                .background(on ? Theme.text : Theme.surface2, in: .rect(cornerRadius: Theme.radiusSmall))
                .foregroundStyle(on ? Theme.base : Theme.text)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
