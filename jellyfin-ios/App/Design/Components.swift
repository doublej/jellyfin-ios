import JellyfinKit
import SwiftUI

/// White on 22 % white, as on the web client.
struct ProgressBar: View {
    let percent: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.22))
                Capsule().fill(.white).frame(width: geometry.size.width * min(1, max(0, percent / 100)))
            }
        }
        .frame(height: 3)
        .accessibilityHidden(true)
    }
}

/// Watched tick or unwatched-episode count, top right of a card.
struct WatchBadge: View {
    let item: Item
    @Environment(AppModel.self) private var app

    var body: some View {
        let data = app.userData.data(item)
        if data?.played == true {
            Image(systemName: "checkmark").font(.caption.weight(.bold)).padding(5)
                .background(Theme.text, in: .rect(cornerRadius: Theme.radiusSmall)).foregroundStyle(Theme.base)
                .accessibilityLabel(L10n.t("played_badge"))
        } else if let count = data?.unplayedItemCount, count > 0, item.kind == .series || item.kind == .season {
            Text(verbatim: "\(count)").font(Theme.caption).padding(.horizontal, 6).padding(.vertical, 3)
                .background(Theme.text, in: .rect(cornerRadius: Theme.radiusSmall)).foregroundStyle(Theme.base)
                .accessibilityLabel(L10n.f("unplayed_count", "\(count)"))
        }
    }
}

struct FavoriteMark: View {
    let item: Item
    @Environment(AppModel.self) private var app

    var body: some View {
        if app.userData.isFavorite(item) {
            Image(systemName: "heart.fill").font(.caption).foregroundStyle(Theme.red).padding(6)
                .accessibilityLabel(L10n.t("status_favorite"))
        }
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text).titleStyle(Theme.title2).frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// What to show when a load failed: what happened, and a way to try again.
struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(message).font(Theme.body).foregroundStyle(Theme.text2).multilineTextAlignment(.center)
            Button(L10n.t("retry"), action: retry).buttonStyle(.secondary)
        }
        .padding(32).frame(maxWidth: 480)
    }
}

/// Horizontal gutter that grows with the width, like the web's clamp(16px, 4vw, 72px).
struct Gutter {
    static func of(_ width: CGFloat) -> CGFloat { min(72, max(16, width * 0.04)) }
}
