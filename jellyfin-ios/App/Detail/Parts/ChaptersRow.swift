import JellyfinKit
import SwiftUI

/// Chapters with their images; a tap plays from there.
struct ChaptersRow: View {
    let item: Item
    var choice = StreamChoice()
    @Environment(AppModel.self) private var app

    var body: some View {
        let chapters = item.chapters ?? []
        if chapters.count > 1 {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: L10n.t("chapters"))
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in tile(index, chapter) }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func tile(_ index: Int, _ chapter: Chapter) -> some View {
        Button {
            app.play(PlayRequest(item: item, start: chapter.startSeconds, sourceId: choice.sourceId, audio: choice.audio, subtitle: choice.subtitle))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Artwork(art: item.chapterArt(index), width: 200).aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: Theme.radius))
                Text(chapter.name ?? "").font(Theme.caption).foregroundStyle(Theme.text).lineLimit(1)
                Text(Format.clock(chapter.startSeconds)).font(Theme.caption.monospacedDigit()).foregroundStyle(Theme.text3)
            }
            .frame(width: 200)
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityLabel(L10n.f("chapter_play", chapter.name ?? "", Format.clock(chapter.startSeconds)))
    }
}
