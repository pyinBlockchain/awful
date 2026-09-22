import Foundation

/// The ONE place prices become text: "120 ر.س" in Arabic, "SAR 120" in English.
/// Whole riyals show no decimals; anything else shows two (decision log §11.9).
struct PriceFormatter {
    enum DigitStyle {
        case western      // 0–9
        case arabicIndic  // ٠–٩
    }

    /// App-wide digit setting (CLAUDE.md §3: Western digits by default, configurable here).
    static let defaultDigitStyle: DigitStyle = .western

    var language: String = AppLanguage.current
    var digitStyle: DigitStyle = PriceFormatter.defaultDigitStyle

    func string(sar amount: Double) -> String {
        let format = Localization.string("price.sar.format", language: language)
        return String(format: format, number(amount))
    }

    /// The bare number, e.g. "1,250" or "12.50".
    func number(_ amount: Double) -> String {
        let halalas = DiscountCalculator.halalas(amount)
        let formatter = halalas % 100 == 0 ? Self.wholeFormatter : Self.fractionFormatter
        let value = NSDecimalNumber(value: halalas).dividing(by: 100)
        let western = formatter.string(from: value) ?? "\(amount)"
        return digitStyle == .western ? western : Self.toArabicIndic(western)
    }

    private static let wholeFormatter = makeFormatter(fractionDigits: 0)
    private static let fractionFormatter = makeFormatter(fractionDigits: 2)

    // POSIX locale pins separators to "," and "."; digit style is applied separately
    // so the setting doesn't depend on the device region.
    private static func makeFormatter(fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.decimalSeparator = "."
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter
    }

    private static func toArabicIndic(_ text: String) -> String {
        String(text.map { char -> Character in
            switch char {
            case "0"..."9":
                let offset = char.unicodeScalars.first!.value - 0x30
                return Character(Unicode.Scalar(0x0660 + offset)!)
            case ".": return "\u{066B}" // Arabic decimal separator ٫
            case ",": return "\u{066C}" // Arabic thousands separator ٬
            default: return char
            }
        })
    }
}

extension PriceFormatter {
    /// "40%" (or "٤٠٪" with Arabic-Indic digits). Lives here so ALL numbers share one
    /// digit setting.
    func percent(_ value: Int) -> String {
        let format = Localization.string("percent.format", language: language)
        let text = String(format: format, number(Double(value)))
        // Inside Arabic text the bidi algorithm moves "%" to the other side ("%50").
        // A left-to-right isolate keeps it reading "50%" everywhere, matching the chips.
        return language == "ar" ? "\u{2066}\(text)\u{2069}" : text
    }
}
