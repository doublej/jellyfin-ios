import JellyfinKit
import SwiftUI

/// Fetches downloads with a background URLSession, so they continue when the app is closed.
/// The server streams a converted file without a length, so progress is measured against the
/// size the bitrate and runtime predict.
final class DownloadSession: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    static let identifier = "dev.jurrejan.jellyfin-ui.downloads"
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    func start(_ url: URL, itemId: String) {
        let task = session.downloadTask(with: url)
        task.taskDescription = itemId
        task.resume()
    }

    func cancel(itemId: String) {
        session.getAllTasks { tasks in tasks.filter { $0.taskDescription == itemId }.forEach { $0.cancel() } }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let id = downloadTask.taskDescription ?? ""
        let expected = totalBytesExpectedToWrite
        MainActor.assumeIsolated { DownloadManager.shared.progressed(id, received: totalBytesWritten, expected: expected) }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let id = downloadTask.taskDescription ?? ""
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        let kept = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.moveItem(at: location, to: kept)
        MainActor.assumeIsolated { DownloadManager.shared.finished(id, file: kept, ok: (200..<300).contains(status)) }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error != nil else { return }
        let id = task.taskDescription ?? ""
        MainActor.assumeIsolated { DownloadManager.shared.failed(id) }
    }
}
