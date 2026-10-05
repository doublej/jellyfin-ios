import JellyfinKit
import SwiftUI

/// Interface, playback and subtitle preferences, Quick Connect, the stock dashboard and sign-out.
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section(L10n.t("settings_interface")) {
                Button(L10n.t("settings_language")) { openURL(URL(string: UIApplication.openSettingsURLString)!) }
                Text(L10n.t("settings_language_ios")).font(Theme.caption).foregroundStyle(Theme.text3)
            }
            AccountPlaybackSection()
            Section {
                NavigationLink(L10n.t("settings_look")) { SubtitleLookView() }
            } footer: { Text(L10n.t("settings_look_hint")) }
            Section {
                Picker(L10n.t("settings_quality"), selection: Bindable(app.prefs).stored.maxBitrate) {
                    ForEach(Quality.steps, id: \.self) { Text(PlaybackPrefs.label($0)).tag($0) }
                }
                .accessibilityIdentifier("settings.quality")
            } footer: { Text(L10n.t("settings_quality_hint")) }
            QuickConnectApprove()
            if let session = app.session { account(session) }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.base)
        .navigationTitle(L10n.t("settings_title"))
    }

    private func account(_ session: Session) -> some View {
        Section {
            if session.isAdmin {
                Link(destination: Auth.dashboardURL(session.server)) {
                    Label(L10n.t("settings_admin"), systemImage: "arrow.up.forward.app")
                }
                .accessibilityIdentifier("settings.dashboard")
            }
            Button(L10n.t("nav_signout"), role: .destructive) { app.signOut() }.accessibilityIdentifier("settings.signout")
        } header: {
            Text(L10n.f("settings_signed_in", session.userName, session.serverName))
        } footer: {
            if session.isAdmin { Text(L10n.t("settings_admin_hint")) }
        }
    }
}
