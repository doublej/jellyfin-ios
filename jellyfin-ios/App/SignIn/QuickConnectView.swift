import JellyfinKit
import SwiftUI

/// Shows a code to approve on a device that is already signed in, and waits for it.
struct QuickConnectView: View {
    let server: SavedServer
    let remember: Bool
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var code: String?
    @State private var message: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 24) {
            Text(L10n.t("qc_title")).titleStyle(Theme.title)
            if let code {
                Text(code).font(.system(size: 48, weight: .semibold, design: .monospaced)).tracking(6)
                    .foregroundStyle(Theme.text).textSelection(.enabled)
                    .accessibilityIdentifier("qc.code").accessibilityValue(code)
                Text(L10n.t("qc_instructions")).metaStyle().multilineTextAlignment(.center)
                if message == nil { ProgressView(L10n.t("qc_waiting")).foregroundStyle(Theme.text2) }
            } else if message == nil {
                ProgressView()
            }
            if let message {
                Text(message).foregroundStyle(Theme.red).multilineTextAlignment(.center)
                Button(L10n.t("retry")) { attempt += 1 }.buttonStyle(.secondary)
            }
            Button(L10n.t("qc_cancel")) { dismiss() }.foregroundStyle(Theme.text2)
        }
        .padding(32)
        .task(id: attempt) { await run() }
    }

    private func run() async {
        let client = app.anonymousClient(server.address)
        message = nil
        code = nil
        do {
            guard try await Auth.quickConnectEnabled(client) else { return message = L10n.t("qc_disabled") }
            let start = try await Auth.startQuickConnect(client)
            code = start.code
            try await wait(client, secret: start.secret ?? "")
        } catch is CancellationError {
        } catch APIError.status(401), APIError.status(404) {
            message = L10n.t("qc_expired")
        } catch {
            message = SignInView.message(for: error, server: server.name)
        }
    }

    /// Polls every 3 seconds until the code is approved; the server expires it after a few minutes.
    private func wait(_ client: APIClient, secret: String) async throws {
        while true {
            try await Task.sleep(for: .seconds(3))
            guard try await Auth.checkQuickConnect(client, secret: secret).authenticated == true else { continue }
            let result = try await Auth.finishQuickConnect(client, secret: secret)
            guard let (session, token) = Auth.session(from: result, server: server) else { throw APIError.badResponse }
            return app.signIn(session, token: token, remember: remember)
        }
    }
}
