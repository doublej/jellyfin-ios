import Foundation

/// Times and codes as the web client prints them.
public enum Format {
    /// 1:02:03 or 2:03.
    public static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.isFinite ? seconds : 0))
        let hours = total / 3600, minutes = total % 3600 / 60, rest = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }

    /// 1h 52m or 47m.
    public static func duration(_ ticks: Int64?) -> String {
        let minutes = Int((Ticks.seconds(ticks) / 60).rounded())
        guard minutes > 0 else { return "" }
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }

    /// "S1:E2" for an episode.
    public static func episodeCode(season: Int?, episode: Int?) -> String {
        guard let episode else { return "" }
        guard let season else { return "E\(episode)" }
        return "S\(season):E\(episode)"
    }

    public static func progress(_ item: Item) -> Double {
        guard let position = item.userData?.playbackPositionTicks, position > 0, let runtime = item.runTimeTicks, runtime > 0 else {
            return item.userData?.playedPercentage ?? 0
        }
        return min(100, Double(position) / Double(runtime) * 100)
    }

    /// Bits per second as the quality menu shows it: "20 Mbps", "720 kbps".
    public static func bitrate(_ bits: Int) -> (value: String, mega: Bool) {
        bits >= 1_000_000 ? ("\(bits / 1_000_000)", true) : ("\(bits / 1000)", false)
    }
}

/// Quality caps offered in Settings and the player, in bits per second; 0 is automatic.
public enum Quality {
    public static let steps = [
        0, 120_000_000, 80_000_000, 60_000_000, 40_000_000, 20_000_000, 10_000_000, 8_000_000,
        4_000_000, 2_000_000, 1_000_000, 720_000, 420_000
    ]

    /// Automatic quality on a LAN means "as high as the server will send".
    public static let auto = 120_000_000

    public static func effective(_ cap: Int) -> Int { cap == 0 ? auto : cap }
}
