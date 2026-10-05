import JellyfinKit
import SwiftUI

/// Text subtitles drawn over the picture, shifted by the subtitle offset and styled with the
/// device's subtitle appearance. Image subtitles are burned in by the server instead.
struct Captions: View {
    let events: [TrackEvent]
    let time: Double
    let offset: Double
    let look: PlaybackPrefs.SubtitleLook

    var body: some View {
        let cues = Cues.active(events, time: time, offset: offset)
        VStack(spacing: 4) {
            ForEach(Array(cues.enumerated()), id: \.offset) { _, cue in
                ForEach(Array(Cues.parse(cue.text).enumerated()), id: \.offset) { _, line in text(line) }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 24)
        .padding(.bottom, max(8, 48 + CGFloat(look.position + 3) * 12))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func text(_ spans: [Cues.Span]) -> some View {
        spans.reduce(Text(verbatim: "")) { line, span in
            var piece = Text(verbatim: span.text)
            if span.italic { piece = piece.italic() }
            if span.bold { piece = piece.bold() }
            return Text("\(line)\(piece)")
        }
        .font(font)
        .foregroundStyle(Color(hexString: look.color) ?? .white)
        .padding(.horizontal, look.background == .none ? 0 : 6)
        .background(background)
        .shadow(color: .black.opacity(shadowOpacity), radius: look.shadow == .drop ? 3 : 0.5, x: shadowOffset, y: shadowOffset)
    }

    private var font: Font {
        let size = 22 * look.size
        let weight: Font.Weight = look.weight == .bold ? .bold : .medium
        switch look.font {
        case .default: return .system(size: size, weight: weight)
        case .serif: return .system(size: size, weight: weight, design: .serif)
        case .mono: return .system(size: size, weight: weight, design: .monospaced)
        case .casual: return .system(size: size, weight: weight, design: .rounded)
        case .smallcaps: return .system(size: size, weight: weight).lowercaseSmallCaps()
        }
    }

    private var background: Color {
        switch look.background {
        case .none: .clear
        case .shade: .black.opacity(0.4)
        case .box: .black.opacity(0.85)
        }
    }

    private var shadowOpacity: Double { look.shadow == .none ? 0 : 0.95 }
    private var shadowOffset: CGFloat {
        switch look.shadow {
        case .raised: -1
        case .depressed: 1
        case .drop: 2
        case .none, .uniform: 0
        }
    }
}

extension Color {
    init?(hexString: String) {
        let clean = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard clean.count == 6, let value = UInt32(clean, radix: 16) else { return nil }
        self.init(hex: value)
    }
}
