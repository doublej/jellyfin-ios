import Foundation

/// Jellyfin sends PascalCase keys (`RunTimeTicks`); Swift properties are camelCase. The
/// strategy flips only the first letter, so dictionary keys (`ImageTags["Primary"]`) stay as sent.
public enum JSONCoding {
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { path in
            CaseKey(path.last?.stringValue.lowercasingFirst ?? "")
        }
        decoder.dateDecodingStrategy = .custom(decodeDate)
        return decoder
    }()

    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .custom { path in
            CaseKey(path.last?.stringValue.uppercasingFirst ?? "")
        }
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// The server writes 7 fractional digits (`2026-10-04T21:57:41.5749749Z`), more than
    /// `ISO8601DateFormatter` accepts, so the fraction is cut to milliseconds first.
    static func decodeDate(_ decoder: Decoder) throws -> Date {
        let text = try decoder.singleValueContainer().decode(String.self)
        if let date = parseDate(text) { return date }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(text)"))
    }

    public static func parseDate(_ text: String) -> Date? {
        let trimmed = text.replacingOccurrences(of: #"(\.\d{3})\d+"#, with: "$1", options: .regularExpression)
        let zoned = trimmed.hasSuffix("Z") || trimmed.contains("+") ? trimmed : trimmed + "Z"
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: zoned) ?? ISO8601DateFormatter().date(from: zoned)
    }
}

struct CaseKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

extension String {
    var lowercasingFirst: String { prefix(1).lowercased() + dropFirst() }
    var uppercasingFirst: String { prefix(1).uppercased() + dropFirst() }
}

/// Jellyfin counts time in ticks of 100 ns.
public enum Ticks {
    public static let perSecond: Double = 10_000_000

    public static func seconds(_ ticks: Int64?) -> Double { Double(ticks ?? 0) / perSecond }
    public static func from(seconds: Double) -> Int64 { Int64((seconds * perSecond).rounded()) }
}
