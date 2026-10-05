import JellyfinKit
import SwiftUI

/// The stream the server offered: the file as-is, or HLS it converts or remuxes.
struct Stream: Equatable {
    var url: URL
    var method: PlayMethod
    var source: MediaSource
    var playSessionId: String
}

/// Asks the server how this device should get an item: direct play when AVPlayer can open the
/// file, otherwise HLS. Ported from jellyfin-ui `src/lib/player/stream.ts`.
struct Negotiator {
    let client: APIClient
    let itemId: String
    var sourceId: String?
    var audio: Int?
    var subtitle: Int?
    var maxBitrate: Int

    func negotiate(start: Double, allowDirect: Bool) async throws -> Stream {
        let request = PlaybackRequest(
            userId: client.userId ?? "", maxStreamingBitrate: maxBitrate, startTimeTicks: Ticks.from(seconds: start),
            audioStreamIndex: audio, subtitleStreamIndex: subtitle, mediaSourceId: sourceId,
            deviceProfile: DeviceProfile.build(.avPlayer, maxBitrate: maxBitrate),
            enableDirectPlay: allowDirect, enableDirectStream: allowDirect
        )
        let info = try await client.playbackInfo(itemId: itemId, request)
        if let code = info.errorCode { throw PlaybackFailure.fromServerCode(code) }
        let sources = info.mediaSources ?? []
        guard let source = sources.first(where: { $0.id == sourceId }) ?? sources.first else { throw PlaybackFailure.noSource }
        return try stream(source, allowDirect: allowDirect, session: info.playSessionId ?? "")
    }

    private func stream(_ source: MediaSource, allowDirect: Bool, session: String) throws -> Stream {
        if allowDirect, source.supportsDirectPlay == true {
            return Stream(url: client.directStreamURL(itemId: itemId, source: source), method: .directPlay, source: source, playSessionId: session)
        }
        guard let path = source.transcodingUrl, let url = client.absolute(path) else { throw PlaybackFailure.incompatible }
        return Stream(url: url, method: .transcode, source: source, playSessionId: session)
    }

    /// Direct play only ever plays the file's default audio track and can't draw image subtitles,
    /// so another audio track or a bitmap subtitle needs the server.
    static func directPlays(_ stream: Stream, audio: Int?, subtitle: Int?) -> Bool {
        let tracks = stream.source.audioTracks
        let fileAudio = tracks.first { $0.isDefault == true } ?? tracks.first
        let sub = stream.source.subtitleTracks.first { $0.index == subtitle }
        return (audio == nil || audio == fileAudio?.index) && sub?.isBurnedIn != true
    }
}
