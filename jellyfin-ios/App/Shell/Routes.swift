import JellyfinKit
import SwiftUI

/// Where a NavigationStack can go. Items travel with the summary already loaded, so a detail
/// page draws its header at once and fills in the rest.
enum Route: Hashable {
    case item(Item)
    case library(Item)
}

/// What the player opens with. Without `start` it resumes from the saved position.
struct PlayRequest: Identifiable, Hashable {
    let id = UUID()
    var item: Item
    var start: Double?
    var sourceId: String?
    var audio: Int?
    var subtitle: Int?
    var queue: [Item] = []
}

extension View {
    func routeDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case let .item(item): ItemScreen(summary: item)
            case let .library(library): LibraryView(library: library)
            }
        }
    }
}

extension Person {
    var asItem: Item {
        var item = Item(id: id, name: name, type: "Person")
        item.imageTags = primaryImageTag.map { ["Primary": $0] }
        item.imageBlurHashes = imageBlurHashes
        return item
    }
}
