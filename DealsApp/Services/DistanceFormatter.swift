import CoreLocation

/// "850 م" / "2.4 كم" / "12 كم". Same digit setting as prices (CLAUDE.md §3).
struct DistanceFormatter {
    var language: String = AppLanguage.current
    var digitStyle: PriceFormatter.DigitStyle = PriceFormatter.defaultDigitStyle

    func string(meters: CLLocationDistance) -> String {
        if meters < 1000 {
            // Round to 10 m: GPS isn't more precise than that, and "853 م" looks falsely exact.
            let rounded = max(10, (meters / 10).rounded() * 10)
            return format("distance.meters", number(rounded, fractionDigits: 0))
        }
        let km = meters / 1000
        return format("distance.km", number(km, fractionDigits: km < 10 ? 1 : 0))
    }

    private func format(_ key: String, _ value: String) -> String {
        String(format: Localization.string(key, language: language), value)
    }

    private func number(_ value: Double, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        let western = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return digitStyle == .western ? western : PriceFormatter.toArabicIndic(western)
    }
}
