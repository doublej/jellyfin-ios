import JellyfinKit
import SwiftUI

/// Loading, failure, the subtitle-loading notice, skip buttons and short toasts.
struct PlayerStatus: View {
    let controller: PlayerController
    let toast: String?
    let close: () -> Void

    var body: some View {
        ZStack {
            if controller.loading, controller.failure == nil { ProgressView().controlSize(.large).tint(.white) }
            if let failure = controller.failure { failed(failure) }
            VStack {
                if controller.subtitlesLoading { notice(L10n.t("subtitles_loading")) }
                if let toast { notice(toast) }
                if let note = controller.failureNotice { notice(note) }
                Spacer()
            }
            .padding(.top, 70)
            if let segment = Timeline.activeSegment(controller.segments, seconds: controller.time) { skip(segment) }
        }
    }

    private func failed(_ failure: PlaybackFailure) -> some View {
        VStack(spacing: 16) {
            Text(L10n.t("err_title")).titleStyle(Theme.title2)
            Text(L10n.t("err_\(failure.rawValue)")).font(Theme.body).foregroundStyle(Theme.text2).multilineTextAlignment(.center)
            HStack {
                Button(L10n.t("retry")) { controller.retry() }.buttonStyle(.primary)
                Button(L10n.t("player_back"), action: close).buttonStyle(.secondary)
            }
        }
        .padding(28).frame(maxWidth: 460)
        .background(Theme.surface1, in: .rect(cornerRadius: Theme.radius))
        .accessibilityIdentifier("player.error")
    }

    private func notice(_ text: String) -> some View {
        Text(text).font(Theme.meta).foregroundStyle(Theme.text).padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.surface1.opacity(0.9), in: .rect(cornerRadius: Theme.radius))
    }

    private func skip(_ segment: MediaSegment) -> some View {
        Button(segment.type == "Outro" ? L10n.t("skip_outro") : L10n.t("skip_intro")) {
            controller.seek(to: Ticks.seconds(segment.endTicks))
        }
        .buttonStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 28).padding(.bottom, 120)
    }
}
