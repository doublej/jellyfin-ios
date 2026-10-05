import Foundation

/// Every way playback can fail. The app turns each into a message that says what happened and
/// what to do (`err_<rawValue>` in Localizable.strings).
public enum PlaybackFailure: String, Error, Sendable, CaseIterable {
    case incompatible, notAllowed = "not_allowed", rateLimited = "rate_limited", noSource = "no_source"
    case server, network, decode, unsupported, stream, subtitles, fatal, offline

    public static func fromServerCode(_ code: String) -> PlaybackFailure {
        switch code {
        case "NotAllowed": .notAllowed
        case "NoCompatibleStream": .incompatible
        case "RateLimitExceeded": .rateLimited
        default: .server
        }
    }

    /// Any thrown error as a kind: our own, an HTTP status, or a dropped connection.
    public static func from(_ error: Error) -> PlaybackFailure {
        switch error {
        case let failure as PlaybackFailure: failure
        case APIError.status(404): .noSource
        case APIError.status(403): .notAllowed
        case APIError.status(let code) where code >= 500: .server
        case APIError.unreachable, is URLError: .network
        default: fromAVError(error as NSError)
        }
    }

    /// AVFoundation's error codes. -11800 is a catch-all; its underlying error tells more.
    static func fromAVError(_ error: NSError) -> PlaybackFailure {
        if error.domain == NSURLErrorDomain { return .network }
        switch error.code {
        case -11828, -11829, -11833: return .unsupported // format not recognised, can't parse, no decoder
        case -11821: return .decode
        case -12938, -12660: return .network // HLS segment answered 404 / 403
        default: break
        }
        guard let under = error.userInfo[NSUnderlyingErrorKey] as? NSError else { return .stream }
        return fromAVError(under)
    }
}
