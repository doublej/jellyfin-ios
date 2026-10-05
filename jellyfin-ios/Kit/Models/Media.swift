import Foundation

/// One playable version of an item: a file, or the server's offer to convert it.
public struct MediaSource: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String?
    public var container: String?
    public var size: Int64?
    public var bitrate: Int?
    public var eTag: String?
    public var runTimeTicks: Int64?
    public var supportsDirectPlay: Bool?
    public var supportsDirectStream: Bool?
    public var supportsTranscoding: Bool?
    public var transcodingUrl: String?
    public var transcodingSubProtocol: String?
    public var transcodeReasons: [String]?
    public var mediaStreams: [MediaStream]?
    public var defaultAudioStreamIndex: Int?
    public var defaultSubtitleStreamIndex: Int?

    public init(id: String) { self.id = id }
}

public extension MediaSource {
    var streams: [MediaStream] { mediaStreams ?? [] }
    var video: MediaStream? { streams.first { $0.type == "Video" } }
    var audioTracks: [MediaStream] { streams.filter { $0.type == "Audio" } }
    var subtitleTracks: [MediaStream] { streams.filter { $0.type == "Subtitle" } }
}

public struct MediaStream: Codable, Sendable, Hashable {
    public var index: Int
    public var type: String?
    public var codec: String?
    public var codecTag: String?
    public var language: String?
    public var title: String?
    public var displayTitle: String?
    public var isDefault: Bool?
    public var isForced: Bool?
    public var isExternal: Bool?
    public var isTextSubtitleStream: Bool?
    public var deliveryMethod: String?
    public var deliveryUrl: String?
    public var profile: String?
    public var level: Double?
    public var bitDepth: Int?
    public var videoRangeType: String?
    public var width: Int?
    public var height: Int?
    public var channels: Int?
    public var bitRate: Int?

    public init(index: Int, type: String, codec: String? = nil) {
        self.index = index
        self.type = type
        self.codec = codec
    }
}

public extension MediaStream {
    /// Image subtitles (PGS, DVD) can't be drawn as text: the server burns them into the picture.
    var isBurnedIn: Bool { deliveryMethod == "Encode" }
    var label: String { displayTitle ?? title ?? language ?? codec ?? "#\(index)" }
}

public struct Chapter: Codable, Sendable, Hashable {
    public var startPositionTicks: Int64?
    public var name: String?
    public var imageTag: String?

    public init(start: Double, name: String? = nil) {
        startPositionTicks = Ticks.from(seconds: start)
        self.name = name
    }

    public var startSeconds: Double { Ticks.seconds(startPositionTicks) }
}

/// One trickplay resolution: sprite sheets of `tileWidth × tileHeight` thumbnails.
public struct TrickplayInfo: Codable, Sendable, Hashable {
    public var width: Int?
    public var height: Int?
    public var tileWidth: Int?
    public var tileHeight: Int?
    public var thumbnailCount: Int?
    public var interval: Int?

    public init(width: Int, height: Int, tileWidth: Int, tileHeight: Int, thumbnailCount: Int, interval: Int) {
        self.width = width
        self.height = height
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.thumbnailCount = thumbnailCount
        self.interval = interval
    }
}

public struct MediaSegment: Codable, Sendable, Hashable {
    public var type: String?
    public var startTicks: Int64?
    public var endTicks: Int64?

    public init(type: String, start: Double, end: Double) {
        self.type = type
        startTicks = Ticks.from(seconds: start)
        endTicks = Ticks.from(seconds: end)
    }
}

public struct PlaybackInfoResponse: Codable, Sendable {
    public var mediaSources: [MediaSource]?
    public var playSessionId: String?
    public var errorCode: String?
}

/// One subtitle line, timed in seconds.
public struct TrackEvent: Codable, Sendable, Hashable {
    public var start: Double
    public var end: Double
    public var text: String

    public init(start: Double, end: Double, text: String) {
        self.start = start
        self.end = end
        self.text = text
    }
}
