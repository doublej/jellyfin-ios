import JellyfinKit
import SwiftUI

/// The one primary action: Resume when there is a position, Play otherwise.
struct PlayButton: View {
    let item: Item
    var choice = StreamChoice()
    @Environment(AppModel.self) private var app

    var body: some View {
        let current = app.userData.current(item)
        Button {
            app.play(PlayRequest(item: item, sourceId: choice.sourceId, audio: choice.audio, subtitle: choice.subtitle))
        } label: {
            Label(current.positionSeconds > 0 && !current.isPlayed ? L10n.t("resume") : L10n.t("play"), systemImage: "play.fill")
        }
        .buttonStyle(.primary)
        .accessibilityIdentifier("detail.play")
    }
}

/// Play, play from the beginning, and the toggles, in a row under the title.
struct PlayActions: View {
    let item: Item
    var choice = StreamChoice()
    @Environment(AppModel.self) private var app

    var body: some View {
        let current = app.userData.current(item)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                PlayButton(item: item, choice: choice)
                if current.positionSeconds > 0, !current.isPlayed {
                    Button { app.play(PlayRequest(item: item, start: 0, sourceId: choice.sourceId, audio: choice.audio, subtitle: choice.subtitle)) } label: {
                        Image(systemName: "backward.end.alt")
                    }
                    .buttonStyle(.secondary).accessibilityLabel(L10n.t("play_from_start"))
                }
                Toggles(item: item)
                DownloadButton(item: item)
            }
            if current.positionSeconds > 0, !current.isPlayed {
                Text(L10n.f("resume_from", Format.clock(current.positionSeconds))).font(Theme.caption).foregroundStyle(Theme.text3)
            }
        }
    }
}

/// Watched and favourite, as icon buttons with spoken labels.
struct Toggles: View {
    let item: Item
    @Environment(AppModel.self) private var app

    var body: some View {
        let played = app.userData.isPlayed(item), favorite = app.userData.isFavorite(item)
        Button { app.userData.togglePlayed(item, client: app.client) } label: {
            Image(systemName: played ? "checkmark.circle.fill" : "checkmark.circle")
        }
        .buttonStyle(.secondary)
        .accessibilityLabel(played ? L10n.t("mark_unplayed") : L10n.t("mark_played"))
        .accessibilityIdentifier("toggle.played")
        Button { app.userData.toggleFavorite(item, client: app.client) } label: {
            Image(systemName: favorite ? "heart.fill" : "heart").foregroundStyle(favorite ? Theme.red : Theme.text)
        }
        .buttonStyle(.secondary)
        .accessibilityLabel(favorite ? L10n.t("remove_favorite") : L10n.t("add_favorite"))
        .accessibilityIdentifier("toggle.favorite")
    }
}

/// Which version, audio and subtitle track the player opens with.
struct StreamChoice: Equatable {
    var sourceId: String?
    var audio: Int?
    var subtitle: Int?
}

struct StreamPickers: View {
    let item: Item
    @Binding var choice: StreamChoice

    var body: some View {
        let sources = item.mediaSources ?? []
        let source = sources.first { $0.id == choice.sourceId } ?? sources.first
        VStack(alignment: .leading, spacing: 8) {
            if sources.count > 1 {
                picker(L10n.t("picker_version"), selection: $choice.sourceId, options: sources.map { ($0.id as String?, $0.name ?? $0.id) })
            }
            if let source, source.audioTracks.count > 1 {
                picker(L10n.t("picker_audio"), selection: $choice.audio, options: source.audioTracks.map { ($0.index as Int?, $0.label) },
                       current: source.defaultAudioStreamIndex)
            }
            if let source, !source.subtitleTracks.isEmpty {
                picker(L10n.t("picker_subtitles"), selection: $choice.subtitle,
                       options: [(-1 as Int?, L10n.t("subtitles_off"))] + source.subtitleTracks.map { ($0.index as Int?, $0.label) },
                       current: source.defaultSubtitleStreamIndex ?? -1)
            }
        }
    }

    private func picker<T: Hashable>(_ title: String, selection: Binding<T?>, options: [(T?, String)], current: T? = nil) -> some View {
        let shown = selection.wrappedValue ?? current ?? options.first?.0
        return Menu {
            Picker(title, selection: selection) {
                ForEach(options, id: \.1) { Text($0.1).tag($0.0) }
            }
        } label: {
            HStack {
                Text(title).foregroundStyle(Theme.text3)
                Text(options.first { $0.0 == shown }?.1 ?? "").foregroundStyle(Theme.text).lineLimit(1)
                Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(Theme.text3)
            }
            .font(Theme.meta)
        }
        .accessibilityIdentifier("picker.\(title)")
    }
}
