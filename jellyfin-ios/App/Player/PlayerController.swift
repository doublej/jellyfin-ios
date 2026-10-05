import AVFoundation
import JellyfinKit
import SwiftUI

/// One playback session: negotiates the stream, switches tracks and quality at the same position,
/// falls back from direct play to HLS, and reports progress so resume points and watched state
/// reach every client. Ported from jellyfin-ui `src/lib/player/controller.svelte.ts`.
@Observable
final class PlayerController {
    let player = AVPlayer()
    private(set) var item: Item
    private(set) var stream: Stream?
    private(set) var audio: Int?
    /// Subtitle stream index; -1 is off, nil means "whatever the server picks".
    private(set) var subtitle: Int?
    private(set) var offset = 0.0
    private(set) var events: [TrackEvent] = []
    private(set) var subtitlesLoading = false
    private(set) var loading = true
    private(set) var failure: PlaybackFailure?
    var segments: [MediaSegment] = []
    var previous: Item?
    var next: Item?
    var autoplay = true
    var upNextDismissed = false
    private(set) var time = 0.0
    private(set) var isPlaying = false

    let client: APIClient?
    let prefs: PlaybackPrefs
    let download: DownloadRecord?
    var onFinished: (() -> Void)?
    var requestedAt = Date()
    private var sourceId: String?
    private var fellBack = false
    var stopped = false
    private var observations: [NSKeyValueObservation] = []
    private var playingObservation: NSKeyValueObservation?
    private var timeToken: Any?
    var reportTask: Task<Void, Never>?
    private var subtitleRequest = 0
    private var startedOnce = false

    init(request: PlayRequest, client: APIClient?, prefs: PlaybackPrefs, download: DownloadRecord?) {
        item = request.item
        self.client = client
        self.prefs = prefs
        self.download = download
        sourceId = request.sourceId
        audio = request.audio
        subtitle = request.subtitle
        player.volume = prefs.stored.volume
        player.allowsExternalPlayback = true
        observePlayer()
    }

    var duration: Double { item.runtimeSeconds > 0 ? item.runtimeSeconds : (player.currentItem?.duration.seconds ?? 0) }
    var source: MediaSource? { stream?.source }
    var audioTracks: [MediaStream] { source?.audioTracks ?? [] }
    var subtitleTracks: [MediaStream] { source?.subtitleTracks ?? [] }
    var chapters: [Chapter] { item.chapters ?? [] }
    var delivery: Delivery? { stream.map { Delivery.of($0.method, url: $0.url) } }

    func start(at seconds: Double) async {
        requestedAt = Date()
        loadExtras()
        startReporting()
        await load(at: seconds)
    }

    func load(at seconds: Double, allowDirect: Bool = true) async {
        loading = true
        failure = nil
        release()
        do {
            let stream = try await choose(seconds, allowDirect: allowDirect)
            Timing.span("play-negotiated", from: requestedAt, stream.method.rawValue)
            self.stream = stream
            attach(stream.url, at: seconds)
            loadSubtitles()
            if download == nil, let state = state() { try? await client?.reportStart(state) }
        } catch {
            fail(PlaybackFailure.from(error))
        }
    }

    private func choose(_ seconds: Double, allowDirect: Bool) async throws -> Stream {
        if let download { return download.stream }
        guard let client else { throw PlaybackFailure.offline }
        var negotiator = Negotiator(client: client, itemId: item.id, sourceId: sourceId, audio: audio, subtitle: subtitle,
                                    maxBitrate: prefs.effectiveBitrate)
        let first = try await negotiator.negotiate(start: seconds, allowDirect: allowDirect)
        sourceId = first.source.id
        if audio == nil { audio = first.source.defaultAudioStreamIndex }
        if subtitle == nil { subtitle = first.source.defaultSubtitleStreamIndex ?? -1 }
        if first.method != .directPlay || Negotiator.directPlays(first, audio: audio, subtitle: subtitle) { return first }
        negotiator.sourceId = sourceId
        negotiator.audio = audio
        negotiator.subtitle = subtitle
        return try await negotiator.negotiate(start: seconds, allowDirect: false)
    }

