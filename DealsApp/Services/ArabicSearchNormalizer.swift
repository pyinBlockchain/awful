import Foundation

/// Makes Arabic search forgiving of the ways people actually type (CLAUDE.md §3):
/// with or without hamza, taa marbuta vs haa, tashkeel, tatweel, Arabic-Indic digits.
/// Apply the same normalization to the query and to the data.
enum ArabicSearchNormalizer {
    static func normalize(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars where !isIgnorable(scalar) {
            scalars.append(replacements[scalar] ?? scalar)
        }
        // Folding handles Latin case and accents ("Café" → "cafe"). It runs after the Arabic
        // mapping so it has nothing left to decompose on the Arabic side.
        let folded = String(scalars)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                     locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        return folded.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// True when every word of the query appears somewhere in the fields, so
    /// "مشويات عائلي" matches a store tagged "مشويات" whose item says "عائلية".
    static func matches(query: String, in fields: [String]) -> Bool {
        let tokens = normalize(query).split(separator: " ")
        guard !tokens.isEmpty else { return true }
        let haystack = fields.map(normalize).joined(separator: "\n")
        return tokens.allSatisfy { haystack.contains($0) }
    }

    private static let replacements: [Unicode.Scalar: Unicode.Scalar] = {
        var map: [Unicode.Scalar: Unicode.Scalar] = [
            "\u{0623}": "\u{0627}", // أ → ا
            "\u{0625}": "\u{0627}", // إ → ا
            "\u{0622}": "\u{0627}", // آ → ا
            "\u{0671}": "\u{0627}", // ٱ → ا
            "\u{0649}": "\u{064A}", // ى → ي
            "\u{0629}": "\u{0647}", // ة → ه
            "\u{0624}": "\u{0648}", // ؤ → و
            "\u{0626}": "\u{064A}", // ئ → ي
        ]
        // Arabic-Indic (٠–٩) and Persian (۰–۹) digits → 0–9, so "٥٠" finds "50".
        for offset in 0...9 {
            let western = Unicode.Scalar(0x30 + UInt32(offset))!
            map[Unicode.Scalar(0x0660 + UInt32(offset))!] = western
            map[Unicode.Scalar(0x06F0 + UInt32(offset))!] = western
        }
        return map
    }()

    private static func isIgnorable(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x064B...0x065F, 0x0670: return true   // tashkeel, incl. decomposed hamza/madda marks
        case 0x06D6...0x06ED: return true           // Quranic annotation marks
        case 0x0640: return true                    // tatweel ـ
        case 0x200B...0x200F: return true           // zero-width and LRM/RLM from copy-paste
        default: return false
        }
    }
}
