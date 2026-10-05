import Foundation

/// BlurHash (blurha.sh) decoding: the placeholder an image fades in over, and the average
/// colour that tints hero, detail and player pages.
public enum BlurHash {
    static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~")
    static let digits: [Character: Int] = Dictionary(uniqueKeysWithValues: alphabet.enumerated().map { ($1, $0) })

    public struct RGB: Sendable, Equatable {
        public var red: Double
        public var green: Double
        public var blue: Double
    }

    /// The DC component: the image's average colour as sRGB 0–1.
    public static func averageColor(_ hash: String) -> RGB? {
        let chars = Array(hash)
        guard chars.count >= 6, let value = decode83(chars[2..<6]) else { return nil }
        return RGB(red: Double(value >> 16) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }

    /// RGBA pixels, `width × height`, or nil for a malformed hash.
    public static func pixels(_ hash: String, width: Int, height: Int) -> [UInt8]? {
        guard let colors = components(hash) else { return nil }
        var out = [UInt8](repeating: 255, count: width * height * 4)
        for row in 0..<height {
            for column in 0..<width {
                let color = pixel(colors, x: column, y: row, width: width, height: height)
                let offset = (row * width + column) * 4
                out[offset] = linearToSRGB(color.red)
                out[offset + 1] = linearToSRGB(color.green)
                out[offset + 2] = linearToSRGB(color.blue)
            }
        }
        return out
    }

    struct Components {
        var columns: Int
        var rows: Int
        var colors: [RGB]
    }

    static func components(_ hash: String) -> Components? {
        let chars = Array(hash)
        guard chars.count >= 6, let size = decode83(chars[0..<1]), let quant = decode83(chars[1..<2]) else { return nil }
        let rows = size / 9 + 1, columns = size % 9 + 1
        guard chars.count == 4 + 2 * columns * rows, let average = decode83(chars[2..<6]) else { return nil }
        let maximum = Double(quant + 1) / 166
        var colors = [RGB(red: srgbToLinear(average >> 16), green: srgbToLinear((average >> 8) & 255), blue: srgbToLinear(average & 255))]
        for index in 1..<(columns * rows) {
            guard let value = decode83(chars[(4 + index * 2)..<(6 + index * 2)]) else { return nil }
            colors.append(decodeAC(value, maximum: maximum))
        }
        return Components(columns: columns, rows: rows, colors: colors)
    }

    static func pixel(_ parts: Components, x: Int, y: Int, width: Int, height: Int) -> RGB {
        var red = 0.0, green = 0.0, blue = 0.0
        for row in 0..<parts.rows {
            for column in 0..<parts.columns {
                let basis = cos(.pi * Double(x * column) / Double(width)) * cos(.pi * Double(y * row) / Double(height))
                let color = parts.colors[column + row * parts.columns]
                red += color.red * basis
                green += color.green * basis
                blue += color.blue * basis
            }
        }
        return RGB(red: red, green: green, blue: blue)
    }

    static func decode83(_ chars: ArraySlice<Character>) -> Int? {
        var value = 0
        for char in chars {
            guard let digit = digits[char] else { return nil }
            value = value * 83 + digit
        }
        return value
    }

    static func decodeAC(_ value: Int, maximum: Double) -> RGB {
        let channel = { (step: Int) -> Double in
            let normalised = Double(step - 9) / 9
            return (normalised < 0 ? -1 : 1) * normalised * normalised * maximum
        }
        return RGB(red: channel(value / (19 * 19)), green: channel((value / 19) % 19), blue: channel(value % 19))
    }

    static func srgbToLinear(_ value: Int) -> Double {
        let unit = Double(value) / 255
        return unit <= 0.04045 ? unit / 12.92 : pow((unit + 0.055) / 1.055, 2.4)
    }

    static func linearToSRGB(_ value: Double) -> UInt8 {
        let unit = max(0, min(1, value))
        let srgb = unit <= 0.003_130_8 ? unit * 12.92 : 1.055 * pow(unit, 1 / 2.4) - 0.055
        return UInt8((srgb * 255).rounded())
    }
}
