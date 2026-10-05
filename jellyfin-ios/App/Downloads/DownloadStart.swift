import JellyfinKit
import SwiftUI

/// Starting a download: which file to ask for at which quality, and saving its subtitles.
extension DownloadManager {
    /// 0 is the original quality: the file itself when AVPlayer opens it, otherwise the same
    /// video and audio remuxed into MP4 by the server.
    static let qualities = [0, 20_000_000, 8_000_000, 4_000_000, 1_500_000]

    func start(_ item: Item, bitrate: Int) {
        guard let client = app?.client else { return }
        Task {
            guard let full = try? await client.item(item.id), let source = full.mediaSources?.first else { return }
            var record = DownloadRecord(item: full, source: source, bitrate: bitrate, fileName: "\(full.id).mp4")
            record.expected = Self.estimate(source, bitrate: bitrate, runtime: full.runtimeSeconds)
            record.state = .downloading
            update(record)
            session.start(Self.url(client, full, source, bitrate: bitrate), itemId: full.id)
            await saveSubtitles(client, &record)
            if let latest = records[record.id] { record.state = latest.state; record.received = latest.received }
            update(record)
        }
    }

    static func url(_ client: APIClient, _ item: Item, _ source: MediaSource, bitrate: Int) -> URL {
        let container = source.container ?? ""
        if bitrate == 0, ["mp4", "m4v", "mov"].contains(container) {
            return client.url("/Items/\(item.id)/Download", [("ApiKey", client.token)])
        }
        let audio = source.audioTracks.first { $0.isDefault == true } ?? source.audioTracks.first
        return client.url("/Videos/\(item.id)/stream.mp4", [
            ("mediaSourceId", source.id), ("static", "false"), ("container", "mp4"),
            ("videoCodec", "h264"), ("audioCodec", "aac"), ("audioChannels", "2"),
            ("audioStreamIndex", audio.map { "\($0.index)" }), ("maxStreamingBitrate", bitrate == 0 ? "120000000" : "\(bitrate)"),
            ("videoBitRate", bitrate == 0 ? nil : "\(max(500_000, bitrate - 192_000))"), ("audioBitRate", "192000"),
            ("deviceId", client.identity.deviceId), ("playSessionId", "download-\(item.id)"), ("ApiKey", client.token)
        ])
    }

    static func estimate(_ source: MediaSource, bitrate: Int, runtime: Double) -> Int64 {
        if bitrate == 0, let size = source.size { return size }
        return Int64(Double(bitrate) / 8 * runtime)
    }

    /// Text subtitles are small: every text track is saved next to the file.
    private func saveSubtitles(_ client: APIClient, _ record: inout DownloadRecord) async {
        for track in record.source.subtitleTracks where !track.isBurnedIn {
            guard let events = try? await client.trackEvents(itemId: record.item.id, sourceId: record.source.id, index: track.index),
                  let data = try? JSONEncoder().encode(events) else { continue }
            try? data.write(to: record.subtitleURL(track.index))
            record.subtitleIndexes.append(track.index)
        }
    }
}
