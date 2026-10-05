import Foundation

/// Everything about how one library looks, remembered per library on this device.
/// Ported from jellyfin-ui `src/lib/browse/prefs.ts`.
public struct ViewPrefs: Codable, Sendable, Equatable {
    public enum Status: String, Codable, Sendable, CaseIterable {
        case all, unplayed, played, resumable, favorite
    }

    public enum Quality: String, Codable, Sendable, CaseIterable {
        case sd, hd, uhd = "4k", threeD = "3d", bluray, dvd
    }

    public enum Layout: String, Codable, Sendable { case grid, list }

    public var sortBy = "SortName"
    public var ascending = true
    public var layout = Layout.grid
    public var status = Status.all
    public var genres: [String] = []
    public var years: [Int] = []
    public var ratings: [String] = []
    public var quality: [Quality] = []

    public init() {}

    public static let movieSorts = ["SortName", "DateCreated", "PremiereDate", "CommunityRating", "Runtime", "DatePlayed", "Random"]
    public static let seriesSorts = ["SortName", "DateCreated", "DateLastContentAdded", "PremiereDate", "CommunityRating", "DatePlayed", "Random"]

    public var activeFilterCount: Int {
        genres.count + years.count + ratings.count + quality.count + (status == .all ? 0 : 1)
    }

    public mutating func clearFilters() {
        status = .all
        genres = []
        years = []
        ratings = []
        quality = []
    }

    public func query(letter: String? = nil) -> Query {
        let tiebreak = sortBy == "SortName" || sortBy == "Random" ? "" : ",SortName"
        return [
            ("sortBy", sortBy + tiebreak), ("sortOrder", ascending ? "Ascending" : "Descending"),
            ("filters", statusFilter), ("genres", genres.isEmpty ? nil : genres.joined(separator: "|")),
            ("years", years.isEmpty ? nil : years.map(String.init).joined(separator: ",")),
            ("officialRatings", ratings.isEmpty ? nil : ratings.joined(separator: "|"))
        ] + qualityQuery + Self.letterQuery(letter)
    }

    var statusFilter: String? {
        switch status {
        case .all: nil
        case .unplayed: "IsUnplayed"
        case .played: "IsPlayed"
        case .resumable: "IsResumable"
        case .favorite: "IsFavorite"
        }
    }

    /// SD and HD together mean "any resolution", so they cancel out.
    var qualityQuery: Query {
        let has = { (quality: Quality) in self.quality.contains(quality) }
        let discs = [has(.bluray) ? "BluRay" : nil, has(.dvd) ? "Dvd" : nil].compactMap { $0 }
        return [
            ("isHd", has(.hd) != has(.sd) ? "\(has(.hd))" : nil), ("is4K", has(.uhd) ? "true" : nil),
            ("is3D", has(.threeD) ? "true" : nil), ("videoTypes", discs.isEmpty ? nil : discs.joined(separator: ","))
        ]
    }

    /// Letter "#" means titles that start before A: digits and punctuation.
    static func letterQuery(_ letter: String?) -> Query {
        guard let letter else { return [] }
        return letter == "#" ? [("nameLessThan", "A")] : [("nameStartsWith", letter)]
    }
}
