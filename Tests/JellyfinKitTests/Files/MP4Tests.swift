import Foundation
import JellyfinKit
import Testing

struct MP4Tests {
    /// ftyp, then a moov holding a `hev1` sample entry, then media data that happens to contain `hev1`.
    private func file() throws -> URL {
        func box(_ type: String, _ body: Data) -> Data {
            var size = UInt32(8 + body.count).bigEndian
            return Data(bytes: &size, count: 4) + Data(type.utf8) + body
        }
        let moov = box("moov", box("trak", Data("....stsd....hev1....hvcC".utf8)))
        let data = box("ftyp", Data("isom".utf8)) + moov + box("mdat", Data("hev1".utf8))
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        try data.write(to: url)
        return url
    }

    @Test func retagsHEVCInsideMoovOnly() throws {
        let url = try file()
        #expect(try MP4.retagHEVC(at: url))
        let text = try #require(String(bytes: try Data(contentsOf: url), encoding: .utf8))
        #expect(text.contains("hvc1....hvcC"))
        #expect(text.hasSuffix("mdathev1"))
        #expect(try !MP4.retagHEVC(at: url), "a second pass finds nothing to change")
    }
}
