import JellyfinKit
import UIKit

/// Artwork from the server: decoded images in memory, raw responses on disk (URLCache), so a
/// warm launch draws Home's posters without the network.
final class ImageLoader: Sendable {
    static let shared = ImageLoader()

    private let memory = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 1 << 30)
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
        memory.totalCostLimit = 160 << 20
    }

    func cached(_ url: URL) -> UIImage? { memory.object(forKey: url as NSURL) }

    func image(_ url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        guard let (data, _) = try? await session.data(from: url), let image = UIImage(data: data) else { return nil }
        let prepared = await image.byPreparingForDisplay() ?? image
        memory.setObject(prepared, forKey: url as NSURL, cost: data.count * 4)
        return prepared
    }

    private static let hashes = NSCache<NSString, UIImage>()

    /// A 32 px BlurHash render, stretched under the real image while it loads.
    static func placeholder(_ hash: String?) -> UIImage? {
        guard let hash else { return nil }
        if let hit = hashes.object(forKey: hash as NSString) { return hit }
        guard let pixels = BlurHash.pixels(hash, width: 32, height: 32) else { return nil }
        let image = Self.image(pixels, width: 32, height: 32)
        if let image { hashes.setObject(image, forKey: hash as NSString) }
        return image
    }

    private static func image(_ pixels: [UInt8], width: Int, height: Int) -> UIImage? {
        let data = Data(pixels) as CFData
        guard let provider = CGDataProvider(data: data),
              let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                    provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
