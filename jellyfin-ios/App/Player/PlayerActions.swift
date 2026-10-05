import AVFoundation
import JellyfinKit
import SwiftUI

/// Transport, progress reports and the episodes around this one.
extension PlayerController {
    func togglePlay() {
        if isPlaying { player.pause() } else { player.play() }
    }

    func seek(to seconds: Double, play: Bool = false) {
        let target = max(0, duration > 0 ? min(seconds, duration - 1) : seconds)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                if play { self?.player.play() }
                self?.report("TimeUpdate")
            }
        }
    }

    func skip(by seconds: Double) { seek(to: time + seconds) }

    func nudgeVolume(_ step: Float) {
        player.volume = max(0, min(1, player.volume + step))
        prefs.stored.volume = player.volume
    }

    func playNext() {
        guard let next else { return }
        advance(to: next)
    }

    func playPrevious() {
        guard let previous else { return }
        advance(to: previous)
    }

    /// The next episode starts where it was left, in the same player.
    func advance(to episode: Item) {
        finish()
        stopped = false
        replace(with: episode)
        Task { await start(at: Resume.startSeconds(episode)) }
    }

    // MARK: Reporting

    func state() -> ReportState? {
        guard let stream else { return nil }
        return ReportState(itemId: item.id, mediaSourceId: stream.source.id, playSessionId: stream.playSessionId,
                           playMethod: stream.method, position: player.currentTime().seconds.finiteOrZero,
                           paused: !isPlaying, muted: player.isMuted, volume: player.volume, audio: audio, subtitle: subtitle)
    }

    /// Fire and forget: a missed report is covered by the next one ten seconds later.
    func report(_ event: String) {
        guard !stopped, !loading, failure == nil, download == nil, let client, let state = state() else { return }
        Task { try? await client.reportProgress(state, event: event) }
    }

    func startReporting() {
        reportTask?.cancel()
        reportTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                self?.report("TimeUpdate")
                self?.saveOfflineProgress()
            }
        }
    }

    /// Reports the final position once; the server turns it into a resume point or "watched".
    /// The returned task ends when the server has it, so pages can reload after that.
    @discardableResult
    func finish() -> Task<Void, Never>? {
        guard !stopped else { return nil }
        stopped = true
        reportTask?.cancel()
        saveOfflineProgress()
        player.pause()
        guard download == nil, failure == nil, let client, let state = state() else { return nil }
        let stream = self.stream
        return Task {
            try? await client.reportStopped(state)
            if stream?.method == .transcode { try? await client.stopTranscode(playSessionId: stream?.playSessionId ?? "") }
        }
    }

    /// A downloaded copy keeps its position locally until the server can be told.
    func saveOfflineProgress() {
        guard let download, !loading else { return }
        let seconds = player.currentTime().seconds.finiteOrZero
        download.manager.recordProgress(itemId: download.itemId, seconds: seconds, runtime: duration)
    }

    // MARK: Extras

    func loadExtras() {
        guard let client else { return }
        let item = self.item
        Task {
            segments = (try? await client.segments(itemId: item.id)) ?? []
            autoplay = (try? await client.me())?.configuration?.enableNextEpisodeAutoPlay ?? true
            (previous, next) = await Self.neighbours(item, client)
        }
    }

    /// The episodes around this one in its series, skipping missing and unaired ones.
    static func neighbours(_ item: Item, _ client: APIClient) async -> (Item?, Item?) {
        guard item.kind == .episode, let seriesId = item.seriesId,
              let all = try? await client.episodes(seriesId: seriesId).filter({ $0.locationType != "Virtual" }),
              let index = all.firstIndex(where: { $0.id == item.id }) else { return (nil, nil) }
        return (all[safe: index - 1], all[safe: index + 1])
    }

    // MARK: Keyboard

    func handle(_ action: PlayerAction) -> String? {
        switch action {
        case .toggle: togglePlay()
        case .back: skip(by: -10)
        case .forward: skip(by: 30)
        case .mute: player.isMuted.toggle()
        case .previous: playPrevious()
        case .next: playNext()
        case .nextChapter: Timeline.nextChapterStart(chapters, seconds: time).map { seek(to: $0) }
        case .previousChapter: seek(to: Timeline.previousChapterStart(chapters, seconds: time))
        case .start: seek(to: 0)
        case .end: seek(to: duration - 5)
        case let .percent(percent): seek(to: duration * Double(percent) / 100)
        case .volumeUp, .volumeDown: return volume(action == .volumeUp ? 0.05 : -0.05)
        case .subtitleEarlier, .subtitleLater: return subtitleShift(action == .subtitleLater ? 0.1 : -0.1)
        case .fullscreen, .escape, .stop: break
        }
        return nil
    }

    private func volume(_ step: Float) -> String {
        nudgeVolume(step)
        return L10n.f("player_volume_toast", "\(Int((player.volume * 100).rounded()))")
    }

    private func subtitleShift(_ step: Double) -> String {
        setOffset(offset + step)
        return L10n.f("player_offset_toast", String(format: "%+.1f", offset))
    }
}
