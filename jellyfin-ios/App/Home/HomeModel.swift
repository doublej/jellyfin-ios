import JellyfinKit
import SwiftUI

/// Home's rows. The last answer is kept on disk and drawn at once on launch, then replaced by
/// the server's fresh one: the server can take seconds, a warm launch shouldn't.
@Observable
final class HomeModel {
    struct Shelf: Codable, Identifiable, Hashable {
        var library: Item
        var items: [Item]
        var id: String { library.id }
    }

    struct Content: Codable, Hashable {
        var resume: [Item] = []
        var nextUp: [Item] = []
        var shelves: [Shelf] = []
        var libraries: [Item] = []

        var hero: Item? { resume.first ?? shelves.first?.items.first }
        var isEmpty: Bool { resume.isEmpty && nextUp.isEmpty && shelves.allSatisfy(\.items.isEmpty) }
    }

    private(set) var content: Content?
    private(set) var failed = false
    private(set) var error: Error?

    func showCached(userId: String) {
        guard content == nil, let cached = HomeCache.load(userId: userId) else { return }
        content = cached
        Timing.mark("home-content", "cache")
    }

    func load(_ client: APIClient) async {
        do {
            let fresh = try await Self.fetch(client)
            content = fresh
            failed = false
            Timing.mark("home-content", "network")
            Timing.mark("home-network")
            HomeCache.save(fresh, userId: client.userId ?? "")
        } catch is CancellationError {
        } catch {
            self.error = error
            failed = content == nil
        }
    }

    static func fetch(_ client: APIClient) async throws -> Content {
        async let views = client.views()
        async let resume = client.resume()
        async let nextUp = client.nextUp()
        let libraries = try await views.filter { $0.collectionType == "movies" || $0.collectionType == "tvshows" }
        let shelves = try await withThrowingTaskGroup(of: (Int, Shelf).self) { group in
            for (index, library) in libraries.enumerated() {
                group.addTask { (index, Shelf(library: library, items: try await client.latest(parentId: library.id))) }
            }
            var found: [Int: Shelf] = [:]
            for try await (index, shelf) in group { found[index] = shelf }
            return found.sorted { $0.key < $1.key }.map(\.value)
        }
        return Content(resume: try await resume, nextUp: try await nextUp, shelves: shelves, libraries: libraries)
    }
}

/// Home's last answer, per user, in Caches.
enum HomeCache {
    static func url(_ userId: String) -> URL {
        URL.cachesDirectory.appending(path: "home-\(userId).json")
    }

    static func load(userId: String) -> HomeModel.Content? {
        guard let data = try? Data(contentsOf: url(userId)) else { return nil }
        return try? JSONDecoder().decode(HomeModel.Content.self, from: data)
    }

    static func save(_ content: HomeModel.Content, userId: String) {
        guard let data = try? JSONEncoder().encode(content) else { return }
        try? data.write(to: url(userId), options: .atomic)
    }

    static func clear() {
        let files = (try? FileManager.default.contentsOfDirectory(at: .cachesDirectory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("home-") { try? FileManager.default.removeItem(at: file) }
    }
}
