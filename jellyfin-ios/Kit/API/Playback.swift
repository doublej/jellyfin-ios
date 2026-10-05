import Foundation

public enum PlayMethod: String, Codable, Sendable {
    case directPlay = "DirectPlay", directStream = "DirectStream", transcode = "Transcode"
}

/// What the server needs to know about the playing stream, sent with every report.
public struct ReportState: Codable, Sendable {
    public var itemId: String
    public var mediaSourceId: String
    public var playSessionId: String
    public var playMethod: PlayMethod
    public var positionTicks: Int64
    public var isPaused: Bool
    public var isMuted: Bool
    public var volumeLevel: Int
    public var audioStreamIndex: Int?
    public var subtitleStreamIndex: Int
    public var canSeek = true
    public var eventName: String?

    public init(itemId: String, mediaSourceId: String, playSessionId: String, playMethod: PlayMethod,
                position: Double, paused: Bool, muted: Bool, volume: Float, audio: Int?, subtitle: Int?) {
        self.itemId = itemId
        self.mediaSourceId = mediaSourceId
        self.playSessionId = playSessionId
        self.playMethod = playMethod
        positionTicks = Ticks.from(seconds: position)
        isPaused = paused
        isMuted = muted
        volumeLevel = Int((volume * 100).rounded())
        audioStreamIndex = audio
        subtitleStreamIndex = subtitle ?? -1
    }
}

public struct PlaybackRequest: Encodable, Sendable {
    public var userId: String
    public var maxStreamingBitrate: Int
    public var startTimeTicks: Int64
    public var audioStreamIndex: Int?
    public var subtitleStreamIndex: Int?
    public var mediaSourceId: String?
    public var deviceProfile: DeviceProfile
    public var enableDirectPlay: Bool
    public var enableDirectStream: Bool
    public var enableTranscoding = true
    public var allowVideoStreamCopy = true
    public var allowAudioStreamCopy = true
    public var autoOpenLiveStream = true

    public init(userId: String, maxStreamingBitrate: Int, startTimeTicks: Int64, audioStreamIndex: Int?,
                subtitleStreamIndex: Int?, mediaSourceId: String?, deviceProfile: DeviceProfile,
                enableDirectPlay: Bool, enableDirectStream: Bool) {
        self.userId = userId
        self.maxStreamingBitrate = maxStreamingBitrate
        self.startTimeTicks = startTimeTicks
        self.audioStreamIndex = audioStreamIndex
        self.subtitleStreamIndex = subtitleStreamIndex
        self.mediaSourceId = mediaSourceId
        self.deviceProfile = deviceProfile
        self.enableDirectPlay = enableDirectPlay
        self.enableDirectStream = enableDirectStream
    }
}

public extension APIClient {
    func playbackInfo(itemId: String, _ request: PlaybackRequest) async throws -> PlaybackInfoResponse {
        try await post("/Items/\(itemId)/PlaybackInfo", [("userId", try requireUser())], body: request)
    }

    func reportStart(_ state: ReportState) async throws {
        try await send("POST", "/Sessions/Playing", body: state)
    }

    func reportProgress(_ state: ReportState, event: String = "TimeUpdate") async throws {
        var state = state
        state.eventName = event
        try await send("POST", "/Sessions/Playing/Progress", body: state)
    }

    func reportStopped(_ state: ReportState) async throws {
        try await send("POST", "/Sessions/Playing/Stopped", body: state)
    }

    func stopTranscode(playSessionId: String) async throws {
        try await send("DELETE", "/Videos/ActiveEncodings", [("deviceId", identity.deviceId), ("playSessionId", playSessionId)])
    }

    func segments(itemId: String) async throws -> [MediaSegment] {
        struct Page: Decodable { let items: [MediaSegment]? }
        let page: Page = try await get("/MediaSegments/\(itemId)")
        return page.items ?? []
    }

    /// A text subtitle track as timed events, converted by the server from any text format.
    func trackEvents(itemId: String, sourceId: String, index: Int) async throws -> [TrackEvent] {
        struct Raw: Decodable { let trackEvents: [Event]? }
        struct Event: Decodable { let startPositionTicks: Int64; let endPositionTicks: Int64; let text: String }
        let path = "/Videos/\(itemId)/\(sourceId)/Subtitles/\(index)/0/Stream.js"
        let raw: Raw = try await get(path)
        return (raw.trackEvents ?? []).map {
            TrackEvent(start: Ticks.seconds($0.startPositionTicks), end: Ticks.seconds($0.endPositionTicks), text: $0.text)
        }
    }

    /// The file as-is, for AVPlayer to read with range requests.
    func directStreamURL(itemId: String, source: MediaSource) -> URL {
        let container = (source.container ?? "mp4").split(separator: ",").first.map(String.init) ?? "mp4"
        return url("/Videos/\(itemId)/stream.\(container)", [
            ("static", "true"), ("mediaSourceId", source.id), ("deviceId", identity.deviceId),
            ("ApiKey", token), ("Tag", source.eTag)
        ])
    }

    /// The server's own relative URL for a converted stream, made absolute.
    func absolute(_ relative: String) -> URL? {
        URL(string: server.absoluteString + relative)
    }

    func trickplayTileURL(itemId: String, sourceId: String, width: Int, sheet: Int) -> URL {
        url("/Videos/\(itemId)/Trickplay/\(width)/\(sheet).jpg", [("mediaSourceId", sourceId), ("ApiKey", token)])
    }
}
