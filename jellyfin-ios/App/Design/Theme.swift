import SwiftUI

/// The projection room (docs/DESIGN.md): the interface is neutral and flat, artwork is the only
/// colour. White is the one accent; red is for favourites and errors.
enum Theme {
    static let base = Color(hex: 0x0D0D0F)
    static let surface1 = Color(hex: 0x16161A)
    static let surface2 = Color(hex: 0x1F1F24)
    static let surface3 = Color(hex: 0x29292F)
    static let line = Color(hex: 0x2B2B31)
    static let text = Color(hex: 0xF1F1EF)
    static let text2 = Color(hex: 0xA2A2A8)
    static let text3 = Color(hex: 0x6C6C73)
    static let red = Color(hex: 0xE5484D)

    static let radius: CGFloat = 6
    static let radiusSmall: CGFloat = 4
    static let fast = Animation.easeOut(duration: 0.14)
    static let fade = Animation.easeOut(duration: 0.25)

    /// Instrument Sans, scaling with Dynamic Type from the given text style.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Instrument Sans", size: size, relativeTo: style).weight(weight)
    }

    static let largeTitle = font(34, .bold, relativeTo: .largeTitle)
    static let title = font(26, .bold, relativeTo: .title)
    static let title2 = font(20, .semibold, relativeTo: .title2)
    static let headline = font(17, .semibold, relativeTo: .headline)
    static let body = font(16)
    static let meta = font(14, relativeTo: .subheadline)
    static let caption = font(12, .medium, relativeTo: .caption)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

extension View {
    /// Titles: heavy and tight (−0.02 em).
    func titleStyle(_ font: Font = Theme.title) -> some View {
        self.font(font).tracking(-0.4).foregroundStyle(Theme.text)
    }

    func metaStyle() -> some View {
        font(Theme.meta).foregroundStyle(Theme.text2)
    }
}

/// White with near-black text: the one primary action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.headline)
            .padding(.horizontal, 20).frame(minHeight: 46)
            .background(Theme.text.opacity(configuration.isPressed ? 0.8 : 1), in: .rect(cornerRadius: Theme.radius))
            .foregroundStyle(Theme.base)
    }
}

/// Solid raised surface for everything else.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.headline)
            .padding(.horizontal, 16).frame(minHeight: 46)
            .background(configuration.isPressed ? Theme.surface3 : Theme.surface2, in: .rect(cornerRadius: Theme.radius))
            .foregroundStyle(Theme.text)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
