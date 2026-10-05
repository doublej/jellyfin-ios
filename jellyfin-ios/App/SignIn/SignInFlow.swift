import JellyfinKit
import SwiftUI

/// Signed out: find the server, then sign in with a password or Quick Connect.
struct SignInFlow: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationStack {
            Group {
                if let server = app.savedServer {
                    SignInView(server: server)
                } else {
                    ServerView()
                }
            }
            .frame(maxWidth: 440)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.base)
        }
    }
}

struct ServerView: View {
    @Environment(AppModel.self) private var app
    @State private var address = ""
    @State private var busy = false
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                TextField(L10n.t("server_label"), text: $address)
                    .textContentType(.URL).keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                    .submitLabel(.go).onSubmit(connect)
                    .accessibilityIdentifier("server.address")
            } header: {
                Text(L10n.t("server_title")).titleStyle(Theme.title).textCase(nil).padding(.bottom, 8)
            } footer: {
                Text(message ?? L10n.t("server_hint")).foregroundStyle(message == nil ? Theme.text3 : Theme.red)
            }
            Button(busy ? L10n.t("server_connecting") : L10n.t("server_connect"), action: connect)
                .disabled(busy || address.isEmpty).accessibilityIdentifier("server.connect")
        }
        .scrollContentBackground(.hidden)
    }

    private func connect() {
        busy = true
        message = nil
        Task {
            defer { busy = false }
            do {
                app.remember(server: try await Auth.connect(address, identity: app.identity))
            } catch ServerProblem.tooOld {
                message = L10n.t("server_too_old")
            } catch {
                message = L10n.t("server_unreachable")
            }
        }
    }
}
