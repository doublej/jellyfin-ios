import AVFoundation
@testable import JellyfinUI
import JellyfinKit
import XCTest

/// The quality bar, measured with the app's own PlayerController against the real server: how long a
/// film takes to start, and whether audio, subtitle and quality switches keep the position. Prints
/// `JFIOS-SWITCH` lines; the start split comes from the app's `JFIOS-TIMING` log. Changes the
/// film's resume point: run `scripts/watch-state.sh restore` afterwards.
@MainActor
final class PlayerTimings: XCTestCase {
    static let asteroidCity = "9246104488ea4ef41aac5c65077c3a0b"  // the library's one MP4
    static let croupier = "59a1b3003aa5cc5ac2d63af3ee8d5fdd"  // H.264, 3 audio tracks, 7 text subtitles

    func testFilmStarts() async throws {
        let client = try await QuickConnectLogin.client()
        let controller = try await play(Self.asteroidCity, client, at: 0)
        controller.finish()
    }

    func testSwitchesKeepPosition() async throws {
        let client = try await QuickConnectLogin.client()
        let prefs = PlaybackPrefs()
        let cap = prefs.maxBitrate
        defer { prefs.maxBitrate = cap }
        let controller = try await play(Self.croupier, client, at: 600, prefs: prefs)
        let audio = try XCTUnwrap(controller.audioTracks.map(\.index).first { $0 != controller.audio })
        let subtitle = try XCTUnwrap(controller.subtitleTracks.first { !$0.isBurnedIn }?.index)
        try await measure("audio", controller) { await controller.setAudio(audio) }
        try await measure("subtitle", controller) { await controller.setSubtitle(subtitle) }
        try await measure("quality", controller) { await controller.setQuality(4_000_000) }
        controller.finish()
    }

    private func play(_ id: String, _ client: APIClient, at seconds: Double, prefs: PlaybackPrefs = PlaybackPrefs()) async throws -> PlayerController {
        let item = try await client.item(id)
        let controller = PlayerController(request: PlayRequest(item: item), client: client, prefs: prefs, download: nil)
        await controller.start(at: seconds)
        try await waitPlaying(controller)
        return controller
    }

    private func measure(_ name: String, _ controller: PlayerController, _ change: () async -> Void) async throws {
        try await Task.sleep(for: .seconds(4))
        let before = controller.player.currentTime().seconds
        let started = Date()
        await change()
        try await waitPlaying(controller)
        let after = controller.player.currentTime().seconds
        let took = Date().timeIntervalSince(started)
        print("JFIOS-SWITCH \(name) before=\(before) after=\(after) drift=\(after - before) took=\(took) method=\(controller.stream?.method.rawValue ?? "")")
        XCTAssertLessThan(abs(after - before), 3, "\(name) keeps the position")
    }

    /// Ready, playing, and the clock moving past where it was.
    private func waitPlaying(_ controller: PlayerController, timeout: Double = 60) async throws {
        let start = Date(), from = controller.player.currentTime().seconds
        while Date().timeIntervalSince(start) < timeout {
            if let failure = controller.failure { return XCTFail("playback failed: \(failure)") }
            if !controller.loading, controller.isPlaying, controller.player.currentTime().seconds > from + 0.5 { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTFail("not playing after \(timeout) s")
    }
}
