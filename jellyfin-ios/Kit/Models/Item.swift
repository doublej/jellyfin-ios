import Foundation

/// The parts of the server's `BaseItemDto` this app reads. Every field is optional on the wire.
public struct Item: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String?
    public var type: String?
    public var collectionType: String?
    public var overview: String?
    public var taglines: [String]?
    public var genres: [String]?
    public var studios: [NameId]?
    public var people: [Person]?
    public var productionYear: Int?
    public var premiereDate: Date?
    public var endDate: Date?
    public var officialRating: String?
    public var communityRating: Double?
    public var criticRating: Double?
    public var runTimeTicks: Int64?
    public var status: String?
    public var productionLocations: [String]?

    public var seriesId: String?
    public var seriesName: String?
    public var seasonId: String?
    public var seasonName: String?
    public var indexNumber: Int?
    public var parentIndexNumber: Int?
    public var locationType: String?
    public var childCount: Int?

    public var imageTags: [String: String]?
    public var backdropImageTags: [String]?
    public var imageBlurHashes: [String: [String: String]]?
    public var parentBackdropItemId: String?
    public var parentBackdropImageTags: [String]?
    public var parentThumbItemId: String?
    public var parentThumbImageTag: String?
    public var parentLogoItemId: String?
    public var parentLogoImageTag: String?
    public var seriesPrimaryImageTag: String?
    public var primaryImageAspectRatio: Double?

    public var userData: UserData?
    public var mediaSources: [MediaSource]?
    public var mediaSourceCount: Int?
    public var chapters: [Chapter]?
    /// Per media source id, per tile width.
    public var trickplay: [String: [String: TrickplayInfo]]?

    public init(id: String, name: String? = nil, type: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
    }
}

public extension Item {
    var kind: ItemKind { ItemKind(rawValue: type ?? "") ?? .other }
    var runtimeSeconds: Double { Ticks.seconds(runTimeTicks) }
    var positionSeconds: Double { Ticks.seconds(userData?.playbackPositionTicks) }
    var isPlayed: Bool { userData?.played ?? false }
    var isFavorite: Bool { userData?.isFavorite ?? false }
    var isPlayable: Bool { kind == .movie || kind == .episode || kind == .video }
}

public enum ItemKind: String, Sendable {
    case movie = "Movie", series = "Series", season = "Season", episode = "Episode"
    case person = "Person", boxSet = "BoxSet", folder = "CollectionFolder", video = "Video"
    case other
}

public struct UserData: Codable, Sendable, Hashable {
    public var played: Bool?
    public var playbackPositionTicks: Int64?
    public var playedPercentage: Double?
    public var isFavorite: Bool?
    public var unplayedItemCount: Int?
    public var lastPlayedDate: Date?

    public init(played: Bool? = nil, playbackPositionTicks: Int64? = nil, isFavorite: Bool? = nil) {
        self.played = played
        self.playbackPositionTicks = playbackPositionTicks
        self.isFavorite = isFavorite
    }
}

public struct NameId: Codable, Sendable, Hashable {
    public var name: String?
    public var id: String?
}

public struct Person: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String?
    public var role: String?
    public var type: String?
    public var primaryImageTag: String?
    public var imageBlurHashes: [String: [String: String]]?
}

public struct ItemsResult: Codable, Sendable {
    public var items: [Item]?
    public var totalRecordCount: Int?
}

/// Genres, years and age ratings present in one library, for the filter sheet.
public struct QueryFilters: Codable, Sendable {
    public var genres: [String]?
    public var years: [Int]?
    public var officialRatings: [String]?

    public init() {}
}
