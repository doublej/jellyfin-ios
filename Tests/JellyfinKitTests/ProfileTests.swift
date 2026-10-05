import Foundation
@testable import JellyfinKit
import Testing

struct ProfileTests {
    let profile = DeviceProfile.build(.avPlayer, maxBitrate: 20_000_000)

    @Test func capsBothBitrates() {
        #expect(profile.maxStreamingBitrate == 20_000_000 && profile.maxStaticBitrate == 20_000_000)
    }

    @Test func directPlaysOnlyContainersAVPlayerOpens() {
        let containers = profile.directPlayProfiles.flatMap { $0.container.split(separator: ",") }
        #expect(containers.contains("mp4"))
        #expect(!containers.contains("mkv"), "AVPlayer can't open Matroska")
    }

    @Test func convertsToFragmentedMP4HLS() throws {
        let hls = try #require(profile.transcodingProfiles.first)
        #expect(hls.container == "mp4" && hls.protocol == "hls" && hls.context == "Streaming")
        #expect(hls.videoCodec.hasPrefix("h264"), "h264 first: what the server converts to")
        #expect(hls.audioCodec.hasPrefix("aac"))
        #expect(!hls.audioCodec.contains("dts"), "AVPlayer has no DTS decoder")
    }

    @Test func burnsInImageSubtitlesAndFetchesText() {
        let methods = Dictionary(uniqueKeysWithValues: profile.subtitleProfiles.map { ($0.format, $0.method) })
        #expect(methods["subrip"] == "External")
        #expect(methods["pgssub"] == "Encode")
        #expect(methods["dvdsub"] == "Encode")
    }

    @Test func encodesTheServerShape() throws {
        let json = try #require(String(data: JSONCoding.encoder.encode(profile), encoding: .utf8))
        for key in ["DirectPlayProfiles", "TranscodingProfiles", "CodecProfiles", "SubtitleProfiles", "\"Protocol\":\"hls\""] {
            #expect(json.contains(key), "missing \(key)")
        }
    }
}
