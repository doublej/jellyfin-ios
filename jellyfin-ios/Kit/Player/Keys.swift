import Foundation

/// The player's keyboard shortcuts, the same keys as jellyfin-ui `src/lib/player/rules/keys.ts`.
/// Key names follow the web's `KeyboardEvent.key`: "k", " ", "ArrowLeft", "PageUp", "Escape".
public enum PlayerAction: Equatable, Sendable {
    case toggle, back, forward, mute, fullscreen, previous, next, nextChapter, previousChapter
    case volumeUp, volumeDown, subtitleEarlier, subtitleLater, start, end, escape, stop
    case percent(Int)
}

public struct KeyInput: Sendable {
    public var key: String
    public var shift = false
    public var control = false
    public var option = false
    public var command = false

    public init(key: String, shift: Bool = false, control: Bool = false, option: Bool = false, command: Bool = false) {
        self.key = key
        self.shift = shift
        self.control = control
        self.option = option
        self.command = command
    }
}

public enum Keys {
    static let always: [String: PlayerAction] = [
        " ": .toggle, "k": .toggle, "j": .back, "l": .forward, "m": .mute, "f": .fullscreen,
        "g": .subtitleEarlier, "h": .subtitleLater, "PageUp": .nextChapter, "PageDown": .previousChapter,
        "Escape": .escape, "Backspace": .escape,
        "MediaPlayPause": .toggle, "MediaPlay": .toggle, "MediaPause": .toggle, "MediaStop": .stop,
        "MediaTrackNext": .next, "MediaTrackPrevious": .previous,
        "MediaFastForward": .forward, "MediaRewind": .back
    ]

    static let shifted: [String: PlayerAction] = ["P": .previous, "N": .next]

    /// Arrows and Home/End seek and set volume only while no control has focus.
    static let whenUnfocused: [String: PlayerAction] = [
        "ArrowLeft": .back, "ArrowRight": .forward, "ArrowUp": .volumeUp, "ArrowDown": .volumeDown,
        "Home": .start, "End": .end
    ]

    /// Modifier keys (other than Shift) switch the shortcuts off, so system shortcuts still work.
    public static func action(for input: KeyInput, controlFocused: Bool = false) -> PlayerAction? {
        if input.control || input.option || input.command { return nil }
        let key = input.key
        if input.shift { return shifted[key.uppercased()] }
        if key.count == 1, let digit = Int(key) { return .percent(digit * 10) }
        if let action = always[key.count == 1 ? key.lowercased() : key] { return action }
        return controlFocused ? nil : whenUnfocused[key]
    }
}
