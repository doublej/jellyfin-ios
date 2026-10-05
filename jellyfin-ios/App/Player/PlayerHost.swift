import AVKit
import JellyfinKit
import SwiftUI

/// What the SwiftUI controls ask of the UIKit side: Picture in Picture and the fill/fit zoom.
@Observable
final class PlayerBridge {
    weak var host: PlayerHostController?
    var pipPossible = false
    var pipActive = false
    var filled = false

    func togglePictureInPicture() {
        guard let pip = host?.pip else { return }
        if pip.isPictureInPictureActive { pip.stopPictureInPicture() } else { pip.startPictureInPicture() }
    }

    func toggleFill() {
        filled.toggle()
        host?.playerLayer.videoGravity = filled ? .resizeAspectFill : .resizeAspect
    }
}

/// The video layer, Picture in Picture, and the hardware keyboard: the parts SwiftUI can't reach.
struct PlayerSurface: UIViewControllerRepresentable {
    let player: AVPlayer
    let bridge: PlayerBridge
    let onKey: (KeyInput) -> Bool

    func makeUIViewController(context: Context) -> PlayerHostController {
        let host = PlayerHostController()
        host.playerLayer.player = player
        host.onKey = onKey
        host.bridge = bridge
        bridge.host = host
        return host
    }

    func updateUIViewController(_ host: PlayerHostController, context: Context) {
        host.onKey = onKey
    }
}

final class PlayerHostController: UIViewController, AVPictureInPictureControllerDelegate {
    final class LayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
    }

    var playerLayer: AVPlayerLayer { (view as? LayerView)?.layer as? AVPlayerLayer ?? AVPlayerLayer() }
    var pip: AVPictureInPictureController?
    var onKey: ((KeyInput) -> Bool)?
    weak var bridge: PlayerBridge?
    private var possible: NSKeyValueObservation?

    override func loadView() {
        view = LayerView()
        view.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        pip = AVPictureInPictureController(playerLayer: playerLayer)
        pip?.canStartPictureInPictureAutomaticallyFromInline = true
        pip?.delegate = self
        possible = pip?.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] pip, _ in
            let value = pip.isPictureInPicturePossible
            Task { @MainActor in self?.bridge?.pipPossible = value }
        }
    }

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let handled = presses.contains { press in press.key.flatMap(KeyMap.input).map { onKey?($0) ?? false } ?? false }
        if !handled { super.pressesBegan(presses, with: event) }
    }

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in bridge?.pipActive = true }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in bridge?.pipActive = false }
    }
}
