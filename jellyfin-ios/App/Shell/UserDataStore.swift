import JellyfinKit
import SwiftUI

/// Watched and favourite state as last changed in this app, shared by every view of an item,
/// so a toggle on a Home card also shows on the detail page and in the library.
@Observable
final class UserDataStore {
    private var overrides: [String: UserData] = [:]
    private var memory = ResumeMemory()
    var failure: String?

    func data(_ item: Item) -> UserData? { overrides[item.id] ?? item.userData }
    func isPlayed(_ item: Item) -> Bool { data(item)?.played ?? false }
    func isFavorite(_ item: Item) -> Bool { data(item)?.isFavorite ?? false }

    func current(_ item: Item) -> Item {
        var copy = item
        copy.userData = data(item)
        return copy
    }

    /// The server's newer answer (after playback, say) replaces what was changed here.
    func update(_ item: Item) {
        overrides[item.id] = item.userData
    }

    func clear() { overrides = [:] }

    /// Marking played clears the server's resume point; un-marking in the same session puts it back.
    func togglePlayed(_ item: Item, client: APIClient?) {
        let played = !isPlayed(item)
        let position = memory.toggle(current(item), played: played)
        var optimistic = data(item) ?? UserData()
        optimistic.played = played
        optimistic.playbackPositionTicks = position
        optimistic.playedPercentage = 0
        flip(item, optimistic) { try await client?.setPlayed(item.id, played: played, position: position) }
    }

    func toggleFavorite(_ item: Item, client: APIClient?) {
        var optimistic = data(item) ?? UserData()
        optimistic.isFavorite = !isFavorite(item)
        let favorite = optimistic.isFavorite ?? false
        flip(item, optimistic) { try await client?.setFavorite(item.id, favorite: favorite) }
    }

    /// Flip at once, then keep the server's answer, or roll back and say so.
    private func flip(_ item: Item, _ optimistic: UserData, save: @escaping () async throws -> UserData?) {
        let before = overrides[item.id]
        overrides[item.id] = optimistic
        Task {
            do {
                if let saved = try await save() { overrides[item.id] = merge(optimistic, saved) }
            } catch {
                overrides[item.id] = before
                failure = L10n.t("toggle_failed")
            }
        }
    }

    private func merge(_ optimistic: UserData, _ saved: UserData) -> UserData {
        var merged = saved
        merged.playedPercentage = saved.playedPercentage ?? optimistic.playedPercentage
        return merged
    }
}
