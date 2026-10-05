import JellyfinKit
import SwiftUI

/// One downloaded (or downloading) item: the server's item as it was, the file, and the text
/// subtitles saved next to it, so it plays and shows without the server.
struct DownloadRecord: Codable, Identifiable, Hashable {
    enum State: String, Codable { case queued, downloading, done, failed }

    var item: Item
    var source: MediaSource
    var bitrate: Int
    var fileName: String
    var state = State.queued
    var received: Int64 = 0
    var expected: Int64 = 0
    var subtitleIndexes: [Int] = []
    var addedAt = Date()

    var id: String { item.id }
    var itemId: String { item.id }
    var manager: DownloadManager { DownloadManager.shared }

    static var folder: URL {
        let url = URL.applicationSupportDirectory.appending(path: "Downloads", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    var fileURL: URL { Self.folder.appending(path: fileName) }

    func subtitleURL(_ index: Int) -> URL { Self.folder.appending(path: "\(item.id)-sub\(index).json") }

    var progress: Double { expected > 0 ? min(1, Double(received) / Double(expected)) : 0 }

    /// The local file as a direct-play stream; only the downloaded subtitle tracks are offered.
    var stream: Stream {
        var local = source
        local.mediaStreams = source.streams.filter { $0.type != "Subtitle" || subtitleIndexes.contains($0.index) }
        local.mediaStreams = local.mediaStreams?.map { stream in
            var copy = stream
            if copy.type == "Subtitle" { copy.deliveryMethod = "External" }
            return copy
        }
        return Stream(url: fileURL, method: .directPlay, source: local, playSessionId: "")
    }

    func subtitles(_ index: Int) -> [TrackEvent]? {
        guard let data = try? Data(contentsOf: subtitleURL(index)) else { return nil }
        return try? JSONDecoder().decode([TrackEvent].self, from: data)
    }
}
