import Foundation

/// User-facing text from Localizable.strings (en base, nl informal). Placeholders are
/// positional `%1$@`, so every argument is passed as a String.
enum L10n {
    static func t(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }

    static func f(_ key: String, _ args: String...) -> String {
        String(format: t(key), locale: .current, arguments: args)
    }
}
