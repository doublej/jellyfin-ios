import JellyfinKit
import SwiftUI

/// One image from the server in a box sized before it loads, so nothing shifts. The BlurHash
/// shows first; the image fades in over it in 250 ms.
struct Artwork: View {
    let art: Art?
    var width: CGFloat
    var contentMode: ContentMode = .fill
    /// Logos are cut-outs: no surface or BlurHash behind them.
    var transparent = false

    @Environment(AppModel.self) private var app
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if !transparent {
                Theme.surface1
                if let placeholder = ImageLoader.placeholder(art?.hash) { Image(uiImage: placeholder).resizable() }
            }
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode).transition(.opacity)
            }
        }
        .clipped()
        .task(id: url) { await load() }
        .accessibilityHidden(true)
    }

    private var url: URL? {
        guard let art, let server = app.session?.server else { return nil }
        return art.url(server: server, width: Int(width * scale))
    }

    private func load() async {
        guard let url else { return }
        if let hit = ImageLoader.shared.cached(url) {
            image = hit
            return
        }
        let loaded = await ImageLoader.shared.image(url)
        withAnimation(Theme.fade) { image = loaded }
    }
}

/// The page glow: the backdrop's average colour, darkened, read from its BlurHash.
extension Art {
    var tint: Color? {
        guard let color = hash.flatMap(BlurHash.averageColor) else { return nil }
        let dim = 0.45
        return Color(red: color.red * dim, green: color.green * dim, blue: color.blue * dim)
    }
}
