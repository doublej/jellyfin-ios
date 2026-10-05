import JellyfinKit
import SwiftUI

/// A person: photo, dates, biography, and the films and series they appear in.
struct PersonView: View {
    let item: Item
    @Environment(AppModel.self) private var app
    @State private var work: [Item] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 20) {
                    Artwork(art: item.primaryArt, width: 140).frame(width: 140, height: 210).clipShape(.rect(cornerRadius: Theme.radius))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name ?? "").titleStyle(Theme.largeTitle)
                        ForEach(dates, id: \.self) { Text($0).metaStyle() }
                    }
                }
                Overview(text: item.overview)
                section(L10n.t("person_films"), work.filter { $0.kind == .movie })
                section(L10n.t("person_series"), work.filter { $0.kind == .series })
            }
            .padding(20)
        }
        .background(Theme.base)
        .task { work = (try? await app.client?.filmography(personId: item.id)) ?? [] }
    }

    @ViewBuilder private func section(_ title: String, _ items: [Item]) -> some View {
        if !items.isEmpty {
            SectionTitle(text: title)
            PosterGrid(items: items)
        }
    }

    private var dates: [String] {
        let format = { (date: Date) in date.formatted(date: .long, time: .omitted) }
        var lines: [String] = []
        if let born = item.premiereDate {
            let place = item.productionLocations?.first.map { ", \($0)" } ?? ""
            lines.append(L10n.f("person_born", format(born)) + place)
        }
        if let died = item.endDate { lines.append(L10n.f("person_died", format(died))) }
        return lines
    }
}
