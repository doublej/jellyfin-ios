import Foundation

/// What the server does to the file on its way here, from untouched to re-encoded video, and why.
/// Ported from jellyfin-ui `src/lib/player/rules/delivery.ts`.
public struct Delivery: Equatable, Sendable {
    public enum Kind: String, Sendable { case direct, remux, audio, video }
    /// Grouped by the part of the file that doesn't fit this device.
    public enum Cause: String, Sendable { case container, video, audio, subtitles, bitrate }

    public var kind: Kind
    public var causes: [Cause]

    /// Reads the server's own reasons from the stream URL. Without a video or audio reason the
    /// server copies both streams into a new container.
    public static func of(_ method: PlayMethod, url: URL) -> Delivery {
        if method == .directPlay { return Delivery(kind: .direct, causes: []) }
        let reasons = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .first { $0.name == "TranscodeReasons" }?.value ?? ""
        var causes: [Cause] = []
        for cause in reasons.split(separator: ",").compactMap({ cause(String($0)) }) where !causes.contains(cause) {
            causes.append(cause)
        }
        return Delivery(kind: heaviest(causes), causes: causes)
    }

    /// Groups one of Jellyfin's TranscodeReason names; DirectPlayError says nothing about the file.
    static func cause(_ reason: String) -> Cause? {
        if reason == "ContainerBitrateExceedsLimit" || reason == "VideoBitrateNotSupported" { return .bitrate }
        if reason.hasPrefix("Container") || reason == "StreamCountExceedsLimit" { return .container }
        if reason.hasPrefix("Subtitle") { return .subtitles }
        if reason.contains("Audio") { return .audio }
        if reason == "DirectPlayError" || reason.isEmpty { return nil }
        return .video
    }

    static func heaviest(_ causes: [Cause]) -> Kind {
        if causes.contains(where: { $0 == .video || $0 == .subtitles || $0 == .bitrate }) { return .video }
        return causes.contains(.audio) ? .audio : .remux
    }
}
