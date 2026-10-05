import JellyfinKit
import SwiftUI

/// Playback preferences kept per device, like the stock client: quality cap, subtitle look,
/// volume. Account-wide preferences (languages, subtitle mode) live on the server.
@Observable
final class PlaybackPrefs {
    struct SubtitleLook: Codable, Equatable {
        enum Weight: String, Codable, CaseIterable { case normal, bold }
        enum Font: String, Codable, CaseIterable { case `default`, serif, mono, casual, smallcaps }
        enum Background: String, Codable, CaseIterable { case none, shade, box }
        enum Shadow: String, Codable, CaseIterable { case none, raised, depressed, uniform, drop }

        var size = 1.0
        var weight = Weight.normal
        var font = Font.default
        var color = "#ffffff"
        var background = Background.none
        var shadow = Shadow.drop
        /// Distance from the bottom in steps; the stock client's −16…+16, default −3.
        var position = -3.0
    }

    struct Stored: Codable {
        var maxBitrate = 0
        var volume: Float = 1
        var showRemaining = false
        var subtitles = SubtitleLook()
        var downloadBitrate = 0
    }

    private static let key = "jf.playback"

    var stored: Stored {
        didSet { save() }
    }

    init() {
        stored = AppModel.load(Stored.self, Self.key) ?? Stored()
    }

    /// Bits per second; 0 is automatic.
    var maxBitrate: Int {
        get { stored.maxBitrate }
        set { stored.maxBitrate = newValue }
    }

    var effectiveBitrate: Int { Quality.effective(stored.maxBitrate) }

    private func save() { AppModel.store(stored, Self.key) }

    static func label(_ bitrate: Int) -> String {
        guard bitrate > 0 else { return L10n.t("quality_auto") }
        let (value, mega) = Format.bitrate(bitrate)
        return L10n.f(mega ? "quality_mbps" : "quality_kbps", value)
    }
}

extension PlaybackPrefs {
    static func downloadLabel(_ bitrate: Int) -> String {
        bitrate == 0 ? L10n.t("download_original") : label(bitrate)
    }
}
