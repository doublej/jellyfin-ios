import Foundation

/// Watched, favourite, resume point and account settings: the calls that change the user's state.
public extension APIClient {
    /// Un-marking with a position puts that resume point back in the same call.
    func setPlayed(_ id: String, played: Bool, position: Int64 = 0) async throws -> UserData {
        let user = try requireUser()
        if !played && position > 0 {
            return try await setUserData(id, UserData(played: false, playbackPositionTicks: position))
        }
        let data = try await send(played ? "POST" : "DELETE", "/UserPlayedItems/\(id)", [("userId", user)])
        return try JSONCoding.decoder.decode(UserData.self, from: data)
    }

    func setFavorite(_ id: String, favorite: Bool) async throws -> UserData {
        let data = try await send(favorite ? "POST" : "DELETE", "/UserFavoriteItems/\(id)", [("userId", try requireUser())])
        return try JSONCoding.decoder.decode(UserData.self, from: data)
    }

    /// Writes played state and position as given; used to restore resume points and to sync
    /// positions watched offline.
    func setUserData(_ id: String, _ userData: UserData) async throws -> UserData {
        try await post("/UserItems/\(id)/UserData", [("userId", try requireUser())], body: userData)
    }

    /// The server replaces the whole configuration on save, so the new values are patched into
    /// the object it last sent rather than sent alone.
    func saveConfiguration(_ changes: UserConfiguration) async throws {
        let raw = try await send("GET", "/Users/Me")
        let user = try JSONSerialization.jsonObject(with: raw) as? [String: Any] ?? [:]
        var config = user["Configuration"] as? [String: Any] ?? [:]
        let patch = try JSONSerialization.jsonObject(with: JSONCoding.encoder.encode(changes)) as? [String: Any] ?? [:]
        config.merge(patch) { _, new in new }
        let body = try JSONSerialization.data(withJSONObject: config)
        try await send("POST", "/Users/Configuration", [("userId", try requireUser())], json: body)
    }
}
