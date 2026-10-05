import Foundation

/// Where things sit on the seek bar: trickplay tiles, skippable segments, Up Next, chapters.
/// Ported from jellyfin-ui `src/lib/player/rules/timeline.ts`.
public enum Timeline {
    public struct Tile: Equatable, Sendable {
        public var sheet: Int
        public var x: Int
        public var y: Int
        public var width: Int
        public var height: Int
    }

    /// Which sprite sheet and which cell of it holds the preview for `seconds`.
    public static func trickplayTile(_ info: TrickplayInfo, seconds: Double) -> Tile? {
        let width = info.width ?? 0, height = info.height ?? 0
        let columns = info.tileWidth ?? 0, rows = info.tileHeight ?? 0
        let count = info.thumbnailCount ?? 0, interval = info.interval ?? 0
        guard interval > 0, columns > 0, rows > 0, count > 0 else { return nil }
        let index = min(count - 1, max(0, Int((seconds * 1000).rounded(.down)) / interval))
        let perSheet = columns * rows
        let cell = index % perSheet
        return Tile(sheet: index / perSheet, x: (cell % columns) * width, y: (cell / columns) * height,
                    width: width, height: height)
    }

    /// The narrowest trickplay resolution at least `minWidth` wide, else the widest there is.
    public static func pickTrickplay(_ byWidth: [String: TrickplayInfo]?, minWidth: Int = 240) -> TrickplayInfo? {
        let infos = (byWidth ?? [:]).values.sorted { ($0.width ?? 0) < ($1.width ?? 0) }
        return infos.first { ($0.width ?? 0) >= minWidth } ?? infos.last
    }

    static let skippable: Set = ["Intro", "Outro"]

    /// The intro or outro playing now, if it is long enough to be worth a button.
    public static func activeSegment(_ segments: [MediaSegment], seconds: Double) -> MediaSegment? {
        let now = Ticks.from(seconds: seconds), second = Int64(Ticks.perSecond)
        return segments.first { segment in
            let start = segment.startTicks ?? 0, end = segment.endTicks ?? 0
            return skippable.contains(segment.type ?? "") && end - start >= 3 * second && start <= now && now < end - second
        }
    }

    /// When the Up Next card appears: at the credits, else 30–40 s before the end; never under 10 min.
    public static func upNextAt(runtime: Double, outroStart: Double? = nil) -> Double? {
        guard runtime >= 600 else { return nil }
        if let outroStart, outroStart > runtime / 2 { return outroStart }
        return runtime - (runtime >= 3000 ? 40 : runtime >= 2400 ? 35 : 30)
    }

    public static func nextChapterStart(_ chapters: [Chapter], seconds: Double) -> Double? {
        chapters.map(\.startSeconds).first { $0 > seconds + 1 }
    }

    /// Looks 10 s back, so a second press steps past the chapter you are in.
    public static func previousChapterStart(_ chapters: [Chapter], seconds: Double) -> Double {
        chapters.map(\.startSeconds).last { $0 <= seconds - 10 } ?? 0
    }

    public static func chapterAt(_ chapters: [Chapter], seconds: Double) -> Int {
        chapters.map(\.startSeconds).filter { $0 <= seconds }.count - 1
    }
}
