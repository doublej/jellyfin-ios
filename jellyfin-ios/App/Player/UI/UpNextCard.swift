import JellyfinKit
import SwiftUI

/// Near the end of an episode: the next one, with a countdown when it plays by itself.
struct UpNextCard: View {
    let controller: PlayerController
    let next: Item

    var body: some View {
        HStack(spacing: 14) {
            Artwork(art: next.thumbArt, width: 160).frame(width: 160, height: 90).clipShape(.rect(cornerRadius: Theme.radius))
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("upnext_title")).font(Theme.caption).foregroundStyle(Theme.text2)
                Text(CardText.subtitle(next)).font(Theme.headline).foregroundStyle(.white).lineLimit(2)
                if controller.autoplay {
                    Text(L10n.f("upnext_countdown", "\(remaining)")).font(Theme.caption).foregroundStyle(Theme.text2)
                }
                HStack {
                    Button(L10n.t("upnext_play")) { controller.playNext() }.buttonStyle(.primary)
                    Button(L10n.t("upnext_dismiss")) { controller.upNextDismissed = true }.buttonStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Theme.surface1.opacity(0.95), in: .rect(cornerRadius: Theme.radius))
        .accessibilityIdentifier("player.upnext")
    }

    private var remaining: Int { max(0, Int((controller.duration - controller.time).rounded())) }

    /// Whether the card shows now: past the Up Next point, not hidden by the viewer.
    static func shows(_ controller: PlayerController) -> Bool {
        guard controller.next != nil, !controller.upNextDismissed,
              let start = Timeline.upNextAt(runtime: controller.duration, outroStart: outroStart(controller)) else { return false }
        return controller.time >= start
    }

    private static func outroStart(_ controller: PlayerController) -> Double? {
        controller.segments.first { $0.type == "Outro" }.map { Ticks.seconds($0.startTicks) }
    }
}
