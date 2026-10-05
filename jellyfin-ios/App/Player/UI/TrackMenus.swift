import JellyfinKit
import SwiftUI

/// Audio, subtitles and their timing, and quality: switching keeps the position.
struct TrackMenu: View {
    let controller: PlayerController
    @Binding var showTiming: Bool

    var body: some View {
        Menu {
            Picker(L10n.t("picker_audio"), selection: audio) {
                ForEach(controller.audioTracks, id: \.index) { Text($0.label).tag($0.index) }
            }
            .pickerStyle(.menu)
            Picker(L10n.t("picker_subtitles"), selection: subtitle) {
                Text(L10n.t("subtitles_off")).tag(-1)
                ForEach(controller.subtitleTracks, id: \.index) { Text($0.label).tag($0.index) }
            }
            .pickerStyle(.menu)
            Button(L10n.t("player_subtitle_timing"), systemImage: "timer") { showTiming = true }
        } label: {
            Image(systemName: "captions.bubble").controlIcon()
        }
        .accessibilityLabel(L10n.t("player_tracks"))
        .accessibilityIdentifier("player.tracks")
    }

    private var audio: Binding<Int> {
        Binding(get: { controller.audio ?? -1 }, set: { index in Task { await controller.setAudio(index) } })
    }

    private var subtitle: Binding<Int> {
        Binding(get: { controller.subtitle ?? -1 }, set: { index in Task { await controller.setSubtitle(index) } })
    }
}

struct QualityMenu: View {
    let controller: PlayerController

    var body: some View {
        Menu {
            Picker(L10n.t("player_quality"), selection: quality) {
                ForEach(Quality.steps, id: \.self) { Text(PlaybackPrefs.label($0)).tag($0) }
            }
            DeliveryNote(controller: controller)
        } label: {
            Image(systemName: "dial.medium").controlIcon()
        }
        .accessibilityLabel(L10n.t("player_quality"))
        .accessibilityIdentifier("player.quality")
    }

    private var quality: Binding<Int> {
        Binding(get: { controller.prefs.maxBitrate }, set: { bitrate in Task { await controller.setQuality(bitrate) } })
    }
}

/// Subtitle offset: −30…+30 s in tenths, with the keyboard's g and h doing the same.
struct SubtitleTiming: View {
    let controller: PlayerController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(String(format: "%+.1f s", controller.offset)).font(Theme.title.monospacedDigit())
                        .frame(maxWidth: .infinity).accessibilityIdentifier("timing.value")
                    Slider(value: offset, in: -30...30, step: 0.1).accessibilityLabel(L10n.t("player_subtitle_offset"))
                    HStack {
                        Button(L10n.t("player_subtitle_earlier"), systemImage: "minus") { controller.setOffset(controller.offset - 0.1) }
                        Spacer()
                        Button(L10n.t("player_subtitle_later"), systemImage: "plus") { controller.setOffset(controller.offset + 0.1) }
                    }
                    .labelStyle(.iconOnly).buttonStyle(.bordered)
                }
                Button(L10n.t("player_subtitle_reset")) { controller.setOffset(0) }
            }
            .navigationTitle(L10n.t("player_subtitle_timing"))
            .toolbar { Button(L10n.t("close")) { dismiss() } }
        }
        .presentationDetents([.medium])
    }

    private var offset: Binding<Double> {
        Binding(get: { controller.offset }, set: { controller.setOffset($0) })
    }
}

extension Image {
    func controlIcon(_ size: CGFloat = 22) -> some View {
        font(.system(size: size, weight: .medium)).foregroundStyle(.white).frame(width: 44, height: 44).contentShape(.rect)
    }
}

/// Direct play, remux, or transcoding audio or video, and why: the server's own reasons.
struct DeliveryNote: View {
    let controller: PlayerController

    var body: some View {
        if let delivery = controller.delivery {
            Text(L10n.t("delivery_\(delivery.kind.rawValue)_detail"))
            ForEach(delivery.causes, id: \.self) { Text(reason($0)) }
        }
    }

    private func reason(_ cause: Delivery.Cause) -> String {
        let source = controller.source
        switch cause {
        case .container: return L10n.f("cause_container", (source?.container ?? "").uppercased())
        case .video: return L10n.f("cause_video", source?.video?.codec?.uppercased() ?? "")
        case .audio:
            let track = controller.audioTracks.first { $0.index == controller.audio }
            return L10n.f("cause_audio", track?.codec?.uppercased() ?? "")
        case .subtitles: return L10n.t("cause_subtitles")
        case .bitrate: return L10n.t("cause_bitrate")
        }
    }
}
