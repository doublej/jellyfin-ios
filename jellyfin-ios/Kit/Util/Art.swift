import Foundation

/// One piece of artwork: which item owns it, which image, its cache tag and BlurHash.
/// Ported from jellyfin-ui `src/lib/api/images.ts`.
public struct Art: Hashable, Sendable {
    public var itemId: String
    public var type: String
    public var tag: String
    public var hash: String?
    public var index: Int?

    /// Width buckets, so the image caches hit across screens.
    static let widths = [160, 240, 360, 480, 720, 1080, 1600, 2400]

    public func url(server: URL, width: Int) -> URL {
        let bucket = Self.widths.first { $0 >= width } ?? Self.widths.last!
        let index = self.index.map { "/\($0)" } ?? ""
        let path = "\(server.absoluteString)/Items/\(itemId)/Images/\(type)\(index)?tag=\(tag)&fillWidth=\(bucket)&quality=90"
        return URL(string: path)!
    }
}

public extension Item {
    private func hash(_ type: String, _ tag: String) -> String? { imageBlurHashes?[type]?[tag] }

    private func own(_ type: String) -> Art? {
        imageTags?[type].map { Art(itemId: id, type: type, tag: $0, hash: hash(type, $0)) }
    }

    private var backdrop: Art? {
        if let tag = backdropImageTags?.first { return Art(itemId: id, type: "Backdrop", tag: tag, hash: hash("Backdrop", tag), index: 0) }
        guard let parent = parentBackdropItemId, let tag = parentBackdropImageTags?.first else { return nil }
        return Art(itemId: parent, type: "Backdrop", tag: tag, hash: hash("Backdrop", tag), index: 0)
    }

    private var parentThumb: Art? {
        guard let parent = parentThumbItemId, let tag = parentThumbImageTag else { return nil }
        return Art(itemId: parent, type: "Thumb", tag: tag, hash: hash("Thumb", tag))
    }

    private var seriesPoster: Art? {
        guard let series = seriesId, let tag = seriesPrimaryImageTag else { return nil }
        return Art(itemId: series, type: "Primary", tag: tag, hash: hash("Primary", tag))
    }

    /// 2:3 poster. Episodes fall back to their series' poster.
    var posterArt: Art? {
        kind == .episode ? seriesPoster ?? own("Primary") : own("Primary") ?? seriesPoster
    }

    /// 16:9 still: an episode's own frame, otherwise a thumb or backdrop.
    var thumbArt: Art? {
        kind == .episode ? own("Primary") ?? parentThumb ?? backdrop : own("Thumb") ?? backdrop ?? parentThumb
    }

    var backdropArt: Art? { backdrop ?? own("Thumb") ?? parentThumb }

    var logoArt: Art? {
        if let logo = own("Logo") { return logo }
        guard let parent = parentLogoItemId, let tag = parentLogoImageTag else { return nil }
        return Art(itemId: parent, type: "Logo", tag: tag, hash: hash("Logo", tag))
    }

    var primaryArt: Art? { own("Primary") }

    func chapterArt(_ index: Int) -> Art? {
        guard let tag = chapters?[safe: index]?.imageTag else { return nil }
        return Art(itemId: id, type: "Chapter", tag: tag, index: index)
    }
}

public extension Person {
    var art: Art? {
        primaryImageTag.map { Art(itemId: id, type: "Primary", tag: $0, hash: imageBlurHashes?["Primary"]?[$0]) }
    }
}

public extension Collection {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
