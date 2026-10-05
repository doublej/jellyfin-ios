import Foundation

/// The device profile sent with every PlaybackInfo request. The server compares each file with it
/// and answers direct play, remux or transcode.
public struct DeviceProfile: Encodable, Sendable, Equatable {
    public var name: String
    public var maxStreamingBitrate: Int
    public var maxStaticBitrate: Int
    public var musicStreamingTranscodingBitrate = 384_000
    public var directPlayProfiles: [DirectPlayProfile]
    public var transcodingProfiles: [TranscodingProfile]
    public var containerProfiles: [String] = []
    public var codecProfiles: [CodecProfile]
    public var subtitleProfiles: [SubtitleProfile]
}

public struct DirectPlayProfile: Encodable, Sendable, Equatable {
    public var container: String
    public var type = "Video"
    public var videoCodec: String
    public var audioCodec: String
}

public struct TranscodingProfile: Encodable, Sendable, Equatable {
    public var container: String
    public var type = "Video"
    public var videoCodec: String
    public var audioCodec: String
    public var `protocol`: String
    public var context: String
    public var maxAudioChannels = "6"
    public var minSegments = 1
    public var breakOnNonKeyFrames = true
}

public struct CodecProfile: Encodable, Sendable, Equatable {
    public var type = "Video"
    public var codec: String
    public var conditions: [ProfileCondition]
}

public struct ProfileCondition: Encodable, Sendable, Equatable {
    public var condition: String
    public var property: String
    public var value: String
    public var isRequired = false

    public init(_ property: String, _ condition: String, _ value: String) {
        self.property = property
        self.condition = condition
        self.value = value
    }
}

public struct SubtitleProfile: Encodable, Sendable, Equatable {
    public var format: String
    public var method: String

    public init(format: String, method: String) {
        self.format = format
        self.method = method
    }
}

public extension DeviceProfile {
    /// `maxBitrate` is the quality cap in bits per second.
    static func build(_ caps: Capabilities, maxBitrate: Int) -> DeviceProfile {
        DeviceProfile(
            name: ClientIdentity.clientName,
            maxStreamingBitrate: maxBitrate,
            maxStaticBitrate: maxBitrate,
            directPlayProfiles: caps.direct.map {
                DirectPlayProfile(container: $0.containers.joined(separator: ","),
                                  videoCodec: $0.video.joined(separator: ","), audioCodec: $0.audio.joined(separator: ","))
            },
            transcodingProfiles: [hls(caps)],
            codecProfiles: codecProfiles(caps),
            subtitleProfiles: caps.textSubtitles.map { SubtitleProfile(format: $0, method: "External") }
                + caps.imageSubtitles.map { SubtitleProfile(format: $0, method: "Encode") }
        )
    }

    /// Fragmented-MP4 HLS: the only HLS segment format AVPlayer takes HEVC in. The first codec of
    /// each list is what the server converts to; the rest are copied when the file has them.
    private static func hls(_ caps: Capabilities) -> TranscodingProfile {
        TranscodingProfile(
            container: "mp4", videoCodec: caps.hlsVideo.joined(separator: ","),
            audioCodec: caps.hlsAudio.joined(separator: ","), protocol: "hls", context: "Streaming"
        )
    }

    private static func codecProfiles(_ caps: Capabilities) -> [CodecProfile] {
        [
            CodecProfile(codec: "h264", conditions: [
                ProfileCondition("VideoBitDepth", "LessThanEqual", "8"),
                ProfileCondition("VideoLevel", "LessThanEqual", "\(caps.h264MaxLevel)"),
                ProfileCondition("VideoProfile", "EqualsAny", "high|main|baseline|constrained baseline")
            ]),
            CodecProfile(codec: "hevc", conditions: [
                ProfileCondition("VideoBitDepth", "LessThanEqual", "10"),
                ProfileCondition("VideoProfile", "EqualsAny", "main|main 10"),
                ProfileCondition("VideoRangeType", "EqualsAny", caps.hevcRanges.joined(separator: "|"))
            ])
        ]
    }
}
