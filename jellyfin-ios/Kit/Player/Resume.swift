import Foundation

/// Where playback starts, and what a position becomes on the server.
public enum Resume {
    /// The server's defaults (Dashboard → Playback → Resume): under 5 % is "not started", over
    /// 90 % is "watched", and items under 5 minutes never get a resume point.
    public static let minPercent = 5.0
    public static let maxPercent = 90.0
    public static let minDuration = 300.0

    /// An explicit start (a chapter, "from the beginning") wins; otherwise the saved position.
    public static func startSeconds(_ item: Item, explicit: Double? = nil) -> Double {
        if let explicit { return max(0, explicit) }
        return item.isPlayed ? 0 : item.positionSeconds
    }

    /// The played state and resume point the server would store for stopping at `seconds`.
    public static func userData(stoppedAt seconds: Double, runtime: Double) -> UserData {
        guard runtime > 0 else { return UserData(played: false, playbackPositionTicks: Ticks.from(seconds: seconds)) }
        let percent = seconds / runtime * 100
        if percent >= maxPercent { return UserData(played: true, playbackPositionTicks: 0) }
        if percent < minPercent || runtime < minDuration { return UserData(played: false, playbackPositionTicks: 0) }
        return UserData(played: false, playbackPositionTicks: Ticks.from(seconds: seconds))
    }
}

/// Marking played clears the server's resume point; un-marking in the same session restores it.
public struct ResumeMemory: Sendable {
    var positions: [String: Int64] = [:]

    public init() {}

    /// The position to send with the new played state.
    public mutating func toggle(_ item: Item, played: Bool) -> Int64 {
        let saved = item.userData?.playbackPositionTicks ?? 0
        if played {
            if saved > 0 { positions[item.id] = saved }
            return 0
        }
        return positions[item.id] ?? 0
    }
}

/// A position watched offline, waiting to reach the server.
public struct PendingProgress: Codable, Sendable, Hashable {
    public var itemId: String
    public var positionTicks: Int64
    public var played: Bool
    public var updatedAt: Date

    public init(itemId: String, positionTicks: Int64, played: Bool, updatedAt: Date) {
        self.itemId = itemId
        self.positionTicks = positionTicks
        self.played = played
        self.updatedAt = updatedAt
    }

    /// Sent only when it is newer than the last play the server knows of, so watching on
    /// another device in the meantime wins.
    public func shouldSync(over server: UserData?) -> Bool {
        guard let last = server?.lastPlayedDate else { return true }
        return updatedAt > last
    }
}
