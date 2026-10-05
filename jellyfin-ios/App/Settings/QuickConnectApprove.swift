import JellyfinKit
import SwiftUI

/// Signing in on another device? Enter the code it shows.
struct QuickConnectApprove: View {
    @Environment(AppModel.self) private var app
    @State private var code = ""
    @State private var result: String?

    var body: some View {
        Section {
            HStack {
                TextField(L10n.t("settings_qc_code"), text: $code).keyboardType(.numberPad).accessibilityIdentifier("settings.qc.code")
                Button(L10n.t("settings_qc_approve"), action: approve).disabled(code.count < 6)
            }
        } header: {
            Text(L10n.t("settings_qc"))
        } footer: {
            Text(result ?? L10n.t("settings_qc_hint"))
        }
    }

    private func approve() {
        guard let client = app.client else { return }
        Task {
            let approved = (try? await Auth.approveQuickConnect(client, code: code)) ?? false
            result = approved ? L10n.t("settings_qc_ok") : L10n.t("settings_qc_bad")
            if approved { code = "" }
        }
    }
}
