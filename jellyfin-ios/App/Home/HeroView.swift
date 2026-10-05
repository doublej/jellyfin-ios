import JellyfinKit
import SwiftUI

/// Full-bleed backdrop with logo art, one metadata line and one primary action: Resume when
/// there is something to resume.
struct HeroView: View {
    let item: Item
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let gutter = Gutter.of(geometry.size.width)
            ZStack(alignment: .bottomLeading) {
                Artwork(art: item.backdropArt, width: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                scrim
                details.padding(.horizontal, gutter).padding(.bottom, 28)
            }
        }
        .frame(height: sizeClass == .regular ? 560 : 480)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.hero")
    }

    private var scrim: some View {
        LinearGradient(colors: [.clear, Theme.base.opacity(0.65), Theme.base], startPoint: .center, endPoint: .bottom)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            TitleArt(item: item, height: sizeClass == .regular ? 120 : 84)
            Text(meta).metaStyle()
            HStack(spacing: 10) {
                PlayButton(item: app.userData.current(item))
                NavigationLink(value: Route.item(item)) { Label(L10n.t("details"), systemImage: "info.circle") }
                    .buttonStyle(.secondary)
            }
        }
        .frame(maxWidth: 560, alignment: .leading)
    }

    private var meta: String {
        let parts: [String?] = item.kind == .episode
            ? [item.seriesName, CardText.subtitle(item)]
            : [item.productionYear.map(String.init), item.officialRating, Format.duration(item.runTimeTicks)]
        return parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// The title logo from the artwork, or the typed title when there is none.
struct TitleArt: View {
    let item: Item
    var height: CGFloat

    var body: some View {
        if let logo = item.logoArt {
            Artwork(art: logo, width: height * 3.5, contentMode: .fit, transparent: true)
                .frame(maxWidth: height * 3.5, maxHeight: height, alignment: .leading)
                .accessibilityLabel(CardText.title(item))
        } else {
            Text(CardText.title(item)).titleStyle(Theme.largeTitle).lineLimit(2)
        }
    }
}
