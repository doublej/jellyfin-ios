import JellyfinKit
import UIKit

/// Hardware keys as the web's `KeyboardEvent.key` names, so `Keys.action` (the same table as
/// jellyfin-ui's keys.ts) decides what they do.
enum KeyMap {
    static let named: [UIKeyboardHIDUsage: String] = [
        .keyboardLeftArrow: "ArrowLeft", .keyboardRightArrow: "ArrowRight", .keyboardUpArrow: "ArrowUp",
        .keyboardDownArrow: "ArrowDown", .keyboardPageUp: "PageUp", .keyboardPageDown: "PageDown",
        .keyboardHome: "Home", .keyboardEnd: "End", .keyboardEscape: "Escape",
        .keyboardDeleteOrBackspace: "Backspace", .keyboardSpacebar: " "
    ]

    static func input(_ key: UIKey) -> KeyInput? {
        let name = named[key.keyCode] ?? key.charactersIgnoringModifiers
        guard !name.isEmpty else { return nil }
        let flags = key.modifierFlags
        return KeyInput(key: name, shift: flags.contains(.shift), control: flags.contains(.control),
                        option: flags.contains(.alternate), command: flags.contains(.command))
    }
}
