import AVFoundation
import JellyfinKit
import XCTest

/// Subtitle formats in this library: SubRip (embedded and external), PGS and DVD bitmaps.
extension AVPlayerProbe {
    func probeSubtitles() async throws {
        let query: Query = [("userId", client.userId), ("recursive", "true"), ("includeItemTypes", "Movie,Episode"),
                            ("fields", "MediaSources"), ("limit", "1000")]
        let items: ItemsResult = try await client.get("/Items", query)
        let all = items.items ?? []
        for (label, match) in Self.subtitleCases {
            guard let (item, track) = Self.first(all, match), let sample = Self.sample(item) else { continue }
            if track.codec?.lowercased().contains("pgs") == true || track.codec?.lowercased().contains("dvd") == true {
                record(sample, "\(label) burned in (hls)", await hls(sample, audio: "aac", subtitle: track.index))
            } else {
                record(sample, "\(label) as text (Stream.js)", await textEvents(item, sample, track))
                record(sample, "\(label) as HLS WebVTT", await webVTT(sample, track))
            }
        }
    }

    static let subtitleCases: [(String, @Sendable (MediaStream) -> Bool)] = [
        ("subrip embedded", { $0.codec == "subrip" && $0.isExternal != true }),
        ("subrip external", { $0.codec == "subrip" && $0.isExternal == true }),
        ("PGSSUB", { $0.codec?.uppercased() == "PGSSUB" }),
        ("DVDSUB", { $0.codec?.uppercased() == "DVDSUB" })
    ]

    static func first(_ items: [Item], _ match: (MediaStream) -> Bool) -> (Item, MediaStream)? {
        for item in items {
            if let track = item.mediaSources?.first?.subtitleTracks.first(where: match) { return (item, track) }
        }
        return nil
    }

    /// The app's way: the server converts any text format to timed events; the app draws them.
    func textEvents(_ item: Item, _ sample: Sample, _ track: MediaStream) async -> Playback.Outcome {
        let start = Date()
        let client = self.client!
        let task = Task { try await client.trackEvents(itemId: item.id, sourceId: sample.sourceId, index: track.index) }
        let timeout = Task { try await Task.sleep(for: .seconds(45)); task.cancel() }
        defer { timeout.cancel() }
        do {
            let events = try await task.value
            let seconds = Date().timeIntervalSince(start)
            return Playback.Outcome(ok: !events.isEmpty, detail: "\(events.count) events", secondsToFrame: seconds)
        } catch {
            return Playback.Outcome(ok: false, detail: "no events within 45 s: \(error)")
        }
    }

    /// The alternative: WebVTT renditions in the HLS playlist, drawn by AVPlayer itself.
    func webVTT(_ sample: Sample, _ track: MediaStream) async -> Playback.Outcome {
        await hls(sample, audio: sample.audio, subtitle: track.index, subtitleMethod: "Hls")
    }
}