    private func attach(_ url: URL, at seconds: Double) {
        let item = AVPlayerItem(url: url)
        observations = [item.observe(\.status) { [weak self] item, _ in
            Task { @MainActor in self?.statusChanged(item, start: seconds) }
        }]
        NotificationCenter.default.addObserver(self, selector: #selector(ended), name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
        player.replaceCurrentItem(with: item)
        watchForStall(item)
    }

    /// A direct file AVPlayer never gets ready for (seen in the simulator) fails no faster than never,
    /// so after a while it counts as failed and falls back to HLS like an error would.
    private func watchForStall(_ item: AVPlayerItem) {
        guard stream?.method == .directPlay, download == nil else { return }
        Task {
            try? await Task.sleep(for: .seconds(Self.directStallSeconds))
            guard item == player.currentItem, loading else { return }
            fail(.stream)
        }
    }

    static let directStallSeconds = 6.0

    /// Ready but not playing ten seconds later: logs why, for the timing log.
    private func reportIfStuck(_ item: AVPlayerItem) {
        Task {
            try? await Task.sleep(for: .seconds(10))
            guard item == player.currentItem, !startedOnce else { return }
            let buffered = item.loadedTimeRanges.map { "\($0.timeRangeValue.start.seconds)+\($0.timeRangeValue.duration.seconds)" }
            let errors = item.errorLog()?.events.suffix(3).map { "\($0.errorStatusCode) \($0.errorComment ?? "")" } ?? []
            Timing.span("play-stuck", from: requestedAt, "status=\(player.timeControlStatus.rawValue) waiting=\(player.reasonForWaitingToPlay?.rawValue ?? "-") "
                + "rate=\(player.rate) time=\(item.currentTime().seconds) keepUp=\(item.isPlaybackLikelyToKeepUp) buffered=\(buffered) errors=\(errors)")
        }
    }

    private func statusChanged(_ item: AVPlayerItem, start: Double) {
        guard item == player.currentItem else { return }
        switch item.status {
        case .readyToPlay where loading:
            Timing.span("play-ready", from: requestedAt)
            loading = false
            seek(to: start, play: true)
            reportIfStuck(item)
        case .failed:
            fail(PlaybackFailure.from(item.error ?? PlaybackFailure.stream))
        default:
            break
        }
    }

    @objc private func ended(_ note: Notification) {
        guard (note.object as? AVPlayerItem) == player.currentItem else { return }
        if autoplay, next != nil { playNext() } else { onFinished?() }
    }

    private func fail(_ kind: PlaybackFailure) {
        if !fellBack, stream?.method == .directPlay, download == nil {
            fellBack = true
            Timing.span("play-fallback", from: requestedAt, kind.rawValue)
            failureNotice = L10n.t("player_fell_back")
            Task { await load(at: player.currentTime().seconds.finiteOrZero, allowDirect: false) }
            return
        }
        loading = false
        failure = kind
    }

    func retry() {
        fellBack = false
        Task { await load(at: time) }
    }

    /// Drops the current stream; a converted one also stops the server's encoder.
    private func release() {
        let old = stream
        player.replaceCurrentItem(with: nil)
        observations = []
        if old?.method == .transcode, let client, let session = old?.playSessionId {
            Task { try? await client.stopTranscode(playSessionId: session) }
        }
    }

    private func observePlayer() {
        timeToken = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 4), queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time.seconds) }
        }
        playingObservation = player.observe(\.timeControlStatus) { [weak self] player, _ in
            Task { @MainActor in self?.playingChanged(player.timeControlStatus == .playing) }
        }
    }

    private func tick(_ seconds: Double) {
        guard !loading, seconds.isFinite else { return }
        time = seconds
    }

    private func playingChanged(_ playing: Bool) {
        guard playing != isPlaying else { return }
        isPlaying = playing
        if playing, !startedOnce {
            startedOnce = true
            Timing.span("play-started", from: requestedAt, stream?.method.rawValue ?? "")
        }
        report(playing ? "Unpause" : "Pause")
    }

    // MARK: Tracks and quality, keeping the position

    private func restart(_ event: String) async {
        let position = player.currentTime().seconds.finiteOrZero
        report(event)
        requestedAt = Date()
        await load(at: position)
    }

    func setAudio(_ index: Int) async {
        guard index != audio else { return }
        audio = index
        await restart("AudioTrackChange")
    }

    func setSubtitle(_ index: Int) async {
        guard index != subtitle else { return }
        let wasBurnedIn = burnedIn
        subtitle = index
        let track = subtitleTracks.first { $0.index == index }
        if wasBurnedIn || track?.isBurnedIn == true { return await restart("SubtitleTrackChange") }
        report("SubtitleTrackChange")
        loadSubtitles()
    }

    func setQuality(_ bitrate: Int) async {
        prefs.maxBitrate = bitrate
        await restart("QualityChange")
    }

    func setOffset(_ seconds: Double) { offset = Cues.clampOffset(seconds) }

    private var burnedIn: Bool {
        stream?.method == .transcode && subtitleTracks.first { $0.index == subtitle }?.isBurnedIn == true
    }

    private func loadSubtitles() {
        subtitleRequest += 1
        let request = subtitleRequest
        events = []
        guard let track = subtitleTracks.first(where: { $0.index == subtitle }), !track.isBurnedIn, let source else { return }
        subtitlesLoading = true
        Task {
            let loaded = await subtitleEvents(track, source: source)
            guard request == subtitleRequest else { return }
            subtitlesLoading = false
            events = loaded ?? []
            if loaded == nil { failureNotice = L10n.t("err_subtitles") }
        }
    }

    private func subtitleEvents(_ track: MediaStream, source: MediaSource) async -> [TrackEvent]? {
        if let download { return download.subtitles(track.index) }
        return try? await client?.trackEvents(itemId: item.id, sourceId: source.id, index: track.index)
    }

    var failureNotice: String?

    func replace(with next: Item) {
        item = next
        stream = nil
        audio = nil
        subtitle = nil
        sourceId = nil
        fellBack = false
        upNextDismissed = false
        segments = []
        startedOnce = false
    }
}

extension Double {
    var finiteOrZero: Double { isFinite ? self : 0 }
}
