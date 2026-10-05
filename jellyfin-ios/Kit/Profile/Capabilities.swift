import Foundation

/// What the player can take, the input to `DeviceProfile.build`.
public struct Capabilities: Sendable, Equatable {
    public struct DirectSet: Sendable, Equatable {
        public var containers: [String]
        public var video: [String]
        public var audio: [String]

        public init(containers: [String], video: [String], audio: [String]) {
            self.containers = containers
            self.video = video
            self.audio = audio
        }
    }

    public var direct: [DirectSet]
    public var hlsVideo: [String]
    public var hlsAudio: [String]
    public var textSubtitles: [String]
    public var imageSubtitles: [String]
    public var h264MaxLevel: Int
    public var hevcRanges: [String]

    public init(direct: [DirectSet], hlsVideo: [String], hlsAudio: [String], textSubtitles: [String],
                imageSubtitles: [String], h264MaxLevel: Int, hevcRanges: [String]) {
        self.direct = direct
        self.hlsVideo = hlsVideo
        self.hlsAudio = hlsAudio
        self.textSubtitles = textSubtitles
        self.imageSubtitles = imageSubtitles
        self.h264MaxLevel = h264MaxLevel
        self.hevcRanges = hevcRanges
    }
}

public extension Capabilities {
    /// AVPlayer as measured against this library by ProbeTests (docs/PROFILE.md has the table).
    static let avPlayer = Capabilities(
        direct: [DirectSet(containers: ["mp4", "m4v", "mov"], video: ["h264", "hevc"], audio: ["aac", "ac3", "eac3", "mp3", "alac", "flac"])],
        hlsVideo: ["h264", "hevc"],
        hlsAudio: ["aac", "ac3", "eac3", "mp3", "alac", "flac"],
        textSubtitles: ["srt", "subrip", "vtt", "webvtt", "ass", "ssa", "smi", "sub", "ttml", "mov_text"],
        imageSubtitles: ["pgssub", "pgs", "dvdsub", "dvbsub", "vobsub", "dvb_subtitle", "dvd_subtitle"],
        h264MaxLevel: 52,
        hevcRanges: ["SDR", "HDR10", "HDR10Plus", "HLG", "DOVIWithHDR10", "DOVIWithSDR", "DOVIWithHLG"]
    )
}
