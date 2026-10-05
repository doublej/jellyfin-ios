import Foundation
@testable import JellyfinKit
import Testing

/// Real server answers captured from the library (file paths removed).
enum Fixture {
    private final class Marker {}

    static func data(_ name: String) throws -> Data {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Marker.self)
        #endif
        let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: "json")
        return try Data(contentsOf: try #require(url))
    }

    static func decode<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        try JSONCoding.decoder.decode(T.self, from: data(name))
    }
}
