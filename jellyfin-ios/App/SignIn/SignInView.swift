import JellyfinKit
import SwiftUI

/// Name and password, user tiles when the server shows any, and the way to Quick Connect.
struct SignInView: View {
    let server: SavedServer
    @Environment(AppModel.self) private var app
    @State private var username = ""
    @State private var password = ""
    @State private var remember = true
    @State private var busy = false
    @State private var message: String?
    @State private var users: [UserDto] = []
    @State private var quickConnect = false
    @FocusState private var passwordFocused: Bool

    var body: some View {
        Form {
            if !users.isEmpty { tiles }
            Section {
                TextField(L10n.t("signin_username"), text: $username)
                    .textContentType(.username).autocorrectionDisabled().textInputAutocapitalization(.never)
                    .accessibilityIdentifier("signin.username")
                SecureField(L10n.t("signin_password"), text: $password)
                    .textContentType(.password).focused($passwordFocused).submitLabel(.go).onSubmit(signIn)
                Toggle(L10n.t("signin_remember"), isOn: $remember).accessibilityIdentifier("signin.remember")
            } header: {
                Text(L10n.f("signin_title", server.name)).titleStyle(Theme.title).textCase(nil).padding(.bottom, 8)
            } footer: {
                if let message { Text(message).foregroundStyle(Theme.red) }
            }
            Section {
                Button(busy ? L10n.t("signin_busy") : L10n.t("signin_submit"), action: signIn).disabled(busy || username.isEmpty)
                Button(L10n.t("qc_button")) { quickConnect = true }.accessibilityIdentifier("signin.quickconnect")
                Button(L10n.t("server_change"), role: .destructive) { app.remember(server: nil) }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationDestination(isPresented: $quickConnect) { QuickConnectView(server: server, remember: remember) }
        .task { users = (try? await Auth.publicUsers(app.anonymousClient(server.address))) ?? [] }
    }

    private var tiles: some View {
        Section {
            ForEach(users, id: \.id) { user in
                Button(user.name ?? "") {
                    username = user.name ?? ""
                    passwordFocused = true
                }
            }
        }
    }

    private func signIn() {
        busy = true
        message = nil
        Task {
            defer { busy = false }
            do {
                let result = try await Auth.signIn(app.anonymousClient(server.address), username: username, password: password)
                guard let (session, token) = Auth.session(from: result, server: server) else { throw APIError.badResponse }
                app.signIn(session, token: token, remember: remember)
            } catch {
                message = Self.message(for: error, server: server.name)
            }
        }
    }

    static func message(for error: Error, server: String) -> String {
        switch error {
        case APIError.status(401), APIError.status(400): L10n.t("signin_invalid")
        case APIError.unreachable: L10n.f("signin_offline", server)
        default: L10n.t("signin_failed")
        }
    }
}
