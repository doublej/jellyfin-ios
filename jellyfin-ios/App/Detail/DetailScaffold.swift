import JellyfinKit
import SwiftUI

/// The backdrop behind the whole page, tinted by its average colour, with the title block over
/// its fade. No poster column: the backdrop already carries the film.
struct DetailScaffold<Content: View>: View {
    let item: Item
    @ViewBuilder let content: Content
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let gutter = Gutter.of(geometry.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    backdrop(geometry.size.width)
                    VStack(alignment: .leading, spacing: 24) { content }
                        .padding(.horizontal, gutter).padding(.bottom, 40)
                        .offset(y: -80).padding(.bottom, -80)
                }
            }
            .background(glow)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var backdropHeight: CGFloat { sizeClass == .regular ? 460 : 300 }

    private func backdrop(_ width: CGFloat) -> some View {
        Artwork(art: item.backdropArt ?? item.primaryArt, width: width)
            .frame(width: width, height: backdropHeight)
            .overlay { LinearGradient(colors: [.clear, .clear, Theme.base.opacity(0.75), Theme.base], startPoint: .top, endPoint: .bottom) }
    }

    private var glow: some View {
        ZStack {
            Theme.base
            if let tint = item.backdropArt?.tint {
                RadialGradient(colors: [tint, .clear], center: .top, startRadius: 0, endRadius: 700).opacity(0.9)
            }
        }
        .ignoresSafeArea()
    }
}

/// Logo or title, then one line of facts.
struct DetailHeader: View {
    let item: Item
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if item.kind == .episode, let series = item.seriesName {
                Text(series).font(Theme.headline).foregroundStyle(Theme.text2)
            }
            if item.kind == .episode {
                Text(item.name ?? "").titleStyle(Theme.largeTitle)
            } else {
                TitleArt(item: item, height: sizeClass == .regular ? 110 : 80)
            }
            Text(facts).metaStyle()
            if let tagline = item.taglines?.first { Text(tagline).font(Theme.body.italic()).foregroundStyle(Theme.text2) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var facts: String {
        var parts: [String] = []
        if item.kind == .episode { parts.append(Format.episodeCode(season: item.parentIndexNumber, episode: item.indexNumber)) }
        if let year = item.productionYear { parts.append(String(year)) }
        if let rating = item.officialRating { parts.append(rating) }
        if let score = item.communityRating { parts.append(String(format: "★ %.1f", score)) }
        let length = Format.duration(item.runTimeTicks)
        if !length.isEmpty { parts.append(length) }
        if item.runTimeTicks != nil, item.isPlayable { parts.append(endsAt) }
        return parts.joined(separator: " · ")
    }

    private var endsAt: String {
        let left = item.runtimeSeconds - item.positionSeconds
        return L10n.f("ends_at", Date(timeIntervalSinceNow: left).formatted(date: .omitted, time: .shortened))
    }
}
