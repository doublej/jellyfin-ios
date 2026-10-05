import Foundation

/// Who this app is to the server, sent with every call in the `Authorization` header.
public struct ClientIdentity: Sendable, Hashable {
    public static let clientName = "Jellyfin UI iOS"
    public static let version = "0.1.0"

    public var device: String
    public var deviceId: String

    public init(device: String, deviceId: String) {
        self.device = device
        self.deviceId = deviceId
    }

    public func header(token: String?) -> String {
        var parts = [
            #"Client="\#(Self.clientName)""#, #"Device="\#(device)""#,
            #"DeviceId="\#(deviceId)""#, #"Version="\#(Self.version)""#
        ]
        if let token { parts.append(#"Token="\#(token)""#) }
        return "MediaBrowser " + parts.joined(separator: ", ")
    }
}

public enum APIError: Error, Equatable, Sendable {
    case status(Int)
    case unreachable
    case badResponse
}

public typealias Query = [(String, String?)]

/// One server, one user. Every call is a plain `URLSession` request; non-2xx throws.
public struct APIClient: Sendable {
    public let server: URL
    public let token: String?
    public let identity: ClientIdentity
    public let userId: String?
    /// Seconds before a call gives up. The server can take minutes on a library-wide query
    /// while a scheduled task reads the disks.
    public var timeout: TimeInterval = 30
    let session: URLSession

    public init(server: URL, token: String?, userId: String?, identity: ClientIdentity, session: URLSession = .shared) {
        self.server = server
        self.token = token
        self.userId = userId
        self.identity = identity
        self.session = session
    }

    public func url(_ path: String, _ query: Query = []) -> URL {
        var parts = URLComponents(url: server.appending(path: path), resolvingAgainstBaseURL: false)!
        let items = query.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }
        parts.queryItems = items.isEmpty ? nil : items
        return parts.url!
    }

    public func get<T: Decodable>(_ path: String, _ query: Query = []) async throws -> T {
        try JSONCoding.decoder.decode(T.self, from: await send("GET", path, query))
    }

    public func post<T: Decodable>(_ path: String, _ query: Query = [], body: (any Encodable)? = nil) async throws -> T {
        try JSONCoding.decoder.decode(T.self, from: await send("POST", path, query, body: body))
    }

    @discardableResult
    public func send(_ method: String, _ path: String, _ query: Query = [], body: (any Encodable)? = nil,
                     json: Data? = nil) async throws -> Data {
        var request = URLRequest(url: url(path, query), timeoutInterval: timeout)
        request.httpMethod = method
        request.setValue(identity.header(token: token), forHTTPHeaderField: "Authorization")
        request.httpBody = try json ?? body.map { try JSONCoding.encoder.encode($0) }
        if request.httpBody != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        return try await perform(request)
    }

    func perform(_ request: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code != .cancelled {
            throw APIError.unreachable
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.status(http.statusCode) }
        return data
    }

    func requireUser() throws -> String {
        guard let userId else { throw APIError.status(401) }
        return userId
    }
}

/// An empty JSON answer, for calls whose response body doesn't matter.
public struct Empty: Decodable, Sendable {}
