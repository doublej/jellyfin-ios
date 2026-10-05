import JellyfinKit
import SwiftUI

/// Overview with More/Less, and the facts column: genres, director, writers, studio.
struct Overview: View {
    let text: String?
    @State private var expanded = false

    var body: some View {
        if let text, !text.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(text).font(Theme.body).foregroundStyle(Theme.text).lineLimit(expanded ? nil : 4)
                Button(expanded ? L10n.t("show_less") : L10n.t("show_more")) { withAnimation(Theme.fast) { expanded.toggle() } }
                    .font(Theme.meta.weight(.semibold)).foregroundStyle(Theme.text2)
            }
            .frame(maxWidth: 720, alignment: .leading)
        }
    }
}

struct Facts: View {
    let item: Item

    var body: some View {
        let rows = self.rows
        if !rows.isEmpty {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 8) {
                ForEach(rows, id: \.0) { label, value in
                    GridRow {
                        Text(label).font(Theme.meta).foregroundStyle(Theme.text3)
                        Text(value).font(Theme.meta).foregroundStyle(Theme.text2)
                    }
                }
            }
        }
    }

    private var rows: [(String, String)] {
        let people = item.people ?? []
        let names = { (type: String) in people.filter { $0.type == type }.compactMap(\.name).prefix(4).joined(separator: ", ") }
        let studio = (item.studios ?? []).compactMap(\.name).prefix(3).joined(separator: ", ")
        return [
            (L10n.t("facts_genres"), (item.genres ?? []).joined(separator: ", ")),
            (L10n.t("facts_directors"), names("Director")),
            (L10n.t("facts_writers"), names("Writer")),
            (L10n.t(item.kind == .series ? "facts_network" : "facts_studios"), studio)
        ].filter { !$0.1.isEmpty }
    }
}
