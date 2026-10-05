import AVKit
import JellyfinKit
import SwiftUI

/// The overlay: close, title, AirPlay and Picture in Picture on top; transport in the middle;
/// the seek bar, episode steps and track menus at the bottom. Hides itself while playing.
struct Controls: View {
    let controller: PlayerController
    let bridge: PlayerBridge
    let close: () -> Void
    @State private var scrubbing = false
    @State private var showTiming = false

    var body: some View {
        VStack(spacing: 0) {
            top
            Spacer()
            transport
            Spacer()
            bottom
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background { scrim }
        .sheet(isPresented: $showTiming) { SubtitleTiming(controller: controller) }
    }

    private var scrim: some View {
        LinearGradient(stops: [.init(color: .black.opacity(0.7), location: 0), .init(color: .clear, location: 0.3),
                               .init(color: .clear, location: 0.6), .init(color: .black.opacity(0.8), location: 1)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea().allowsHitTesting(false)
    }

    private var top: some View {
        HStack(spacing: 4) {
            Button(action: close) { Image(systemName: "chevron.down").controlIcon() }
                .accessibilityLabel(L10n.t("player_back")).accessibilityIdentifier("player.close")
            VStack(alignment: .leading, spacing: 2) {
                Text(CardText.title(controller.item)).font(Theme.headline).foregroundStyle(.white).lineLimit(1)
                HStack(spacing: 8) {
                    if controller.item.kind == .episode { Text(CardText.subtitle(controller.item)).lineLimit(1) }
                    if let delivery = controller.delivery {
                        Text(L10n.t("delivery_\(delivery.kind.rawValue)")).padding(.horizontal, 5).padding(.vertical, 1)
                            .overlay(RoundedRectangle(cornerRadius: Theme.radiusSmall).stroke(Theme.text3))
                            .accessibilityIdentifier("player.delivery")
                    }
                }
                .font(Theme.caption).foregroundStyle(Theme.text2)
            }
            Spacer()
            RoutePicker().frame(width: 44, height: 44)
            if bridge.pipPossible {
                Button { bridge.togglePictureInPicture() } label: { Image(systemName: "pip.enter").controlIcon() }
                    .accessibilityLabel(L10n.t("player_pip"))
            }
        }
    }

    private var transport: some View {
        HStack(spacing: 44) {
            Button { controller.skip(by: -10) } label: { Image(systemName: "gobackward.10").controlIcon(30) }
                .accessibilityLabel(L10n.t("player_back10"))
            Button { controller.togglePlay() } label: {
                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill").controlIcon(44).frame(width: 72, height: 72)
            }
            .accessibilityLabel(controller.isPlaying ? L10n.t("player_pause") : L10n.t("player_play"))
            .accessibilityIdentifier("player.toggle")
            Button { controller.skip(by: 30) } label: { Image(systemName: "goforward.30").controlIcon(30) }
                .accessibilityLabel(L10n.t("player_forward30"))
        }
        .opacity(controller.loading ? 0 : 1)
    }

    private var bottom: some View {
        VStack(spacing: 4) {
            SeekBar(controller: controller, scrubbing: $scrubbing)
            HStack(spacing: 4) {
                if controller.previous != nil {
                    Button { controller.playPrevious() } label: { Image(systemName: "backward.end.fill").controlIcon() }
                        .accessibilityLabel(L10n.t("player_previous"))
                }
                if controller.next != nil {
                    Button { controller.playNext() } label: { Image(systemName: "forward.end.fill").controlIcon() }
                        .accessibilityLabel(L10n.t("player_next"))
                }
                Spacer()
                Button { bridge.toggleFill() } label: {
                    Image(systemName: bridge.filled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right").controlIcon()
                }
                .accessibilityLabel(L10n.t("player_zoom"))
                TrackMenu(controller: controller, showTiming: $showTiming)
                if controller.download == nil { QualityMenu(controller: controller) }
            }
        }
    }
}

/// AirPlay's own route button.
struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.prioritizesVideoDevices = true
        return view
    }

    func updateUIView(_ view: AVRoutePickerView, context: Context) {}
}
