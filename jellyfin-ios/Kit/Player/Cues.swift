import Foundation

/// Subtitle timing and markup, ported from jellyfin-ui `src/lib/player/rules/cues.ts`.
public enum Cues {
    /// Events that should be on screen at `time`. A positive offset shows subtitles later.
    public static func active(_ events: [TrackEvent], time: Double, offset: Double) -> [TrackEvent] {
        let target = time - offset
        var low = 0, high = events.count - 1, last = -1
        while low <= high {
            let mid = (low + high) / 2
            if events[mid].start <= target {
                last = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        var active: [TrackEvent] = []
        var index = last
        while index >= 0, target - events[index].start < 60 {
            if events[index].end > target { active.insert(events[index], at: 0) }
            index -= 1
        }
        return active
    }

    public struct Span: Equatable, Sendable {
        public var text: String
        public var italic: Bool
        public var bold: Bool

        public init(text: String, italic: Bool = false, bold: Bool = false) {
            self.text = text
            self.italic = italic
            self.bold = bold
        }
    }

    /// Subtitle text as lines of styled spans. Keeps italic and bold, drops every other tag and
    /// ASS override block.
    public static func parse(_ text: String) -> [[Span]] {
        let clean = text
            .replacingOccurrences(of: #"\{\\[^}]*\}"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\\[Nn]|<br\s*/?>"#, with: "\n", options: [.regularExpression, .caseInsensitive])
        return clean.components(separatedBy: "\n").map(parseLine)
    }

    static func parseLine(_ line: String) -> [Span] {
        var spans: [Span] = []
        var italic = false, bold = false
        for part in line.splitKeepingTags() {
            guard let tag = part.firstMatch(of: /^<(\/?)([a-zA-Z]+)[^>]*>$/) else {
                if !part.isEmpty { spans.append(Span(text: part, italic: italic, bold: bold)) }
                continue
            }
            let on = tag.1.isEmpty
            switch tag.2.lowercased() {
            case "i": italic = on
            case "b": bold = on
            default: break
            }
        }
        return spans
    }

    /// "+1.5s" or "-0.3" typed by hand, clamped to the ±30 s the slider allows.
    public static func parseOffset(_ input: String) -> Double? {
        var text = input.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        if text.lowercased().hasSuffix("s") { text.removeLast() }
        guard let value = Double(text) else { return nil }
        return clampOffset(value)
    }

    public static func clampOffset(_ value: Double) -> Double {
        max(-30, min(30, (value * 10).rounded() / 10))
    }
}

extension String {
    /// Splits around `<…>` tags, keeping the tags as their own parts.
    func splitKeepingTags() -> [String] {
        var parts: [String] = [], rest = self[...]
        while let range = rest.firstRange(of: /<[^>]+>/) {
            parts.append(String(rest[..<range.lowerBound]))
            parts.append(String(rest[range]))
            rest = rest[range.upperBound...]
        }
        parts.append(String(rest))
        return parts
    }
}
