import SwiftUI

/// Poster and still widths: phones fit three posters across and show 2.5 stills, so the
/// overflow is visible; iPads show 6–8 posters per row.
struct CardSize {
    let poster: CGFloat
    let thumb: CGFloat

    static func of(_ sizeClass: UserInterfaceSizeClass?) -> CardSize {
        sizeClass == .regular ? CardSize(poster: 150, thumb: 280) : CardSize(poster: 112, thumb: 250)
    }
}

private struct CardSizeKey: EnvironmentKey {
    static let defaultValue = CardSize.of(.compact)
}

extension EnvironmentValues {
    var cardSize: CardSize {
        get { self[CardSizeKey.self] }
        set { self[CardSizeKey.self] = newValue }
    }
}

/// Pressed cards sink a little, the touch version of the web's focus lift.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1).animation(Theme.fast, value: configuration.isPressed)
    }
}
