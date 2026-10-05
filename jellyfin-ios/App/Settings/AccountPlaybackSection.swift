import JellyfinKit
import SwiftUI

/// Audio and subtitle languages, subtitle mode and autoplay: saved to the account on the server,
/// so every device uses them.
struct AccountPlaybackSection: View {
    @Environment(AppModel.self) private var app
    @State private var config: UserConfiguration?
    @State private var cultures: [Culture] = []
    @State private var status: String?

    static let modes = ["Default", "Smart", "OnlyForced", "Always", "None"]

    var body: some View {
        Section {
            if config != nil { fields } else { ProgressView() }
        } header: {
            Text(L10n.t("settings_playback"))
        } footer: {
            Text(status ?? L10n.t("settings_playback_hint"))
        }
        .task { await load() }
    }

    @ViewBuilder private var fields: some View {
        language(L10n.t("settings_audio_language"), \.audioLanguagePreference)
        Toggle(L10n.t("settings_default_audio"), isOn: flag(\.playDefaultAudioTrack))
        language(L10n.t("settings_subtitle_language"), \.subtitleLanguagePreference)
        Picker(L10n.t("settings_subtitle_mode"), selection: text(\.subtitleMode, fallback: "Default")) {
            ForEach(Self.modes, id: \.self) { Text(L10n.t("mode_\($0)")).tag($0) }
        }
        Toggle(L10n.t("settings_autoplay"), isOn: flag(\.enableNextEpisodeAutoPlay)).accessibilityIdentifier("settings.autoplay")
    }

    private func language(_ title: String, _ path: WritableKeyPath<UserConfiguration, String?>) -> some View {
        Picker(title, selection: text(path, fallback: "")) {
            Text(L10n.t("settings_any_language")).tag("")
            ForEach(cultures, id: \.threeLetterISOLanguageName) { Text($0.displayName ?? "").tag($0.threeLetterISOLanguageName ?? "") }
        }
    }

    private func text(_ path: WritableKeyPath<UserConfiguration, String?>, fallback: String) -> Binding<String> {
        Binding(get: { config?[keyPath: path] ?? fallback }, set: { value in change { $0[keyPath: path] = value } })
    }

    private func flag(_ path: WritableKeyPath<UserConfiguration, Bool?>) -> Binding<Bool> {
        Binding(get: { config?[keyPath: path] ?? false }, set: { value in change { $0[keyPath: path] = value } })
    }

    private func change(_ edit: (inout UserConfiguration) -> Void) {
        guard var next = config else { return }
        edit(&next)
        config = next
        Task {
            do {
                try await app.client?.saveConfiguration(next)
                status = L10n.t("settings_saved")
            } catch {
                status = L10n.t("settings_save_failed")
            }
        }
    }

    private func load() async {
        guard let client = app.client else { return }
        config = (try? await client.me())?.configuration
        cultures = ((try? await client.cultures()) ?? []).filter { $0.threeLetterISOLanguageName != nil }
            .sorted { ($0.displayName ?? "") < ($1.displayName ?? "") }
    }
}
