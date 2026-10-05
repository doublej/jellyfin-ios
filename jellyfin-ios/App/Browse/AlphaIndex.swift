import SwiftUI

/// The letter strip on the right edge, like Contacts: a tap shows only titles from that letter;
/// a second tap on it shows all again.
struct AlphaIndex: View {
    @Binding var selection: String?
    static let letters = ["#"] + (65...90).map { String(UnicodeScalar($0)) }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Self.letters, id: \.self) { letter in
                Button { selection = selection == letter ? nil : letter } label: {
                    Text(letter).font(.system(size: 11, weight: selection == letter ? .heavy : .semibold))
                        .foregroundStyle(selection == letter ? Theme.base : Theme.text2)
                        .frame(width: 18, height: 17)
                        .background(selection == letter ? Theme.text : .clear, in: .rect(cornerRadius: 3))
                }
                .accessibilityLabel(letter == "#" ? "0–9" : letter)
            }
        }
        .padding(.trailing, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.t("alpha_label"))
        .accessibilityIdentifier("browse.alpha")
    }
}
