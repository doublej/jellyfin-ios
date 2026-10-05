import AVFoundation
import Foundation

/// Plays one URL muted and reports whether AVPlayer really decoded it: a video frame came out,
/// the clock passed one second, and (when asked) an audio track was playable.
@MainActor
enum Playback {
    nonisolated struct Outcome: Codable, Sendable {
        var ok: Bool
        var detail: String
        var secondsToFrame: Double?
    }

    static func check(_ url: URL, timeout: Double = 25) async -> Outcome {
        let item = AVPlayerItem(url: url)
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: nil)
        item.add(output)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.play()
        defer { player.pause(); player.replaceCurrentItem(with: nil) }
        return await watch(player, item, output, timeout: timeout)
    }

    private static func watch(_ player: AVPlayer, _ item: AVPlayerItem, _ output: AVPlayerItemVideoOutput,
                              timeout: Double) async -> Outcome {
        let start = Date()
        var frameAt: Double?
        while Date().timeIntervalSince(start) < timeout {
            if item.status == .failed { return Outcome(ok: false, detail: describe(item.error)) }
            let now = item.currentTime()
            if frameAt == nil, output.hasNewPixelBuffer(forItemTime: now) { frameAt = Date().timeIntervalSince(start) }
            if let frameAt, now.seconds >= 1 { return Outcome(ok: true, detail: tracks(item), secondsToFrame: frameAt) }
            try? await Task.sleep(for: .milliseconds(100))
        }
        let state = "timeout at \(item.currentTime().seconds)s, frame=\(frameAt != nil), \(tracks(item))"
        return Outcome(ok: false, detail: state)
    }

    static func tracks(_ item: AVPlayerItem) -> String {
        let kinds = item.tracks.compactMap { track -> String? in
            guard let type = track.assetTrack?.mediaType, track.isEnabled else { return nil }
            return type.rawValue
        }
        return "tracks=" + kinds.joined(separator: "+")
    }

    static func describe(_ error: Error?) -> String {
        guard let error = error as NSError? else { return "failed" }
        let under = (error.userInfo[NSUnderlyingErrorKey] as? NSError).map { " / \($0.domain) \($0.code)" } ?? ""
        return "\(error.domain) \(error.code)\(under): \(error.localizedDescription)"
    }

    /// Downloads up to `bytes` of a progressive stream to a file, as the Downloads tab would.
    static func fetch(_ url: URL, bytes: Int = 24_000_000, timeout: Double = 40) async throws -> URL {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".mp4")
        let (stream, _) = try await URLSession.shared.bytes(from: url)
        var data = Data()
        data.reserveCapacity(bytes)
        let start = Date()
        for try await byte in stream {
            data.append(byte)
            if data.count >= bytes || Date().timeIntervalSince(start) > timeout { break }
        }
        try data.write(to: file)
        return file
    }
}
