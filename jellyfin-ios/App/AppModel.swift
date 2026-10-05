import JellyfinKit
import Network
import SwiftUI
import UIKit

/// Who is signed in where, and the API client for them. "Remember me" decides whether the
/// session survives the app closing: the token then sits in the Keychain, otherwise in memory.
@Observable
final class AppModel {
    private(set) var session: Session?
    private(set) var savedServer: SavedServer?
    private(set) var isOnline = true
    /// What the full-screen player shows; nil when it is closed.
    var playing: PlayRequest?
    private var token: String?
    private let monitor = NWPathMonitor()

    let identity: ClientIdentity
    let userData = UserDataStore()
    let downloads: DownloadManager
    let prefs = PlaybackPrefs()

    private static let sessionKey = "jf.session", serverKey = "jf.server", deviceKey = "jf.device"

    init() {
        identity = ClientIdentity(device: UIDevice.current.model, deviceId: Self.deviceId())
        downloads = DownloadManager.shared
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") { Self.reset() }
        savedServer = Self.load(SavedServer.self, Self.serverKey)
        if let saved = Self.load(Session.self, Self.sessionKey), let token = Keychain.token(account: saved.userId) {
            session = saved
            self.token = token
        }
        downloads.app = self
        watchNetwork()
    }

    var client: APIClient? {
        guard let session, let token else { return nil }
        return APIClient(server: session.server, token: token, userId: session.userId, identity: identity)
    }

    func play(_ request: PlayRequest) { playing = request }

    func anonymousClient(_ server: URL) -> APIClient {
        APIClient(server: server, token: nil, userId: nil, identity: identity)
    }

    func remember(server: SavedServer?) {
        savedServer = server
        Self.store(server, Self.serverKey)
    }

    func signIn(_ session: Session, token: String, remember: Bool) {
        self.session = session
        self.token = token
        userData.clear()
        guard remember else { return }
        Self.store(session, Self.sessionKey)
        Keychain.save(token, account: session.userId)
    }

    func signOut() {
        if let client { Task { await Auth.signOut(client) } }
        if let session { Keychain.delete(account: session.userId) }
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
        session = nil
        token = nil
    }

    /// A 401 means the token was revoked on the server: back to sign-in.
    func check(_ error: Error) {
        if case APIError.status(401) = error { signOut() }
    }

    private func watchNetwork() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in self?.networkChanged(path.status == .satisfied) }
        }
        monitor.start(queue: .global(qos: .utility))
    }

    private func networkChanged(_ online: Bool) {
        isOnline = online
        if online { downloads.syncProgress() }
    }

    private static func deviceId() -> String {
        if let id = UserDefaults.standard.string(forKey: deviceKey) { return id }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: deviceKey)
        return id
    }

    private static func reset() {
        if let saved = load(Session.self, sessionKey) { Keychain.delete(account: saved.userId) }
        for key in [sessionKey, serverKey] { UserDefaults.standard.removeObject(forKey: key) }
        HomeCache.clear()
    }

    static func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    static func store<T: Encodable>(_ value: T?, _ key: String) {
        let data = value.flatMap { try? JSONEncoder().encode($0) }
        UserDefaults.standard.set(data, forKey: key)
    }
}
