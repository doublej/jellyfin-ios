import JellyfinKit
import SwiftUI

/// Cast and crew, each opening their person page.
struct CastRow: View {
    let people: [Person]

    var body: some View {
        if !people.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: L10n.t("cast"))
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(people.prefix(30), id: \.self) { person in
                            NavigationLink(value: Route.item(person.asItem)) { tile(person) }.buttonStyle(CardButtonStyle())
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func tile(_ person: Person) -> some View {
        VStack(spacing: 6) {
            Artwork(art: person.art, width: 84).frame(width: 84, height: 84).clipShape(.circle)
            Text(person.name ?? "").font(Theme.caption).foregroundStyle(Theme.text).lineLimit(2).multilineTextAlignment(.center)
            if let role = person.role, !role.isEmpty {
                Text(role).font(Theme.caption).foregroundStyle(Theme.text3).lineLimit(1)
            }
        }
        .frame(width: 96)
    }
}

/// Posters in a grid that adapts to the width: three across on phones.
struct PosterGrid: View {
    let items: [Item]
    @Environment(\.cardSize) private var size

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size.poster - 8), spacing: 12, alignment: .top)], spacing: 18) {
            ForEach(items) { PosterCard(item: $0, width: nil) }
        }
    }
}
