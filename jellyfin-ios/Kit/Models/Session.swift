import Foundation

/// The signed-in user on one server. The access token lives in the Keychain, never here.
public struct Session: Codable, Sendable, Hashable {
    public var server: URL
    public var serverName: String
    public var userId: String
    public var userName: String
    public var isAdmin: Bool

    public init(server: URL, serverName: String, userId: String, userName: String, isAdmin: Bool) {
        self.server = server
        self.serverName = serverName
        self.userId = userId
        self.userName = userName
        self.isAdmin = isAdmin
    }
}

public struct SavedServer: Codable, Sendable, Hashable {
    public var address: URL
    public var name: String

    public init(address: URL, name: String) {
        self.address = address
        self.name = name
    }
}

public struct PublicSystemInfo: Codable, Sendable {
    public var serverName: String?
    public var version: String?
}

public struct UserDto: Codable, Sendable, Hashable {
    public var id: String
    public var name: String?
    public var primaryImageTag: String?
    public var policy: UserPolicy?
    public var configuration: UserConfiguration?
}

public struct UserPolicy: Codable, Sendable, Hashable {
    public var isAdministrator: Bool?
}

/// The account-wide playback preferences the Settings screen edits. The server replaces the
/// whole configuration on save, so saving patches these keys into the full object it sent.
public struct UserConfiguration: Codable, Sendable, Hashable {
    public var audioLanguagePreference: String?
    public var playDefaultAudioTrack: Bool?
    public var subtitleLanguagePreference: String?
    public var subtitleMode: String?
    public var enableNextEpisodeAutoPlay: Bool?
    public var rememberAudioSelections: Bool?
    public var rememberSubtitleSelections: Bool?
    public var hidePlayedInLatest: Bool?
    public var displayMissingEpisodes: Bool?

    public init() {}
}

public struct AuthenticationResult: Codable, Sendable {
    public var accessToken: String?
    public var user: UserDto?
}

public struct QuickConnectResult: Codable, Sendable {
    public var authenticated: Bool?
    public var secret: String?
    public var code: String?
}

public struct Culture: Codable, Sendable, Hashable {
    public var displayName: String?
    public var threeLetterISOLanguageName: String?
}
