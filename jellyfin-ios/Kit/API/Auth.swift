import Foundation

public enum ServerProblem: Error, Equatable, Sendable {
    case unreachable
    case tooOld
}

/// Signing in: finding the server, then a password or Quick Connect.
public enum Auth {
    /// Spaces and trailing slashes go; without a scheme, a secure connection is tried first.
    public static func candidateAddresses(_ input: String) -> [URL] {
        var clean = input.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
        while clean.hasSuffix("/") { clean.removeLast() }
        guard !clean.isEmpty else { return [] }
        if clean.range(of: #"^https?://"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return [URL(string: clean)].compactMap { $0 }
        }
        return ["https://\(clean)", "http://\(clean)"].compactMap(URL.init(string:))
    }

    public static func isSupported(version: String) -> Bool {
        let parts = version.split(separator: ".").compactMap { Int($0) }
        guard parts.count >= 2 else { return false }
        return parts[0] > 10 || (parts[0] == 10 && parts[1] >= 10)
    }

    public static func connect(_ input: String, identity: ClientIdentity) async throws -> SavedServer {
        for address in candidateAddresses(input) {
            let client = APIClient(server: address, token: nil, userId: nil, identity: identity)
            guard let info: PublicSystemInfo = try? await client.get("/System/Info/Public") else { continue }
            guard isSupported(version: info.version ?? "") else { throw ServerProblem.tooOld }
            return SavedServer(address: address, name: info.serverName ?? address.host() ?? "")
        }
        throw ServerProblem.unreachable
    }

    public static func publicUsers(_ client: APIClient) async throws -> [UserDto] {
        try await client.get("/Users/Public")
    }

    public static func signIn(_ client: APIClient, username: String, password: String) async throws -> AuthenticationResult {
        struct Body: Encodable { let username: String; let pw: String }
        return try await client.post("/Users/AuthenticateByName", body: Body(username: username, pw: password))
    }

    public static func quickConnectEnabled(_ client: APIClient) async throws -> Bool {
        try await client.get("/QuickConnect/Enabled")
    }

    public static func startQuickConnect(_ client: APIClient) async throws -> QuickConnectResult {
        try await client.post("/QuickConnect/Initiate")
    }

    public static func checkQuickConnect(_ client: APIClient, secret: String) async throws -> QuickConnectResult {
        try await client.get("/QuickConnect/Connect", [("secret", secret)])
    }

    public static func finishQuickConnect(_ client: APIClient, secret: String) async throws -> AuthenticationResult {
        struct Body: Encodable { let secret: String }
        return try await client.post("/Users/AuthenticateWithQuickConnect", body: Body(secret: secret))
    }

    /// Approve another device's Quick Connect code as the signed-in user.
    public static func approveQuickConnect(_ client: APIClient, code: String) async throws -> Bool {
        let clean = code.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
        return try await client.post("/QuickConnect/Authorize", [("code", clean)])
    }

    public static func signOut(_ client: APIClient) async {
        _ = try? await client.send("POST", "/Sessions/Logout")
    }

    /// Installed as the server's web client, jellyfin-ui owns /web; the stock client moved to /web/stock/.
    public static func dashboardURL(_ server: URL) -> URL {
        URL(string: server.absoluteString + "/web/stock/#/dashboard")!
    }

    public static func session(from result: AuthenticationResult, server: SavedServer) -> (Session, String)? {
        guard let token = result.accessToken, let user = result.user else { return nil }
        let session = Session(
            server: server.address, serverName: server.name, userId: user.id,
            userName: user.name ?? "", isAdmin: user.policy?.isAdministrator ?? false
        )
        return (session, token)
    }
}
