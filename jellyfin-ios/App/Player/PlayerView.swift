import JellyfinKit
import SwiftUI

/// The full-screen player. Tap shows or hides the controls; on iPad a hardware keyboard drives
/// it with the web client's keys.
struct PlayerView: View {
    let request: PlayRequest
    @Environment(AppModel.self) private var app
    @State private var controller: PlayerController?
    @State private var bridge = PlayerBridge()
    @State private var nowPlaying = NowPlaying()
    @State private var controlsShown = true
    @State private var toast: String?
    @State private var lastTouch = Date()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let controller { stage(controller) }
        }
        .statusBarHidden(!controlsShown)
        .persistentSystemOverlays(.hidden)
        .task { await start() }
        .task(id: lastTouch) { await hideLater() }
        .onDisappear { stop() }
    }

    private func stage(_ controller: PlayerController) -> some View {
        ZStack {
            PlayerSurface(player: controller.player, bridge: bridge) { handle($0, controller) }
                .ignoresSafeArea()
                .onTapGesture { toggleControls() }
            Captions(events: controller.events, time: controller.time, offset: controller.offset, look: app.prefs.stored.subtitles)
            if controlsShown || controller.loading || !controller.isPlaying {
                Controls(controller: controller, bridge: bridge, close: close).transition(.opacity)
            }
            PlayerStatus(controller: controller, toast: toast, close: close)
            if UpNextCard.shows(controller), let next = controller.next {
                UpNextCard(controller: controller, next: next)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(24)
            }
        }
        .onChange(of: controller.isPlaying) { nowPlaying.update() }
        .onChange(of: controller.item.id) { nowPlaying.attach(controller, server: app.session?.server) }
    }

    private func start() async {
        guard controller == nil else { return }
        let download = app.downloads.playable(request.item.id)
        let client = download != nil && !app.isOnline ? nil : app.client
        let controller = PlayerController(request: request, client: client, prefs: app.prefs, download: download)
        controller.onFinished = { close() }
        self.controller = controller
        nowPlaying.attach(controller, server: app.session?.server)
        await controller.start(at: Resume.startSeconds(app.userData.current(request.item), explicit: request.start))
    }

    private func stop() {
        app.stopReport = controller?.finish()
        nowPlaying.detach()
        app.downloads.syncProgress()
    }

    private func close() {
        stop()
        app.playing = nil
    }

    private func toggleControls() {
        withAnimation(Theme.fast) { controlsShown.toggle() }
        lastTouch = Date()
    }

    private func hideLater() async {
        try? await Task.sleep(for: .seconds(4))
        guard controller?.isPlaying == true else { return }
        withAnimation(Theme.fade) { controlsShown = false }
    }

    /// Keys from `Keys.action`; Escape closes, `f` toggles fill (the player is always full screen).
    private func handle(_ input: KeyInput, _ controller: PlayerController) -> Bool {
        guard let action = Keys.action(for: input) else { return false }
        switch action {
        case .escape, .stop: close()
        case .fullscreen: bridge.toggleFill()
        default: show(controller.handle(action))
        }
        lastTouch = Date()
        return true
    }

    private func show(_ message: String?) {
        guard let message else { return }
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if toast == message { toast = nil }
        }
    }
}
