import AVFoundation
import JellyfinKit
import XCTest

/// One file per kind of file in the library: container, video codec/profile/range, audio codec.
struct Sample: Codable {
    var itemId: String
    var name: String
    var sourceId: String
    var container: String
    var video: String
    var audio: String
    var audioIndex: Int

    var key: String { "\(container) | \(video) | \(audio)" }
}

struct Result: Codable {
    var sample: String
    var mode: String
    var outcome: Playback.Outcome
}

/// What AVPlayer actually plays, tried against the real library. Prints `JFIOS-PROBE` lines that
/// `just probe` collects into docs/PROFILE.md. Not part of the default test run.
@MainActor
final class AVPlayerProbe: XCTestCase {
    var client: APIClient!
    var results: [Result] = []

    func testWhatAVPlayerPlays() async throws {
        client = try await QuickConnectLogin.client()
        for sample in try await samples() {
            await record(sample, "direct", Playback.check(client.directStreamURL(itemId: sample.itemId, source: source(sample))))
            await record(sample, "hls copy", hls(sample, audio: sample.audio))
            if sample.audio != "aac" { await record(sample, "hls audio→aac", hls(sample, audio: "aac")) }
            await record(sample, "progressive file", progressive(sample))
        }
        try await probeSubtitles()
        let json = try JSONEncoder().encode(results)
        try json.write(to: URL(filePath: "/tmp/jfios-probe.json"))
    }

    func record(_ sample: Sample, _ mode: String, _ outcome: Playback.Outcome) {
        let result = Result(sample: sample.key + " — " + sample.name, mode: mode, outcome: outcome)
        results.append(result)
        let line = (try? JSONEncoder().encode(result)).flatMap { String(bytes: $0, encoding: .utf8) } ?? ""
        print("JFIOS-PROBE \(line)")
    }

    func source(_ sample: Sample) -> MediaSource {
        var source = MediaSource(id: sample.sourceId)
        source.container = sample.container
        return source
    }

    func samples() async throws -> [Sample] {
        let query: Query = [("userId", client.userId), ("recursive", "true"), ("includeItemTypes", "Movie,Episode"),
                            ("fields", "MediaSources"), ("limit", "1000")]
        let result: ItemsResult = try await client.get("/Items", query)
        var seen: [String: Sample] = [:]
        for item in result.items ?? [] {
            guard let sample = Self.sample(item), seen[sample.key] == nil else { continue }
            seen[sample.key] = sample
        }
        return seen.values.sorted { $0.key < $1.key }
    }

    static func sample(_ item: Item) -> Sample? {
        guard let source = item.mediaSources?.first, let video = source.video, let audio = source.audioTracks.first else { return nil }
        let videoKey = [video.codec ?? "?", video.profile ?? "", video.videoRangeType ?? ""].joined(separator: "/")
        return Sample(itemId: item.id, name: item.name ?? "", sourceId: source.id, container: source.container ?? "?",
                      video: videoKey, audio: audio.codec ?? "?", audioIndex: audio.index)
    }

    /// Asks the server for HLS that copies the video and either copies or converts the audio.
    func hls(_ sample: Sample, audio: String, subtitle: Int? = nil, subtitleMethod: String = "Encode") async -> Playback.Outcome {
        let request = PlaybackRequest(
            userId: client.userId ?? "", maxStreamingBitrate: 120_000_000, startTimeTicks: 0,
            audioStreamIndex: sample.audioIndex, subtitleStreamIndex: subtitle ?? -1, mediaSourceId: sample.sourceId,
            deviceProfile: Self.copyProfile(sample, audio: audio, subtitleMethod: subtitleMethod),
            enableDirectPlay: false, enableDirectStream: false
        )
        do {
            let info = try await client.playbackInfo(itemId: sample.itemId, request)
            guard let path = info.mediaSources?.first?.transcodingUrl, let url = client.absolute(path) else {
                return Playback.Outcome(ok: false, detail: "no TranscodingUrl, error \(info.errorCode ?? "-")")
            }
            var outcome = await Playback.check(url, timeout: 40)
            let base = String(path.split(separator: "?").first ?? "")
            outcome.detail += " url=\(base) \(Self.params(path))"
            try? await client.stopTranscode(playSessionId: info.playSessionId ?? "")
            return outcome
        } catch {
            return Playback.Outcome(ok: false, detail: "PlaybackInfo failed: \(error)")
        }
    }

    /// No direct play, no codec conditions: the server copies whatever the HLS profile lists.
    static func copyProfile(_ sample: Sample, audio: String, subtitleMethod: String) -> DeviceProfile {
        var profile = DeviceProfile.build(.avPlayer, maxBitrate: 120_000_000)
        profile.directPlayProfiles = []
        profile.codecProfiles = []
        profile.transcodingProfiles[0].videoCodec = String(sample.video.split(separator: "/").first ?? "h264")
        profile.transcodingProfiles[0].audioCodec = audio
        profile.subtitleProfiles = profile.subtitleProfiles.map { SubtitleProfile(format: $0.format, method: subtitleMethod) }
        return profile
    }

    static func params(_ path: String) -> String {
        let query = URLComponents(string: path)?.queryItems ?? []
        let keep = ["VideoCodec", "AudioCodec", "SegmentContainer", "TranscodeReasons", "SubtitleMethod"]
        return query.filter { keep.contains($0.name) }.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: " ")
    }

    /// The Downloads tab's format: a remuxed MP4 fetched to a file, then played from disk.
    func progressive(_ sample: Sample) async -> Playback.Outcome {
        let codec = String(sample.video.split(separator: "/").first ?? "h264")
        let url = client.url("/Videos/\(sample.itemId)/stream.mp4", [
            ("mediaSourceId", sample.sourceId), ("static", "false"), ("container", "mp4"),
            ("videoCodec", codec), ("audioCodec", "aac"), ("audioStreamIndex", "\(sample.audioIndex)"),
            ("maxStreamingBitrate", "120000000"), ("deviceId", client.identity.deviceId),
            ("playSessionId", "probe-\(sample.itemId)"), ("ApiKey", client.token)
        ])
        do {
            let file = try await Playback.fetch(url)
            try? await client.stopTranscode(playSessionId: "probe-\(sample.itemId)")
            return await Playback.check(file)
        } catch {
            return Playback.Outcome(ok: false, detail: "download failed: \(error)")
        }
    }
}
