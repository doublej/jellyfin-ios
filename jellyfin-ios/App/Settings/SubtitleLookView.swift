import JellyfinKit
import SwiftUI

/// Size, weight, font, colour, background, edge and height of text subtitles on this device.
struct SubtitleLookView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var prefs = app.prefs
        Form {
            Section { preview }
            Section {
                Slider(value: $prefs.stored.subtitles.size, in: 0.5...2, step: 0.1) { Text(L10n.t("look_size")) }
                Picker(L10n.t("look_weight"), selection: $prefs.stored.subtitles.weight) {
                    ForEach(PlaybackPrefs.SubtitleLook.Weight.allCases, id: \.self) { Text(L10n.t("look_weight_\($0.rawValue)")).tag($0) }
                }
                Picker(L10n.t("look_font"), selection: $prefs.stored.subtitles.font) {
                    ForEach(PlaybackPrefs.SubtitleLook.Font.allCases, id: \.self) { Text(L10n.t("font_\($0.rawValue)")).tag($0) }
                }
                ColorPicker(L10n.t("look_color"), selection: color, supportsOpacity: false)
                Picker(L10n.t("look_background"), selection: $prefs.stored.subtitles.background) {
                    ForEach(PlaybackPrefs.SubtitleLook.Background.allCases, id: \.self) { Text(L10n.t("background_\($0.rawValue)")).tag($0) }
                }
                Picker(L10n.t("look_shadow"), selection: $prefs.stored.subtitles.shadow) {
                    ForEach(PlaybackPrefs.SubtitleLook.Shadow.allCases, id: \.self) { Text(L10n.t("shadow_\($0.rawValue)")).tag($0) }
                }
                Stepper(value: $prefs.stored.subtitles.position, in: -16...16) {
                    Text(verbatim: "\(L10n.t("look_position"))  \(Int(prefs.stored.subtitles.position))")
                }
            }
            Button(L10n.t("look_reset")) { prefs.stored.subtitles = .init() }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.base)
        .navigationTitle(L10n.t("settings_look"))
    }

    private var preview: some View {
        ZStack {
            Color.black
            Captions(events: [TrackEvent(start: 0, end: 10, text: L10n.t("look_preview"))], time: 1, offset: 0,
                     look: app.prefs.stored.subtitles)
        }
        .frame(height: 160)
        .listRowInsets(EdgeInsets())
    }

    private var color: Binding<Color> {
        Binding(get: { Color(hexString: app.prefs.stored.subtitles.color) ?? .white },
                set: { app.prefs.stored.subtitles.color = $0.hexString })
    }
}

extension Color {
    var hexString: String {
        let resolved = resolve(in: EnvironmentValues())
        let channel = { (value: Float) in Int((max(0, min(1, value)) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", channel(resolved.red), channel(resolved.green), channel(resolved.blue))
    }
}
