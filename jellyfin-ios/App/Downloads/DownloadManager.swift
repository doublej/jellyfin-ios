import JellyfinKit
import SwiftUI

/// Downloads for offline viewing, and positions watched offline waiting to reach the server.
@Observable
final class DownloadManager {
    static let shared = DownloadManager()

    weak var app: AppModel?
    let session = DownloadSession()
    private(set) var records: [String: DownloadRecord] = [:]
    private(set) var pending: [String: PendingProgress] = [:]

    private static var indexURL: URL { DownloadRecord.folder.appending(path: "index.json") }
    private static var pendingURL: URL { DownloadRecord.folder.appending(path: "pending.json") }

    init() {
        records = Self.read([String: DownloadRecord].self, Self.indexURL) ?? [:]
        pending = Self.read([String: PendingProgress].self, Self.pendingURL) ?? [:]
    }

    var sorted: [DownloadRecord] { records.values.sorted { $0.addedAt > $1.addedAt } }

    func record(for itemId: String) -> DownloadRecord? { records[itemId] }

    func playable(_ itemId: String) -> DownloadRecord? {
        records[itemId].flatMap { $0.state == .done ? $0 : nil }
    }

    func update(_ record: DownloadRecord) {
        records[record.id] = record
        Self.write(records, Self.indexURL)
    }

    func remove(_ itemId: String) {
        session.cancel(itemId: itemId)
        guard let record = records.removeValue(forKey: itemId) else { return }
        try? FileManager.default.removeItem(at: record.fileURL)
        for index in record.subtitleIndexes { try? FileManager.default.removeItem(at: record.subtitleURL(index)) }
        Self.write(records, Self.indexURL)
    }

    // MARK: Transfer events

    func progressed(_ itemId: String, received: Int64, expected: Int64) {
        guard var record = records[itemId] else { return }
        record.received = received
        if expected > 0 { record.expected = expected }
        record.expected = max(record.expected, received)
        records[itemId] = record
    }

    func finished(_ itemId: String, file: URL, ok: Bool) {
        guard var record = records[itemId] else {
            try? FileManager.default.removeItem(at: file)
            return
        }
        try? FileManager.default.removeItem(at: record.fileURL)
        let moved = ok && (try? FileManager.default.moveItem(at: file, to: record.fileURL)) != nil
        if moved { try? MP4.retagHEVC(at: record.fileURL) }
        record.state = moved ? .done : .failed
        record.expected = record.received
        update(record)
    }

    func failed(_ itemId: String) {
        guard var record = records[itemId], record.state != .done else { return }
        record.state = .failed
        update(record)
    }

    // MARK: Offline progress

    /// What the server would store for this stop, queued until it can be sent.
    func recordProgress(itemId: String, seconds: Double, runtime: Double) {
        let data = Resume.userData(stoppedAt: seconds, runtime: runtime)
        pending[itemId] = PendingProgress(itemId: itemId, positionTicks: data.playbackPositionTicks ?? 0,
                                          played: data.played ?? false, updatedAt: Date())
        if var record = records[itemId] {
            record.item.userData = UserData(played: data.played, playbackPositionTicks: data.playbackPositionTicks)
            records[itemId] = record
        }
        Self.write(pending, Self.pendingURL)
        Self.write(records, Self.indexURL)
    }

    /// Sends every queued position the server doesn't already have a newer one for.
    func syncProgress() {
        guard let client = app?.client, !pending.isEmpty else { return }
        let queue = pending
        Task {
            for (itemId, progress) in queue {
                guard let current = try? await client.item(itemId) else { continue }
                if progress.shouldSync(over: current.userData) {
                    let data = UserData(played: progress.played, playbackPositionTicks: progress.positionTicks)
                    guard (try? await client.setUserData(itemId, data)) != nil else { continue }
                }
                pending[itemId] = nil
            }
            Self.write(pending, Self.pendingURL)
        }
    }

    static func read<T: Decodable>(_ type: T.Type, _ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func write<T: Encodable>(_ value: T, _ url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
