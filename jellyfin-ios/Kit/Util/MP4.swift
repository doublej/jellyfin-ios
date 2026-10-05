import Foundation

/// Fix-ups for MP4 files the server writes.
public enum MP4 {
    /// The server's MP4 remux tags HEVC as `hev1`, which AVPlayer on iOS won't decode. The parameter
    /// sets are in the `hvcC` box either way, so renaming the sample entry to `hvc1` makes it play.
    /// Returns whether a tag was changed; a file without `hev1` in its leading `moov` is left alone.
    @discardableResult
    public static func retagHEVC(at url: URL) throws -> Bool {
        let handle = try FileHandle(forUpdating: url)
        defer { try? handle.close() }
        let head = try handle.read(upToCount: 1 << 20) ?? Data()
        guard let moov = head.range(of: Data("moov".utf8)), moov.lowerBound >= 4 else { return false }
        let size = head[(moov.lowerBound - 4)..<moov.lowerBound].reduce(0) { $0 << 8 | Int($1) }
        let end = min(head.count, moov.lowerBound - 4 + size)
        guard end > moov.upperBound, let tag = head.range(of: Data("hev1".utf8), in: moov.upperBound..<end) else { return false }
        try handle.seek(toOffset: UInt64(tag.lowerBound))
        try handle.write(contentsOf: Data("hvc1".utf8))
        return true
    }
}
