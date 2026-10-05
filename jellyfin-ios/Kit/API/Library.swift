import Foundation

/// Browsing calls, as the signed-in user.
public extension APIClient {
    /// Fields every card needs beyond the defaults (list view shows genres, hero shows overview).
    static let cardFields: Query = [
        ("fields", "PrimaryImageAspectRatio,Genres,MediaSourceCount,Overview"),
        ("enableImageTypes", "Primary,Backdrop,Thumb,Logo"),
        ("imageTypeLimit", "1")
    ]

    static let detailFields = "Overview,Genres,People,Studios,Taglines,MediaSources,Chapters,Trickplay,ProductionLocations"

    func items(_ path: String, _ query: Query = []) async throws -> [Item] {
        let result: ItemsResult = try await get(path, [("userId", try requireUser())] + query)
        return result.items ?? []
    }

    func views() async throws -> [Item] {
        try await items("/UserViews")
    }

    func resume(limit: Int = 12) async throws -> [Item] {
        try await items("/UserItems/Resume", [("limit", "\(limit)"), ("mediaTypes", "Video")] + Self.cardFields)
    }

    func nextUp(limit: Int = 24, seriesId: String? = nil) async throws -> [Item] {
        let cutoff = ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: -365 * 86_400))
        let query: Query = [
            ("limit", "\(limit)"), ("seriesId", seriesId), ("nextUpDateCutoff", cutoff),
            ("enableResumable", "false"), ("enableRewatching", "false")
        ]
        return try await items("/Shows/NextUp", query + Self.cardFields)
    }

    func latest(parentId: String, limit: Int = 16) async throws -> [Item] {
        let query: Query = [("userId", try requireUser()), ("parentId", parentId), ("limit", "\(limit)"), ("groupItems", "true")]
        return try await get("/Items/Latest", query + Self.cardFields)
    }

    func item(_ id: String) async throws -> Item {
        try await get("/Items/\(id)", [("userId", try requireUser()), ("fields", Self.detailFields)])
    }

    func page(_ query: Query) async throws -> ItemsResult {
        try await get("/Items", [("userId", try requireUser())] + Self.cardFields + query)
    }

    func seasons(seriesId: String) async throws -> [Item] {
        try await items("/Shows/\(seriesId)/Seasons", Self.cardFields)
    }

    func episodes(seriesId: String, seasonId: String? = nil) async throws -> [Item] {
        try await items("/Shows/\(seriesId)/Episodes", [("seasonId", seasonId)] + Self.cardFields)
    }

    func similar(_ id: String, limit: Int = 12) async throws -> [Item] {
        try await items("/Items/\(id)/Similar", [("limit", "\(limit)")] + Self.cardFields)
    }

    func filters(parentId: String, types: String) async throws -> QueryFilters {
        try await get("/Items/Filters", [("userId", try requireUser()), ("parentId", parentId), ("includeItemTypes", types)])
    }

    func search(_ term: String) async throws -> [Item] {
        let query: Query = [
            ("searchTerm", term), ("recursive", "true"),
            ("includeItemTypes", "Movie,Series,Episode,BoxSet"), ("limit", "60")
        ]
        return try await items("/Items", query + Self.cardFields)
    }

    func searchPeople(_ term: String) async throws -> [Item] {
        try await items("/Persons", [("searchTerm", term), ("limit", "12"), ("enableImageTypes", "Primary")])
    }

    /// Films and series a person appears in.
    func filmography(personId: String) async throws -> [Item] {
        let query: Query = [
            ("personIds", personId), ("recursive", "true"), ("includeItemTypes", "Movie,Series"),
            ("sortBy", "PremiereDate,SortName"), ("sortOrder", "Descending")
        ]
        return try await items("/Items", query + Self.cardFields)
    }

    func me() async throws -> UserDto {
        try await get("/Users/Me")
    }

    func cultures() async throws -> [Culture] {
        try await get("/Localization/Cultures")
    }
}
