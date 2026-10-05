import JellyfinKit
import SwiftUI

/// Scrubbing with a trickplay preview above the thumb when the item has thumbnails; otherwise
/// just the time.
struct SeekBar: View {
    let controller: PlayerController
    @Binding var scrubbing: Bool
    @State private var value = 0.0
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    if scrubbing { preview.offset(x: previewX(geometry.size.width), y: -34) }
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 0)
            Slider(value: $value, in: 0...max(1, controller.duration)) { editing in
                scrubbing = editing
                if !editing { controller.seek(to: value) }
            }
            .tint(.white)
            .accessibilityLabel(L10n.t("player_seek"))
            .accessibilityValue(Format.clock(value))
            .accessibilityIdentifier("player.seek")
            times
        }
        .onChange(of: controller.time) { _, time in if !scrubbing { value = time } }
    }

    private var times: some View {
        HStack {
            Text(Format.clock(scrubbing ? value : controller.time)).accessibilityIdentifier("player.time")
            Spacer()
            Button { app.prefs.stored.showRemaining.toggle() } label: {
                Text(app.prefs.stored.showRemaining
                     ? L10n.f("player_remaining", Format.clock(controller.duration - value))
                     : Format.clock(controller.duration))
            }
        }
        .font(Theme.caption.monospacedDigit()).foregroundStyle(Theme.text2)
    }

    private var tileWidth: CGFloat { 200 }

    private func previewX(_ width: CGFloat) -> CGFloat {
        let fraction = controller.duration > 0 ? value / controller.duration : 0
        return min(max(0, width * fraction - tileWidth / 2), max(0, width - tileWidth))
    }

    @ViewBuilder private var preview: some View {
        VStack(spacing: 4) {
            TrickplayTile(controller: controller, seconds: value, width: tileWidth)
            Text(Format.clock(value)).font(Theme.caption.monospacedDigit()).foregroundStyle(Theme.text)
        }
    }
}

/// One thumbnail cut from the server's trickplay sprite sheet.
struct TrickplayTile: View {
    let controller: PlayerController
    let seconds: Double
    let width: CGFloat
    @State private var sheet: UIImage?
    @State private var sheetIndex = -1

    var body: some View {
        if let info, let tile = Timeline.trickplayTile(info, seconds: seconds) {
            let height = width * CGFloat(tile.height) / CGFloat(max(1, tile.width))
            ZStack {
                Color.black
                if let image = crop(tile) { Image(uiImage: image).resizable() }
            }
            .frame(width: width, height: height)
            .clipShape(.rect(cornerRadius: Theme.radiusSmall))
            .task(id: tile.sheet) { await load(tile.sheet, info: info) }
        }
    }

    private var info: TrickplayInfo? {
        guard let sourceId = controller.source?.id ?? controller.item.mediaSources?.first?.id else { return nil }
        return Timeline.pickTrickplay(controller.item.trickplay?[sourceId])
    }

    private func load(_ index: Int, info: TrickplayInfo) async {
        guard let client = controller.client, let sourceId = controller.source?.id, let width = info.width else { return }
        let url = client.trickplayTileURL(itemId: controller.item.id, sourceId: sourceId, width: width, sheet: index)
        sheet = await ImageLoader.shared.image(url)
        sheetIndex = index
    }

    private func crop(_ tile: Timeline.Tile) -> UIImage? {
        guard sheetIndex == tile.sheet, let cgImage = sheet?.cgImage else { return nil }
        let rect = CGRect(x: tile.x, y: tile.y, width: tile.width, height: tile.height)
        return cgImage.cropping(to: rect).map { UIImage(cgImage: $0) }
    }
}
