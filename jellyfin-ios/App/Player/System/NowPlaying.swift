import AVFoundation
import JellyfinKit
import MediaPlayer
import UIKit

/// The lock screen, Control Center and AirPlay remote: what is playing, and the commands they
/// send back (play, pause, skip 10/30 s, scrub, next and previous episode).
final class NowPlaying {
    private weak var controller: PlayerController?
    private var targets: [(MPRemoteCommand, Any)] = []
    private var artwork: MPMediaItemArtwork?

    func attach(_ controller: PlayerController, server: URL?) {
        self.controller = controller
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        registerCommands()
        loadArtwork(controller.item, server: server)
        update()
    }

    func detach() {
        for (command, target) in targets { command.removeTarget(target) }
        targets = []
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Elapsed time and rate; the system runs the clock between updates.
    func update() {
        guard let controller else { return }
        let item = controller.item
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.name ?? "",
            MPMediaItemPropertyPlaybackDuration: controller.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: controller.player.currentTime().seconds.finiteOrZero,
            MPNowPlayingInfoPropertyPlaybackRate: controller.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.video.rawValue
        ]
        if item.kind == .episode {
            info[MPMediaItemPropertyArtist] = item.seriesName
            info[MPMediaItemPropertyAlbumTitle] = item.seasonName
        }
        if let artwork { info[MPMediaItemPropertyArtwork] = artwork }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = controller.next != nil
        center.previousTrackCommand.isEnabled = controller.previous != nil
    }

    private func registerCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.skipForwardCommand.preferredIntervals = [30]
        center.skipBackwardCommand.preferredIntervals = [10]
        add(center.playCommand) { $0.player.play() }
        add(center.pauseCommand) { $0.player.pause() }
        add(center.togglePlayPauseCommand) { $0.togglePlay() }
        add(center.skipForwardCommand) { $0.skip(by: 30) }
        add(center.skipBackwardCommand) { $0.skip(by: -10) }
        add(center.nextTrackCommand) { $0.playNext() }
        add(center.previousTrackCommand) { $0.playPrevious() }
        let scrub = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            MainActor.assumeIsolated { self?.controller?.seek(to: event.positionTime) }
            return .success
        }
        targets.append((center.changePlaybackPositionCommand, scrub))
    }

    private func add(_ command: MPRemoteCommand, _ action: @escaping @MainActor (PlayerController) -> Void) {
        command.isEnabled = true
        let target = command.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let controller = self?.controller else { return .noActionableNowPlayingItem }
                action(controller)
                return .success
            }
        }
        targets.append((command, target))
    }

    private func loadArtwork(_ item: Item, server: URL?) {
        guard let server, let art = item.thumbArt ?? item.posterArt else { return }
        Task {
            guard let image = await ImageLoader.shared.image(art.url(server: server, width: 720)) else { return }
            artwork = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in image }
            update()
        }
    }
}
