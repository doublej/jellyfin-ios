import Foundation
import JellyfinKit

/// Signs the probe in with Quick Connect. `scripts/xctest.sh` sees the printed code and approves
/// it as the admin, so no password ever reaches the simulator.
enum QuickConnectLogin {
    static let server = URL(string: "http://192.168.178.120:8096")!
    static let identity = ClientIdentity(device: "Probe", deviceId: "jellyfin-ios-probe")

    static func client() async throws -> APIClient {
        let anonymous = APIClient(server: server, token: nil, userId: nil, identity: identity)
        let start = try await Auth.startQuickConnect(anonymous)
        let code = start.code ?? "", secret = start.secret ?? ""
        announce(code)
        for _ in 0..<60 {
            try await Task.sleep(for: .seconds(2))
            guard try await Auth.checkQuickConnect(anonymous, secret: secret).authenticated == true else { continue }
            let result = try await Auth.finishQuickConnect(anonymous, secret: secret)
            var client = APIClient(server: server, token: result.accessToken, userId: result.user?.id, identity: identity)
            client.timeout = 300
            return client
        }
        throw APIError.status(408)
    }

    static func announce(_ code: String) {
        print("JFIOS-QC-CODE=\(code)")
        try? code.write(toFile: "/tmp/jfios-qc-code", atomically: true, encoding: .utf8)
    }
}
