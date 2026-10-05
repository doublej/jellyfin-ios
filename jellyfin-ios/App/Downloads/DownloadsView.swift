import JellyfinKit
import SwiftUI

/// Everything downloaded or downloading; plays without the server.
struct DownloadsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            if app.downloads.sorted.isEmpty {
                Text(L10n.t("downloads_empty")).metaStyle()
            }
            ForEach(app.downloads.sorted) { record in
                DownloadRow(record: record)
            }
            .onDelete { offsets in
                for index in offsets { app.downloads.remove(app.downloads.sorted[index].id) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.base)
        .navigationTitle(L10n.t("nav_downloads"))
    }
}

struct DownloadRow: View {
    let record: DownloadRecord
    @Environment(AppModel.self) private var app

    var body: some View {
        Button { if record.state == .done { app.play(PlayRequest(item: record.item)) } } label: {
            HStack(spacing: 12) {
                Artwork(art: record.item.thumbArt, width: 120).frame(width: 120, height: 68).clipShape(.rect(cornerRadius: Theme.radius))
                VStack(alignment: .leading, spacing: 4) {
                    Text(CardText.title(record.item)).font(Theme.headline).foregroundStyle(Theme.text).lineLimit(1)
                    if record.item.kind == .episode { Text(CardText.subtitle(record.item)).metaStyle().lineLimit(1) }
                    status
                }
            }
        }
        .accessibilityIdentifier("download.\(record.id)")
    }

    @ViewBuilder private var status: some View {
        switch record.state {
        case .done: Text(PlaybackPrefs.downloadLabel(record.bitrate)).font(Theme.caption).foregroundStyle(Theme.text3)
        case .failed: Text(L10n.t("download_failed")).font(Theme.caption).foregroundStyle(Theme.red)
        case .queued, .downloading:
            ProgressView(value: record.progress).tint(.white)
            Text(L10n.f("download_progress", "\(Int(record.progress * 100))")).font(Theme.caption).foregroundStyle(Theme.text3)
        }
    }
}

/// The detail page's download control: choose a quality, see progress, or remove.
struct DownloadButton: View {
    let item: Item
    @Environment(AppModel.self) private var app

    var body: some View {
        if item.isPlayable {
            let record = app.downloads.record(for: item.id)
            Menu {
                if let record {
                    Button(L10n.t("download_remove"), systemImage: "trash", role: .destructive) { app.downloads.remove(record.id) }
                } else {
                    ForEach(DownloadManager.qualities, id: \.self) { bitrate in
                        Button(PlaybackPrefs.downloadLabel(bitrate)) { app.downloads.start(item, bitrate: bitrate) }
                    }
                }
            } label: {
                Image(systemName: icon(record))
            }
            .buttonStyle(.secondary)
            .accessibilityLabel(record == nil ? L10n.t("download") : L10n.t("download_remove"))
            .accessibilityIdentifier("detail.download")
        }
    }

    private func icon(_ record: DownloadRecord?) -> String {
        switch record?.state {
        case .done: "arrow.down.circle.fill"
        case .queued, .downloading: "arrow.down.circle.dotted"
        case .failed: "exclamationmark.circle"
        case nil: "arrow.down.circle"
        }
    }
}
